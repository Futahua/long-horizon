# win-identity-lib.ps1 — native window-instance identity probe (Lane 4)
#
# PROBE ONLY. Reads native window facts and exercises SetProp/GetProp against
# windows owned by processes launched BY THIS PROBE. It never mutates, moves,
# hides, retags or closes any pre-existing application window.
#
# Evidence rule: every claim in the Lane 4 findings must come from here or from
# an equivalent direct measurement, never from API memory.

$ErrorActionPreference = 'Stop'

if (-not ('WhProbe.Win32' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

namespace WhProbe {
  public delegate bool EnumProc(IntPtr h, IntPtr p);

  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left, Top, Right, Bottom; }

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct GUITHREADINFO {
    public int cbSize;
    public int flags;
    public IntPtr hwndActive, hwndFocus, hwndCapture, hwndMenuOwner, hwndMoveSize, hwndCaret;
    public RECT rcCaret;
  }

  public static class Win32 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowExW(IntPtr parent, IntPtr after, string cls, string title);

    // Per-HWND property store. NOTE (measured, probe-02): SetPropW's value is a
    // bare pointer-sized integer. Passing a pointer to a string that the CALLER
    // allocated leaves that pointer in the property store, and every later reader
    // -- in any process -- dereferences freed memory. It is not a copy.
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetPropW(IntPtr h, string name, IntPtr value);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetPropW(IntPtr h, string name);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr RemovePropW(IntPtr h, string name);

    // The portable alternative: the value IS an integer (a global atom), so no
    // pointer is ever stored and no reader has to trust foreign memory.
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalAddAtomW(string name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalFindAtomW(string name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalDeleteAtom(ushort atom);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    public static extern uint GlobalGetAtomNameW(ushort atom, StringBuilder buffer, int size);

    // Owner-attached metadata (the documented path when the helper owns a
    // surrogate HWND on behalf of a foreign window).
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SetWindowSubclass(IntPtr h, IntPtr proc, UIntPtr id, UIntPtr data);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool GetWindowSubclassInfo(IntPtr h, IntPtr proc, UIntPtr id, out UIntPtr data);

    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint cmd);
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint flags);
    [DllImport("user32.dll", SetLastError = true)] public static extern uint GetWindowThreadProcessId(uint h, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint tid, ref GUITHREADINFO info);

    // ---- round two -------------------------------------------------------
    // Session scope: same-session reconnect vs different logon session.
    [DllImport("kernel32.dll", SetLastError = true)] public static extern bool ProcessIdToSessionId(uint pid, out uint session);
    [DllImport("user32.dll")] public static extern bool SetWindowTextW(IntPtr h, string t);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);

    // Build number, for deciding whether the process-incarnation field exists.
    [DllImport("ntdll.dll")] public static extern int RtlGetVersion(ref RTL_OSVERSIONINFOW info);

    // Undocumented-but-stable process incarnation. SequenceNumber exists in
    // SystemBasicProcessInformation on recent builds; on older ones the field is
    // absent and the documented FILETIME creation time is the fallback.
    [DllImport("ntdll.dll")] public static extern int NtQuerySystemInformation(int cls, IntPtr info, int len, out int ret);
    [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);
    [DllImport("kernel32.dll", SetLastError = true)] public static extern bool CloseHandle(IntPtr h);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct RTL_OSVERSIONINFOW {
      public uint dwOSVersionInfoSize;
      public uint dwMajorVersion, dwMinorVersion, dwBuildNumber, dwPlatformId;
      [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string szCSDVersion;
    }

    // SYSTEM_PROCESS_INFORMATION, current revision. Fields up to and including
    // SequenceNumber are stable across supported Windows versions; the remainder
    // (threads) is not walked, so trailing-layout drift is irrelevant here.
    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEM_PROCESS_INFORMATION {
      public uint NextEntryOffset;
      public uint NumberOfThreads;
      public byte Reserved1_0, Reserved1_1, Reserved1_2, Reserved1_3;
      public byte Reserved1_4, Reserved1_5, Reserved1_6, Reserved1_7;
      public IntPtr Reserved2_0, Reserved2_1, Reserved2_2;
      public IntPtr UniqueProcessId;
      public IntPtr Reserved3;
      public uint HandleCount;
      public uint SessionId;
      public IntPtr Reserved4;
      public IntPtr PeakVirtualSize;
      public IntPtr VirtualSize;
      public uint Reserved5;
      public IntPtr PeakWorkingSetSize;
      public IntPtr WorkingSetSize;
      public IntPtr Reserved6;
      public IntPtr QuotaPagedPoolUsage;
      public IntPtr QuotaNonPagedPoolUsage;
      public IntPtr PagefileUsage;
      public IntPtr PeakPagefileUsage;
      public IntPtr PrivatePageCount;
      public long Reserved7_0, Reserved7_1, Reserved7_2, Reserved7_3, Reserved7_4, Reserved7_5;
      public uint SequenceNumber;
    }
  }
}
'@
}

