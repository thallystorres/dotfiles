# windows/bootstrap.ps1
# Windows host bootstrap for the dotfiles repo. Idempotent.
#   - enables WSL2
#   - installs apps via winget (windows/winget-packages.txt)
#   - installs CLI tools via scoop (windows/scoop-packages.txt)
#   - stages Windows Terminal settings.json (with the repo's Kanagawa scheme)
#   - installs apps via winget (windows/winget-packages.txt), incl. AutoHotkey
#   - installs CLI tools via scoop (windows/scoop-packages.txt)
#   - stages Windows Terminal settings.json (with the repo's Kanagawa scheme)
#   - applies Cursor config via cursor/windows-profile.ps1 (if Cursor is present)
#   - installs the GNOME-keybindings AutoHotkey script + a startup shortcut
#     (windows/ahk/gnome-keybindings.ahk) so Super+*/Shift+Super+* map as in
#     gnome/keybindings.ini; prints the one-off admin command to enable Super+l
#   - clones the repo to $env:USERPROFILE\dev\dotfiles if missing
#   - hands off to wsl/setup-wsl.ps1 via -RunWsl switch
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1
#   powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1 -SkipWsl
#   powershell -ExecutionPolicy Bypass -File windows\bootstrap.ps1 -WhatIf
[CmdletBinding()]
param(
    [switch]$SkipWsl,
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $here

function Invoke-Cmd($cmd) {
    if ($WhatIf) { Write-Host "WHATIF: $cmd"; return }
    Invoke-Expression $cmd
}

Write-Host '==> 1/8 Enable WSL2 + Virtual Machine Platform'
$feat = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if ($feat -and $feat.State -ne 'Enabled') {
    Invoke-Cmd 'Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart'
    $needReboot = $true
} else { Write-Host '    already enabled' }
$feat = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
if ($feat -and $feat.State -ne 'Enabled') {
    Invoke-Cmd 'Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart'
    $needReboot = $true
} else { Write-Host '    already enabled' }
if ($needReboot -and -not $WhatIf) {
    Write-Host '    WSL features enabled; rebooting in 10s (rerun this script after reboot).'
    Start-Sleep -Seconds 10; Restart-Computer -Force
}
wsl --set-default-version 2 | Out-Null

Write-Host '==> 2/8 winget apps (windows/winget-packages.txt)'
$winget = Join-Path $here 'winget-packages.txt'
Get-Content $winget | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    $id = $_.Trim()
    Write-Host "    winget install --id $id -e --silent"
    if (-not $WhatIf) { winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements 2>$null | Out-Null }
}

Write-Host '==> 3/8 scoop CLI tools (windows/scoop-packages.txt)'
$scoop = Get-Command scoop -ErrorAction SilentlyContinue
if (-not $scoop) {
    Write-Host '    installing scoop (user-scope, no admin)'
    if (-not $WhatIf) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
    }
}
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' + $env:PATH
$sp = Join-Path $here 'scoop-packages.txt'
Get-Content $sp | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    $p = $_.Trim()
    Write-Host "    scoop install $p"
    if (-not $WhatIf) { scoop install $p 2>$null | Out-Null }
}

Write-Host '==> 4/8 Stage Windows Terminal settings.json'
$wtState = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
if (Test-Path $wtState) {
    $src = Join-Path $here 'windows-terminal\settings.json'
    $dst = Join-Path $wtState 'settings.json'
    if ($WhatIf) { Write-Host "WHATIF: copy $src -> $dst" }
    else {
        Copy-Item $src $dst -Force
        Write-Host '    staged'
    }
} else {
    Write-Host '    Windows Terminal state dir not found; start it once first.'
}

Write-Host '==> 5/8 Apply Cursor config (cursor/windows-profile.ps1)'
$cursorPs = Join-Path $repo 'cursor\windows-profile.ps1'
if (Test-Path $cursorPs) {
    $cursorBin = Get-Command cursor -ErrorAction SilentlyContinue
    $cursorDir = Join-Path $env:APPDATA 'Cursor\User'
    if ($cursorBin -or (Test-Path $cursorDir)) {
        if ($WhatIf) { Write-Host "WHATIF: $cursorPs" }
        else { & $cursorPs }
    } else {
        Write-Host '    Cursor not installed yet; run cursor\windows-profile.ps1 later.'
    }
} else { Write-Host '    cursor scaffold missing; skip' }

Write-Host '==> 6/8 AutoHotkey: GNOME keybindings + startup entry'
$ahkExe = Get-Command AutoHotkey -ErrorAction SilentlyContinue
if (-not $ahkExe) {
    $ahkExe = Get-Command 'AutoHotkey64.exe' -ErrorAction SilentlyContinue
}
if ($ahkExe) {
    $ahkScript = Join-Path $repo 'windows\ahk\gnome-keybindings.ahk'
    $enableSuperL = Join-Path $here 'enable-super-l.ps1'

    # Stage a startup shortcut so the script runs at every login.
    $startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
    if (-not (Test-Path $startup)) { New-Item -ItemType Directory -Force -Path $startup | Out-Null }
    $lnk = Join-Path $startup 'gnome-keybindings.lnk'
    if ($WhatIf) {
        Write-Host "WHATIF: create startup shortcut -> $lnk"
    } else {
        $shell = New-Object -ComObject WScript.Shell
        $s = $shell.CreateShortcut($lnk)
        $s.TargetPath = $ahkExe.Source
        $s.Arguments  = "`"$ahkScript`""
        $s.WindowStyle = 7   # minimized
        $s.Save()
        Write-Host '    startup shortcut created'
    }

    # Disable Windows' Win+L lock so Super+l can be remapped; needs admin.
    # We *don't* auto-elevate — print clear instructions instead.
    Write-Host '    To enable Super+l (snap right), run once as admin then reboot:'
    Write-Host "      powershell -ExecutionPolicy Bypass -File `"$enableSuperL`""

    # Launch the AHK script now so the bindings work in the current session.
    if (-not $WhatIf) { & $ahkExe.Source $ahkScript }
} else {
    Write-Host '    AutoHotkey not installed yet (winget AutoHotkey.AutoHotkey); rerun bootstrap after reboot.'
}

Write-Host '==> 7/8 PowerShell profile'
$pf = Join-Path $here 'powershell\Microsoft.PowerShell_profile.ps1'
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir  = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }
if ($WhatIf) { Write-Host "WHATIF: link $pf -> $profilePath" }
else {
    if (Test-Path $profilePath) { Remove-Item $profilePath -Force }
    try { New-Item -ItemType SymbolicLink -Path $profilePath -Target $pf | Out-Null }
    catch { Copy-Item $pf $profilePath -Force }
}

Write-Host '==> 8/8 Hand off to WSL setup'
if ($SkipWsl) { Write-Host '    -SkipWsl set; rerun wsl\setup-wsl.ps1 manually.' }
else {
    $setupWsl = Join-Path $repo 'wsl\setup-wsl.ps1'
    if ($WhatIf) { Write-Host "WHATIF: & $setupWsl" }
    else { & $setupWsl }
}

Write-Host '==> Done. Open Windows Terminal (default profile is Fedora WSL).'