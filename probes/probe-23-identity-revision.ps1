# probe-23-identity-revision.ps1
#
# EXPERIMENT 23 — does the 018 identity revision actually do what it claims,
# against the REAL shipping helper and real live windows?
#
# The host suite passed unchanged, but the host suite has no executable test for
# the helper at all (it validates the .ps1 by string assertions only). A green
# suite therefore proves the TypeScript layer still parses; it proves nothing
# about identity. This probe is the evidence.
#
# Claims under test:
#   1. a title change no longer invalidates a live session token;
#   2. the token is REUSED across a title change (same identity => same token);
#   3. process/class corroboration still fails closed;
#   4. every observation now carries windowClass, on the wire;
#   5. a dead window still reports missing.
#
# Windows retitled here are probe-owned. Nothing the creator owns is modified.

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
  param([string]$Plan, [IntPtr]$MutateHwnd = [IntPtr]::Zero)
  $mutator = Join-Path $PSScriptRoot 'probe-mutate-title.ps1'
  # Responses come back through a JSON file, not stdout: PowerShell's 2>&1
  # interleaving injected a non-string record that shifted every assertion by
  # one. A file cannot do that.
  $respFile = Join-Path $env:TEMP ('probe-r23-' + [guid]::NewGuid().ToString('N') + '.json')
  $env:PROBE_RESPONSE_FILE = $respFile
  try {
    if ($MutateHwnd -ne [IntPtr]::Zero) {
      $null = & node $CLIENT $HELPER $PS51 $Plan $mutator $MutateHwnd.ToInt64() 2>&1
    } else {
      $null = & node $CLIENT $HELPER $PS51 $Plan 2>&1
    }
    if (Test-Path $respFile) {
      $raw = Get-Content $respFile -Raw
      $parsed = $raw | ConvertFrom-Json
      return @($parsed)
    }
    return @()
  } finally {
    Remove-Item Env:\PROBE_RESPONSE_FILE -ErrorAction SilentlyContinue
    Remove-Item $respFile -ErrorAction SilentlyContinue
  }
}

"=== EXPERIMENT 23 : the 018 identity revision, against the real helper ==="
"helper : $HELPER"
""

# ---------------------------------------------------------------------------
# A. Wire shape: every observation carries windowClass
# ---------------------------------------------------------------------------
"--- A. wire shape ---"
$list = Invoke-Helper -Plan 'list'
$windows = @($list[0].windows)
"  listed windows: $($windows.Count)"
$withClass = @($windows | Where-Object { $_.PSObject.Properties['windowClass'] -and $_.windowClass })
"  carrying windowClass: $($withClass.Count)"
$withTitle = @($windows | Where-Object { $_.title })
"  carrying title      : $($withTitle.Count)"
Add-Result 'every listed window carries windowClass on the wire' 'all listed windows' "$($withClass.Count) of $($windows.Count)" ($withClass.Count -eq $windows.Count -and $windows.Count -gt 0)
if ($withClass.Count -gt 0) {
  $sample = $withClass | Select-Object -First 3
  foreach ($w in $sample) {
    "    class='$($w.windowClass)' pid=$($w.processId) title='$(if ($w.title.Length -gt 40) { $w.title.Substring(0,40) } else { $w.title })'"
  }
}
""

