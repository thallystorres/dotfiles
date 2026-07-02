# cursor/windows-profile.ps1
# Apply the repo's Cursor config onto the Windows host.
# Links settings.json + keybindings.json into %APPDATA%\Cursor\User and
# installs every extension listed in cursor/extensions.txt.
#
# Usage (from repo root):  powershell -ExecutionPolicy Bypass -File cursor\windows-profile.ps1
#                        powershell -ExecutionPolicy Bypass -File cursor\windows-profile.ps1 -WhatIf
[CmdletBinding()]
param([switch]$WhatIf)

$ErrorActionPreference = 'Stop'
$here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$cursorDir = Join-Path $env:APPDATA 'Cursor\User'

if (-not (Test-Path $cursorDir)) {
    Write-Host "Cursor User dir not found ($cursorDir)."
    Write-Host "Start Cursor once first, then re-run this script."
    exit 0
}

function Link-Config($name) {
    $src = Join-Path $here $name
    $dst = Join-Path $cursorDir $name
    if (-not (Test-Path $src)) { Write-Warning "missing $src"; return }
    if ($WhatIf) { Write-Host "WHATIF: link $src -> $dst"; return }
    if (Test-Path $dst) { Remove-Item $dst -Force -Recurse }
    # Symlink requires admin/dev mode on Windows; fall back to copy.
    try { New-Item -ItemType SymbolicLink -Path $dst -Target $src | Out-Null }
    catch { Copy-Item $src $dst -Force }
    Write-Host "applied $name"
}
Link-Config 'settings.json'
Link-Config 'keybindings.json'

$ext = Join-Path $here 'extensions.txt'
$cursorBin = (Get-Command cursor -ErrorAction SilentlyContinue)
if (-not $cursorBin) {
    Write-Host "cursor.exe not on PATH; skipping extension install."
    return
}
Get-Content $ext | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object {
    Write-Host "installing: $_"
    if (-not $WhatIf) { & cursor --install-extension $_ }
}