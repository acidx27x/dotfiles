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

## Set Up Codex

Codex uses two separate configuration layers in this repository:

- `codex-system/etc/codex/config.toml` is the portable base installed at `/etc/codex/config.toml`.
- `codex/` contains files that are safe to Stow into `~/.codex`, including the `zed-acp` named profile.

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

stow -n -v -t "$HOME" zsh git nvim
stow -v -t "$HOME" zsh git nvim
```

## Command Reference

| Command | Purpose |
|---|---|
| `stow -n -v -t "$HOME" <package>` | Preview changes |
| `stow -v -t "$HOME" <package>` | Create symlinks |
| `stow -D -t "$HOME" <package>` | Remove symlinks |
| `stow -R -t "$HOME" <package>` | Refresh symlinks |
| `stow --adopt -t "$HOME" <package>` | Move conflicting target files into the package |
