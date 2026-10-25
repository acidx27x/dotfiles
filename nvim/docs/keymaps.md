# Keymap reference

This is the complete mapping reference for the configuration in
[`lua/core/keymaps.lua`](../.config/nvim/lua/core/keymaps.lua) and the plugin/LSP modules. Press
Space to begin leader mappings. Keys shown in angle brackets are special keys; `N`, `S`, and
`L` are uppercase and require Shift.

Mappings registered after an event are labeled **buffer-local** or **lazy**. Plugin UI keys are
active only inside that plugin's buffer/window. MiniClue is configured to show descriptions for
leader, `g`, `<C-w>`, `[`, `]`, marks, registers, completion, and `z` sequences. Use `<Space>pk` to
pick keymaps or `:verbose map {keys}` to identify the active owner.

## Everyday keys

| Keys | Mode | Action |
| --- | --- | --- |
| `<Space>pf` / `<Space>pg` | Normal | Find files / live grep (MiniPick) |
| `<Space>pb` / `<Space>pd` | Normal | Pick buffers / diagnostics |
| `<Space>pr` / `<Space>ph` | Normal | Resume picker / search help |
| `<Space>bd` / `<Space>bn` / `<Space>bp` | Normal | Delete / next / previous buffer |
| `<Space>bb` / `]b` / `[b` | Normal | Alternate / next / previous buffer |
| `gd` / `gy` / `gc` / `gr` / `gi` | Normal, LSP buffer | Definition / type / declaration / references / implementation |
| `<C-s>h` / `<C-s>rn` / `<C-s>ca` | Normal, LSP buffer | Hover / rename / code action preview |
| `<Space>ha` / `<Space>ht` / `<Space>hn` / `<Space>hp` | Normal, lazy | Harpoon add / menu / next / previous |
| `<Space>sv` / `<Space>sh` | Normal | Open vertical / horizontal split |
| `<Space>sf` / `<Space>st` | Normal | Toggle float/split / move window to a tab |
| `<Space>tf` | Normal, lazy | Toggle floating terminal |
| `<Space>tw` | Normal | Trim trailing whitespace and final blank lines |

## Core mappings

Source: [`lua/core/keymaps.lua`](../.config/nvim/lua/core/keymaps.lua). Core maps use
[`core.keymap`](../.config/nvim/lua/core/keymap.lua), which defaults to `silent = true` and attaches
`desc` labels; call options can override defaults.

| Keys | Mode | Action | Overrides / conflicts |
| --- | --- | --- | --- |
| `<Space>` | Normal, Visual | No-op leader prefix | Reserves Space for leader sequences. |
| `<Space>nh` | Normal | Clear search highlight | User map. |
| `n` / `N` | Normal | Next / previous search match, centered | Overrides built-in search motion with centering. |
| `<C-d>` / `<C-u>` | Normal | Half-page down / up, centered | Preserves motion and adds centering. |
| `<Space>d`, `<Space>o`, `<Space>p` | Normal, Visual | No-op prefix guards | Intentionally stop a bare prefix from falling through. |
| `<Space>bd` | Normal | `MiniBufremove.delete(0, false)` | Uses MiniBufremove; preserves layout. |
| `<Space>bn` / `<Space>bp` | Normal | Next / previous buffer | User aliases for `:bnext`/`:bprevious`. |
| `]b` / `[b` | Normal | Next / previous buffer | Bracket-style aliases for `:bnext`/`:bprevious`. |
| `<Space>bb` | Normal | Switch to alternate buffer | Uses Neovim's `<C-^>` motion. |
| `<Space>q` / `<Space>Q` | Normal | Close current window / quit | `<Space>q` may fail if it is the last window; use `<Space>Q` to quit. |
| `<A-h/j/k/l>` | Normal, non-macOS | Focus left / down / up / right window | Selected instead of Meta spelling on Linux/other OS. |
| `<M-h/j/k/l>` | Normal, macOS | Focus left / down / up / right window | Selected instead of Alt spelling on macOS. Terminal delivery needs local confirmation. |
| `<Space>sv` / `<Space>sh` | Normal | Vertical / horizontal split | User mappings. |
| `<Space>st` | Normal | Move the current split or float to a new tab | Uses `<C-w>T` for a split; copies a sole window or float into a new tab and closes the source float. |
| `<Space>sf` | Normal | Toggle the current window between float and split | If it is the tab's sole normal window, opens a float for the same buffer and keeps the base window. |
| `<Space>sH/J/K/L` | Normal | Move current split to far left/bottom/top/right | Uses Neovim's `<C-w>H/J/K/L` layout motions. |
| `<Space>sx` / `<Space>s=` | Normal | Exchange current split / equalize split sizes | Uses `<C-w>x` / `<C-w>=`. |
| Selected Alt/Meta + `<Up>` / `<Down>` | Normal | Increase / decrease window height by 2 | One platform-selected modifier spelling. |
| Selected Alt/Meta + `<Right>` / `<Left>` | Normal | Increase / decrease window width by 2 | One platform-selected modifier spelling. |
| Selected Alt/Meta + `w/s/a/d` | Normal | Move focused floating window up/down/left/right | Warns if current window is not floating. |
| `<Space>rc` | Normal | Edit config `init.lua` | User utility. |
| `<Space>fp` | Normal | Copy current full file path to `+` register | Requires a functioning clipboard provider. |
| `<Space>tt` / `<Space>tv` / `<Space>th` | Normal | Open terminal in tab / vertical split / horizontal split | User utilities. |
| `<Space>cd` | Normal | Set window-local cwd to current buffer directory | User utility; warns for invalid directory. |