# ---------------------------------------------------------------------------
# Identity signals Windows will give us for one HWND
# ---------------------------------------------------------------------------

# Process facts are expensive (CIM + Get-Process). One bulk query per refresh,
# cached, instead of one query per window per enumeration. A measurement
# instrument that takes 8s to look at the desktop cannot measure it.
$script:ProcFactsCache = $null
$script:ProcFactsAt = [datetime]::MinValue

function Update-ProbeProcessFacts {
  param([int]$MaxAgeMs = 2000)
  if ($script:ProcFactsCache -and ((Get-Date) - $script:ProcFactsAt).TotalMilliseconds -lt $MaxAgeMs) { return }
  $table = @{}
  foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
    $path = $null
    $start = $null
    try { $path = $p.Path } catch { }
    try { $start = $p.StartTime.ToUniversalTime() } catch { }
    $table[[int]$p.Id] = [pscustomobject]@{ Path = $path; StartUtc = $start; Pid = [int]$p.Id }
  }
  # Corroborate creation time against a second, independent source.
  try {
    foreach ($c in (Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
      $cimStart = $c.CreationDate.ToUniversalTime()
      $entry = $table[[int]$c.ProcessId]
      if ($entry) {
        if (-not $entry.StartUtc) { $entry.StartUtc = $cimStart }
        if ([math]::Abs(($cimStart - $entry.StartUtc).TotalSeconds) -gt 2) { $entry | Add-Member -NotePropertyName SourceDisagrees -NotePropertyValue $true -Force }
      }
    }
  } catch { }
  $script:ProcFactsCache = $table
  $script:ProcFactsAt = Get-Date
}

function Get-ProbeWindowSignals {
  param([IntPtr]$Hwnd)

  Update-ProbeProcessFacts

  $title = New-Object System.Text.StringBuilder 512
  [void][WhProbe.Win32]::GetWindowTextW($Hwnd, $title, $title.Capacity)
  $class = New-Object System.Text.StringBuilder 256
  [void][WhProbe.Win32]::GetClassNameW($Hwnd, $class, $class.Capacity)

  $pidValue = [uint32]0
  [void][WhProbe.Win32]::GetWindowThreadProcessId($Hwnd, [ref]$pidValue)

  $facts = $script:ProcFactsCache[[int]$pidValue]

  [pscustomobject]@{
    Hwnd          = ('0x{0:X}' -f $Hwnd.ToInt64())
    HwndValue     = $Hwnd.ToInt64()
    Title         = $title.ToString()
    ClassName     = $class.ToString()
    Pid           = [int]$pidValue
    ProcessPath   = if ($facts) { $facts.Path } else { $null }
    ProcCreatedUtc = if ($facts) { $facts.StartUtc } else { $null }
    PidSourceDisagrees = if ($facts -and $facts.PSObject.Properties['SourceDisagrees']) { $facts.SourceDisagrees } else { $null }
    IsWindowAlive = [WhProbe.Win32]::IsWindow($Hwnd)
    IsVisible     = [WhProbe.Win32]::IsWindowVisible($Hwnd)
    Tag           = (Get-ProbeTag $Hwnd)
  }
}

