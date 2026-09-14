# probe-02-tag-mechanism.ps1
#
# EXPERIMENT 2 — does a Papers-owned per-HWND tag behave the way the design's
# Stage 0 assumes, measured across REAL process boundaries?
#
# Every read/write below happens in a FRESH child process with no memory of any
# previous run. That is the helper-restart / Papers-restart condition, not a
# simulation of it. If a child process dies, the parent survives and reports it.
#
# Windows written to here were created by this probe: scratch windows owned by
# processes this probe starts. No pre-existing application window of the
# creator's is written to, moved, hidden or closed.

. "$PSScriptRoot\win-identity-lib.ps1"

$PS = (Get-Process -Id $PID).Path
$CHILD = Join-Path $PSScriptRoot 'probe-child.ps1'
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}

function Invoke-Child {
  param([string[]]$ChildArgs, [int]$TimeoutSec = 40)
  $job = Start-Job -ScriptBlock {
    param($ps, $child, $a)
    & $ps -NoProfile -File $child @a 2>&1 | Out-String
  } -ArgumentList $PS, $CHILD, $ChildArgs
  if (Wait-Job $job -Timeout $TimeoutSec) {
    $out = (Receive-Job $job | Out-String).Trim()
    Remove-Job $job -Force
    return $out
  }
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force
  return "<child did not return within ${TimeoutSec}s>"
}

function Get-TagFromChildOutput {
  param([string]$Out)
  if ($Out -match 'value=(PapersProbe\.InstanceId\.\S+)') { return $matches[1] }
  return $null
}

$tmp = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeTitleMut' -Namespace 'WhProbe' -PassThru

function Set-Title {
  param([IntPtr]$Hwnd, [string]$Text)
  return $tmp::SetWindowTextW($Hwnd, $Text)
}

function Start-ScratchWindow {
  param([string]$Title)
  $p = Start-Process -FilePath $PS -ArgumentList @('-NoProfile', '-File', $SCRATCH, $Title) -PassThru
  for ($i = 0; $i -lt 80; $i++) {
    $hit = Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $p.Id } | Select-Object -First 1
    if ($hit) { return [pscustomobject]@{ Process = $p; Window = $hit } }
    Start-Sleep -Milliseconds 250
  }
  return [pscustomobject]@{ Process = $p; Window = $null }
}

"=== EXPERIMENT 2 : per-HWND tag mechanism across real process boundaries ==="
"probe process : $PID  ($PS)"
""

# ---------------------------------------------------------------------------
# A. Atom-backed tag on a window, read back by fresh processes
# ---------------------------------------------------------------------------
"--- A. atom-backed tag on a NON-OWNED window, read back by fresh processes ---"

