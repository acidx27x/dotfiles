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

Each top-level directory is a Stow package.

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

