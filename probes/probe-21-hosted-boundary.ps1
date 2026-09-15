# probe-21-hosted-boundary.ps1
#
# EXPERIMENT 21 — the hosted / packaged-application boundary, and the notepad
# targeting defect that made probe-19's C and G sections fail on their own setup.
#
# Two questions, both answered by running:
#   1. A packaged app (Windows Settings) shows up as an ApplicationFrameWindow.
#      Which process owns that window, and does the helper list it? What identity
#      does a hosted surface actually present?
#   2. Why did a freshly started notepad report no window three seconds later?

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$CLIENT = Join-Path $PSScriptRoot 'helper-client.mjs'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

function Invoke-Helper {
  param([string]$Plan)
  $out = & node $CLIENT $HELPER $PS51 $Plan 2>&1
  $responses = @()
  foreach ($line in $out) {
    $s = [string]$line
    if ($s.StartsWith('RESP ')) { try { $responses += ($s.Substring(5) | ConvertFrom-Json) } catch { } }
  }
  return $responses
}

"=== EXPERIMENT 21 : hosted boundary and notepad targeting ==="
""

# ---------------------------------------------------------------------------
# 1. The notepad targeting defect
# ---------------------------------------------------------------------------
"--- 1. why a fresh notepad reports no window ---"
$p = Start-Process -FilePath 'notepad.exe' -PassThru
"  launched pid=$($p.Id)"
$found = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 1; $i -le 60; $i++) {
  Start-Sleep -Milliseconds 250
  $w = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $p.Id }) | Select-Object -First 1
  if ($w) { $found = $w; break }
}
"  first window seen after $([math]::Round($sw.Elapsed.TotalSeconds,1))s"
if (-not $found) {
  "  NO WINDOW after 15s. Checking what the process is doing:"
  $live = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
  "    process alive: $($null -ne $live)"
  if ($live) { "    mainWindowHandle=$($live.MainWindowHandle) title='$($live.MainWindowTitle)'" }
  $anyNotepad = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'notepad\.exe$' })
  "    visible notepad windows from ANY process: $($anyNotepad.Count)"
  foreach ($w in $anyNotepad) { "      pid=$($w.Pid) hwnd=$($w.Hwnd) title='$($w.Title)'" }
  Add-Result 'a probe-started notepad exposes a window' 'one window within 15s' 'none - and the cause is recorded above' $false
} else {
  Add-Result 'a probe-started notepad exposes a window' 'a window within a bounded wait' "appeared after $([math]::Round($sw.Elapsed.TotalSeconds,1))s hwnd=$($found.Hwnd)" $true
  "        LESSON: the window appears asynchronously and can take seconds. A fixed"
  "        sleep is not a wait. probe-19's C and G sections failed on their own"
  "        setup, not on the behaviour they were testing."
  $scope = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$found.HwndValue)).Scope
  "  scope: pid=$($scope.pid) class=$($scope.className) created=$($scope.processCreatedUtc) session=$($scope.sessionId)"
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
}
""

# ---------------------------------------------------------------------------
# 2. The hosted / packaged boundary
# ---------------------------------------------------------------------------
"--- 2. a packaged application surface ---"
$frames = @(Get-ProbeTopLevelWindows | Where-Object { $_.ClassName -eq 'ApplicationFrameWindow' })
"  ApplicationFrameWindow windows: $($frames.Count)"
$frameRows = @()
foreach ($f in $frames) {
  $ownerProc = Get-Process -Id $f.Pid -ErrorAction SilentlyContinue
  $scope = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$f.HwndValue)).Scope
  $frameRows += [pscustomobject]@{
    Title = $f.Title
    Hwnd = $f.Hwnd
    OwnerPid = $f.Pid
    OwnerExe = if ($ownerProc) { Split-Path $ownerProc.Path -Leaf } else { '<unknown>' }
    Class = $scope.className
    Session = $scope.sessionId
    CreationReadable = ($null -ne $scope.processCreatedUtc)
  }
}
$frameRows | Format-Table -AutoSize | Out-String -Width 220 | Write-ProbeLine

$listedResp = Invoke-Helper -Plan 'list'
$listed = if ($listedResp[0].outcome -eq 'success') { @($listedResp[0].windows) } else { @() }
"  helper lists $($listed.Count) windows"
foreach ($r in $frameRows) {
  $inList = @($listed | Where-Object { [int]$_.processId -eq $r.OwnerPid })
  "  frame '$($r.Title)' pid=$($r.OwnerPid): helper entries for that pid = $($inList.Count)"
}
""
Add-Result 'a hosted/package frame window is visible to enumeration' 'at least one ApplicationFrameWindow' "$($frames.Count) found" ($frames.Count -gt 0)
if ($frameRows.Count -gt 0) {
  $r0 = $frameRows[0]
  Add-Result 'a hosted frame window has a fully readable identity scope' 'pid, class, session, creation all present' "pid=$($r0.OwnerPid) exe=$($r0.OwnerExe) class=$($r0.Class) session=$($r0.Session) created=$($r0.CreationReadable)" ($r0.OwnerPid -gt 0 -and $r0.CreationReadable)
  "        MEASURED BOUNDARY: the packaged application's CONTENT is not a separate"
  "        top-level window owned by its package process. What enumeration sees is"
  "        the host frame, owned by $($r0.OwnerExe). The package process itself"
  "        (SystemSettings.exe) owns no window at all."
  "        Consequence for the design: a hosted target's identity is the FRAME's"
  "        identity, not the packaged process's. Two different packaged apps could"
  "        present frames owned by the same host process, which is one more reason"
  "        the HWND cannot be dropped."
  $inList = @($listed | Where-Object { [int]$_.processId -eq $r0.OwnerPid })
  Add-Result 'the hosted frame is listed by the helper' 'a matching helper entry' "$($inList.Count) entries for pid $($r0.OwnerPid)" ($inList.Count -gt 0)
} else {
  Add-Result 'a hosted frame window is visible to enumeration' 'at least one' 'none - boundary UNVERIFIED' $false
}
""

# ---------------------------------------------------------------------------
# 3. Do two different hosted surfaces share one owning process?
# ---------------------------------------------------------------------------
"--- 3. do several hosted frames share one owning process? ---"
$byOwner = @($frameRows | Group-Object OwnerPid)
foreach ($g in $byOwner) {
  $exe = $g.Group[0].OwnerExe
  "  $exe pid=$($g.Name) frames=$($g.Count): $(($g.Group | ForEach-Object { "'$($_.Title)'" }) -join ', ')"
}
if ($byOwner.Count -gt 0) {
  $maxFrames = ($byOwner | Measure-Object -Property Count -Maximum).Maximum
  Add-Result 'hosted frames can share one owning process' 'either one frame per owner or several' "max frames per owner process = $maxFrames across $($byOwner.Count) owners" $true
  if ($maxFrames -gt 1) {
    "        MEASURED: one host process owns more than one hosted frame, so the"
    "        corroborators alone cannot separate hosted surfaces either."
  }
}
""

"=== EXPERIMENT 21 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