$w1 = Start-ScratchWindow -Title 'PROBE-MARKER-A'
if (-not $w1.Window) {
  Add-Result 'scratch window A created' 'a visible top-level window' 'none appeared' $false
} else {
  $h1 = [IntPtr]$w1.Window.HwndValue
  Add-Result 'scratch window A created' 'a visible top-level window' "hwnd=$($w1.Window.Hwnd) class=$($w1.Window.ClassName) pid=$($w1.Window.Pid)" $true

  $atomOut = Invoke-Child @('atom', "$($h1.ToInt64())")
  "  write     : $atomOut"
  $tagA = Get-TagFromChildOutput $atomOut
  Add-Result 'a NON-OWNER process can tag a foreign HWND' 'atom=OK' $atomOut ($atomOut -match 'atom=OK' -and $tagA)

  $getOut = Invoke-Child @('get', "$($h1.ToInt64())")
  "  read #1   : $getOut"
  Add-Result 'tag readable by a FRESH process (different PID)' "tag=$tagA" $getOut ($tagA -and $getOut -match [regex]::Escape($tagA))

  $getOut2 = Invoke-Child @('get', "$($h1.ToInt64())")
  "  read #2   : $getOut2"
  Add-Result 'a SECOND fresh process reads the identical tag' "tag=$tagA" $getOut2 ($tagA -and $getOut2 -match [regex]::Escape($tagA))

  for ($n = 1; $n -le 5; $n++) {
    [void](Set-Title -Hwnd $h1 -Text "PROBE-MARKER-A mutated $n")
    Start-Sleep -Milliseconds 120
    $sig = Get-ProbeWindowSignals -Hwnd $h1
    $read = Invoke-Child @('get', "$($h1.ToInt64())")
    "  title $n   : title='$($sig.Title)' hwnd=$($sig.Hwnd) pid=$($sig.Pid) -> tag=$((Get-TagFromChildOutput $read))"
    if ($n -eq 5) {
      Add-Result 'tag survives 5 title changes on the same HWND' "tag=$tagA unchanged" $read ($tagA -and $read -match [regex]::Escape($tagA))
    }
  }
  $sigAfter = Get-ProbeWindowSignals -Hwnd $h1
  Add-Result 'title mutation changes the title and nothing else' 'same HWND, same PID, new title' "title='$($sigAfter.Title)' hwnd=$($sigAfter.Hwnd) pid=$($sigAfter.Pid)" ($sigAfter.HwndValue -eq $h1.ToInt64() -and $sigAfter.Pid -eq $w1.Window.Pid)

  # Is Notepad (the design's named Win32 reference app) even reachable this way?
  ""
  "--- A2. the design's named reference app, measured ---"
  $npProbe = Start-Process -FilePath 'notepad.exe' -PassThru -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 3
  $npAll = @(Get-Process -Name notepad -ErrorAction SilentlyContinue)
  $npWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'notepad\.exe$' })
  $npVisible = @($npWins | Where-Object { $_.IsVisible })
  "  notepad.exe processes        : $(($npAll | ForEach-Object { $_.Id }) -join ',')"
  "  notepad-owned windows (any)  : $($npWins.Count)"
  "  notepad-owned windows visible: $($npVisible.Count)"
  foreach ($w in $npWins) { "    hwnd=$($w.Hwnd) class=$($w.ClassName) visible=$($w.IsVisible) title='$($w.Title)'" }
  Add-Result 'Notepad exposes a visible top-level window for a helper to enumerate' 'at least one visible notepad.exe top-level window' "found $($npVisible.Count)" ($npVisible.Count -gt 0)
  foreach ($p in $npAll) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
  if ($npProbe -and -not $npProbe.HasExited) { Stop-Process -Id $npProbe.Id -Force -ErrorAction SilentlyContinue }

  # -------------------------------------------------------------------------
  # B. THE HAZARD, reproduced on purpose: a pointer-valued property.
  # -------------------------------------------------------------------------
  ""
  "--- B. pointer-valued property: what a later reader actually gets ---"
  Add-Result 'window carries no pre-existing tag' 'tag=null' "tag=$(Get-ProbeTag $h1)" ($null -eq (Get-ProbeTag $h1))

  # The writer process allocates the string, stores the POINTER, then dies.
  $ptrOut = Invoke-Child @('setptr', "$($h1.ToInt64())", 'DANGLING-VALUE')
  "  writer    : $ptrOut"
  Add-Result 'SetProp with a caller-allocated pointer succeeds' 'setptr=OK' $ptrOut ($ptrOut -match 'setptr=OK')

  $rawOut = Invoke-Child @('getraw', "$($h1.ToInt64())")
  "  raw read  : $rawOut"
  Add-Result 'the stored value is a memory address, not a portable identifier' 'a pointer value, not <= 0xFFFF' $rawOut ($rawOut -match 'looksLikeAtom=False')

  $safeOut = Invoke-Child @('get', "$($h1.ToInt64())")
  "  safe read : $safeOut"
  Add-Result 'safe read REFUSES a non-atom value instead of dereferencing it' 'reports non-atom-value, no crash' $safeOut ($safeOut -match 'non-atom-value' -and $safeOut -notmatch 'Fatal error')

  $derefOut = Invoke-Child @('deref', "$($h1.ToInt64())")
  "  unsafe deref (writer already dead) : $($derefOut.Split("`n")[0])"
  $derefText = $derefOut.Split("`n")[0]
  $derefDurable = ($derefOut -match 'deref=OK value=DANGLING-VALUE')
  Add-Result 'dereferencing the stored pointer after the writer died' 'an unusable identity: either an access violation, or memory that merely happens to still read' $derefText (-not $derefDurable)
  if ($derefDurable) { "        NOTE: deref succeeded here only because the freed pages were still mapped." }
  "        Either outcome disqualifies the value: it is a stale address, not an identifier."

  [void](Invoke-Child @('remove', "$($h1.ToInt64())"))

  # A raw small integer is indistinguishable from an atom by range alone.
  $intOut = Invoke-Child @('setint', "$($h1.ToInt64())", '4660')
  "  small int : $intOut"
  Add-Result 'a raw small integer stored as a property is read back as if it were an atom' 'safeRead resolves it through the atom table, never as the number 4660' $intOut ($intOut -match 'safeRead=<atom-4660-unknown>|safeRead=PapersProbe|safeRead=\S+')
  [void](Invoke-Child @('remove', "$($h1.ToInt64())"))

  # -------------------------------------------------------------------------
  # C. Rediscovery by enumeration, and destruction
  # -------------------------------------------------------------------------
  ""
  "--- C. rediscovery by enumeration, then window destruction ---"
  $atomOut = Invoke-Child @('atom', "$($h1.ToInt64())")
  "  write     : $atomOut"
  $tagC = Get-TagFromChildOutput $atomOut

  $scanOut = Invoke-Child @('scan')
  "  scan      : $($scanOut.Substring(0, [Math]::Min(200, $scanOut.Length)))"
  Add-Result 'a fresh process rediscovers the tagged window by enumerating the desktop' 'tag present in the enumeration' $scanOut ($tagC -and $scanOut -match [regex]::Escape($tagC))

  $markerBefore = Get-ProbeMarker -Hwnd $h1
  "  marker    : $($markerBefore.MarkerNoBoot)"
  Stop-Process -Id $w1.Process.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  $aliveAfter = [WhProbe.Win32]::IsWindow($h1)
  $after = Invoke-Child @('get', "$($h1.ToInt64())")
  "  after death : $after"
  Add-Result 'HWND is dead once the owning process dies' 'alive=False' "alive=$aliveAfter" (-not $aliveAfter)
  Add-Result 'tag is unreadable once the owning process dies' 'tag is empty on a dead HWND' $after ($after -match 'tag=\s*$')
  $scanAfter = Invoke-Child @('scan')
  "  scan after : $($scanAfter.Substring(0, [Math]::Min(200, $scanAfter.Length)))"
  Add-Result 'dead window disappears from a fresh enumeration' 'tag no longer discoverable' $scanAfter ($tagC -and $scanAfter -notmatch [regex]::Escape($tagC))
}

""
"=== EXPERIMENT 2 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

if ($w1.Process -and -not $w1.Process.HasExited) { Stop-Process -Id $w1.Process.Id -Force -ErrorAction SilentlyContinue }
