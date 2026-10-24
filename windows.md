# Windows Setup

Windows uses Scoop for packages and Dotter for symbolic-link deployment. The `windows/` directory
contains their tracked configuration and is not a GNU Stow package.

## Bootstrap Scoop

Run the bootstrap from a non-elevated Windows PowerShell 5.1 session. PowerShell 7 is included in
the package list, so it is not required for the first run.

Choose one parent directory for all Scoop-managed data:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 -Root 'D:\Scoop'
```

The selected parent is split into three directories:

| Purpose                                            | Example path      |
| -------------------------------------------------- | ----------------- |
| Scoop, user apps, shims, persistence, and modules  | `D:\Scoop\User`   |
| Apps installed later with `scoop install --global` | `D:\Scoop\Global` |
| Download cache                                     | `D:\Scoop\Cache`  |

To use Scoop's standard locations instead, omit `-Root`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1
```

The script prints `%USERPROFILE%\scoop`, `%ProgramData%\scoop`, and `%USERPROFILE%\scoop\cache`,
then requires an explicit `y` or `yes`. Any other answer stops the setup. A non-interactive first
run must supply `-Root`.

Preview the selected paths and operations without downloading or changing anything:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 `
  -Root 'D:\Scoop' -WhatIf
```

The bootstrap does not migrate Scoop. When Scoop already exists, omit `-Root` to keep its current
paths or pass the same parent again. A different requested path stops with an error.

After setup completes, close the current terminal and open a new one so that every process sees the
updated environment.

## Package Bundle

`windows\scoop\Scoopfile.json` is the Windows equivalent of the repository's Brewfile. It is a
native Scoop import file that records buckets and desired packages without pinning versions. The
bootstrap imports it automatically; it can also be applied directly:

```powershell
scoop import .\windows\scoop\Scoopfile.json
```

Add or remove entries in the `apps` array to change the desired package list. Keep `Name`, `Source`,
and `Info` on each entry. WezTerm comes from the `versions` bucket as `wezterm-nightly`, and
`update_nightly` keeps nightly packages eligible for normal updates.

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

