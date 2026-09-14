# probe-08-owned-vs-unowned.ps1
#
# EXPERIMENT 8 — which real windows does the shipping helper actually accept, and
# is "owned" the clause that decides it?
#
# Why this matters for identity work: the auto-tracker's whole job is to decide
# WHAT to add. If a clause silently rejects a whole class of ordinary application
# windows, the layout quietly misses them, and that only shows up on day thirty.
#
# Read-only: only `list` is sent to the helper. Windows created here are probe-owned.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'
$SCRATCH2 = Join-Path $PSScriptRoot 'scratch-two-windows.ps1'

function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

$ex = Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr h, uint c);
[DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint f);
[DllImport("user32.dll")] public static extern IntPtr GetLastActivePopup(IntPtr h);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
'@ -Name 'ProbeOwn' -Namespace 'WhProbe' -PassThru

"=== EXPERIMENT 8 : owned vs unowned, and what the helper accepts ==="
""

# --- start the real helper exactly as Papers does --------------------------
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $PS51
$psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$helper = [System.Diagnostics.Process]::Start($psi)
$helper.StandardInput.WriteLine('{"requestId":1,"method":"list"}')
$helper.StandardInput.Flush()
$deadline = (Get-Date).AddSeconds(90)
$resp = $null
while ((Get-Date) -lt $deadline) {
  $task = $helper.StandardOutput.ReadLineAsync()
  if ($task.Wait(1000)) { $resp = $task.Result; break }
}
if (-not $resp) { "HELPER DID NOT RESPOND"; exit 1 }
$listed = ($resp | ConvertFrom-Json).windows
"helper listed $($listed.Count) windows"
""

# --- probe windows: owned vs unowned ---------------------------------------
$idFileA = Join-Path $env:TEMP ('probe-own-a-' + [guid]::NewGuid().ToString('N') + '.txt')
$idFileB = Join-Path $env:TEMP ('probe-own-b-' + [guid]::NewGuid().ToString('N') + '.txt')
$scratchA = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile', '-File', $SCRATCH, 'PROBE-OWNED-A', $idFileA) -PassThru
$scratchB = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile', '-File', $SCRATCH2, 'PROBE-OWNED-B', $idFileB) -PassThru
Start-Sleep -Seconds 4

$hwndA = [IntPtr]::Zero
if (Test-Path $idFileA) { $r = (Get-Content $idFileA -Raw).Trim(); if ($r -match 'HWNDDEC=(\d+)') { $hwndA = [IntPtr][long]$matches[1] } }
$hwndB = @()
foreach ($w in (Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $scratchB.Id -and $_.ClassName -notmatch 'PseudoConsole' })) { $hwndB += [IntPtr]$w.HwndValue }

function Describe-Owner {
  param([IntPtr]$H)
  if ($H -eq [IntPtr]::Zero) { return 'n/a' }
  $owner = $ex::GetWindow($H, 4)
  $root = $ex::GetAncestor($H, 2)
  $lap = if ($owner -ne [IntPtr]::Zero) { $ex::GetLastActivePopup($root) } else { [IntPtr]::Zero }
  $cn = New-Object System.Text.StringBuilder 200
  if ($owner -ne [IntPtr]::Zero) { [void]$ex::GetClassNameW($owner, $cn, $cn.Capacity) }
  $isOwned = $owner -ne [IntPtr]::Zero
  $clausePass = (-not $isOwned) -or ($lap -eq $H)
  [pscustomobject]@{
    Hwnd = '0x{0:X}' -f $H.ToInt64()
    Owned = $isOwned
    Owner = if ($isOwned) { '0x{0:X} ({1})' -f $owner.ToInt64(), $cn.ToString() } else { 'none' }
    Root = '0x{0:X}' -f $root.ToInt64()
    LastActivePopupOfRoot = if ($isOwned) { '0x{0:X}' -f $lap.ToInt64() } else { 'n/a' }
    OwnedClausePasses = $clausePass
  }
}

"--- probe window A: one visible WinForms window ---"
$descA = Describe-Owner $hwndA
$descA | Format-List | Out-String -Width 200 | Write-ProbeLine
""

"--- probe window B: two visible WinForms windows in one process ---"
foreach ($h in $hwndB) {
  $d = Describe-Owner $h
  $d | Format-List | Out-String -Width 200 | Write-ProbeLine
}
""

# --- the real applications -------------------------------------------------
"--- the creator's real application windows: owner state and helper acceptance ---"
""
$realPaths = 'chrome\.exe$|Obsidian\.exe$|Code\.exe$|Papers\.exe$|claude\.exe$'
$realWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match $realPaths })
$rows = @()
foreach ($w in $realWins) {
  $h = [IntPtr]$w.HwndValue
  $d = Describe-Owner $h
  $rows += [pscustomobject]@{
    Exe = Split-Path $w.ProcessPath -Leaf
    Pid = $w.Pid
    Hwnd = $d.Hwnd
    Owned = $d.Owned
    Owner = $d.Owner
    ClauseOK = $d.OwnedClausePasses
    ListedByHelper = (@($listed | Where-Object { [int]$_.processId -eq $w.Pid }).Count -gt 0)
    Title = if ($w.Title.Length -gt 30) { $w.Title.Substring(0, 30) } else { $w.Title }
  }
}
$rows | Format-Table -AutoSize | Out-String -Width 250 | Write-ProbeLine
""

$probeA = @($listed | Where-Object { [int]$_.processId -eq $scratchA.Id })
$probeB = @($listed | Where-Object { [int]$_.processId -eq $scratchB.Id })
"probe A (1 window, owned=$($descA.Owned), clause=$($descA.OwnedClausePasses)) listed: $($probeA.Count)"
"probe B ($($hwndB.Count) windows) listed: $($probeB.Count)"
""
"VERDICT: the helper's owned-window clause is evaluated as"
"         owner != 0 AND GetLastActivePopup(root) != this-window  ->  rejected."
"         Measured owner states above show which real windows that hits."

if (-not $helper.HasExited) { $helper.Kill() }
foreach ($p in @($scratchA, $scratchB)) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }
Remove-Item $idFileA, $idFileB -ErrorAction SilentlyContinue
