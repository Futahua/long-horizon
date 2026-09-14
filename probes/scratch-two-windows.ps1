# scratch-two-windows.ps1 — ONE process that owns TWO top-level windows.
#
# This is the shape that decides whether PID is a usable identity component:
# two distinct native windows, same process, same executable, same window class.
# Nothing pre-existing is touched; both windows are this process's own.

. "$PSScriptRoot\win-identity-lib.ps1"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$forms = @()
foreach ($i in 1..2) {
  $f = New-Object System.Windows.Forms.Form
  $f.Text = "PROBE-PAIR-$i"
  $f.Width = 300
  $f.Height = 150
  $f.StartPosition = 'Manual'
  $f.Left = 40 + ($i * 340)
  $f.Top = 40
  $f.ShowInTaskbar = $false
  $forms += $f
}

$forms[0].add_Shown({
  foreach ($f in $forms) {
    "PAIR_PID=$PID HWND=$('0x{0:X}' -f $f.Handle.ToInt64()) TITLE=$($f.Text)"
  }
  [Console]::Out.Flush()
})

# Both windows must exist at once: show the second, then run the loop on the first.
$forms[1].Show()
$forms[0].Show()
[void][System.Windows.Forms.Application]::Run($forms[0])
