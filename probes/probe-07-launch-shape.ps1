# probe-07-launch-shape.ps1
#
# EXPERIMENT 7 — does the WAY the helper is launched change what it can see?
#
# Papers launches the helper with node child_process.spawn: stdio pipes,
# windowsHide true, shell false. If a launch shape changes what the helper can
# enumerate, then a measurement taken through that shape is an artefact of the
# instrument rather than a fact about Windows.
#
# Method: run the same P/Invoke enumeration IN PLACE of the helper, under several
# launch shapes, and compare. `_inner-enum.ps1` is that same-code stand-in.

. "$PSScriptRoot\win-identity-lib.ps1"

$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'
$INNER = Join-Path $PSScriptRoot '_inner-enum.ps1'
$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'

function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

"=== EXPERIMENT 7 : launch shape vs what the helper can see ==="
"inner stand-in : $INNER"
"real helper    : $HELPER"
""

$mine = Get-ProbeTopLevelWindows
"this probe process sees : $($mine.Count) visible top-level windows"
""

$idFile = Join-Path $env:TEMP ('probe-launch-' + [guid]::NewGuid().ToString('N') + '.txt')
$scratch = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile', '-File', $SCRATCH, 'PROBE-LAUNCH', $idFile) -PassThru
$scratchHwnd = [IntPtr]::Zero
for ($i = 0; $i -lt 80; $i++) {
  if (Test-Path $idFile) {
    $r = (Get-Content $idFile -Raw).Trim()
    if ($r -match 'HWNDDEC=(\d+)') { $scratchHwnd = [IntPtr][long]$matches[1]; break }
  }
  Start-Sleep -Milliseconds 250
}
$t = $scratchHwnd.ToInt64()
"probe target window     : hwnd=$('0x{0:X}' -f $t) pid=$($scratch.Id)"
"target visible to me    : $(@(Get-ProbeTopLevelWindows | Where-Object { $_.HwndValue -eq $t }).Count -gt 0)"
""

function Invoke-Shape {
  param([string]$Name, [string]$File, [string]$Arguments, [bool]$CreateNoWindow, [bool]$Shell)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  if ($Shell) {
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = "/c `"`"$File`" $Arguments`""
  } else {
    $psi.FileName = $File
    $psi.Arguments = $Arguments
  }
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $CreateNoWindow
  $p = [System.Diagnostics.Process]::Start($psi)
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit(60000) | Out-Null
  "--- $Name"
  foreach ($line in ($out.Trim() -split "`r?`n")) { if ($line.Trim()) { "    $($line.Trim())" } }
  if ($err.Trim()) { "    stderr: $($err.Trim().Substring(0, [Math]::Min(200, $err.Trim().Length)))" }
  ""
}

$innerArgs = "-NoProfile -NonInteractive -File `"$INNER`" -TargetHwnd $t"
Invoke-Shape -Name 'A. CreateNoWindow=true, direct exe, redirected stdio' -File $PS51 -Arguments $innerArgs -CreateNoWindow $true -Shell $false
Invoke-Shape -Name 'B. CreateNoWindow=false, direct exe, redirected stdio' -File $PS51 -Arguments $innerArgs -CreateNoWindow $false -Shell $false
Invoke-Shape -Name 'C. via cmd /c (what a shell-spawned child looks like)' -File $PS51 -Arguments $innerArgs -CreateNoWindow $true -Shell $true
Invoke-Shape -Name 'D. inherited console (no redirection at all)' -File $PS51 -Arguments $innerArgs -CreateNoWindow $false -Shell $false

"--- E. the p/invoke stand-in launched with the helper command line shape, no redirection"
$pE = Start-Process -FilePath $PS51 -ArgumentList @('-NoProfile', '-NonInteractive', '-File', $INNER, '-TargetHwnd', "$t") -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 6
"    (see the line above the prompt; Start-Process cannot capture it without redirect)"
if (-not $pE.HasExited) { Stop-Process -Id $pE.Id -Force -ErrorAction SilentlyContinue }
""

"--- F. the REAL helper through CIM: what session and window station does it run in?"
$psiF = New-Object System.Diagnostics.ProcessStartInfo
$psiF.FileName = $PS51
$psiF.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
$psiF.RedirectStandardInput = $true
$psiF.RedirectStandardOutput = $true
$psiF.RedirectStandardError = $true
$psiF.UseShellExecute = $false
$psiF.CreateNoWindow = $true
$hF = [System.Diagnostics.Process]::Start($psiF)
Start-Sleep -Seconds 3
"    helper pid=$($hF.Id) session=$($hF.SessionId) mine=$((Get-Process -Id $PID).SessionId)"
$hF.StandardInput.WriteLine('{"requestId":1,"method":"list"}')
$hF.StandardInput.Flush()
$deadline = (Get-Date).AddSeconds(60)
$resp = $null
while ((Get-Date) -lt $deadline) {
  $task = $hF.StandardOutput.ReadLineAsync()
  if ($task.Wait(1000)) { $resp = $task.Result; break }
}
if ($resp) {
  $obj = $resp | ConvertFrom-Json
  "    helper listed $($obj.windows.Count) windows (this probe sees $((Get-ProbeTopLevelWindows).Count))"
  "    target listed: $(@($obj.windows | Where-Object { [int]$_.processId -eq $scratch.Id }).Count -gt 0)"
} else {
  "    helper produced no response within 60s"
}
if (-not $hF.HasExited) { $hF.Kill() }

if ($scratch -and -not $scratch.HasExited) { Stop-Process -Id $scratch.Id -Force -ErrorAction SilentlyContinue }
Remove-Item $idFile -ErrorAction SilentlyContinue
