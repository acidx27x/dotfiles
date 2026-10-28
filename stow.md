# Dotfiles with GNU Stow

This repository stores configuration files as GNU Stow packages and creates symbolic links in your
home directory. `setup/stow.sh` provides the supported package/profile interface while GNU Stow
remains the deployment engine and the package directory layout remains authoritative.

## Install GNU Stow

```bash
# Debian / Ubuntu
sudo apt install stow

# Arch Linux
sudo pacman -S stow

# macOS
brew install stow
```

## Example Repository Structure

Most top-level directories are Stow packages. Setup-only directories such as `codex-system/` are
exceptions.

```text
~/dotfiles/
├── git/
│   └── .gitconfig
├── zsh/
│   └── .zshrc
└── nvim/
    └── .config/
        └── nvim/
            └── init.lua
```

Files inside a package should use the same path they will have under your home directory.

For example:

```text
~/dotfiles/nvim/.config/nvim/init.lua
```

links to:

```text
~/.config/nvim/init.lua
```

## Deployment Wrapper

The wrapper detects Linux or macOS, resolves the repository from its own path, validates every
selection, targets `$HOME`, and passes `--no-folding` to Stow. It can be called from any working
directory, including when the repository path contains spaces.

Every operation first runs Stow with `--simulate`. If preflight reports a conflict, the apply step
does not run. `--dry-run` stops after the simulation and creates no links, state, or cache files.
The wrapper never passes `--adopt` or `--override`, and it isolates Stow from user `.stowrc` options
so those settings cannot weaken conflict handling.

### Deploy Packages

Deploy is additive: packages not named by the command remain linked.

```bash
./setup/stow.sh deploy --package nvim
./setup/stow.sh deploy --package git,nvim
./setup/stow.sh deploy --package git --package nvim
```

Add `--dry-run` to preview any command:

```bash
./setup/stow.sh deploy --package nvim --dry-run
```

### Keep Target Directories Real with `--no-folding`

By default, Stow may replace an entire target directory with one symlink to the package directory.
For example, it may make `~/.config/bash` a symlink to `~/dotfiles/bash/.config/bash`.

Use `--no-folding` when an application or local configuration needs to create untracked files beside
the linked files. Stow then keeps the target directories real and links their contents individually.
A `.gitignore` prevents files from being tracked, but does not prevent them from being created
inside the repository when their parent directory is a symlink.

The wrapper always enables `--no-folding`, including deploy, undeploy, restow, preflight, and
replacement operations. The direct Stow examples below are retained for migration and diagnosis.

The following packages need or benefit from `--no-folding`:

| Package     | Target directory      |
| ----------- | --------------------- |
| `codex`     | `~/.codex`            |
| `bash`      | `~/.config/bash`      |
| `zsh`       | `~/.config/zsh`       |
| `nvim`      | `~/.config/nvim`      |
| `brew`      | `~/.config/homebrew`  |
| `htop`      | `~/.config/htop`      |
| `atuin`     | `~/.atuin`            |
| `worktrunk` | `~/.config/worktrunk` |

- `codex`: Codex writes machine-local config, authentication, packages, logs, and other state. Use
  `setup/codex.sh`, which creates the directory and passes `--no-folding`.
- `bash` and `zsh`: `conf.local.d/` and local shell files are intentionally untracked.
- `nvim`: `lua/core/paths_override.lua` and `nvim-pack-lock.json` are machine-local.
- `brew`: Homebrew writes `trust.json` and `trust.json.lock`. Its Stow-local ignore prevents
  generated copies already in the package from being linked back into the target directory.
- `htop`: htop writes `htop_history`.
- `atuin`: Atuin keeps config, databases, keys, sessions, logs, and other state together.
- `worktrunk`: Worktrunk writes `approvals.toml` beside its user config.

For example:

```bash
stow --no-folding --target="$HOME" bash zsh nvim brew htop atuin worktrunk
```

To convert packages that are already stowed with folded directory links, preview and then restow
them:

```bash
stow --restow --simulate --verbose --no-folding --target="$HOME" \
  bash zsh nvim brew htop atuin worktrunk
stow --restow --verbose --no-folding --target="$HOME" \
  bash zsh nvim brew htop atuin worktrunk
```

Inspect the package directories before converting them. Any generated or machine-local files that
were already created through a folded directory link are physically inside the repository and remain
package contents until moved back to the real target directory.