# ---------------------------------------------------------------------------
# Tag read/write (the candidate Papers-owned opaque instance tag)
# ---------------------------------------------------------------------------

$script:TagName = 'PapersProbeInstanceId'
$script:AtomPrefix = 'PapersProbe.InstanceId.'

# Raw read path: returns the pointer the property store holds. Only safe when the
# stored value is known NOT to be a pointer. Kept because the hazard has to be
# reproducible to be reportable.
function Get-ProbeTagRaw {
  param([IntPtr]$Hwnd)
  return [WhProbe.Win32]::GetPropW($Hwnd, $script:TagName)
}

# Safe read path (the primitive worth proposing): the property holds a GLOBAL ATOM
# as an integer, so the reader resolves it through the system atom table and never
# dereferences memory belonging to another process.
function Get-ProbeTag {
  param([IntPtr]$Hwnd)
  $raw = [WhProbe.Win32]::GetPropW($Hwnd, $script:TagName)
  if ($raw -eq [IntPtr]::Zero) { return $null }
  $value = $raw.ToInt64()
  if ($value -lt 0 -or $value -gt 0xFFFF) {
    return "<non-atom-value:0x$($value.ToString('X'))>"
  }
  $atom = [uint16]$value
  $sb = New-Object System.Text.StringBuilder 512
  $len = [WhProbe.Win32]::GlobalGetAtomNameW($atom, $sb, $sb.Capacity)
  if ($len -eq 0) { return "<atom-$atom-unknown>" }
  return $sb.ToString()
}

function New-ProbeInstanceTag {
  param([string]$Prefix = $script:AtomPrefix)
  return $Prefix + [guid]::NewGuid().ToString('N')
}

