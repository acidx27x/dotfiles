# Dotfiles

This repository keeps application configuration in package directories and deploys it with symbolic
links. Windows uses Dotter; Linux and macOS continue to use GNU Stow. Package layout is
authoritative, and application installation remains in the dedicated bootstrap scripts under
`setup/`.

| Platform        | Deployment engine                    | Configuration                                 |
| --------------- | ------------------------------------ | --------------------------------------------- |
| Windows         | Dotter 0.13.5 or newer, PowerShell 7 | `windows/dotter/global.toml`                  |
| Linux and macOS | GNU Stow                             | package directories and `stow/profiles/*.txt` |

## Formatting

[dprint](https://dprint.dev/) is the repository-wide formatter. Install its pinned plugins once,
then format or check one top-level package at a time so each package can be reviewed and committed
separately:

```bash
dprint install
dprint fmt bash
dprint check bash
```

PowerShell formatting also requires PowerShell 7 and PSScriptAnalyzer 1.25.0 or newer. Install the
module from PowerShell with `Install-PSResource PSScriptAnalyzer -Scope CurrentUser`. The `zed/` and
`ssh/` packages are temporarily excluded from dprint.

See [zed.md](zed.md) for syncing shared Zed preferences while keeping SSH and WSL connections local
to each machine.

## Linux and macOS Quick Start

Install GNU Stow, then use `setup/stow.sh` from any working directory. Package directories keep the
same layout they have under `$HOME`; the wrapper adds selection and safety checks without a second
file-to-destination mapping.

```bash
./setup/stow.sh deploy --package nvim --dry-run
./setup/stow.sh deploy --package git,nvim
./setup/stow.sh deploy --profile common
```

A plain `deploy` uses the `linux` or `macos` profile detected for the current platform. Deploy is
additive unless `--replace` is explicit. Removal is always selective unless `--all` is explicit:

```bash
./setup/stow.sh undeploy --package nvim
./setup/stow.sh restow --package nvim
./setup/stow.sh deploy --profile linux --replace
./setup/stow.sh undeploy --all
```

Every operation is simulated before it is applied, and `--dry-run` stops after that read-only
simulation. Application installation remains separate in scripts such as `setup/homebrew.sh`,
`setup/rust.sh`, and `setup/codex.sh`. See [stow.md](stow.md) for package validation, profiles,
conflict handling, and tests.

## Windows Quick Start

Bootstrap applications as described in [windows.md](windows.md), then preview and deploy one or more
packages from any working directory:

```powershell
pwsh -NoProfile -File C:\path\to\dotfiles\setup\dotter.ps1 -Package nvim -WhatIf
pwsh -NoProfile -File C:\path\to\dotfiles\setup\dotter.ps1 -Package git,nvim
```

Deploy a profile, remove one package, refresh a package, replace the complete active selection, or
explicitly remove everything:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Profile all
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Restow -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Profile minimal -Replace
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -All
```

A plain deploy selects the tracked `all` profile. Add `-WhatIf` to any command for a read-only
preview. See [windows.md](windows.md) for prerequisites, cache integrity behavior, and the
regression test command.