It is safe to use `--no-folding` for every package. Doing so creates more individual symlinks, but
gives applications no opportunity to place generated or machine-local files inside the repository
through a folded directory symlink.

### Deploy Profiles

```bash
./setup/stow.sh deploy --profile common
```

Profiles under `stow/profiles/` contain package names only. `common` is the portable selection;
`linux` and `macos` are the complete platform defaults. A plain deploy chooses the current
platform's default profile:

```bash
./setup/stow.sh deploy
```

Use either `--package` or `--profile`, not both. `--package` may be repeated and accepts
comma-separated names; `--profile` selects exactly one profile. Duplicate package names are removed
before Stow runs. Profile contents are validated exactly like command-line package names.

### Remove or Refresh Packages

Undeploy removes only the selected package links and leaves unrelated packages in place. Complete
removal requires the explicit `--all` option.

```bash
./setup/stow.sh undeploy --package nvim
./setup/stow.sh undeploy --profile common
./setup/stow.sh undeploy --all
```

Restow removes and recreates only the selected package links. Use it after adding, moving, or
deleting files inside a package:

```bash
./setup/stow.sh restow --package nvim
```

### Replace the Complete Selection

`--replace` explicitly removes links belonging to every recognized Stow package and then deploys the
requested selection in one Stow transaction. It is valid only with `deploy`:

```bash
./setup/stow.sh deploy --profile linux --replace
```

Ordinary deploy, undeploy, and restow operations do not use an active-package database. Stow
determines link ownership from the package directories and target links.

### Package Validation

A selectable package must be an existing top-level directory and must not be one of the explicit
repository-only or platform exclusions: `.agents`, `.aws`, `.codex`, `.git`, `brave`,
`codex-system`, `setup`, `windows`, or `wsl`. Unknown packages and profiles fail before Stow runs.
Configuration packages omitted from a default profile, such as `ssh`, remain available through
`--package`.

Profile files accept one package name per line, plus blank lines and full-line comments:

```text
# Example profile
git
nvim
zsh
```

### Ignore Rules

The `stow` package deploys `stow/.stow-global-ignore` as `~/.stow-global-ignore`. It retains GNU
Stow's built-in exclusions for version-control metadata, package documentation, editor backups,
autosave files, and lock files, and adds `.DS_Store`. It also excludes `stow/profiles/`, which is
wrapper metadata rather than home-directory configuration. Known machine-local files beside managed
configuration, including Neovim's `nvim-pack-lock.json` and `paths_override.lua`, are also excluded.

A package's `.stow-local-ignore` continues to take precedence for that package, as defined by GNU
Stow. The existing `brew` and `wsl` local rules remain unchanged.

## Add Existing Dotfiles

Move existing configuration files into the appropriate package:

```bash
mkdir -p ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/
```

Then create the symlink:

```bash
./setup/stow.sh deploy --package zsh
```

For an application stored under `~/.config`:

```bash
mkdir -p ~/dotfiles/nvim/.config
mv ~/.config/nvim ~/dotfiles/nvim/.config/
./setup/stow.sh deploy --package nvim
```

## Resolve Conflicts

If a file already exists at the target location, back it up before running Stow:

```bash
mv ~/.zshrc ~/.zshrc.backup
./setup/stow.sh deploy --package zsh
```

The wrapper deliberately does not expose Stow's adoption or override features. It will not move an
unmanaged target into the repository or replace one. Inspect and resolve each conflict explicitly,
rerun with `--dry-run`, and then apply it.

## Set Up Homebrew

The Homebrew setup uses the official installer when `brew` is unavailable, ensures GNU Stow is
installed, restows the `brew` package with `--no-folding`, and installs the global Brewfile:

```bash
./setup/homebrew.sh --dry-run
./setup/homebrew.sh
```

The setup scripts are executable. On macOS, direct invocation uses Bash through the shebang; running
`bash ./setup/homebrew.sh` is equivalent.

The package is linked into `~/.config/homebrew`. Homebrew reads `brew.env` from that directory, and
`brew bundle --global --no-upgrade` installs missing dependencies from the repository-managed
`Brewfile` without upgrading everything already installed. The apply step may ask for `sudo` while
the official Homebrew installer creates its platform-default prefix.

## Set Up Rust

The Rust setup follows the paths exported by the Bash and Zsh configurations:

