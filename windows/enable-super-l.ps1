# windows/enable-super-l.ps1
# Disable Windows' hard-coded Win+L lock handler so AutoHotkey can rebind
# Super+l to "snap window right" (matching gnome/keybindings.ini).
#
# Lock is NOT lost: Super+q still locks via the LockWorkStation() API call
# inside gnome-keybindings.ahk.
#
# Run ONCE as administrator, then reboot. To revert, run with -Revert.
#
#   powershell -ExecutionPolicy Bypass -File windows\enable-super-l.ps1
#   powershell -ExecutionPolicy Bypass -File windows\enable-super-l.ps1 -Revert
[CmdletBinding()]
param([switch]$Revert)
$ErrorActionPreference = 'Stop'

$path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$name  = 'DisableLockWorkstation'

if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }

if ($Revert) {
    Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
    Write-Host 'Win+L lock restored. Reboot for it to take effect.'
} else {
    New-ItemProperty -Path $path -Name $name -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host 'Win+L lock handler disabled.'
    Write-Host 'Super+q will now be your lock key (already wired in gnome-keybindings.ahk).'
    Write-Host 'Reboot for the change to take effect.'
}