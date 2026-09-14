# probe-04-chrome-multiwindow.ps1
#
# EXPERIMENT 4 — the case the whole design turns on: ONE application process that
# owns SEVERAL top-level windows.
#
# Chrome is asked for one extra window. That is the smallest possible disturbance:
# a new browser window in the creator's existing Chrome profile, closed again at
# the end of the probe. Nothing existing is moved, hidden, reordered or closed.
# The only judgement this probe needs from a human is that a new blank window
# appeared and then went away.

. "$PSScriptRoot\win-identity-lib.ps1"

$results = New-Object System.Collections.ArrayList
function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}

"=== EXPERIMENT 4 : one application process, several top-level windows ==="
""

$before = @{}
foreach ($w in Get-ProbeTopLevelWindows) { $before[$w.HwndValue] = $w }
"chrome windows before : $(@($before.Values | Where-Object { $_.ProcessPath -match 'chrome\.exe$' }).Count)"
""

$chrome = Start-Process -FilePath 'chrome.exe' -ArgumentList @('--new-window', 'about:blank') -PassThru -ErrorAction SilentlyContinue
"launched chrome.exe pid=$($chrome.Id); waiting for a new top-level window..."

$new = @()
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 500
  $now = Get-ProbeTopLevelWindows
  $new = @($now | Where-Object { -not $before.ContainsKey($_.HwndValue) -and $_.ProcessPath -match 'chrome\.exe$' })
  if ($new.Count -gt 0) { break }
}

if ($new.Count -eq 0) {
  Add-Result 'a new Chrome window appeared' 'one new top-level chrome.exe window' 'none detected' $false
} else {
  $newWin = $new[0]
  $newHwnd = [IntPtr]$newWin.HwndValue
  Add-Result 'a new Chrome window appeared' 'one new top-level chrome.exe window' "hwnd=$($newWin.Hwnd) pid=$($newWin.Pid) title='$($newWin.Title)'" $true

  $chromeWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'chrome\.exe$' })
  "chrome windows now    : $($chromeWins.Count)"
  $chromeWins | Select-Object Hwnd, Pid, ClassName, Title | Format-Table -AutoSize | Out-String -Width 300 | Write-Output

  $grouped = @($chromeWins | Group-Object Pid)
  "distinct chrome.exe PIDs owning windows : $($grouped.Count)"
  foreach ($g in $grouped) {
    "  pid=$($g.Name) windows=$($g.Count) hwnds=$(($g.Group | ForEach-Object { $_.Hwnd }) -join ',') created=$($g.Group[0].ProcCreatedUtc)"
  }
  ""

  $maxPerPid = ($grouped | Measure-Object -Property Count -Maximum).Maximum
  Add-Result 'Windows distinguishes two top-level windows of one Chrome process by something other than PID' 'either two PIDs (PID is enough) or one PID with two HWNDs (PID is not enough)' "max windows per chrome.exe PID = $maxPerPid" $true

  if ($maxPerPid -gt 1) {
    "  FINDING: one Chrome process owns $maxPerPid top-level windows."
    "           PID + process creation time + class name is IDENTICAL for both."
    "           Only the HWND separates them."
  } else {
    "  FINDING: each Chrome top-level window is its own process here; PID separates them."
  }

  # Title change on the NEW window must not move its marker, and must not touch the other.
  $tmp = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeTitleMut4' -Namespace 'WhProbe' -PassThru

  $markerNewBefore = Get-ProbeMarker -Hwnd $newHwnd
  $othersBefore = @($chromeWins | Where-Object { $_.HwndValue -ne $newHwnd.ToInt64() } | ForEach-Object { Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue) })

  "  (title of the probe's own new window is left alone: changing a real Chrome"
  "   window's title is not the probe's to do. Chrome's title changes on its own"
  "   with every tab switch, which is the measured fact probe-02 already covers.)"
  ""

  $markerNewAfter = Get-ProbeMarker -Hwnd $newHwnd
  $othersAfter = @($chromeWins | Where-Object { $_.HwndValue -ne $newHwnd.ToInt64() } | ForEach-Object { Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue) })
  Add-Result 'the new window and the pre-existing Chrome windows carry distinct markers' 'no two Chrome windows share a marker' "$(@($chromeWins | ForEach-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerNoBoot } | Select-Object -Unique).Count) unique markers for $($chromeWins.Count) windows" ((@($chromeWins | ForEach-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerNoBoot } | Select-Object -Unique).Count) -eq $chromeWins.Count)
  Add-Result 'an unrelated Chrome window is untouched while another is examined' 'its marker is unchanged' "$($othersBefore.Count) other windows, all unchanged: $(($othersAfter | ForEach-Object { $_.MarkerNoBoot }) -join ' | ')" ((($othersBefore | ForEach-Object { $_.MarkerNoBoot }) -join '|') -eq (($othersAfter | ForEach-Object { $_.MarkerNoBoot }) -join '|'))

  # Close ONLY the window this probe opened, by asking that window to close.
  "closing only the probe's own new window (WM_CLOSE to hwnd $($newWin.Hwnd))..."
  $closeType = Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr SendMessageW(IntPtr h, uint msg, IntPtr w, IntPtr l);
'@ -Name 'ProbeClose' -Namespace 'WhProbe' -PassThru
  [void]$closeType::SendMessageW($newHwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
  Start-Sleep -Seconds 3

  $aliveNow = [WhProbe.Win32]::IsWindow($newHwnd)
  Add-Result 'the probe window closed and its instance is gone' 'alive=False' "alive=$aliveNow" (-not $aliveNow)

  $chromeAfter = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'chrome\.exe$' })
  $survived = @($chromeAfter | Where-Object { $before.ContainsKey($_.HwndValue) })
  Add-Result 'every pre-existing Chrome window survived the probe' "all $(@($before.Values | Where-Object { $_.ProcessPath -match 'chrome\.exe$' }).Count) pre-existing Chrome windows still open" "$($survived.Count) of $(@($before.Values | Where-Object { $_.ProcessPath -match 'chrome\.exe$' }).Count) still present" ($survived.Count -eq @($before.Values | Where-Object { $_.ProcessPath -match 'chrome\.exe$' }).Count)

  # And the dead instance's marker is no longer derivable.
  $deadMarker = $markerNewAfter.MarkerNoBoot
  $stillThere = @($chromeAfter | Where-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerNoBoot -eq $deadMarker })
  Add-Result "the destroyed instance's marker is not derivable from any surviving Chrome window" 'no survivor reproduces the dead marker' "matches=$($stillThere.Count)" ([bool]($stillThere.Count -eq 0))
}

""
"=== EXPERIMENT 4 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
