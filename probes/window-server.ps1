# window-server.ps1 — a long-lived process that creates and destroys its OWN
# top-level windows on command, so HWND slot reuse can be FORCED rather than
# waited for.
#
# Required by probe-11-hwnd-reuse-harness.ps1.
#
# Usage: window-server.ps1 <channelDirectory>
#   channelDirectory/cmd.txt  <- "CREATE|<title>" | "DESTROY|<hwndDecimal>" | "EXIT"
#   channelDirectory/res.txt  <- one response line per command
#
# Every window here is this process's own and is destroyed by this process. No
# pre-existing window is touched.

param([Parameter(Mandatory = $true)][string]$ChannelDirectory)

. "$PSScriptRoot\win-identity-lib.ps1"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $ChannelDirectory)) { New-Item -ItemType Directory -Path $ChannelDirectory -Force | Out-Null }
$cmdPath = Join-Path $ChannelDirectory 'cmd.txt'
$resPath = Join-Path $ChannelDirectory 'res.txt'

function Write-Response {
  param([string[]]$Lines)
  Set-Content -Path $resPath -Value ($Lines -join "`r`n") -Encoding utf8
}

# A hidden but real top-level window: no parent, its own window class, and a
# title we can read back natively to prove which window object holds a handle.
function New-ServerWindow {
  param([string]$Title, [string]$ClassName)
  $form = New-Object System.Windows.Forms.Form
  $form.Text = $Title
  $form.Width = 260
  $form.Height = 120
  $form.StartPosition = 'Manual'
  $form.Left = -4000          # offscreen: the creator's desktop is not disturbed
  $form.Top = -4000
  $form.ShowInTaskbar = $false
  $form.FormBorderStyle = 'Sizable'
  $form.Show()
  # Force creation and drain the queued messages so the title is really set
  # before we report the handle.
  [void]$form.Handle
  [System.Windows.Forms.Application]::DoEvents()
  $h = $form.Handle
  # Read the title back through the native API - ground truth, not the property.
  $sb = New-Object System.Text.StringBuilder 512
  [void][WhProbe.Win32]::GetWindowTextW($h, $sb, $sb.Capacity)
  $readBack = $sb.ToString()
  $script:Windows[[int64]$h] = $form
  return [pscustomobject]@{ Hwnd = $h; TitleReadBack = $readBack }
}

$script:Windows = @{}
Write-Response @("ready|pid=$PID|session=$([System.Diagnostics.Process]::GetCurrentProcess().SessionId)")

while ($true) {
  if (Test-Path $cmdPath) {
    $line = (Get-Content $cmdPath -Raw -ErrorAction SilentlyContinue)
    if ($line) { $line = $line.Trim() }
    Remove-Item $cmdPath -Force -ErrorAction SilentlyContinue
    if (-not $line) { continue }

    $parts = $line -split '\|'
    switch ($parts[0]) {
      'CREATE' {
        $title = if ($parts.Count -gt 1) { $parts[1] } else { 'PROBE-SERVER-WINDOW' }
        $w = New-ServerWindow -Title $title
        Write-Response @("CREATED|$($w.Hwnd.ToInt64())|$('0x{0:X}' -f $w.Hwnd.ToInt64())|title=$($w.TitleReadBack)|pid=$PID")
      }
      'DESTROY' {
        $hv = [int64]$parts[1]
        $h = [IntPtr]$hv
        if ($script:Windows.ContainsKey($hv)) {
          $form = $script:Windows[$hv]
          $resolved = $form.Handle
          # Dispose the form and drain messages so the HWND is really gone.
          $form.Dispose()
          [System.Windows.Forms.Application]::DoEvents()
          $script:Windows.Remove($hv)
          $alive = [WhProbe.Win32]::IsWindow($h)
          Write-Response @("DESTROYED|$hv|resolved=$('0x{0:X}' -f $resolved.ToInt64())|stillAlive=$alive")
        } else {
          Write-Response @("DESTROY-FAILED|$hv|not-owned-by-this-server")
        }
      }
      'LIST' {
        $lines = @("LIST|count=$($script:Windows.Count)")
        foreach ($k in $script:Windows.Keys) {
          $alive = [WhProbe.Win32]::IsWindow([IntPtr]$k)
          $lines += "  hwnd=0x$($k.ToString('X')) alive=$alive"
        }
        Write-Response $lines
      }
      'EXIT' {
        Write-Response @('EXITING')
        foreach ($k in @($script:Windows.Keys)) { try { $script:Windows[$k].Dispose() } catch { } }
        [System.Windows.Forms.Application]::DoEvents()
        exit 0
      }
      default { Write-Response @("UNKNOWN|$($parts[0])") }
    }
  }
  [System.Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 20
}