# Returns the atom value actually stored, so callers can report what is on the window.
function Set-ProbeTag {
  param([IntPtr]$Hwnd, [string]$Value)
  $atom = [WhProbe.Win32]::GlobalAddAtomW($Value)
  if ($atom -eq 0) { throw "GlobalAddAtomW failed, Win32Error=$([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
  $ok = [WhProbe.Win32]::SetPropW($Hwnd, $script:TagName, [IntPtr][int]$atom)
  if (-not $ok) { throw "SetPropW(atom) failed, Win32Error=$([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
  return [pscustomobject]@{ Atom = $atom; Value = $Value }
}

# Legacy/hazardous path, kept to reproduce the recorded failure.
function Set-ProbeTagPointer {
  param([IntPtr]$Hwnd, [long]$Value)
  $ok = [WhProbe.Win32]::SetPropW($Hwnd, $script:TagName, [IntPtr]$Value)
  if (-not $ok) { throw "SetPropW(pointer) failed, Win32Error=$([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
  return $ok
}

# Measures the hazard: does the stored value look like a pointer into the writer's
# address space (unsafe to dereference) or an atom (safe to resolve)?
function Test-ProbeTagIsDereferenceable {
  param([IntPtr]$Hwnd)
  $raw = Get-ProbeTagRaw $Hwnd
  $value = $raw.ToInt64()
  return [pscustomobject]@{
    RawValue = '0x{0:X}' -f $value
    LooksLikeAtom = ($value -gt 0 -and $value -le 0xFFFF)
    Safe = ($value -gt 0 -and $value -le 0xFFFF)
  }
}

function Remove-ProbeTag {
  param([IntPtr]$Hwnd)
  $raw = Get-ProbeTagRaw $Hwnd
  if ($raw -ne [IntPtr]::Zero) {
    $value = $raw.ToInt64()
    if ($value -gt 0 -and $value -le 0xFFFF) { [void][WhProbe.Win32]::GlobalDeleteAtom([uint16]$value) }
  }
  [void][WhProbe.Win32]::RemovePropW($Hwnd, $script:TagName)
}

# ---------------------------------------------------------------------------
# Enumeration
# ---------------------------------------------------------------------------

function Get-ProbeTopLevelWindows {
  $list = New-Object System.Collections.ArrayList
  $cb = [WhProbe.EnumProc] {
    param($h, $p)
    if ([WhProbe.Win32]::IsWindowVisible($h)) {
      [void]$list.Add((Get-ProbeWindowSignals -Hwnd $h))
    }
    return $true
  }
  [void][WhProbe.Win32]::EnumWindows($cb, [IntPtr]::Zero)
  return $list
}

function Get-ProbeKeyWindows {
  # The applications the design names, plus any scratch process grouped by path.
  $all = Get-ProbeTopLevelWindows
  $all | Where-Object {
    $_.ClassName -eq 'Chrome_WidgetWin_1' -or
    $_.ProcessPath -match 'chrome\.exe$' -or
    $_.ProcessPath -match 'obsidian\.exe$' -or
    $_.ProcessPath -match 'Code\.exe$' -or
    $_.ClassName -eq 'Notepad' -or
    $_.ProcessPath -match 'notepad\.exe$'
  } | Sort-Object ProcessPath, HwndValue
}

$script:BootTimeUtc = $null
function Get-ProbeBootTimeUtc {
  if (-not $script:BootTimeUtc) {
    $script:BootTimeUtc = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()
  }
  return $script:BootTimeUtc
}

function Get-ProbeMarker {
  <#
    The exact string a helper could recompute from any live HWND without
    owning it, plus the fields it is built from.
  #>
  param([IntPtr]$Hwnd)
  $s = Get-ProbeWindowSignals -Hwnd $Hwnd
  $boot = Get-ProbeBootTimeUtc
  $stamp = if ($s.ProcCreatedUtc) { $s.ProcCreatedUtc.ToString('o') } else { 'none' }
  [pscustomobject]@{
    Hwnd             = $s.Hwnd
    Pid              = $s.Pid
    ProcessPath      = $s.ProcessPath
    ProcCreatedUtc   = $stamp
    ClassName        = $s.ClassName
    BootTimeUtc      = $boot.ToString('o')
    PidSourceDisagrees = $s.PidSourceDisagrees
    Marker           = "$($boot.ToString('o'))|$($s.Pid)|$stamp|$($s.ClassName)"
    MarkerNoBoot     = "$($s.Pid)|$stamp|$($s.ClassName)"
    MarkerHwndIncluded = "$($s.Hwnd)|$($s.Pid)|$stamp|$($s.ClassName)"
    TitleOnly        = $s.Title
    ProcessAlive     = ($null -ne $s.ProcessPath)
  }
}

# ===========================================================================
# ROUND TWO — the identity SCOPE the reviewer asked for, measured per window.
# ===========================================================================

$script:BuildNumber = $null
function Get-ProbeBuildNumber {
  if (-not $script:BuildNumber) {
    $v = New-Object WhProbe.Win32+RTL_OSVERSIONINFOW
    $v.dwOSVersionInfoSize = [System.Runtime.InteropServices.Marshal]::SizeOf($v)
    [void][WhProbe.Win32]::RtlGetVersion([ref]$v)
    $script:BuildNumber = [int]$v.dwBuildNumber
  }
  return $script:BuildNumber
}

# Process incarnation: SequenceNumber where the field exists, FILETIME creation
# time always. Never PID alone.
$script:IncarnationCache = @{}
function Get-ProbeProcessIncarnation {
  param([int]$PidValue)
  Update-ProbeProcessFacts
  $facts = $script:ProcFactsCache[$PidValue]
  $created = if ($facts) { $facts.StartUtc } else { $null }

  $sequence = $null
  $sequenceReadable = $false
  $bufSize = [int]1MB
  $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($bufSize)
  try {
    $retLen = 0
    $status = [WhProbe.Win32]::NtQuerySystemInformation(57, $buf, $bufSize, [ref]$retLen)
    if ($status -eq 0) {
      $offset = 0
      while ($true) {
        $ptr = [IntPtr]::Add($buf, $offset)
        $spi = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][WhProbe.Win32+SYSTEM_PROCESS_INFORMATION])
        if ([int]$spi.UniqueProcessId -eq $PidValue) {
          $sequence = [uint32]$spi.SequenceNumber
          $sequenceReadable = $true
          break
        }
        if ($spi.NextEntryOffset -eq 0) { break }
        $offset += [int]$spi.NextEntryOffset
      }
    }
  } catch { } finally {
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf)
  }

  [pscustomobject]@{
    Pid               = $PidValue
    SequenceNumber    = $sequence
    SequenceReadable  = $sequenceReadable
    CreatedUtc        = $created
    Incarnation       = if ($sequenceReadable) { "seq:$sequence" } elseif ($created) { "created:$($created.ToString('o'))" } else { $null }
    Source            = if ($sequenceReadable) { 'SequenceNumber' } elseif ($created) { 'creationFiletime' } else { 'unavailable' }
  }
}

