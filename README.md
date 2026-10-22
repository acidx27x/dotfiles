# Dotfiles

This repository keeps application configuration in package directories and deploys it with
symbolic links. Windows uses Dotter; Linux and macOS continue to use GNU Stow. Package layout is
authoritative, and application installation remains in the dedicated bootstrap scripts under
`setup/`.

| Platform | Deployment engine | Configuration |
|---|---|---|
| Windows | Dotter 0.13.5 or newer, PowerShell 7 | `windows/dotter/global.toml` |
| Linux and macOS | GNU Stow | package directories and `stow/` ignore rules |

## Windows Quick Start

Bootstrap applications as described in [windows.md](windows.md), then preview and deploy one or
more packages from any working directory:

```powershell
pwsh -NoProfile -File C:\path\to\dotfiles\setup\dotter.ps1 -Package nvim -WhatIf
pwsh -NoProfile -File C:\path\to\dotfiles\setup\dotter.ps1 -Package git,nvim
```

Deploy a profile, remove one package, refresh a package, replace the complete active selection,
or explicitly remove everything:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Profile windows
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Restow -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Profile minimal -Replace
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -All
```

A plain deploy selects the tracked `windows` profile for backward compatibility. Add `-WhatIf`
to any command for a read-only preview. See [windows.md](windows.md) for prerequisites, migration,
state behavior, and the regression test command.

## Linux and macOS TODO

The unified wrapper work is intentionally not implemented for Unix yet. Existing GNU Stow usage
and bootstrap scripts remain unchanged; see [stow.md](stow.md) for the current workflow.

Next implementation steps:

1. Restore GNU Stow's important built-in exclusions in `stow/.stow-global-ignore` while retaining
   `.DS_Store` and all package-local ignore rules.
2. Add `setup/stow.sh` with `deploy`, `undeploy`, and `restow`, package/profile selection,
   `--replace`, explicit `--all`, `--dry-run`, and mandatory preflight simulation.
3. Add validated package-name-only `common`, `linux`, and `macos` profiles under `stow/profiles/`.
4. Add isolated Linux and macOS conflict, idempotency, path-with-spaces, and dry-run tests.
5. Update `stow.md` after the wrapper exists, preserving `--no-folding` and the existing special
   setup scripts.
