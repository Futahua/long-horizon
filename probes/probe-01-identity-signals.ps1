# probe-01-identity-signals.ps1
#
# EXPERIMENT 1 — what identity does Windows actually expose per top-level window?
#
# Read-only against the creator's live applications: enumerates, never mutates.
# Answers:
#   * do the named apps expose distinguishable identity per window?
#   * do two windows of ONE process share a PID (i.e. is PID enough)?
#   * is process creation time available and is it boot-scoped?

. "$PSScriptRoot\win-identity-lib.ps1"

$boot = Get-ProbeBootTimeUtc
"BOOT_TIME_UTC : $($boot.ToString('o'))"
"NOW_UTC       : $((Get-Date).ToUniversalTime().ToString('o'))"
"UPTIME_MIN    : $([math]::Round(((Get-Date).ToUniversalTime() - $boot).TotalMinutes, 2))"
"PWSH          : $($PSVersionTable.PSVersion)"
"KIND          : $($PSVersionTable.PSEdition)"
"ELEVATED      : $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
""

$keys = Get-ProbeKeyWindows
"=== NAMED APPLICATION TOP-LEVEL WINDOWS (visible) : $($keys.Count) ==="
$keys | Select-Object Hwnd, Pid, ClassName,
  @{n='ProcCreatedUtc';e={ if ($_.ProcCreatedUtc) { $_.ProcCreatedUtc.ToString('o') } else { $null } }},
  @{n='Exe';e={ if ($_.ProcessPath) { Split-Path $_.ProcessPath -Leaf } else { $null } }},
  @{n='Title';e={ if ($_.Title.Length -gt 58) { $_.Title.Substring(0,58) + '...' } else { $_.Title } }} |
  Format-Table -AutoSize | Out-String -Width 400

"=== PID -> DISTINCT WINDOW COUNTS (named apps) ==="
$keys | Group-Object Pid | ForEach-Object {
  [pscustomobject]@{
    Pid          = $_.Name
    WindowCount  = $_.Count
    Exe          = ($_.Group[0].ProcessPath)
    Classes      = (($_.Group | Select-Object -ExpandProperty ClassName -Unique) -join ',')
    Hwnds        = (($_.Group | Select-Object -ExpandProperty Hwnd) -join ',')
    CreatedUtc   = if ($_.Group[0].ProcCreatedUtc) { $_.Group[0].ProcCreatedUtc.ToString('o') } else { $null }
  }
} | Format-Table -AutoSize | Out-String -Width 400

"=== PROCESS CREATION TIME vs BOOT (boot-scoped?) ==="
$keys | Group-Object Pid | ForEach-Object {
  $c = $_.Group[0].ProcCreatedUtc
  [pscustomobject]@{
    Pid            = $_.Name
    Exe            = Split-Path $_.Group[0].ProcessPath -Leaf
    CreatedAfterBoot = if ($c) { $c -gt $boot } else { $null }
    CreatedUtc     = if ($c) { $c.ToString('o') } else { $null }
    ThreadCreated  = if ($_.Group[0].ThreadCreatedUtc) { $_.Group[0].ThreadCreatedUtc.ToString('o') } else { $null }
    TitleChangesOnThread = 'n/a'
  }
} | Format-Table -AutoSize | Out-String -Width 400

"=== MARKER PREVIEW (what a helper can recompute with no tag at all) ==="
$keys | Select-Object -First 8 | ForEach-Object {
  $m = Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)
  [pscustomobject]@{
    Hwnd        = $m.Hwnd
    Class       = $m.ClassName
    Pid         = $m.Pid
    MarkerNoBoot= $m.MarkerNoBoot
  }
} | Format-Table -AutoSize | Out-String -Width 400

"=== TAG PRESENCE ON FOREIGN WINDOWS (expect: none) ==="
$tagged = 0
foreach ($k in $keys) { if ($k.Tag) { $tagged++ } }
"named-app windows carrying the probe tag: $tagged of $($keys.Count)"

"=== ALL VISIBLE TOP-LEVEL WINDOWS : $((Get-ProbeTopLevelWindows).Count) ==="