The `alt_modifier` is chosen from `vim.uv.os_uname().sysname`: macOS gets `<M-...>`, other systems
get `<A-...>`. The config intentionally does not register both aliases because the user observed
different Alt/Meta behavior on macOS and Linux.

### Custom commands and command-line abbreviation

| Command / abbreviation | Action | Source |
| --- | --- | --- |
| `:BTab {buffer-number}` | Open a named buffer in a new tab | `core/keymaps.lua` |
| `:btab` | Command-line abbreviation for `:BTab` | `core/keymaps.lua` |
| `:Cwd` / `:Twd` / `:Lwd` | Print global / tab / window cwd | `core/keymaps.lua` |
| `:CTags lang=... [exclude=...]` | Run configured Universal Ctags asynchronously | `core/keymaps.lua` |

## LSP mappings

Registered buffer-locally in
[`lua/lsp/lsp-base-config.lua`](../.config/nvim/lua/lsp/lsp-base-config.lua) on LSP attach.
Custom readable keys are retained alongside Neovim's documented/default-style LSP mappings. This
means related operations can have more than one intentional spelling.

| Keys | Mode | Action | Relationship |
| --- | --- | --- | --- |
| `gd` | Normal | Go to definition | Custom short alias; common built-in/Neovim LSP key. |
| `gy` | Normal | Go to type definition | Custom readable alias; `grt` is retained too. |
| `gc` | Normal | Go to declaration | Custom readable alias. |
| `gr` | Normal | Show references | Custom short alias; distinct from `grr`. |
| `gi` | Normal | Go to implementation | Custom short alias; `gri` retained too. |
| `gpd` / `gpy` / `gpc` / `gpr` / `gpi` | Normal | Preview definition / type / declaration / references / implementation | First use loads goto-preview and logger; buffer-local. |
| `gpq` | Normal | Close preview windows | Loads goto-preview on first use. |
| `<C-s>h` / `<C-s>s` | Normal | Hover / signature help | Human-readable LSP group. |
| `<C-s>rn` | Normal | Rename symbol | Human-readable LSP group; `grn` retained too. |
| `<C-s>ic` / `<C-s>oc` | Normal | Incoming / outgoing calls | Human-readable LSP group. |
| `<C-s>th` | Normal | Type hierarchy | Human-readable LSP group. |
| `<C-s>ca` | Normal, Visual | Code action with preview picker | First use loads actions-preview; intentionally takes precedence over the normal LSP code-action mapping for this key. |
| `<C-s>ds` / `<C-s>dh` / `<C-s>cr` | Normal | Document symbols / highlight / clear references | Human-readable LSP group. |
| `<C-s>ws` / `<C-s>wd` | Normal | Workspace symbols / diagnostics | Human-readable LSP group. |
| `<C-s>l` | Normal | Toggle inlay hints for current buffer | Passes `{ bufnr = 0 }`; its map description now reflects buffer scope. |
| `<C-s>L` | Normal | Toggle inlay hints globally | Calls `is_enabled()` / `enable()` without a buffer filter. |
| `<C-s>u` / `<C-s>U` | Normal | Toggle symbol-usage display for current buffer / globally | First use loads symbol-usage plugin. |
| `K` | Normal | Hover | Reinstates Neovim's familiar LSP hover mapping. |
| `gri` / `grn` / `grr` / `grt` / `gO` | Normal | Implementation / rename / references / type definition / document symbols | Neovim-style LSP map aliases deliberately retained. |
| `gra` | Normal, Visual | Code action | Retained LSP-native spelling. |
| `<C-s>` | Insert | Signature help | Buffer-local; does not conflict with Normal `<C-s>{sequence}`. |

