# probe-20-helper-stdin.ps1
#
# EXPERIMENT 20 — establishing a reliable way to drive the shipping helper from
# PowerShell, because probe-19 hit "the pipe is being closed" and a broken
# instrument must be diagnosed before any of its results are believed.
#
# The helper's main loop is `while (($inputLine = [Console]::In.ReadLine()) -ne
# $null)`, so the child exits the moment stdin reports EOF. If the parent's write
# arrives after that, the pipe is already gone. This probe measures what actually
# happens in each launch shape.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

function Try-HelperShape {
  param([string]$Name, [bool]$WaitBeforeWrite, [int]$WaitMs, [bool]$StderrToFile)
  "--- $Name"
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $PS51
  $psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  if ($WaitBeforeWrite) { Start-Sleep -Milliseconds $WaitMs }
  $writeOk = $true
  $writeErr = ''
  try {
    $p.StandardInput.WriteLine('{"requestId":1,"method":"list"}')
    $p.StandardInput.Flush()
  } catch {
    $writeOk = $false
    $writeErr = $_.Exception.Message
  }
  $resp = $null
  if ($writeOk) {
    # NOTE (measured): two shapes are wrong here.
    #   * ReadLineAsync() inside a retry loop throws "The stream is currently in
    #     use by a previous operation on the stream" on the second attempt,
    #     because the first task is still pending.
    #   * ReadLine() with no bound blocks forever when the child never answers.
    # The correct shape is ONE task created once, then awaited repeatedly.
    try {
      $task = $p.StandardOutput.ReadLineAsync()
      if ($task.Wait(45000)) { $resp = $task.Result } else { $resp = '<timeout after 45s>' }
    } catch {
      $resp = "<read failed: $($_.Exception.Message)>"
    }
  }
  Start-Sleep -Milliseconds 300
  $exited = $p.HasExited
  $code = if ($exited) { $p.ExitCode } else { $null }
  $err = ''
  try { $err = $p.StandardError.ReadToEnd() } catch { }
  "  write ok      : $writeOk $(if (-not $writeOk) { "($writeErr)" })"
  "  response      : $(if ($resp) { $resp.Substring(0, [Math]::Min(90, $resp.Length)) } else { '<none>' })"
  "  exited        : $exited $(if ($exited) { "code=$code" } else { '' })"
  "  stderr        : $(if ($err.Trim()) { $err.Trim().Substring(0, [Math]::Min(200, $err.Trim().Length)) } else { '<empty>' })"
  if (-not $exited) { $p.Kill() }
  ""
  return [pscustomobject]@{ Shape = $Name; WriteOk = $writeOk; GotResponse = ($null -ne $resp); ExitedEarly = $exited }
}

"=== EXPERIMENT 20 : driving the shipping helper reliably ==="
"helper : $HELPER"
"exists : $(Test-Path $HELPER)"
""

$shapes = @()
$shapes += Try-HelperShape -Name 'A. write immediately, no wait' -WaitBeforeWrite $false -WaitMs 0
$shapes += Try-HelperShape -Name 'B. wait 1500ms, then write' -WaitBeforeWrite $true -WaitMs 1500
$shapes += Try-HelperShape -Name 'C. wait 4000ms, then write' -WaitBeforeWrite $true -WaitMs 4000

"--- summary ---"
$shapes | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine

$working = @($shapes | Where-Object { $_.GotResponse })
if ($working.Count -gt 0) {
  "RELIABLE SHAPE: $($working[0].Shape)"
  "  any shape that produced a response is usable; the probe must wait for the"
  "  helper to finish importing its adapter before the first write, and must not"
  "  let the stdin stream be collected."
} else {
  "NO SHAPE PRODUCED A RESPONSE."
  "  The helper exits on stdin EOF. A parent that holds the stream correctly is"
  "  required; if PowerShell cannot hold it, the driver must be Node (which is how"
  "  Papers itself spawns it: node child_process.spawn with stdio pipes)."
}
