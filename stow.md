# Dotfiles with GNU Stow

This repository stores configuration files as GNU Stow packages and creates symbolic links in your home directory.

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

Most top-level directories are Stow packages. Setup-only directories such as `codex-system/` are exceptions.

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

## Basic Commands

Run these commands from the dotfiles directory:

```bash
cd ~/dotfiles
```

### Preview Changes

Shows what Stow will do without creating or removing links.

```bash
stow --simulate --verbose --target="$HOME" zsh git nvim
```

Short form:

```bash
stow -n -v -t "$HOME" zsh git nvim
```

### Create Symlinks

```bash
stow --verbose --target="$HOME" zsh git nvim
```

Short form:

```bash
stow -v -t "$HOME" zsh git nvim
```

### Keep Target Directories Real with `--no-folding`

By default, Stow may replace an entire target directory with one symlink to the package
directory. For example, it may make `~/.config/bash` a symlink to
`~/dotfiles/bash/.config/bash`.

Use `--no-folding` when an application or local configuration needs to create untracked files
beside the linked files. Stow then keeps the target directories real and links their contents
individually. A `.gitignore` prevents files from being tracked, but does not prevent them from
being created inside the repository when their parent directory is a symlink.

The following packages need or benefit from `--no-folding`:

| Package | Target directory |
|---|---|
| `codex` | `~/.codex` |
| `bash` | `~/.config/bash` |
| `zsh` | `~/.config/zsh` |
| `nvim` | `~/.config/nvim` |
| `brew` | `~/.config/homebrew` |
| `htop` | `~/.config/htop` |
| `atuin` (future layout) | `~/.atuin` |

- `codex`: Codex writes machine-local config, authentication, packages, logs, and other state.
  Use `setup/codex.sh`, which creates the directory and passes `--no-folding`.
- `bash` and `zsh`: `conf.local.d/` and local shell files are intentionally untracked.
- `nvim`: `lua/core/paths_override.lua` and `nvim-pack-lock.json` are machine-local.
- `brew`: Homebrew writes `trust.json` and `trust.json.lock`. Its Stow-local ignore prevents
  generated copies already in the package from being linked back into the target directory.
- `htop`: htop writes `htop_history`.
- `atuin`: newer layouts keep config, databases, keys, sessions, logs, and other state together.
  The current Atuin 18.22 layout in this repository still uses `~/.config/atuin` and stores
  data separately, so it does not require this yet.

For example:

```bash
stow --no-folding --target="$HOME" bash zsh nvim brew htop
```

To convert packages that are already stowed with folded directory links, preview and then
restow them:

```bash
stow --restow --simulate --verbose --no-folding --target="$HOME" bash zsh nvim brew htop
stow --restow --verbose --no-folding --target="$HOME" bash zsh nvim brew htop
```

Inspect the package directories before converting them. Any generated or machine-local files
that were already created through a folded directory link are physically inside the repository
and remain package contents until moved back to the real target directory.

It is safe to use `--no-folding` for every package. Doing so creates more individual symlinks,
but gives applications no opportunity to place generated or machine-local files inside the
repository through a folded directory symlink.

### Stow One Package

```bash
stow -t "$HOME" nvim
```

### Remove a Package's Symlinks

This removes the symlinks but keeps the files in the repository.

```bash
stow --delete --target="$HOME" nvim
```

Short form:

```bash
stow -D -t "$HOME" nvim
```

### Refresh a Package

Useful after adding, moving, or deleting files inside a package.

```bash
stow --restow --target="$HOME" nvim
```

Short form:

```bash
stow -R -t "$HOME" nvim
```

## Add Existing Dotfiles

Move existing configuration files into the appropriate package:

```bash
mkdir -p ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/
```

Then create the symlink:

```bash
cd ~/dotfiles
stow -t "$HOME" zsh
```

For an application stored under `~/.config`:

```bash
mkdir -p ~/dotfiles/nvim/.config
mv ~/.config/nvim ~/dotfiles/nvim/.config/
stow -t "$HOME" nvim
```

## Resolve Conflicts

If a file already exists at the target location, back it up before running Stow:

```bash
mv ~/.zshrc ~/.zshrc.backup
stow -t "$HOME" zsh
```

Stow also supports adoption:

```bash
stow --adopt -t "$HOME" zsh
```

`--adopt` moves conflicting files from the target into the Stow package. Use it carefully and inspect the changes afterward:

```bash
git diff
```

## Set Up Homebrew

The Homebrew setup uses the official installer when `brew` is unavailable, ensures GNU Stow is
installed, restows the `brew` package with `--no-folding`, and installs the global Brewfile:

```bash
./setup/homebrew.sh --dry-run
./setup/homebrew.sh
```

The setup scripts are executable. On macOS, direct invocation uses Bash through the shebang;
running `bash ./setup/homebrew.sh` is equivalent.

The package is linked into `~/.config/homebrew`. Homebrew reads `brew.env` from that directory,
and `brew bundle --global --no-upgrade` installs missing dependencies from the repository-managed
`Brewfile` without upgrading everything already installed. The apply step may ask for `sudo`
while the official Homebrew installer creates its platform-default prefix.

## Set Up Rust

The Rust setup follows the paths exported by the Bash and Zsh configurations:

| Variable | Path |
|---|---|
| `RUST_HOME` | `/opt/rust` |
| `RUSTUP_HOME` | `/opt/rust/rustup` |
| `CARGO_HOME` | `/opt/rust/cargo` |
| `CARGO_INSTALL_ROOT` | `/opt/rust` |

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
- `codex/` contains files that are safe to Stow into `~/.codex`, including the `zed-acp` named profile.

On Windows, the same portable base is installed at
`%ProgramData%\OpenAI\Codex\config.toml` with `setup/codex.ps1`; see `windows.md` for the Windows
workflow. The writable user config remains `%USERPROFILE%\.codex\config.toml`.

Preview a clean setup, then apply it:

```bash
./setup/codex.sh --dry-run
./setup/codex.sh
```

The apply step may ask for `sudo` when `/etc/codex/config.toml` needs to be installed or updated. It creates `~/.codex` as a real directory and uses Stow's `--no-folding` option so that the directory itself does not become a repository symlink.

Keep machine-local settings in `~/.codex/config.toml`. That file is intentionally not tracked, linked, created, read, or modified by the setup script. Examples of machine-local settings include trusted projects, absolute workspace paths, and notices written by Codex.

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

Zed remains configured through its registry-managed `codex-acp` settings. Its `mode = "auto"` and reasoning setting do not automatically select the `zed-acp` Codex CLI profile.

The script is for clean setup, not migration. It stops instead of replacing an existing `~/.codex` symlink, an unrelated `/etc/codex/config.toml`, or conflicting Stow targets. Resolve those conditions manually before running it again.

## Set Up on a New Computer

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles

./setup/homebrew.sh
./setup/rust.sh

stow -n -v -t "$HOME" zsh git nvim
stow -v -t "$HOME" zsh git nvim
```

Each successful bootstrap script prints a terminal-restart reminder. On a new computer, finish
the Stow commands first, then close the current terminal and open a new one once.

## Command Reference

| Command | Purpose |
|---|---|
| `stow -n -v -t "$HOME" <package>` | Preview changes |
| `stow -v -t "$HOME" <package>` | Create symlinks |
| `stow -D -t "$HOME" <package>` | Remove symlinks |
| `stow -R -t "$HOME" <package>` | Refresh symlinks |
| `stow --adopt -t "$HOME" <package>` | Move conflicting target files into the package |
| `stow --no-folding -t "$HOME" <package>` | Disable directory folding |
