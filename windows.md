# Windows Setup

Windows uses Scoop for packages and Dotter for symbolic-link deployment. The `windows/`
directory contains their tracked configuration and is not a GNU Stow package.

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

## Deploy Dotfiles

[Dotter](https://github.com/SuperCuber/dotter) provides the Windows equivalent of this
repository's GNU Stow workflow. Its tracked Windows profile maps the existing package directories
to native Windows destinations:

| Package | Destination |
|---|---|
| `git` | `%USERPROFILE%\.gitconfig` |
| `nvim` | `%LOCALAPPDATA%\nvim` |
| `wezterm` | `%USERPROFILE%\.config\wezterm` |
| `atuin` | `%USERPROFILE%\.atuin` |
| `starship` | `%USERPROFILE%\.config\starship.toml` |
| `bat` | `%APPDATA%\bat\config` |
| `lazygit` | `%LOCALAPPDATA%\lazygit\config.yml` |

The profile deploys Neovim as one directory symlink, like a folded GNU Stow package. Neovim can
therefore create `nvim-pack-lock.json` and `lua/core/paths_override.lua` inside the repository;
their existing `.gitignore` rules keep them untracked.

### Typical Workflow

Place the repository on the machine first. Clone it when Git is already available, or download
and extract the repository archive when bootstrapping a machine without Git. Then open a
non-elevated PowerShell session in its root and bootstrap Scoop:

```powershell
git clone git@github.com:acidx27x/dotfiles.git $HOME\dotfiles
Set-Location $HOME\dotfiles
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 `
  -Root 'D:\Scoop'
```

Close that terminal when the bootstrap prompts you, open PowerShell 7, return to the repository
root, and deploy the configuration:

```powershell
Set-Location $HOME\dotfiles
pwsh -NoProfile -File .\setup\dotter.ps1 -WhatIf
pwsh -NoProfile -File .\setup\dotter.ps1
```

Use `-WhatIf` whenever you want to inspect the proposed changes. On an already configured
machine, pull repository updates and run the same preview and deployment commands again. Rerun the
deployment when `windows\dotter\global.toml`, `windows\dotter\windows.toml`, or the set of managed
files changes.

Edits to an already linked configuration file take effect through the symlink, so changing only
its contents does not require another deployment. Review those edits with `git diff` and commit
them from the repository as usual.

### Symlink Prerequisite

Run deployment from a non-elevated PowerShell session with Windows Developer Mode enabled, or
with equivalent permission to create symbolic links. The setup tests file-symlink creation and
stops if it is unavailable. It never lets Dotter fall back to copied configuration files.

After the Scoop bootstrap has completed, close that terminal and open PowerShell 7 so `dotter` and
`pwsh` are on `PATH`. Preview the complete deployment first:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -WhatIf
```

Deploy after resolving any reported conflicts:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1
```

Every real deployment first repeats Dotter's dry-run. An existing file that is not the expected
link stops the operation before links are created. Back up or move the conflicting file manually;
the wrapper does not expose Dotter's destructive `--force` behavior or an adopt operation.

Preview and remove the managed links with:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -WhatIf
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy
```

Dotter's generated cache is machine-local under `%LOCALAPPDATA%\dotfiles\dotter`; it never writes
cache data into this repository.

### bat Configuration

Scoop sets `BAT_CONFIG_DIR` to its package directory and persists `bat`'s default configuration
with a hard link. The deployment therefore sets the user-scoped `BAT_CONFIG_PATH` to the linked
`%APPDATA%\bat\config` file. It refuses to replace a different existing value. Undeployment
removes the variable only when it still has the managed value.

Close the terminal and open a new one after deployment or undeployment so the environment change
is visible to new processes.

### PowerShell Shell Integration

The Dotter profile deploys the Atuin and Starship configuration, but it does not own your complete
PowerShell profile. Add these lines to the PowerShell 7 profile reported by `$PROFILE` if they are
not already present:

```powershell
atuin init powershell | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
```

The shared Starship configuration uses Bash for its custom Git provider and worktree modules on
Unix, and PowerShell 7 on Windows. No separate generated Starship configuration is required.

The deployed files are symbolic links, not filesystem read-only files. If an application rewrites
a linked configuration file, it changes the repository source and will appear in `git diff`.

## Location Limits

The configured roots contain Scoop-managed application payloads, persistence, shims, cache, and
PowerShell modules. Windows integrations can still use Windows-owned locations. In particular,
`FiraCode-NF` copies fonts into `%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registers them for the
current user. Applications may also create Start Menu shortcuts or registry entries outside the
Scoop roots.

The bundle installs user-scoped packages. The global root is prepared for future elevated
`scoop install --global` commands but the bootstrap does not install anything globally.