Dynamic LSP maps are created when a server attaches, not at startup. `<C-s>l` toggles current-buffer
hints; `<C-s>L` toggles hints globally.

## Completion and snippets

Source: [`lua/lsp/blink-cmp-config.lua`](../.config/nvim/lua/lsp/blink-cmp-config.lua).
Blink uses Neovim's built-in snippet engine. Select a snippet from completion and accept it with
`<C-y>`; `<C-g>s` opens a completion menu containing only snippets.

| Keys | Mode | Action |
| --- | --- | --- |
| `<C-space>` | Insert | Show completion; then show or hide documentation. |
| `<C-g>s` | Insert | Show only snippets. |
| `<C-y>` | Insert | Accept selected completion or snippet. |
| `<Tab>` / `<S-Tab>` | Insert | Jump to next / previous snippet placeholder. Outside snippets, Tab keeps its normal behavior and Shift-Tab accepts the selected completion. |
| `<C-n>` / `<C-p>` | Insert, command line, terminal | Select next / previous completion without inserting a preview. |

The command line uses command completions for `:` and `@`, and buffer text for `/` and `?` searches.
Insert-mode ghost text appears while typing and clears when the cursor moves without an edit.

## Diagnostics

Source: [`lua/lsp/diagnostic-default-config.lua`](../.config/nvim/lua/lsp/diagnostic-default-config.lua).

| Keys | Mode | Action | Overrides / conflicts |
| --- | --- | --- | --- |
| `<C-w>dt` | Normal | Toggle diagnostics globally | Extends the built-in `<C-w>` window prefix. |
| `<C-w>dft` | Normal | Toggle diagnostic virtual text for current line | Nested custom diagnostic prefix. |
| `<C-w>dfl` | Normal | Toggle diagnostic virtual lines for current line | Nested custom diagnostic prefix. |
| `<C-w>dl` | Normal | Populate location list from diagnostics | Custom diagnostic prefix. |
| `<C-w>do` | Normal | Open diagnostic float | Custom diagnostic prefix. |
| `<C-w>d` | Normal | Open diagnostic float | Preserves the intended native diagnostic key if available in this Neovim release; check effective mapping with `:verbose nmap <C-w>d`. |
| `]d` / `[d` | Normal | Next / previous diagnostic | Calls `vim.diagnostic.jump`; may replace version/plugin-provided diagnostic motions. |

`<C-w>` and `]`/`[` are MiniClue triggers. The shorter `<C-w>d` mapping is a prefix of the custom
`<C-w>d...` family; key sequence recognition should be tested in the actual terminal.

## Mini.nvim mappings

These are plugin-native maps created by each module setup. Source modules are named in the plugin
inventory. MiniClue can display their descriptions where supplied.

| Keys | Mode | Action | Notes |
| --- | --- | --- | --- |
| `<Space>cc` | Normal / Visual / Operator-pending | Comment operator or selected lines; textobject | `mini.comment`. |
| `<Space>ccl` | Normal | Comment current line | `mini.comment`. |
| `<C-h/j/k/l>` | Normal / Visual | Move line or selection left/down/up/right | `mini.move`; intentionally replaces default Ctrl-window movement in Normal mode. Use `<C-w>h/j/k/l` for window navigation. |
| `S` / `J` | Normal | Split / join current syntax-aware line | `mini.splitjoin`; `toggle` mapping is disabled. |
| `sa` / `sd` / `sr` | Normal / Visual / Operator-pending as supported | Add / delete / replace surrounding | `mini.surround`; `l` and `n` select previous/next target. |
| `sf` / `sF` / `sh` | Normal | Find right / left / highlight surrounding | `mini.surround`. |
| `(`, `[`, `{`, `)`, `]`, `}` | Insert | Pair open/close behavior | `mini.pairs`; quotes `'`, `"`, and backtick are also customized for close-open behavior. |