function Get-ProbeWindowSession {
  param([int]$PidValue)
  $sid = [uint32]0
  $ok = [WhProbe.Win32]::ProcessIdToSessionId([uint32]$PidValue, [ref]$sid)
  if ($ok) { return [int]$sid }
  return $null
}

function Get-ProbeIdentityScope {
  <#
    The full scope a fail-closed identity check must compare. Deliberately
    separates:
      * locator   — the HWND, never authority on its own
      * corroboration — boot, session, process incarnation, window class
      * marker    — the per-HWND enrolled generation nonce, if present
    `Verified` is only true when every corroborator was readable AND matched.
    An unreadable corroborator is `Unverified`, never `Gone`.
  #>
  param([IntPtr]$Hwnd, [object]$Expected = $null, [uint16]$MarkerAtom = 0)

  $s = Get-ProbeWindowSignals -Hwnd $Hwnd
  $inc = if ($s.Pid -gt 0) { Get-ProbeProcessIncarnation -PidValue $s.Pid } else { $null }
  $sess = if ($s.Pid -gt 0) { Get-ProbeWindowSession -PidValue $s.Pid } else { $null }

  $scope = [ordered]@{
    hwnd              = $s.Hwnd
    hwndValue         = $s.HwndValue
    alive             = $s.IsWindowAlive
    pid               = $s.Pid
    processCreatedUtc = if ($s.ProcCreatedUtc) { $s.ProcCreatedUtc.ToString('o') } else { $null }
    processSequence   = if ($inc) { $inc.SequenceNumber } else { $null }
    incarnationSource = if ($inc) { $inc.Source } else { 'unavailable' }
    bootId            = (Get-ProbeBootTimeUtc).ToString('o')
    sessionId         = $sess
    className         = $s.ClassName
    processPath       = $s.ProcessPath
    title             = $s.Title
    marker            = (Get-ProbeTag $Hwnd)
  }

  $result = [ordered]@{
    Scope        = $scope
    Verified     = $null
    Unverified   = @()
    Mismatches   = @()
  }

  if ($null -eq $Expected) { return [pscustomobject]$result }

  # Compare against an enrolled scope.
  $checks = @(
    @{ Name = 'alive';             Got = $scope.alive;             Want = $true },
    @{ Name = 'bootId';            Got = $scope.bootId;            Want = $Expected.bootId },
    @{ Name = 'pid';               Got = $scope.pid;               Want = $Expected.pid },
    @{ Name = 'sessionId';         Got = $scope.sessionId;         Want = $Expected.sessionId },
    @{ Name = 'className';         Got = $scope.className;         Want = $Expected.className },
    @{ Name = 'processCreatedUtc'; Got = $scope.processCreatedUtc; Want = $Expected.processCreatedUtc },
    @{ Name = 'processSequence';   Got = $scope.processSequence;   Want = $Expected.processSequence }
  )
  foreach ($c in $checks) {
    if ($null -eq $c.Got -or $c.Got -eq '') { $result.Unverified += $c.Name; continue }
    if ($null -eq $c.Want -or $c.Want -eq '') { $result.Unverified += $c.Name; continue }
    if ([string]$c.Got -ne [string]$c.Want) { $result.Mismatches += "$($c.Name): got=$($c.Got) want=$($c.Want)" }
  }
  if ($MarkerAtom -ne 0) {
    if ($null -eq $scope.marker) { $result.Unverified += 'marker' }
    elseif ($scope.marker -ne (Get-ProbeAtomName $MarkerAtom)) { $result.Mismatches += "marker: got=$($scope.marker)" }
  }
  $result.Verified = ($result.Mismatches.Count -eq 0 -and $result.Unverified.Count -eq 0)
  return [pscustomobject]$result
}

