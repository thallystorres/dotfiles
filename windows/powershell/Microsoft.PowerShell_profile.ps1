# windows/powershell/Microsoft.PowerShell_profile.ps1
# Minimal PowerShell profile for the Windows host. Aliases the same CLI tools
# scoop installs to match the Linux muscle memory from the dotfiles repo.
# Copy or symlink to: $PROFILE  (run `echo $PROFILE` in pwsh to find it).

# --- aliases mirroring the zsh aliases in zsh/config/aliases -----------------
function ll { eza -la --git @args }
function l  { eza @args }
function .. { Set-Location .. }
function ff { fastfetch @args }
function cat { batcat @args 2>$null; if (-not $?) { bat @args } }
function find { fd @args }
function ..2 { Set-Location ../.. }
function ..3 { Set-Location ../../.. }

# --- prompt ------------------------------------------------------------------
function Prompt {
    $dir = (Get-Location).Path.Replace($HOME, '~')
    $git = ''
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) { $git = "(`e[36m$branch`e[0m)" }
    }
    "`e[33m$dir`e[0m $git`n`e[32m❯`e[0m "
}

# --- integrate WSL if installed ---------------------------------------------
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    function fedora { wsl -d Fedora43 @args }
}