# Extracting Cursor config from another machine

Cursor stores its User config in a **VS Code-compatible** directory. The path
differs by OS:

| OS       | Cursor User dir                                                |
|----------|----------------------------------------------------------------|
| Windows  | `%APPDATA%\Cursor\User`  (`C:\Users\<you>\AppData\Roaming\Cursor\User`) |
| macOS    | `~/Library/Application Support/Cursor/User`                    |
| Linux    | `~/.config/Cursor/User`                                         |

The files you want to copy into this repo's `cursor/` directory are:

- `settings.json`        → overwrite `cursor/settings.json`
- `keybindings.json`     → overwrite `cursor/keybindings.json`

## Regenerating the extensions list

From the machine that has the real Cursor config, run:

```bash
cursor --list-extensions > extensions.txt
# then edit: remove the header line and anything you don't want in the repo.
```

On Windows PowerShell:

```powershell
cursor --list-extensions | Set-Content extensions.txt
```

Drop that `extensions.txt` onto `cursor/extensions.txt` (one extension id per
line; lines starting with `#` are ignored), then regenerate the installer so
the script and the list stay in lockstep:

```bash
bash scripts/gen-extension-installer.sh cursor
```

## Applying the repo config to a new Windows install

```powershell
powershell -ExecutionPolicy Bypass -File cursor\windows-profile.ps1
```

Place a `cursor` symlink/copy of the repo at a stable location; the profile
script links the two JSON files and installs every extension in `extensions.txt`.

## Why this is in the repo at all

Cursor config is VS Code-compatible, so the repo derives a working `cursor/`
from the existing `vscode/` config plus Cursor-specific keys (see
`cursor/settings.json` — the `cursor.*`, `telemetry.*`, and `update.*` blocks).
That gives you a sane default on a fresh machine **today**; the recipe above
lets you replace it with the real config from your other machine whenever
you're ready, without touching the rest of the dotfiles.