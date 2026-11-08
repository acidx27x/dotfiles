# Extra tools with mise

Homebrew installs mise and shared dependencies. The global tool list in
[config.toml](.config/mise/config.toml) installs pyroclear through Cargo and the original Pokémon
colorscripts through mise's HTTP backend on macOS and Linux.

Pyroclear follows `latest`. Pokémon uses a fixed upstream commit and archive checksum. Its Python
script, metadata, sprites, and command symlink all live inside mise's installation directory; it
does not run the upstream system installer. Both tools support normal mise uninstallation.

## Install on macOS or Linux

Run from the dotfiles repository. Homebrew's Brewfile includes mise and Python 3; install them
directly if Homebrew is already set up:

```sh
brew install mise python3
```

The Cargo backend also needs this repository's Rust setup, or an existing working Cargo toolchain:

```sh
./setup/rust.sh
```

Deploy the tool list, shell initialization, and pyroclear settings:

```sh
./setup/stow.sh deploy --package mise,bash,zsh,pyroclear --dry-run
./setup/stow.sh deploy --package mise,bash,zsh,pyroclear
mise trust "$HOME/.config/mise/config.toml"
mise install
```

Resolve any Stow conflicts before applying deployment; see [the Stow guide](../stow.md). The Linux
and macOS profiles also include mise and pyroclear. Configuration deployment and tool installation
are separate: Stow creates the links; `mise install` installs the declared tools. When running
inside another project, its mise configuration can add or override tools; run from this repository
for these bootstrap commands.

Open a new terminal to load the mise shims before the Pokémon startup module. Verify the paths and
commands:

```sh
type -a pyroclear pokemon-colorscripts
mise which pyroclear
mise which pokemon-colorscripts
mise exec -- pyroclear --help
mise exec -- pokemon-colorscripts -n pikachu
```

The resolved tools should live under mise's data directory, normally `~/.local/share/mise`. The
existing `pclear` alias and random Pokémon on terminal startup continue to use these command names.
Shell initialization skips mise when it is unavailable.

## Update tools

```sh
mise upgrade cargo:pyroclear
```

To update Pokémon, select a new upstream commit, download its archive, calculate its SHA-256
checksum, and update the version and checksum together in the tracked config. Then run
`mise install`. The HTTP backend cannot discover newer source commits automatically.

## Uninstall mise-managed tools

To remove all installed versions while keeping the declarations for later reinstallation:

```sh
mise uninstall --all cargo:pyroclear
mise uninstall --all http:pokemon-colorscripts
```

`mise install` can reinstall them afterward. To permanently remove their global declarations and
prune installations that no other tracked config needs:

```sh
mise unuse --global cargo:pyroclear
mise unuse --global http:pokemon-colorscripts
```

Review and commit the resulting changes to the tracked config. Other projects declaring a tool can
keep its installation in use. Mise removal does not remove your separately Stowed pyroclear settings
or unrelated tools. No custom uninstall task or plugin is needed.

See the official [HTTP backend](https://mise.jdx.dev/dev-tools/backends/http.html),
[Cargo backend](https://mise.jdx.dev/dev-tools/backends/cargo.html), and
[tool removal documentation](https://mise.jdx.dev/dev-tools/#remove-tools).
