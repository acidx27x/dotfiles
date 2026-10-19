# Windows Setup

Windows uses Scoop for packages. The Windows dotfile deployment tool will be handled separately;
the `windows/` directory is not a GNU Stow package.

## Bootstrap Scoop

Run the bootstrap from a non-elevated Windows PowerShell 5.1 session. PowerShell 7 is included in
the package list, so it is not required for the first run.

Choose one parent directory for all Scoop-managed data:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 -Root 'D:\Scoop'
```

The selected parent is split into three directories:

| Purpose | Example path |
|---|---|
| Scoop, user apps, shims, persistence, and modules | `D:\Scoop\User` |
| Apps installed later with `scoop install --global` | `D:\Scoop\Global` |
| Download cache | `D:\Scoop\Cache` |

To use Scoop's standard locations instead, omit `-Root`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1
```

The script prints `%USERPROFILE%\scoop`, `%ProgramData%\scoop`, and
`%USERPROFILE%\scoop\cache`, then requires an explicit `y` or `yes`. Any other answer stops the
setup. A non-interactive first run must supply `-Root`.

Preview the selected paths and operations without downloading or changing anything:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 `
  -Root 'D:\Scoop' -WhatIf
```

The bootstrap does not migrate Scoop. When Scoop already exists, omit `-Root` to keep its current
paths or pass the same parent again. A different requested path stops with an error.

After setup completes, close the current terminal and open a new one so that every process sees
the updated environment.

## Package Bundle

`windows\scoop\Scoopfile.json` is the Windows equivalent of the repository's Brewfile. It is a
native Scoop import file that records buckets and desired packages without pinning versions. The
bootstrap imports it automatically; it can also be applied directly:

```powershell
scoop import .\windows\scoop\Scoopfile.json
```

Add or remove entries in the `apps` array to change the desired package list. Keep `Name`,
`Source`, and `Info` on each entry. WezTerm comes from the `versions` bucket as
`wezterm-nightly`, and `update_nightly` keeps nightly packages eligible for normal updates.

To inspect the packages installed on a machine without overwriting the tracked list, export to a
temporary file and compare it manually:

```powershell
$generated = Join-Path $env:TEMP 'Scoopfile.generated.json'
scoop export --config | Set-Content -Encoding utf8 $generated
git diff --no-index .\windows\scoop\Scoopfile.json $generated
```

The generated export contains installed versions and update metadata. Treat it as a snapshot for
review, not as a direct replacement for the versionless tracked list.

## Location Limits

The configured roots contain Scoop-managed application payloads, persistence, shims, cache, and
PowerShell modules. Windows integrations can still use Windows-owned locations. In particular,
`FiraCode-NF` copies fonts into `%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registers them for the
current user. Applications may also create Start Menu shortcuts or registry entries outside the
Scoop roots.

The bundle installs user-scoped packages. The global root is prepared for future elevated
`scoop install --global` commands but the bootstrap does not install anything globally.