MiniTrailspace's `<Space>tw` is listed under feature mappings below. Most other Mini modules retain
their normal built-in mappings unless explicitly listed above.

## MiniPick mappings

Defined globally in `lua/plugins/mini-pick-config.lua`; MiniPick is eagerly configured and overrides
`vim.ui.select`.

| Keys | Picker action |
| --- | --- |
| `<Space>pr` / `<Space>pf` / `<Space>pg` | Resume / files / live grep |
| `<Space>pb` / `<Space>pd` / `<Space>ps` | Buffers / diagnostics / history |
| `<Space>pp` / `<Space>pk` / `<Space>p"` / `<Space>ph` | Hipatterns / keymaps / registers / help |
| `<Space>plc` / `<Space>pld` / `<Space>pls` | LSP declarations / definitions / document symbols |
| `<Space>pli` / `<Space>plr` / `<Space>plt` / `<Space>plS` | LSP implementations / references / type definitions / workspace symbols |

## Feature and lazy-loaded mappings

| Keys | Mode | Action | Owner and loading |
| --- | --- | --- | --- |
| `<Space>nd` | Normal, Visual | Dismiss notifications | nvim-notify; eager. |
| `<Space>cf` | Normal, Visual | Format buffer or selection | Conform; loads on first use. Autoformat-on-save is disabled. |
| `<Space>ast` | Normal | Toggle auto-save | Buffer UI group; also loads when the first file is read or created. |
| `<Space>tf` | Normal | Toggle floating terminal | Floaterm + Volt lazy group. In sidebar buffer: `q` toggles closed and `<Esc>` is a no-op. |
| `<Space>ha` / `<Space>ht` / `<Space>hn` / `<Space>hp` | Normal | Harpoon add / menu / next / previous | Harpoon2 lazy group. |
| `<C-s>` / `<C-h>` / `<C-t>` | Normal, Harpoon menu only | Open selected item vertically / horizontally / in tab | Buffer-local Harpoon UI maps. |
| `<Space>np` | Normal | Toggle centered layout | No-Neck-Pain lazy group. |
| `<Space>sn` | Normal | Open Snipe buffer menu | Snipe lazy group. |
| `<Space>S` | Normal / Visual | Toggle Spectre / search visual selection | Spectre lazy group. |
| `<Space>db` / `<Space>dB` | Normal | Toggle breakpoint / set conditional breakpoint | DAP lazy group. |
| `<Space>dc` / `<Space>ds` / `<Space>dn` / `<Space>do` | Normal | Continue / step into / step over / step out | DAP lazy group. |
| `<Space>dR` / `<Space>dt` / `<Space>d?` | Normal | Restart / toggle REPL / evaluate expression | DAP lazy group. |
| `<Space>tw` | Normal | Trim trailing whitespace and final blank lines | MiniTrailspace eager. |
| `<Space>vw` | Normal, Visual | Toggle visible whitespace rendering | Visual Whitespace; loads on first file event or mapping use. |
| `<Space>ot` / `<Space>of` / `<Space>ov` / `<Space>oh` | Normal | Open Oil in tab / float / vertical / horizontal split | Oil; eager. |

### Oil buffer mappings

Oil disables its default keymaps and uses the following mappings inside Oil buffers. They do not
override same keys in normal editing buffers.

| Keys | Action |
| --- | --- |
| `<CR>` / `<C-s>` / `<C-h>` / `<C-t>` | Open entry here / vertical split / horizontal split / tab |
| `<C-p>` / `<C-f>` / `<C-b>` | Toggle preview / scroll preview down / up |
| `<Space>o?` / `<Space>or` | Help / refresh |
| `<Space>ob` / `<Space>o-` | Open cwd / parent directory |
| `<Space>o.` / `<Space>o,` | Change cwd / window-local cwd |
| `<Space>ox` / `<Space>os` | Open external / change sort |
| `<Space>oth` / `<Space>ott` / `<Space>otc` | Toggle hidden / trash / detailed columns |

