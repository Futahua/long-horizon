# probe-child.ps1 — ONE short-lived helper process.
#
# Each invocation is a fresh process with no memory of any previous run: this is
# exactly the "Papers/helper restarted" condition the design has to survive.
#
#   <op> get    <hwndDecimal>            safe read (atom-resolved, no dereference)
#   <op> getraw <hwndDecimal>            read the stored value WITHOUT dereferencing
#   <op> deref  <hwndDecimal>            UNSAFE: dereference the stored value as a string
#   <op> atom   <hwndDecimal>            set a new atom-backed tag; prints the value
#   <op> setptr <hwndDecimal> <text>     HAZARD: store a pointer into THIS process's memory
#   <op> setint <hwndDecimal> <int>      store a small integer (atom-collision test)
#   <op> remove <hwndDecimal>
#   <op> scan                            enumerate visible top-level windows for tags

. "$PSScriptRoot\win-identity-lib.ps1"

$op = $args[0]
$hwnd = if ($args.Count -gt 1) { [IntPtr][long]$args[1] } else { [IntPtr]::Zero }

switch ($op) {
  'get' {
    $alive = [WhProbe.Win32]::IsWindow($hwnd)
    $tag = if ($alive) { Get-ProbeTag $hwnd } else { $null }
    "child=$PID alive=$alive hwnd=$('0x{0:X}' -f $hwnd.ToInt64()) tag=$tag"
  }
  'getraw' {
    $raw = Get-ProbeTagRaw $hwnd
    $info = Test-ProbeTagIsDereferenceable $hwnd
    "child=$PID hwnd=$('0x{0:X}' -f $hwnd.ToInt64()) raw=$($info.RawValue) looksLikeAtom=$($info.LooksLikeAtom)"
  }
  'deref' {
    # Reproduces the hazard deliberately: treat the stored value as a string pointer.
    $raw = Get-ProbeTagRaw $hwnd
    if ($raw -eq [IntPtr]::Zero) { "child=$PID deref=NO_VALUE"; break }
    try {
      $text = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($raw)
      "child=$PID deref=OK value=$text"
    } catch {
      "child=$PID deref=THREW $($_.Exception.GetType().Name)"
    }
  }
  'atom' {
    $value = New-ProbeInstanceTag
    $set = Set-ProbeTag -Hwnd $hwnd -Value $value
    "child=$PID atom=OK atomValue=$($set.Atom) value=$value"
  }
  'setptr' {
    # Hazard reproduction: the value IS a pointer into this process.
    $text = if ($args.Count -gt 2) { $args[2] } else { 'POINTER-TAGGED-' + [guid]::NewGuid().ToString('N') }
    $ptr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($text)
    [void](Set-ProbeTagPointer -Hwnd $hwnd -Value $ptr.ToInt64())
    "child=$PID setptr=OK pointer=0x$($ptr.ToInt64().ToString('X')) text=$text"
    Start-Sleep -Milliseconds 400
  }
  'setint' {
    $value = [long]$args[2]
    [void](Set-ProbeTagPointer -Hwnd $hwnd -Value $value)
    $read = Get-ProbeTag $hwnd
    "child=$PID setint=OK value=$value safeRead=$read"
  }
  'remove' {
    try { Remove-ProbeTag $hwnd; "child=$PID remove=OK" } catch { "child=$PID remove=FAIL $_" }
  }
  'scan' {
    $all = Get-ProbeTopLevelWindows
    $found = @()
    foreach ($w in $all) { if ($w.Tag) { $found += "$($w.Hwnd)/$($w.Pid)/$($w.Tag)" } }
    "child=$PID scan visible=$($all.Count) tagged=$($found.Count) [$($found -join ' ')]"
  }
  default { "child=$PID unknown-op=$op" }
}
