# Plugin inventory

The inventory comes from [`lua/plugins/spec.lua`](../.config/nvim/lua/plugins/spec.lua) and
[`nvim-pack-lock.json`](../.config/nvim/nvim-pack-lock.json). It currently contains 49 repositories:
26 eager specs and 23 optional specs. “Eager” means registered with `vim.pack.add(eager)` at startup;
“optional” means registered with a no-op load callback, then activated with `:packadd` by a lazy
group. All revision IDs are in the lock file; branch/tag constraints are noted below.
See [the review](review.md) for the upstream revision check and migration notes.
Optional config files that own global mappings register them at startup; their setup runs when the
group is first loaded.

## Eager packages

| Plugin / repository | Purpose | Setup file | Dependencies / loading notes | Recommendation |
| --- | --- | --- | --- | --- |
| [blink.cmp](https://github.com/Saghen/blink.cmp) | Completion UI and LSP completion capabilities | `lua/lsp/blink-cmp-config.lua` | Eager; tracks `main` (v2); builds the native matcher on first startup and after revisions change; uses `blink.lib` and `lspkind.nvim`. | Keep; completion capabilities are shared with LSP setup. |
| [blink.lib](https://github.com/saghen/blink.lib) | Blink v2 runtime and build support | No separate setup module | Eager; loaded before `blink.cmp`. | Required by Blink v2. |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Ready-made snippets for Blink's built-in snippet source | No separate setup module | Eager data package; Blink loads its snippets automatically. | Keep for snippet completion. |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Colorscheme | `lua/colorscheme/kanagawa-nvim-config.lua` | Eager so the selected theme is available during startup. | Keep. |
| [matchparen.nvim](https://github.com/monkoose/matchparen.nvim) | Matching bracket highlighting | `lua/plugins/matchparen-nvim-config.lua` | Eager setup. | Keep if preferred over built-in match highlighting. |
| [mini.bufremove](https://github.com/nvim-mini/mini.bufremove) | Delete buffers without changing window layout | `lua/plugins/mini-bufremove-config.lua` | Eager; used by `<Space>bd`. | Keep. |
| [mini.clue](https://github.com/nvim-mini/mini.clue) | Key-sequence hints from map descriptions | `lua/plugins/mini-clue-config.lua` | Eager; configured triggers include leader, `g`, `<C-w>`, brackets, marks, registers, and `z`. Calls `ensure_buf_triggers()` after LSP, Gitsigns, and Tree-sitter buffer mappings. | Keep; improves mapping discovery. Follow the [upstream MiniClue guide](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-clue.md). |
| [mini.comment](https://github.com/nvim-mini/mini.comment) | Comment operator and line/visual commenting | `lua/plugins/mini-comment-config.lua` | Eager; mappings customized to `<Space>cc` and `<Space>ccl`. | Keep. |
| [mini.extra](https://github.com/nvim-mini/mini.extra) | Additional MiniPick sources | `lua/plugins/mini-pick-config.lua` | Eager with `mini.pick`; supplies extra pickers such as hipatterns and LSP. | Keep with MiniPick. |
| [mini.hipatterns](https://github.com/nvim-mini/mini.hipatterns) | Highlight patterns such as TODO markers | `lua/plugins/mini-hipatterns-config.lua` | Eager; also provides the configured picker source. | Keep. |
| [mini.icons](https://github.com/nvim-mini/mini.icons) | Icon provider for compatible plugins | `lua/plugins/icons-config.lua` | Eager setup; replaces `nvim-web-devicons`. | Keep. |
| [mini.move](https://github.com/nvim-mini/mini.move) | Move lines and visual selections | `lua/plugins/mini-move-config.lua` | Eager; maps Ctrl+h/j/k/l in Normal and Visual modes. | Keep; note mode-specific key shadowing in keymap reference. |
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | Insert-mode bracket and quote pairing | `lua/plugins/mini-pairs-config.lua` | Eager; customized quote/pair rules. | Keep. |
| [mini.pick](https://github.com/nvim-mini/mini.pick) | Fuzzy picker for files, buffers, grep, help, LSP, and more | `lua/plugins/mini-pick-config.lua` | Eager; overrides `vim.ui.select`; uses `mini.extra`; custom cwd-aware files/grep sources. | Keep upstream version. |
| [mini.splitjoin](https://github.com/nvim-mini/mini.splitjoin) | Split/join structured lines | `lua/plugins/mini-splitjoin-config.lua` | Eager; maps `S` to split and `J` to join. | Keep. |
| [mini.statusline](https://github.com/nvim-mini/mini.statusline) | Statusline | `lua/plugins/mini-statusline-config.lua` | Eager. | Keep. |
| [mini.surround](https://github.com/nvim-mini/mini.surround) | Add, delete, replace, find, and highlight surroundings | `lua/plugins/mini-surround-config.lua` | Eager; customized `sa/sd/sr/sf/sF/sh`. | Keep. |
| [mini.tabline](https://github.com/nvim-mini/mini.tabline) | Buffer tabline | `lua/plugins/mini-tabline-config.lua` | Eager. | Keep. |
| [mini.trailspace](https://github.com/nvim-mini/mini.trailspace) | Detect and trim trailing whitespace | `lua/plugins/mini-trailspace-config.lua` | Eager; `<Space>tw` trims trailing whitespace and final blank lines. | Keep; replaces the commented third-party plugin. |
| [multinput.nvim](https://github.com/r0nsha/multinput.nvim) | Enhanced `vim.ui.input` implementation | `lua/plugins/multinput-nvim-config.lua` | Eager because it overrides global input UI. | Keep if global input override remains desired. |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP server configurations | `lua/lsp/*.lua` | Eager with server configs; server executables are external dependencies. | Keep; track Neovim LSP API and upstream changes. |
| [nvim-navic](https://github.com/SmiteshP/nvim-navic) | LSP document breadcrumb context | `lua/lsp/nvim-navic-config.lua` | Eager; attached from LSP `on_attach`. | Keep if breadcrumb UI is used. |
| [nvim-notify](https://github.com/rcarriga/nvim-notify) | Notification UI and `vim.notify` replacement | `lua/plugins/nvim-notify-config.lua` | Eager because `vim.notify` is replaced globally. | Keep. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Parser installation and Tree-sitter features | `lua/plugins/nvim-treesitter-config.lua` | Eager setup; `main` branch; parsers installed on package change and highlighting starts for configured filetypes. | Keep; upstream API differs from legacy configs. |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | Filesystem buffer explorer | `lua/plugins/oil-nvim-config.lua` | Eager because it is the default file explorer and owns `Oil` command/maps. | Keep in place of Neo-tree. |
| [lspkind.nvim](https://github.com/onsails/lspkind.nvim) | Completion-kind icons/labels | `lua/lsp/blink-cmp-config.lua` | Eager alongside Blink. | Keep while Blink config depends on it. |

## Optional packages and loading triggers

| Plugin / repository | Purpose | Setup file | Group and trigger | Dependencies / recommendation |
| --- | --- | --- | --- | --- |
| [actions-preview.nvim](https://github.com/aznhe21/actions-preview.nvim) | Code-action preview picker | `lua/lsp/actions-preview-nvim-config.lua` | `lsp_actions`; first `<C-s>ca` on an attached LSP buffer | Keep; loads after preview mapping is invoked. |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | Conditional automatic saving | `lua/plugins/auto-save-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile`; `<Space>ast` is a lazy fallback trigger | Keep if autosave behavior is wanted. |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatter dispatch | `lua/plugins/conform-nvim-config.lua` | `conform`; `<Space>cf` | External formatters with LSP fallback; Conform excludes the neocmake and ruff LSP clients for CMake and Python. Autoformat is disabled. |
| [floaterm](https://github.com/nvzone/floaterm) | Floating terminal UI | `lua/plugins/floaterm-config.lua` | `floaterm`; `<Space>tf` | Depends on `volt`; plugin API stability was noted as a concern in source comments. |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git hunk signs and buffer actions | `lua/plugins/gitsigns-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile` | Git repository context required; buffer maps created on attach. |
| [goto-preview](https://github.com/rmagatti/goto-preview) | Floating LSP navigation previews | `lua/lsp/goto-preview-config.lua` | `lsp_preview`; `gp*` LSP mappings | Depends on `logger.nvim`; loaded on first preview mapping. |
| [harpoon](https://github.com/ThePrimeagen/harpoon) | Quick file list/navigation | `lua/plugins/harpoon-config.lua` | `harpoon`; `<Space>ha/ht/hn/hp` | Constrained to `harpoon2`; depends on `plenary.nvim`. |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indentation guides | `lua/plugins/indent-blankline-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile` | Keep if guides are useful. |
| [indent-rainbowline.nvim](https://github.com/TheGLander/indent-rainbowline.nvim) | Colorized indentation guides | `lua/plugins/indent-blankline-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile` | Shares indentation UI purpose with indent-blankline; check visual overlap after theme changes. |
| [logger.nvim](https://github.com/rmagatti/logger.nvim) | Logging dependency for goto-preview | No separate setup module | `lsp_preview`; loaded with goto-preview | Keep as required dependency. |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap) | Debug Adapter Protocol client | `lua/dap/nvim-dap-config.lua` | `dap`; `<Space>d...` | Depends on external adapter executable; CodeLLDB configuration is separate. |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | DAP panels and evaluation | `lua/dap/nvim-dap-ui-config.lua` | `dap`; `<Space>d?` and DAP setup | Depends on `nvim-nio` and `nvim-dap`. |
| [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) | Inline debugger values | `lua/dap/nvim-dap-virtual-text-config.lua` | `dap`; loaded with DAP group | Depends on `nvim-dap`. |
| [nvim-nio](https://github.com/nvim-neotest/nvim-nio) | Async support library | No separate setup module | `dap`; loaded with DAP UI group | Dependency of DAP UI. |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Common Lua utility library | No separate setup module | `harpoon` and `spectre` | Shared dependency for those groups. |
| [nvim-spectre](https://github.com/nvim-pack/nvim-spectre) | Search and replace UI | `lua/plugins/nvim-spectre-config.lua` | `spectre`; `<Space>S` | Depends on `plenary.nvim`; external `rg` and `sd` commands configured. |
| [smartcolumn.nvim](https://github.com/m4xshen/smartcolumn.nvim) | Contextual color column | `lua/plugins/smartcolumn-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile` | Keep if contextual column behavior is desired. |
| [snipe.nvim](https://github.com/leath-dub/snipe.nvim) | Fast buffer menu | `lua/plugins/snipe-nvim-config.lua` | `snipe`; `<Space>sn` | Keep if preferred over MiniPick buffer picker. |
| [symbol-usage.nvim](https://github.com/Wansmer/symbol-usage.nvim) | Inline LSP reference/usage counts | `lua/lsp/symbol-usage-nvim-config.lua` | `symbol_usage`; `<C-s>u/U` | Requires an attached LSP client; load on demand. |
| [visimatch.nvim](https://github.com/wurli/visimatch.nvim) | Highlight matching text in visual selection | `lua/plugins/visimatch-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile` | Pinned upstream revision may use deprecated `vim.validate`; compatibility needs retest. |
| [visual-whitespace.nvim](https://github.com/mcauley-penney/visual-whitespace.nvim) | Display whitespace markers | `lua/plugins/visual-whitespace-nvim-config.lua` | `buffer_ui`; first `BufReadPre` or `BufNewFile`; `<Space>vw` toggle | Keep if explicit whitespace visualization is useful. |
| [no-neck-pain.nvim](https://github.com/shortcuts/no-neck-pain.nvim) | Centered writing layout | `lua/plugins/no-neck-pain-nvim-config.lua` | `no_neck_pain`; `<Space>np` | Keep if centered layout is used. |
| [volt](https://github.com/nvzone/volt) | UI framework dependency | No separate setup module | `floaterm`; loaded with Floaterm | Required by Floaterm. |

## Dependencies and removals

Transitive relationships represented explicitly by groups include `volt` → Floaterm,
`plenary.nvim` → Harpoon and Spectre, `logger.nvim` → goto-preview, and `nvim-nio`/`nvim-dap` → DAP
UI. Blink uses `blink.lib`, `friendly-snippets`, and `lspkind.nvim`; MiniPick uses MiniExtra. External binaries include language servers,
formatters, ripgrep, sd, Tree-sitter CLI/parser downloads, and CodeLLDB.

Neo-tree and `nui.nvim`, Vague, `nvim-web-devicons`, Hardtime, the forked MiniPick package, the
commented trailing-whitespace plugin, and plain LLDB adapter configuration were removed. Oil,
Kanagawa, MiniIcons, upstream MiniPick/MiniTrailspace, CodeLLDB, and upstream Tree-sitter are the
current counterparts where applicable.

## Native package references

Neovim's [`vim.pack` help](https://neovim.io/doc/user/pack.html) describes the package manager and
`:PackUpdate` workflow. Evgeni Chasnovski's [vim.pack guide](https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack)
is an additional practical reference. `vim.pack` installs/updates packages and adds them to the
runtime path; the local lazy helper determines when optional groups are activated.