### Snipe buffer mappings

Inside the Snipe menu: `,` starts a tagged action; `,d`, `,v`, and `,h` close the selected buffer,
open it vertically, or horizontally. `<C-f>` / `<C-b>` page forward/back; `<CR>` selects;
`<Esc>` cancels; `D` closes; `<C-s>` / `<C-h>` open in vertical/horizontal splits. Hint characters
come from `sadflewcmpghio`; `.` disambiguates persistent tags.

## Buffer-local Git and Tree-sitter mappings

| Keys | Mode | Action | Activation / conflict notes |
| --- | --- | --- | --- |
| `]c` / `[c` | Normal, Git buffer | Next / previous Git hunk | Gitsigns on attach; falls through to built-in diff motion when `vim.wo.diff`. |
| `<Space>gs` / `<Space>gr` | Normal, Visual, Git buffer | Stage / reset hunk | Buffer-local Gitsigns maps. |
| `<Space>gS` / `<Space>gR` | Normal, Git buffer | Stage / reset whole buffer | Gitsigns on attach. |
| `<Space>gp` / `<Space>gi` | Normal, Git buffer | Preview hunk / inline preview | Gitsigns on attach. |
| `<Space>gb` / `<Space>gB` | Normal, Git buffer | Blame current line with full info / blame buffer | Gitsigns on attach. |
| `<Space>gd` / `<Space>gD` | Normal, Git buffer | Diff current buffer / diff against `~` | Gitsigns on attach. |
| `<Space>gq` / `<Space>gQ` | Normal, Git buffer | Add current buffer / all buffers to quickfix | Gitsigns on attach. |
| `<Space>gtw` / `<Space>gtb` | Normal, Git buffer | Toggle word diff / current-line blame | Gitsigns on attach. |
| `gnn` | Normal, configured Tree-sitter filetype | Start node selection | Tree-sitter maps created on configured filetype. |
| `grn` / `grc` / `grm` | Visual, configured Tree-sitter filetype | Grow node / grow scope / shrink node selection | `grn` also matches Neovim's Normal-mode LSP rename only by mode distinction; no same-mode collision. `grc` implementation currently grows to parent like `grn`. |

## Explicit overrides and known ambiguities

- Search motions `n/N` and page motions `<C-d>/<C-u>` are intentional behavior-preserving overrides
  that add centering.
- LSP aliases are intentionally duplicated by purpose, not by key: e.g. custom `gr` and retained
  native-style `grr` both mean references. The default LSP map overrides in source are explicit.
- MiniMove intentionally claims `<C-h/j/k/l>` in Normal and Visual modes. This means Normal-mode
  `<C-w>` remains available for built-in window operations and is the recommended route.
- `<C-w>d` is both a complete diagnostic-float mapping and the prefix of custom `<C-w>d...` maps.
  Test sequence handling in the target terminal; MiniClue's `<C-w>` trigger can explain descendants.
- `<C-s>ca` replaces the direct code-action behavior for that key with the preview picker. `gra`
  remains available for the direct Neovim code action.
- DAP mappings load the DAP group on first use and then run the requested action. The same mapping
  remains active afterward.
- `<C-s>l` toggles current-buffer hints and `<C-s>L` toggles them globally; descriptions distinguish
  those scopes.
- Plugin keys such as Oil `<C-h>` and Harpoon `<C-h>` exist only inside their respective plugin
  buffers, not globally.
- User reported Alt/Meta modifier differences across macOS and Linux. The configuration chooses one
  platform-specific spelling; do not reintroduce both aliases without retesting.

## Runtime verification

Global keymaps can be inspected with `:verbose nmap {keys}`, `:verbose vmap {keys}`, or
`:<mode>map {prefix}`. LSP, Gitsigns, and Tree-sitter mappings do not exist until their buffer
events occur. After attaching a server or opening a configured filetype, inspect the buffer-local
map with the same `:verbose` command. `<Space>pk` exposes configured mappings through MiniPick.
