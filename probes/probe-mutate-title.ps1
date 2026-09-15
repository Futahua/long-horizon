# probe-mutate-title.ps1 — retitle ONE probe-owned window, by handle.
#
# Used by helper-client.mjs between two requests so the helper process stays
# alive across the change. The handle is passed explicitly; this script never
# searches for a window and never touches anything the probe did not create.

param([string]$HwndDecimal)

if (-not $HwndDecimal) { "no hwnd supplied"; exit 1 }

$ex = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
'@ -Name 'MutTitle' -Namespace 'WhProbeMut' -PassThru

$h = [IntPtr][long]$HwndDecimal
if (-not $ex::IsWindow($h)) { "hwnd $HwndDecimal is not a window"; exit 2 }

$before = New-Object System.Text.StringBuilder 512
[void]$ex::GetWindowTextW($h, $before, $before.Capacity)
$newTitle = "PROBE-018 title changed at $(Get-Date -Format 'HH:mm:ss')"
[void]$ex::SetWindowTextW($h, $newTitle)
Start-Sleep -Milliseconds 250
$after = New-Object System.Text.StringBuilder 512
[void]$ex::GetWindowTextW($h, $after, $after.Capacity)

"title-before='$($before.ToString())'"
"title-after ='$($after.ToString())'"
"still-a-window=$($ex::IsWindow($h))"
