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

## Neovim

The Neovim package is a Lua configuration for Neovim 0.12. It uses Neovim's native `vim.pack`
manager and checks exact plugin revisions into `nvim/.config/nvim/nvim-pack-lock.json`. The current
audit found 50 active repositories and a warm headless startup mean of about 88 ms. It also found a
required nvim-treesitter branch migration and LSP mapping fixes; see the audit before changing or
updating those areas.

Detailed references:

- [Configuration audit](docs/audit.md)
- [Plugin inventory](docs/plugins.md)
- [Key mapping reference](docs/keymaps.md)
- [Prioritized recommendations and migration plan](docs/recommendations.md)

### Requirements and installation

Install Neovim 0.12, Git, a Nerd Font, `rg`, `fd`, and `sd`. Language features also need their
configured external tools: clangd/clang-format and lldb-dap for C/C++, plus the selected Python and
CMake language servers/formatters. `:checkhealth` and `:ConformInfo` report missing tools.

Deploy only the Neovim package with the existing platform wrapper:

```bash
./setup/stow.sh deploy --package nvim --dry-run
./setup/stow.sh deploy --package nvim
nvim
```

On Windows, preview and deploy it with:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Package nvim -WhatIf
pwsh -NoProfile -File .\setup\dotter.ps1 -Package nvim
```

The package layout mirrors the deployed path:

```text
nvim/.config/nvim/
├── init.lua                 startup sequence
├── nvim-pack-lock.json      exact plugin revisions
├── after/ftplugin/          filetype-local behavior
└── lua/
    ├── core/                paths, options, mappings, autocommands
    ├── plugins/             general plugin setup
    ├── lsp/                 completion, diagnostics, servers, LSP UI
    ├── dap/                 debugger adapters and UI
    └── colorscheme/         Kanagawa and Vague configuration
```

### Essential mappings

Space is the leader key. Use `<leader>pk` to search the effective mapping table.

| Task                                  | Mapping                                    |
| ------------------------------------- | ------------------------------------------ |
| Find files / text / buffers           | `<leader>pf` / `<leader>pg` / `<leader>pb` |
| Open Oil float / toggle Neo-tree      | `<leader>of` / `<leader>\|t`               |
| Format buffer or selection            | `<leader>cf`                               |
| Next / previous Git hunk              | `]c` / `[c`                                |
| Stage / reset Git hunk                | `<leader>gs` / `<leader>gr`                |
| LSP definition                        | `gd`                                       |
| Diagnostics                           | `]d` / `[d`                                |
| Floating / tab terminal               | `<leader>tf` / `<leader>tt`                |
| DAP breakpoint / continue / step over | `<leader>db` / `<leader>dc` / `<leader>dn` |

The current LSP attach layer interferes with Neovim 0.12's native `gr...`, `K`, `gra`, `gO`, and
`<C-w>d` mappings. The exact verified behavior and proposed correction are documented in
[keymaps.md](docs/keymaps.md).

### Plugin updates

Review native pack updates interactively:

```vim
:packupdate
```

Inspect the confirmation buffer, write it to apply selected changes, restart Neovim, and run
`:checkhealth`. Commit the resulting lockfile separately from unrelated configuration changes.
Tree-sitter parsers must be updated together with nvim-treesitter. The current frozen `master`
configuration must be migrated before normal plugin updates; follow
[recommendation N1](docs/recommendations.md#n1-migrate-nvim-treesitter-to-the-neovim-012-branch).

### Troubleshooting and validation

Run these inside Neovim:

```vim
:checkhealth
:checkhealth vim.pack
:checkhealth vim.lsp
:checkhealth dap
:ConformInfo
:messages
:verbose map <key>
```

After deployment, a noninteractive startup and timing check are reproducible with:

```bash
nvim --headless +qa
nvim --headless --startuptime nvim-startup.log +qa
tail -n 20 nvim-startup.log
```

If a mapping behaves differently from the reference, `:verbose map <key>` identifies the last script
that defined it. For a buffer-local mapping, run it in the affected LSP, Oil, Gitsigns, or plugin
buffer.

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
