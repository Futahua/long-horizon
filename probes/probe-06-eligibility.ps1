# probe-06-eligibility.ps1
#
# EXPERIMENT 6 — the REAL helper's task-worthiness predicate, applied to real
# windows. This answers "what would auto-tracking actually capture?" with
# measurements instead of a reading of the code.
#
# It drives the shipping helper exactly as Papers does and reports, per listed
# window, what the helper decided. Then it checks a probe-owned window against
# each individual predicate clause to find which one rejects it.
#
# Read-only: only `list` is ever sent.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'

function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

"=== EXPERIMENT 6 : what the shipping helper's list actually contains ==="
""

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $PS51
$psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$helper = [System.Diagnostics.Process]::Start($psi)

function Send-Helper {
  param([hashtable]$Request, [int]$Id)
  $Request['requestId'] = $Id
  $json = ($Request | ConvertTo-Json -Compress -Depth 8)
  Write-ProbeLine "  -> $json"
  $helper.StandardInput.WriteLine($json)
  $helper.StandardInput.Flush()
  $deadline = (Get-Date).AddSeconds(60)
  while ((Get-Date) -lt $deadline) {
    $task = $helper.StandardOutput.ReadLineAsync()
    if ($task.Wait(1000)) {
      $line = $task.Result
      if ($null -eq $line) { return $null }
      return ($line | ConvertFrom-Json)
    }
  }
  return $null
}

$idFile = Join-Path $env:TEMP ('probe-elig-' + [guid]::NewGuid().ToString('N') + '.txt')
$scratch = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile', '-File', $SCRATCH, 'PROBE-ELIGIBILITY', $idFile) -PassThru
$scratchHwnd = [IntPtr]::Zero
for ($i = 0; $i -lt 80; $i++) {
  if (Test-Path $idFile) {
    $reported = (Get-Content $idFile -Raw).Trim()
    if ($reported -match 'HWNDDEC=(\d+)') { $scratchHwnd = [IntPtr][long]$matches[1]; break }
  }
  Start-Sleep -Milliseconds 250
}
"probe window : hwnd=$(('0x{0:X}' -f $scratchHwnd.ToInt64())) pid=$($scratch.Id)"
""

$list = Send-Helper @{ method = 'list' } 1
if (-not $list -or $list.outcome -ne 'success') {
  "HELPER LIST FAILED: $($list | ConvertTo-Json -Compress)"
} else {
  "helper listed $($list.windows.Count) windows:"
  ""
  $rows = foreach ($w in $list.windows) {
    [pscustomobject]@{
      Pid      = $w.processId
      Title    = if ($w.title.Length -gt 42) { $w.title.Substring(0, 42) } else { $w.title }
      Exe      = if ($w.processPath) { Split-Path $w.processPath -Leaf } else { '<NULL-PATH>' }
      State    = $w.state
      Token    = $w.runtimeId.Substring(0, 8)
    }
  }
  $rows | Sort-Object Exe, Pid | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
  ""
  $nullPath = @($list.windows | Where-Object { -not $_.processPath })
  "windows the helper listed with a NULL processPath: $($nullPath.Count) of $($list.windows.Count)"
  foreach ($w in $nullPath) { "  pid=$($w.processId) title='$($w.title)' state=$($w.state)" }
  ""

  $isListed = @($list.windows | Where-Object { [int]$_.processId -eq $scratch.Id })
  "probe window listed by the helper: $($isListed.Count -gt 0)"
  ""

  # Which clause rejects it?
  "--- per-clause evaluation of the PROBE window's native state ---"
  $ex = Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtrW(IntPtr h, int n);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
[DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint c);
[DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint f);
[DllImport("user32.dll")] public static extern IntPtr GetLastActivePopup(IntPtr h);
[DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out int v, int cb);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder s, int n);
'@ -Name 'ProbeElig' -Namespace 'WhProbe' -PassThru

  $h = $scratchHwnd
  $cloak = 0
  [void]$ex::DwmGetWindowAttribute($h, 14, [ref]$cloak, 4)
  $exStyle = $ex::GetWindowLongPtrW($h, -20).ToInt64()
  $owner = $ex::GetWindow($h, 4)
  $root = $ex::GetAncestor($h, 2)
  $lastActive = if ($owner -ne [IntPtr]::Zero) { $ex::GetLastActivePopup($root) } else { [IntPtr]::Zero }
  $cn = New-Object System.Text.StringBuilder 256
  [void]$ex::GetClassNameW($h, $cn, $cn.Capacity)

  $clauses = [ordered]@{
    'IsWindow alive'                              = $ex::IsWindow($h)
    'Visible'                                     = $ex::IsWindowVisible($h)
    'Not DWM-cloaked'                             = ($cloak -eq 0)
    'No WS_EX_TOOLWINDOW (0x80)'                  = (($exStyle -band 0x80) -eq 0)
    'No WS_EX_NOACTIVATE (0x8000000)'             = (($exStyle -band 0x8000000) -eq 0)
    'Class not Progman/WorkerW'                   = ($cn.ToString() -notin @('Progman', 'WorkerW'))
    'Process not TextInputHost'                   = $true
  }
  foreach ($k in $clauses.Keys) { "  {0,-42} {1}" -f $k, $clauses[$k] }

  if ($owner -ne [IntPtr]::Zero) {
    "  owner present: owner=$('0x{0:X}' -f $owner.ToInt64()) root=$('0x{0:X}' -f $root.ToInt64()) lastActivePopup=$('0x{0:X}' -f $lastActive.ToInt64())"
    "  'LastActivePopup == this window'            $($lastActive -eq $h)"
    "  >>> an OWNED window is rejected unless its root's last-active popup is itself"
  } else {
    "  owner: none (no owned-popup clause applies)"
  }
  ""
  "  exStyle=0x$($exStyle.ToString('X'))  class='$($cn.ToString())'"
  ""
  "  CONCLUSION: the probe window's clauses above are the helper's own predicate;"
  "              the helper's decision is the authority, and it was: listed=$($isListed.Count -gt 0)."
}

if ($helper -and -not $helper.HasExited) { $helper.Kill() }
if ($scratch -and -not $scratch.HasExited) { Stop-Process -Id $scratch.Id -Force -ErrorAction SilentlyContinue }
Remove-Item $idFile -ErrorAction SilentlyContinue
