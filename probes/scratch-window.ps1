# scratch-window.ps1 — a disposable top-level window owned by a process this probe starts.
#
# Used to reproduce the "tag set by the owner" case and to test what happens to a
# window property when the OWNING process dies. Nothing pre-existing is touched.

. "$PSScriptRoot\win-identity-lib.ps1"

$title = if ($args.Count -gt 0) { $args[0] } else { 'PROBE-SCRATCH' }
$idFile = if ($args.Count -gt 1) { $args[1] } else { $null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = $title
$form.Width = 320
$form.Height = 160
$form.StartPosition = 'Manual'
$form.Left = 40
$form.Top = 40
$form.ShowInTaskbar = $false

# Report our own HWND so the parent can correlate without relying on process
# discovery, and so the probe never has to guess which PID owns the window.
$form.add_Shown({
  $h = $form.Handle
  $line = "SCRATCH_PID=$PID HWND=$('0x{0:X}' -f $h.ToInt64()) HWNDDEC=$($h.ToInt64()) TITLE=$($form.Text)"
  if ($idFile) { Set-Content -Path $idFile -Value $line -Encoding utf8 }
  $line
  [Console]::Out.Flush()
})

[void][System.Windows.Forms.Application]::Run($form)
