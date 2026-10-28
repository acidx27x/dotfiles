# Neovim

This package deploys `.config/nvim` to Neovim's standard config directory. It targets Neovim 0.12 or
newer and uses built-in `vim.pack` for plugin installation, updates, and package registration.
Selected optional plugins load on first relevant event or mapping.

## Setup

From the dotfiles repository root:

```bash
./setup/stow.sh deploy --package nvim --dry-run
./setup/stow.sh deploy --package nvim
```

Then start Neovim. The first launch installs missing packages through `vim.pack`; review and confirm
the package prompt. First install and updates require Git and network access. See the
[plugin inventory](docs/plugins.md) for all packages and load groups.

## Find a mapping

The [keymap reference](docs/keymaps.md) is the complete searchable list, including LSP, buffer-local,
plugin UI, and lazy-loaded mappings. Space is the leader. Common mappings:

| Keys | Action |
| --- | --- |
| `<Space>pf` / `<Space>pg` | Find files / live grep with MiniPick |
| `<Space>pb` | Pick a buffer |
| `<Space>bd` / `<Space>bn` / `<Space>bp` | Delete / next / previous buffer |
| `<Space>bb` / `]b` / `[b` | Alternate / next / previous buffer |
| `<Space>sv` / `<Space>sh` | Vertical / horizontal split |
| `<Space>sf` / `<Space>st` | Toggle float/split / move window to a tab |
| `gd` / `gr` / `gi` / `gy` / `gc` | LSP definition / references / implementation / type / declaration |
| `<C-s>h` / `<C-s>rn` / `<C-s>ca` | LSP hover / rename / code action |
| `<Space>ha` / `<Space>ht` | Harpoon add / menu |
| `<Space>tf` | Toggle floating terminal |

MiniClue shows descriptions while typing prefixes. `<Space>pk` opens the configured keymap picker.
For practical examples of quickfix, terminal windows, splits, buffers, and other built-in Vim tools,
see the [workflow guide](docs/workflows.md).

## Layout

- `.config/nvim/init.lua` and `lua/core/`: startup, options, core mappings, and shared helpers.
- `lua/plugins/spec.lua`: centralized native package specs and lazy groups.
- `lua/plugins/` and `lua/lsp/`: plugin and language-server modules.
- Feature files with global mappings register those keys at startup and defer plugin setup until
  the first relevant event or keypress.
- `lua/dap/`: debugger setup; `after/ftplugin/`: filetype-specific settings.
- `nvim-pack-lock.json`: locked plugin revisions maintained by `vim.pack`.
- `docs/`: [workflows](docs/workflows.md), [review](docs/review.md), [plugins](docs/plugins.md),
  and [keymaps](docs/keymaps.md).

## Plugin management and validation

Use Neovim's native package commands; no external plugin manager is used:

```vim
:PackUpdate
:PackUpdate nvim-treesitter
:checkhealth
:messages
```

Useful command-line checks:

```bash
nvim --version
nvim --headless '+lua print(vim.inspect(vim.pack.get()))' +qa
nvim --startuptime /tmp/nvim-startup.log +qa
```

If startup fails, try `nvim --clean`, inspect `:messages`, and run `:checkhealth`. For a missing
lazy-loaded feature, inspect `:verbose nmap <keys>` and confirm its package is in
`nvim-pack-lock.json`.