| Variable             | Path               |
| -------------------- | ------------------ |
| `RUST_HOME`          | `/opt/rust`        |
| `RUSTUP_HOME`        | `/opt/rust/rustup` |
| `CARGO_HOME`         | `/opt/rust/cargo`  |
| `CARGO_INSTALL_ROOT` | `/opt/rust`        |

Preview the setup, then install or update the stable toolchain with rustup's default profile:

```bash
./setup/rust.sh --dry-run
./setup/rust.sh
```

Direct invocation works on macOS; `bash ./setup/rust.sh` is equivalent.

The apply step may ask for `sudo` only when it needs to create `/opt/rust`; the directory is then
owned by the current user. Rustup is invoked with `--no-modify-path`, because the shell configs
already add `/opt/rust/bin` and `/opt/rust/cargo/bin` to `PATH`.

The script does not install extra versioned or nightly toolchains, targets, or Cargo binaries.
Declare those separately before treating them as portable bootstrap dependencies.

## Set Up Codex

Codex uses two separate configuration layers in this repository:

- `codex-system/config.toml` is the portable base installed at `/etc/codex/config.toml`.
- `codex/` contains files that are safe to Stow into `~/.codex`, including the `zed-acp` named
  profile.

On Windows, the same portable base is installed at `%ProgramData%\OpenAI\Codex\config.toml` with
`setup/codex.ps1`; see `windows.md` for the Windows workflow. The writable user config remains
`%USERPROFILE%\.codex\config.toml`.

Preview a clean setup, then apply it:

```bash
./setup/codex.sh --dry-run
./setup/codex.sh
```

The apply step may ask for `sudo` when `/etc/codex/config.toml` needs to be installed or updated. It
creates `~/.codex` as a real directory and uses Stow's `--no-folding` option so that the directory
itself does not become a repository symlink.

Keep machine-local settings in `~/.codex/config.toml`. That file is intentionally not tracked,
linked, created, read, or modified by the setup script. Examples of machine-local settings include
trusted projects, absolute workspace paths, and notices written by Codex.

Codex merges configuration in this order, from highest to lowest precedence:

1. Command-line options
2. Project configuration
3. A named profile selected with `--profile`
4. `~/.codex/config.toml`
5. `/etc/codex/config.toml`
6. Built-in defaults

Run the repository's workspace-oriented named profile explicitly with:

```bash
codex --profile zed-acp
```

Zed remains configured through its registry-managed `codex-acp` settings. Its `mode = "auto"` and
reasoning setting do not automatically select the `zed-acp` Codex CLI profile.

The script is for clean setup, not migration. It stops instead of replacing an existing `~/.codex`
symlink, an unrelated `/etc/codex/config.toml`, or conflicting Stow targets. Resolve those
conditions manually before running it again.

## Set Up on a New Computer

<!-- dprint-ignore -->
```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles

./setup/homebrew.sh
./setup/rust.sh

./setup/stow.sh deploy --dry-run
./setup/stow.sh deploy
```

Each successful bootstrap script prints a terminal-restart reminder. On a new computer, finish the
Stow commands first, then close the current terminal and open a new one once.

## Command Reference

| Command                                           | Purpose                             |
| ------------------------------------------------- | ----------------------------------- |
| `setup/stow.sh deploy --package <name>`           | Add one package                     |
| `setup/stow.sh deploy --package <a,b>`            | Add multiple packages               |
| `setup/stow.sh deploy --profile <name>`           | Add a profile                       |
| `setup/stow.sh undeploy --package <name>`         | Remove one package                  |
| `setup/stow.sh restow --package <name>`           | Refresh one package                 |
| `setup/stow.sh deploy --profile <name> --replace` | Replace the complete selection      |
| `setup/stow.sh undeploy --all`                    | Remove all recognized package links |
| `<command> --dry-run`                             | Preview without applying changes    |

## Regression Tests

Run the isolated Linux suite with GNU Stow and ripgrep installed:

```bash
./setup/tests/stow.Tests.sh
```

The suite uses a disposable home and repository path containing spaces. It covers malformed
selections, additive and repeated deployment, profiles and duplicate package names, selective
removal, restow, replacement, remove-all, ignore rules, conflicts, unsafe user `.stowrc` options,
and dry-run behavior.

Run syntax and integration checks separately on macOS because the test suite intentionally uses the
detected platform's default profile:

```bash
bash -n ./setup/stow.sh ./setup/tests/stow.Tests.sh
./setup/stow.sh deploy --profile macos --dry-run
```
