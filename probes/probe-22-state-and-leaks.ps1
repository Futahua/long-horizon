# probe-22-state-and-leaks.ps1
#
# EXPERIMENT 22 — housekeeping with evidential value.
#
# Probe-15 enrolled generation markers on twelve REAL application windows and
# removed them again. Probe-16 did the same on an elevated window it could not
# write to. This probe verifies that no probe artefact was left on any window the
# creator owns, and captures the power/transition facts this round could not
# measure by performing them.

. "$PSScriptRoot\win-identity-lib.ps1"

$MARKER = 'PapersInstanceGeneration'
$LEGACY = 'PapersProbeInstanceId'

function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Flush() }

"=== EXPERIMENT 22 : leftover-marker audit and transition facts ==="
""

# ---------------------------------------------------------------------------
# 1. Does ANY live window carry a probe marker?
# ---------------------------------------------------------------------------
"--- 1. scanning every visible top-level window for probe property names ---"
$all = @(Get-ProbeTopLevelWindows)
$carrying = @()
foreach ($w in $all) {
  $h = [IntPtr]$w.HwndValue
  $m1 = [WhProbe.Win32]::GetPropW($h, $MARKER)
  $m2 = [WhProbe.Win32]::GetPropW($h, $LEGACY)
  if ($m1 -ne [IntPtr]::Zero -or $m2 -ne [IntPtr]::Zero) {
    $carrying += [pscustomobject]@{
      Hwnd = $w.Hwnd
      Exe = if ($w.ProcessPath) { Split-Path $w.ProcessPath -Leaf } else { '<null>' }
      Pid = $w.Pid
      Generation = ('0x{0:X}' -f $m1.ToInt64())
      Legacy = ('0x{0:X}' -f $m2.ToInt64())
    }
  }
}
"  visible windows scanned : $($all.Count)"
"  windows carrying markers: $($carrying.Count)"
if ($carrying.Count -gt 0) {
  $carrying | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
  foreach ($c in $carrying) {
    [void][WhProbe.Win32]::RemovePropW([IntPtr][long]("0x$($c.Hwnd.Substring(2))" -as [int]), $MARKER)
  }
  "  (any found are listed above with their owning executable)"
} else {
  "  no window of any process carries a probe property name."
}
""

# ---------------------------------------------------------------------------
# 2. Power and transition capabilities, read rather than guessed
# ---------------------------------------------------------------------------
"--- 2. what transitions this machine supports ---"
try {
  $sleepStates = (& powercfg /a 2>&1 | Out-String)
  foreach ($line in ($sleepStates -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 18)) {
    "  $($line.Trim())"
  }
} catch {
  "  powercfg /a failed: $($_.Exception.Message)"
}
""

# Fast Startup: a shutdown that is really a hibernate of the kernel session. It is
# the transition most likely to confuse a boot-id scoping rule, so its setting is
# recorded even though the transition itself was not performed.
"--- Fast Startup / hibernate configuration ---"
try {
  $hb = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction Stop
  "  HiberbootEnabled (Fast Startup) : $($hb.HiberbootEnabled)"
} catch { "  HiberbootEnabled: unreadable ($($_.Exception.Message))" }
try {
  $pw = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction Stop
  "  HibernateEnabled               : $($pw.HibernateEnabled)"
} catch { "  HibernateEnabled: unreadable" }
""

# Boot-scoped identity facts that a suspend/resume or Fast Startup would have to
# preserve or break. Recorded so a later round can compare against a real event.
"--- boot-scoped facts right now ---"
$boot = Get-ProbeBootTimeUtc
$now = (Get-Date).ToUniversalTime()
"  boot time (LastBootUpTime) : $($boot.ToString('o'))"
"  now                        : $($now.ToString('o'))"
"  uptime                     : $([math]::Round(($now - $boot).TotalHours, 2)) hours"
"  current session id         : $((Get-Process -Id $PID).SessionId)"
$r = @(Get-Process -Name explorer -ErrorAction SilentlyContinue)
if ($r) { "  explorer session           : $($r[0].SessionId) started $($r[0].StartTime.ToUniversalTime().ToString('o'))" }
""
"  NOTE: sleep, hibernate, Fast Startup shutdown and full restart were NOT"
"  performed. They take the creator's machine away while they may be using it,"
"  and a probe does not get to decide that. The design consequence is recorded"
"  in the write-up: bootId is a SCOPE FENCE that makes an old record provably"
"  out of scope, not proof that any particular window died. That framing is what"
"  keeps an unmeasured transition from becoming a wrong answer."
""

# ---------------------------------------------------------------------------
# 3. RDP / session facts
# ---------------------------------------------------------------------------
"--- 3. session scope facts ---"
$sessions = @()
foreach ($p in (Get-Process -ErrorAction SilentlyContinue | Select-Object -First 600)) {
  try { $sessions += $p.SessionId } catch { }
}
$distinct = @($sessions | Sort-Object -Unique)
"  distinct session ids across processes: $($distinct -join ', ')"
"  this probe's session id              : $((Get-Process -Id $PID).SessionId)"
$rdp = @(Get-CimInstance Win32_LogonSession -ErrorAction SilentlyContinue | Where-Object { $_.LogonType -in 2, 10 })
"  interactive/remote logon sessions    : $($rdp.Count)"
foreach ($l in ($rdp | Select-Object -First 5)) { "    logonType=$($l.LogonType) start=$($l.StartTime)" }
""
"  Same-session RDP reconnect preserves the session id by definition of the"
"  term, so the fence this round proposes is: a DIFFERENT session id must never"
"  cross-bind. Whether a reconnect actually preserves the id was NOT measured -"
"  performing one requires taking over the creator's session."
""

"=== EXPERIMENT 22 SUMMARY ==="
"visible windows scanned     : $($all.Count)"
"windows carrying a marker   : $($carrying.Count)"
"Fast Startup enabled        : $((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -ErrorAction SilentlyContinue).HiberbootEnabled)"
