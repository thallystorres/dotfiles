# wsl/setup-wsl.ps1
# Create a Fedora 43 WSL2 distro on the Windows host and hand off to the
# in-distro post-install script. Idempotent: skips steps already done.
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File wsl\setup-wsl.ps1
#   powershell -ExecutionPolicy Bypass -File wsl\setup-wsl.ps1 -User thallys
[CmdletBinding()]
param(
    [string]$DistroName = 'Fedora43',
    [string]$InstallDir = 'C:\WSL\Fedora43',
    [string]$User = 'thallys'
)
$ErrorActionPreference = 'Stop'
$here        = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootfsTar   = Join-Path $env:TEMP 'fedora-43-rootfs.tar.gz'

Write-Host '==> Ensuring WSL2 is the default version'
wsl --set-default-version 2 | Out-Null

Write-Host '==> Downloading Fedora 43 rootfs'
# Fedora publishes OCI images; we export a rootfs tarball usable by wsl --import.
if (-not (Test-Path $rootfsTar)) {
    # Pull the official Fedora 43 container image and export its rootfs.
    $tmp = Join-Path $env:TEMP 'fedora-rootfs-tmp'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    docker pull fedora:43
    $cid = docker create fedora:43
    docker export $cid -o $rootfsTar
    docker rm $cid | Out-Null
} else {
    Write-Host '    rootfs already present, skipping download'
}

Write-Host "==> Importing WSL distro '$DistroName' -> $InstallDir"
if (-not (wsl -l -q | Where-Object { $_ -eq $DistroName })) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    wsl --import $DistroName $InstallDir $rootfsTar
} else {
    Write-Host "    distro '$DistroName' already present, skipping import"
}

Write-Host '==> Dropping /etc/wsl.conf inside the distro'
$wslConf = Join-Path $here 'wsl.conf'
wsl -d $DistroName -- bash -lc "cat > /etc/wsl.conf" < $wslConf
wsl -d $DistroName -- bash -lc "echo 'PS1 kept default for now'"

# Create the user if missing
Write-Host "==> Ensuring user '$User' exists"
wsl -d $DistroName -- bash -lc "id $User 2>/dev/null || (useradd -m -G wheel $User && passwd $User)"
wsl -d $DistroName -- bash -lc "configure-user $User 2>/dev/null || true"

Write-Host '==> Setting default user via wsl.conf and restarting the distro'
wsl --terminate $DistroName
wsl -d $DistroName -- bash -lc "echo '[user]' >> /etc/wsl.conf && echo 'default=$User' >> /etc/wsl.conf"

Write-Host '==> Copying host .wslconfig to %USERPROFILE%'
Copy-Item (Join-Path $here 'fedora.wslconfig') (Join-Path $env:USERPROFILE '.wslconfig') -Force
wsl --shutdown
Start-Sleep -Seconds 3

Write-Host '==> Handing off to in-distro post-install'
$dotfilesHost = Join-Path $env:USERPROFILE 'dev\dotfiles'
wsl -d $DistroName -- $User -- bash -lc "cd ~ && \
  if [ ! -d dotfiles ]; then git clone https://github.com/thallystorres/dotfiles.git dotfiles; fi && \
  cd dotfiles && \
  sudo bash wsl/post-install.sh --user $User"

Write-Host '==> Done. Open a WSL terminal and run `fastfetch` to verify.'