[Dotter](https://github.com/SuperCuber/dotter) provides the Windows equivalent of this repository's
GNU Stow workflow. PowerShell 7 and Dotter 0.13.5 or newer are required. The wrapper resolves the
repository from its own location, so commands work outside the repository and when its path contains
spaces.

`windows\dotter\global.toml` is the only source of file-to-target mappings:

| Package    | Destination                           |
| ---------- | ------------------------------------- |
| `git`      | `%USERPROFILE%\.gitconfig`            |
| `nvim`     | `%LOCALAPPDATA%\nvim`                 |
| `wezterm`  | `%USERPROFILE%\.config\wezterm`       |
| `atuin`    | `%USERPROFILE%\.atuin`                |
| `starship` | `%USERPROFILE%\.config\starship.toml` |
| `bat`      | `%APPDATA%\bat\config`                |
| `lazygit`  | `%LOCALAPPDATA%\lazygit\config.yml`   |

`windows\dotter\profiles\all.toml` is the default tracked profile. The optional `minimal` profile
contains `git`, `nvim`, and `starship`. Profiles contain package names only and are validated
against `global.toml` before Dotter runs.

Dotter recursively expands the current Neovim directory mapping into file symlinks. Generated files
such as `%LOCALAPPDATA%\nvim\nvim-pack-lock.json` and
`%LOCALAPPDATA%\nvim\lua\core\paths_override.lua` therefore remain outside the repository. Their
existing repository `.gitignore` entries remain as additional protection.

### Typical Workflow

Place the repository on the machine first. Clone it when Git is already available, or download and
extract the repository archive when bootstrapping a machine without Git. Then open a non-elevated
PowerShell session in its root and bootstrap Scoop:

```powershell
git clone git@github.com:acidx27x/dotfiles.git $HOME\dotfiles
Set-Location $HOME\dotfiles
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\setup\scoop.ps1 `
  -Root 'D:\Scoop'
```

Close that terminal when the bootstrap prompts you, open PowerShell 7, and preview the default
Windows profile before deploying it:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -WhatIf
pwsh -NoProfile -File .\setup\dotter.ps1
```

The plain command selects the `all` profile. Normal deploys add to the active selection without
removing unrelated packages:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Package git,nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Profile minimal
```

Selective removal and refresh preserve every unrelated active package:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -Package nvim
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Restow -Package nvim
```

Complete replacement and removal must be explicit:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Deploy -Profile minimal -Replace
pwsh -NoProfile -File .\setup\dotter.ps1 -Action Undeploy -All
```

`-Package` accepts comma-separated names and removes duplicates. Empty values and missing names
around commas are rejected. `-Package` and `-Profile` are mutually exclusive. Undeploy and restow
require an explicit package or profile; only `-Action Undeploy -All` removes the complete managed
selection. Add `-WhatIf` to any command for a read-only preview.

Run `pwsh -NoProfile -File .\setup\dotter.ps1 --help` for the complete option summary. Help exits
before checking Dotter, environment variables, or machine state.

Edits to linked configuration files take effect immediately. Rerun `Restow` when mappings or the
selected package contents change. Repeated deployments are idempotent.

### Active State and Reconciliation

Dotter uses one cache for the full deployed configuration, so the wrapper reconciles a complete
desired package set for every operation. Machine-local data is stored under
`%LOCALAPPDATA%\dotfiles\dotter`:

| Path                      | Purpose                                                           |
| ------------------------- | ----------------------------------------------------------------- |
| `active-packages.json`    | Versioned package selection, Bat ownership, and cache fingerprint |
| `cache.toml` and `cache\` | Shared Dotter cache and generated data                            |

The wrapper fingerprints the cache file and recursively stored cache data after each successful
operation. A later run stops if the cache no longer matches the saved fingerprint. A named mutex
also prevents two wrapper processes from reconciling the same machine state concurrently.

Each real operation runs Dotter's dry-run before applying changes and again afterward. State is
saved only when the second preview reports no remaining work. A failed preview, deployment, or
convergence check does not update active state. `-WhatIf` does not create persistent state, links,
cache data, or environment variables.

Do not edit the machine-local files to select packages; use the wrapper. They are deliberately
outside Git and must not be committed.

Edits to an already linked configuration file take effect through the symlink, so changing only its
contents does not require another deployment. Review those edits with `git diff` and commit them
from the repository as usual.

### Symlink Prerequisite

Run deployment from a non-elevated PowerShell session with Windows Developer Mode enabled, or with
equivalent permission to create symbolic links. `-WhatIf` returns before permission tests, so
preview works without Developer Mode or elevation. Before applying previewed link additions, a real
operation tests both file and directory symlink capability. Failures retain the original Windows
exception as the inner error for diagnosis. The wrapper never falls back to copying.

After the Scoop bootstrap has completed, close that terminal and open PowerShell 7 so `dotter` and
`pwsh` are on `PATH`. Preview the complete deployment first:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -WhatIf
```

Deploy after resolving any reported conflicts:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1
```

An existing unmanaged file, changed managed target, or unexpected symlink stops reconciliation. Back
up or move the conflict manually. The wrapper does not expose Dotter's destructive `--force`
behavior and never adopts unrelated files.

### bat Configuration

Scoop sets `BAT_CONFIG_DIR` to its package directory and persists `bat`'s default configuration with
a hard link. When `bat` is selected and successfully deployed, the wrapper sets the user-scoped
`BAT_CONFIG_PATH` to `%APPDATA%\bat\config` if it is unset. It refuses to replace a different
existing value.

Removing `bat` removes `BAT_CONFIG_PATH` only when the wrapper recorded ownership and the value is
still the managed path. Selecting or removing unrelated packages never changes it.

Close the terminal and open a new one after deployment or undeployment so the environment change is
visible to new processes.

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

The deployed files are symbolic links, not filesystem read-only files. If an application rewrites a
linked configuration file, it changes the repository source and will appear in `git diff`.

The tracked Git configuration behavior is unchanged. For machine-local identity, use Git's normal
conditional includes or a separate untracked include file rather than editing deployment state.

### Regression Tests

Run the isolated Windows suite after changing the wrapper or Dotter mappings:

```powershell
pwsh -NoProfile -File .\setup\tests\dotter.Tests.ps1
```

The suite uses a unique temporary target path containing spaces. It covers malformed selections,
dry-run immutability, single and repeated deploys, duplicate names, profile validation, selective
removal, restow, replacement, conflict rejection, failed-state preservation, cache fingerprinting,
state validation, execution locking, orphaned-cache rejection, and explicit remove-all. It does not
change the normal Dotter state or `BAT_CONFIG_PATH`.

For release validation, also run the default profile preview in a non-Developer-Mode session,
exercise Bat deployment/removal on a disposable Windows user, and test a real clone whose repository
path contains spaces.

## Location Limits

The configured roots contain Scoop-managed application payloads, persistence, shims, cache, and
PowerShell modules. Windows integrations can still use Windows-owned locations. In particular,
`FiraCode-NF` copies fonts into `%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registers them for the
current user. Applications may also create Start Menu shortcuts or registry entries outside the
Scoop roots.

The bundle installs user-scoped packages. The global root is prepared for future elevated
`scoop install --global` commands but the bootstrap does not install anything globally.

## Codex Configuration Layers

Codex on Windows reads machine-wide defaults from `%ProgramData%\OpenAI\Codex\config.toml` before
the writable user config at `%USERPROFILE%\.codex\config.toml`. Install the repository's portable
base from an elevated PowerShell 7 session:

```powershell
pwsh -NoProfile -File .\setup\codex.ps1 -WhatIf
pwsh -NoProfile -File .\setup\codex.ps1
```

The script installs `codex-system/config.toml` into the machine-wide location. It is idempotent and
only updates an existing file carrying this repository's managed marker. It never reads, creates, or
changes the user config, where Codex can continue writing trusted projects, model migrations,
notices, and other machine-local settings.

Normal users can read the installed file but cannot modify it under the default `ProgramData`
permissions. Run the script elevated again after changing the tracked base. Do not use
`%USERPROFILE%\.codex\managed_config.toml`; current Codex versions use the `ProgramData` config for
Windows defaults. `requirements.toml` in the same directory is reserved for enforced policy, not
portable defaults.
