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
[plugin inventory](docs/plugins.md) for all 46 repositories (28 eager, 18 optional) and load groups.

The tracked `nvim-pack-lock.json` is deployed with this package. If an older, unlinked copy already
exists at `~/.config/nvim/nvim-pack-lock.json`, move it aside before restowing `nvim`. Stow can then
link the current lockfile. Otherwise `vim.pack` may reinstall plugins removed from the package list.

Install `tree-sitter-cli` 0.26.1 or newer through your system package manager before installing or
updating Tree-sitter parsers. Confirm it is available with `tree-sitter --version`. Install `fzf`
and `rg` for the picker mappings; fzf-lua uses them for its UI and live grep.

## Find a mapping

The [keymap reference](docs/keymaps.md) is the complete searchable list, including LSP,
buffer-local, plugin UI, and lazy-loaded mappings. Space is the leader. Common mappings:

| Keys                                    | Action                                                            |
| --------------------------------------- | ----------------------------------------------------------------- |
| `<Space>pf` / `<Space>pg`               | Find files / live grep with fzf-lua                               |
| `<Space>pb`                             | Pick a buffer                                                     |
| `<Space>bd` / `<Space>bn` / `<Space>bp` | Delete / next / previous buffer                                   |
| `<Space>bb` / `]b` / `[b`               | Alternate / next / previous buffer                                |
| `<Space>sv` / `<Space>sh`               | Vertical / horizontal split                                       |
| `<Space>sf` / `<Space>st`               | Toggle float/split / move window to a tab                         |
| `gd` / `grr` / `gi` / `gy` / `<C-s>dc`  | LSP definition / references / implementation / type / declaration |
| `<C-s>h` / `<C-s>rn` / `<C-s>ca`        | LSP hover / rename / code action                                  |
| `<Space>ha` / `<Space>ht`               | Harpoon add / menu                                                |
| `<Space>tt/tv/th`                       | Terminal in a tab / vertical split / horizontal split             |
| `]e` / `[e` / `]w` / `[w`               | Next / previous error or warning                                  |
| `<Space>is` / `<Space>it`               | Convert line or selected lines to spaces / tabs                   |
| `Kf` / `Kb`                             | Leap forward / backward (two-character target)                    |
| `f/F/t/T` then `;` / `,`                | One-character Leap motion; repeat / reverse it                    |
| `<Space>xe/xx/xm/xr/xs`                 | Evaluate / exchange / multiply / replace / sort text              |

`<Space>S` toggles grug-far; Visual `<Space>S` prefills the selected text. Its ripgrep engine
searches case insensitively from the invocation's cwd and honors the `rg` executable override.
`<C-s>ca` uses fzf-lua's built-in code-action diff preview. MiniNotify initializes before feature
modules, wraps messages within 80 columns, and enables built-in LSP progress with upstream defaults.
Use `<Space>nd` to dismiss notifications and `:lua MiniNotify.show_history()` to read history.

`<Space>pp` searches saved project files for standalone `TODO`, `FIXME`, `ERROR`, `HACK`, `WARN`,
`NOTE`, `HINT`, and `INFO` markers with fzf-lua and ripgrep. Hidden files are included while ignore
rules and `.git` exclusion apply. Unsaved and unnamed buffers are excluded. MiniHipatterns keeps its
in-buffer marker and hex-color highlighting. See the [workflow guide](docs/workflows.md).

MiniClue shows descriptions while typing prefixes. `<Space>pk` opens the configured keymap picker.
For practical examples of quickfix, terminal windows, splits, buffers, and other built-in Vim tools,
see the [workflow guide](docs/workflows.md).

## Layout

- `.config/nvim/init.lua` and `lua/core/`: startup, options, core mappings, and shared helpers.
- `lua/plugins/spec.lua`: centralized native package specs and lazy groups.
- `lua/plugins/` and `lua/lsp/`: plugin and language-server modules.
- Feature files with global mappings register those keys at startup and defer plugin setup until the
  first relevant event or keypress.
- `lua/dap/`: debugger setup; `after/ftplugin/`: filetype-specific settings.
- `nvim-pack-lock.json`: locked plugin revisions maintained by `vim.pack`.
- `docs/`: [workflows](docs/workflows.md), [review](docs/review.md), [plugins](docs/plugins.md), and
  [keymaps](docs/keymaps.md).

## Plugin management and validation

Use Neovim's native package API; no external plugin manager is used:

```vim
:lua vim.pack.update()
:lua vim.pack.update({"nvim-treesitter"})
:lua vim.pack.update({"blink.cmp"}, {target="lockfile"})
```

To remove a plugin, remove its specification and configuration, restart Neovim, then run
`:lua vim.pack.del({"plugin-name"})` with its exact managed name. This removes both its installed
directory and lockfile entry. Removing only the specification does not uninstall the package.

The package hook runs `:TSUpdate` after updating `nvim-treesitter`. You can also run these checks
and parser commands manually:

```vim
:TSInstallConfigured
:TSUpdate
:checkhealth
:messages
```

`:TSInstallConfigured` adds newly configured parsers, including CMake.

## Formatting

`<Space>cf` formats the current buffer or Visual selection. A manual save formats before writing by
default; writes from auto-save.nvim do not trigger formatting. C/C++ prefers clangd's formatter and
uses `clang-format` if clangd cannot format the buffer. Lua, CMake, and Python use `stylua`,
`gersemi`, and `ruff format` respectively; other filetypes can use LSP formatting.

To disable format-on-save for one project, create `.nvim.json` in its root. Settings are resolved
for each buffer, so they do not affect other open projects:

```json
{
  "formatting": {
    "format_on_save": false
  }
}
```

`format_on_save` defaults to `true`; disabling it leaves `<Space>cf` available. A filetype's
`formatters` list replaces the global list. Set `lsp_format` to a Conform mode such as `never`,
`fallback`, or `prefer` to control LSP use. Set `lsp_client` to an LSP name to restrict formatting
to that client. Define additional external formatters and executable paths in
`lua/plugins/conform-nvim-config.lua`; use `:ConformInfo` to inspect availability.

Useful command-line checks:

```bash
nvim --version
nvim --headless '+lua print(vim.inspect(vim.pack.get()))' +qa
nvim --startuptime /tmp/nvim-startup.log +qa
```

These checks use the live installation. `vim.pack` can update `nvim-pack-lock.json` during startup
when installed package directories differ from the spec; use a disposable XDG config/data copy for
an audit that must leave the tracked lockfile untouched. See the [dated review](docs/review.md).

External language servers, search tools, CodeLLDB, CTags, and parser build tools are checked when
their features are first used. Missing required tools stop that action with one error. Conform
checks formatter availability and can fall back to LSP formatting. Configure executable paths in
`lua/local_paths.lua` when a tool is outside `PATH`. A valid override takes priority; otherwise the
first executable candidate is used. For example, CTags tries `ctags-universal` then `ctags`. Blink,
fzf-lua, and Tree-sitter invoke fixed command names, so their checks use the names those plugins
call. Parser installation requires `curl`.

If startup fails, try `nvim --clean`, inspect `:messages`, and run `:checkhealth`. For a missing
lazy-loaded feature, inspect `:verbose nmap <keys>` and confirm its package is in
`nvim-pack-lock.json`.