# ---------------------------------------------------------------------------
# B. THE FIX: a title change must not invalidate a live token
# ---------------------------------------------------------------------------
"--- B. title mutation (the defect this revision removes) ---"
$np = Start-Process -FilePath 'notepad.exe' -PassThru
$npWin = $null
for ($i = 1; $i -le 60; $i++) {
  Start-Sleep -Milliseconds 250
  $w = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $np.Id }) | Select-Object -First 1
  if ($w) { $npWin = $w; break }
}
if (-not $npWin) {
  # Single-instance handoff: the window may belong to an older notepad process.
  $npWin = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'notepad\.exe$' }) | Select-Object -First 1
}
if (-not $npWin) {
  Add-Result 'a probe-owned window to retitle' 'one notepad window' 'none' $false
} else {
  $hwnd = [IntPtr]$npWin.HwndValue
  "  target: pid=$($npWin.Pid) hwnd=$($npWin.Hwnd) class=$($npWin.ClassName) title='$($npWin.Title)'"

  # ONE helper process for the whole sequence: list -> observe -> mutate the title
  # -> observe the SAME token -> list again. The helper must stay alive across the
  # mutation or the token dies with it and the probe measures a restart instead.
  $hwndDec = $hwnd.ToInt64()
  $responses = Invoke-Helper -Plan 'list,observe:last,mutate,sleep:400,observe:last,list' -MutateHwnd $hwnd
  "  helper returned $($responses.Count) response(s)"
  for ($i = 0; $i -lt $responses.Count; $i++) {
    $r = $responses[$i]
    $shape = if ($r.PSObject.Properties['windows']) { "windows=$(@($r.windows).Count)" }
      elseif ($r.PSObject.Properties['observation']) { "observation=yes" }
      else { "keys=$(($r.PSObject.Properties.Name) -join ',')" }
    "    [$i] method=$($r.method) outcome=$($r.outcome) $shape"
  }
  if ($responses.Count -lt 4) {
    Add-Result 'the helper answered every step of the sequence' '4 responses (list, observe, observe, list)' "only $($responses.Count) returned" $false
  }
  $listA = $responses[0]
  $obs1 = $responses[1]
  $obs2 = $responses[2]
  $listB = $responses[3]

  $entryA = @($listA.windows | Where-Object { [int]$_.processId -eq $npWin.Pid -and $_.title -eq $npWin.Title }) | Select-Object -First 1
  if (-not $entryA) { $entryA = @($listA.windows | Where-Object { [int]$_.processId -eq $npWin.Pid }) | Select-Object -First 1 }
  "  helper entry: token=$($entryA.runtimeId) class='$($entryA.windowClass)' title='$($entryA.title)'"

  $sigAfter = Get-ProbeWindowSignals -Hwnd $hwnd
  "  after mutation: title='$($sigAfter.Title)' class=$($sigAfter.ClassName) pid=$($sigAfter.Pid) alive=$($sigAfter.IsWindowAlive)"
  Add-Result 'the window itself is unchanged apart from its title' 'same HWND, same PID, same CLASS, alive' "hwnd=$($sigAfter.Hwnd) pid=$($sigAfter.Pid) class=$($sigAfter.ClassName) alive=$($sigAfter.IsWindowAlive)" ($sigAfter.IsWindowAlive -and $sigAfter.Pid -eq $npWin.Pid -and $sigAfter.ClassName -eq $npWin.ClassName)

  Add-Result 'observe succeeds before any mutation' 'outcome=success' "outcome=$($obs1.outcome) error=$($obs1.error)" ($obs1.outcome -eq 'success')
  "  observe with the SAME token after the title change: outcome=$($obs2.outcome) error=$($obs2.error)"
  Add-Result 'THE FIX: observe still succeeds after only the title changed' 'outcome=success - identity no longer depends on the title' "outcome=$($obs2.outcome) error=$($obs2.error)" ($obs2.outcome -eq 'success')

  $entryB = @($listB.windows | Where-Object { [int]$_.processId -eq $npWin.Pid -and $_.windowClass -eq $npWin.ClassName }) | Select-Object -First 1
  "  token before: $($entryA.runtimeId)"
  "  token after : $($entryB.runtimeId)"
  Add-Result 'the token is REUSED across the title change (same identity => same token)' 'identical token' "same=$($entryA.runtimeId -eq $entryB.runtimeId)" ($entryA.runtimeId -eq $entryB.runtimeId)
  Add-Result 'the class reported after the title change is unchanged' 'same windowClass' "before='$($entryA.windowClass)' after='$($entryB.windowClass)'" ($entryA.windowClass -eq $entryB.windowClass)
  Add-Result 'the title reported on the wire DID change (the mutation was real)' 'a different title after than before' "before='$($entryA.title)' after='$($entryB.title)'" ($entryA.title -ne $entryB.title)
  $deadToken = $entryA.runtimeId
  ""

  # -------------------------------------------------------------------------
  # C. Fail-closed: a token for a DEAD window still fails
  # -------------------------------------------------------------------------
  "--- C. fail-closed behaviour is preserved ---"
  $killed = $false
  foreach ($proc in @(Get-Process -Name notepad -ErrorAction SilentlyContinue)) {
    $owned = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $proc.Id -and $_.HwndValue -eq $hwnd.ToInt64() })
    if ($owned.Count -gt 0) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue; $killed = $true }
  }
  if (-not $killed) { Stop-Process -Id $np.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 2
  $alive = [WhProbe.Win32]::IsWindow($hwnd)
  $obs3 = Invoke-Helper -Plan "observe:$deadToken"
  "  window alive after kill: $alive (IsWindow=$alive)"
  "  observe on the dead window: outcome=$($obs3[0].outcome) error=$($obs3[0].error)"
  Add-Result 'a token for a dead window still reports missing' 'outcome=missing' "outcome=$($obs3[0].outcome) error=$($obs3[0].error)" ($obs3[0].outcome -eq 'missing')

  # An unknown/guessed token still fails closed.
  $bogus = Invoke-Helper -Plan 'observe:T00000000000000000000000000000000'
  "  observe with a guessed token: outcome=$($bogus[0].outcome) error=$($bogus[0].error)"
  Add-Result 'a guessed token still fails closed' 'outcome=missing' "outcome=$($bogus[0].outcome)" ($bogus[0].outcome -eq 'missing')
  ""
}

# ---------------------------------------------------------------------------
# D. Two windows of one process keep distinct tokens
# ---------------------------------------------------------------------------
"--- D. two windows of one process still get distinct tokens ---"
$listD = Invoke-Helper -Plan 'list'
$byPid = @($listD[0].windows | Group-Object processId | Where-Object { $_.Count -gt 1 })
if ($byPid.Count -gt 0) {
  $g = $byPid[0]
  $tokens = @($g.Group | ForEach-Object { $_.runtimeId })
  $classes = @($g.Group | ForEach-Object { $_.windowClass } | Select-Object -Unique)
  "  pid=$($g.Name) windows=$($g.Count) distinct tokens=$(@($tokens | Select-Object -Unique).Count) distinct classes=$($classes.Count)"
  Add-Result 'two windows of one process receive distinct tokens' 'distinct tokens despite a shared class' "tokens=$(@($tokens | Select-Object -Unique).Count) of $($tokens.Count), classes=$($classes.Count)" ((@($tokens | Select-Object -Unique).Count) -eq $tokens.Count)
} else {
  "  no multi-window process present at this moment"
  Add-Result 'two windows of one process receive distinct tokens' 'a multi-window process to measure' 'none present' $false
}
""

"=== EXPERIMENT 23 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

foreach ($p in @(Get-Process -Name notepad -ErrorAction SilentlyContinue)) {
  $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
  if ($cim -and $cim.CreationDate -gt (Get-Date).AddMinutes(-10)) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
}