function Get-ProbeAtomName {
  param([uint16]$Atom)
  $sb = New-Object System.Text.StringBuilder 512
  $len = [WhProbe.Win32]::GlobalGetAtomNameW($Atom, $sb, $sb.Capacity)
  if ($len -eq 0) { return $null }
  return $sb.ToString()
}

# A marker value the reviewer asked for: a SCALAR nonce, not a pointer, and
# deliberately inside the named-atom range so the low-word representation is
# unambiguous on every bitness.
$script:MarkerPropName = 'PapersInstanceGeneration'
function New-ProbeGenerationNonce {
  # 1..32767: below the integer-atom range (0xC000+) so it can never be confused
  # with a synthesised "#nnn" atom name.
  return [uint16](Get-Random -Minimum 1 -Maximum 32768)
}

function Set-ProbeGenerationMarker {
  param([IntPtr]$Hwnd, [uint16]$Nonce)
  $name = "PapersProbe.Gen.$Nonce"
  $atom = [WhProbe.Win32]::GlobalAddAtomW($name)
  if ($atom -eq 0) { throw "GlobalAddAtomW failed: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
  $err = 0
  $ok = [WhProbe.Win32]::SetPropW($Hwnd, $script:MarkerPropName, [IntPtr][int]$atom)
  if (-not $ok) {
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    [void][WhProbe.Win32]::GlobalDeleteAtom($atom)
    return [pscustomobject]@{ Ok = $false; Win32Error = $err; Nonce = $Nonce; Atom = $atom }
  }
  return [pscustomobject]@{ Ok = $true; Win32Error = 0; Nonce = $Nonce; Atom = $atom }
}

function Get-ProbeGenerationMarker {
  param([IntPtr]$Hwnd)
  $raw = [WhProbe.Win32]::GetPropW($Hwnd, $script:MarkerPropName)
  if ($raw -eq [IntPtr]::Zero) { return $null }
  $v = $raw.ToInt64()
  if ($v -le 0 -or $v -gt 0xFFFF) { return "<non-scalar:0x$($v.ToString('X'))>" }
  return (Get-ProbeAtomName ([uint16]$v))
}

function Remove-ProbeGenerationMarker {
  param([IntPtr]$Hwnd)
  $raw = [WhProbe.Win32]::GetPropW($Hwnd, $script:MarkerPropName)
  if ($raw -ne [IntPtr]::Zero) {
    $v = $raw.ToInt64()
    if ($v -gt 0 -and $v -le 0xFFFF) { [void][WhProbe.Win32]::GlobalDeleteAtom([uint16]$v) }
  }
  [void][WhProbe.Win32]::RemovePropW($Hwnd, $script:MarkerPropName)
}
