# Keymap reference

This is the complete mapping reference for the configuration in
[`lua/core/keymaps.lua`](../.config/nvim/lua/core/keymaps.lua) and the plugin/LSP modules. Press
Space to begin leader mappings. Keys shown in angle brackets are special keys; `N`, `S`, and `L` are
uppercase and require Shift.

Mappings registered after an event are labeled **buffer-local** or **lazy**. Plugin UI keys are
active only inside that plugin's buffer/window. MiniClue is configured to show descriptions for
leader, `g`, `<C-w>`, `[`, `]`, marks, registers, completion, and `z` sequences. Use `<Space>pk` to
pick keymaps or `:verbose map {keys}` to identify the active owner.

## Everyday keys

| Keys                                                  | Mode               | Action                                                        |
| ----------------------------------------------------- | ------------------ | ------------------------------------------------------------- |
| `<Space>pf` / `<Space>pg`                             | Normal             | Find files / live grep (fzf-lua)                              |
| `<Space>pb` / `<Space>pd`                             | Normal             | Pick buffers / diagnostics                                    |
| `<Space>pr` / `<Space>ph`                             | Normal             | Resume picker / search help                                   |
| `<Space>bd` / `<Space>bn` / `<Space>bp`               | Normal             | Delete / next / previous buffer                               |
| `<Space>bb` / `]b` / `[b`                             | Normal             | Alternate / next / previous buffer                            |
| `gd` / `gy` / `<C-s>dc` / `grr` / `gi`                | Normal, LSP buffer | Definition / type / declaration / references / implementation |
| `<C-s>h` / `<C-s>rn` / `<C-s>ca`                      | Normal, LSP buffer | Hover / rename / code action preview                          |
| `<Space>ha` / `<Space>ht` / `<Space>hn` / `<Space>hp` | Normal, lazy       | Harpoon add / menu / next / previous                          |
| `<Space>sv` / `<Space>sh`                             | Normal             | Open vertical / horizontal split                              |
| `<Space>sf` / `<Space>st`                             | Normal             | Toggle float/split / move window to a tab                     |
| `<Space>tw`                                           | Normal             | Trim trailing whitespace and final blank lines                |

## Core mappings

Source: [`lua/core/keymaps.lua`](../.config/nvim/lua/core/keymaps.lua). Core maps use
[`core.keymap`](../.config/nvim/lua/core/keymap.lua), which defaults to `silent = true` and attaches
`desc` labels; call options can override defaults.

| Keys                                     | Mode              | Action                                                   | Overrides / conflicts                                                                                |
| ---------------------------------------- | ----------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `<Space>`                                | Normal, Visual    | No-op leader prefix                                      | Reserves Space for leader sequences.                                                                 |
| `<Space>nh`                              | Normal            | Clear search highlight                                   | User map.                                                                                            |
| `<Space>vc`                              | Normal            | Toggle vertical cursor-column highlight                  | Applies to the current window.                                                                       |
| `n` / `N`                                | Normal            | Next / previous search match, centered                   | Overrides built-in search motion with centering.                                                     |
| `<C-d>` / `<C-u>`                        | Normal            | Half-page down / up, centered                            | Preserves motion and adds centering.                                                                 |
| `<Space>d`, `<Space>o`, `<Space>p`       | Normal, Visual    | No-op prefix guards                                      | Intentionally stop a bare prefix from falling through.                                               |
| `<Space>bd`                              | Normal            | `MiniBufremove.delete(0, false)`                         | Uses MiniBufremove; preserves layout.                                                                |
| `<Space>bn` / `<Space>bp`                | Normal            | Next / previous buffer                                   | User aliases for `:bnext`/`:bprevious`.                                                              |
| `<Space>bb`                              | Normal            | Switch to alternate buffer                               | Uses Neovim's `<C-^>` motion.                                                                        |
| `<Space>q` / `<Space>Q`                  | Normal            | Close current window / quit                              | `<Space>q` may fail if it is the last window; use `<Space>Q` to quit.                                |
| Selected Alt/Meta + `h/j/k/l`            | Normal            | Focus left / down / up / right window                    | One platform-selected modifier spelling.                                                             |
| `<Space>sv` / `<Space>sh`                | Normal            | Vertical / horizontal split                              | User mappings.                                                                                       |
| `<Space>st`                              | Normal            | Move the current split or float to a new tab             | Uses `<C-w>T` for a split; copies a sole window or float into a new tab and closes the source float. |
| `<Space>sf`                              | Normal            | Toggle the current window between float and split        | If it is the tab's sole normal window, opens a float for the same buffer and keeps the base window.  |
| `<Space>sH/J/K/L`                        | Normal            | Move current split to far left/bottom/top/right          | Uses Neovim's `<C-w>H/J/K/L` layout motions.                                                         |
| `<Space>sx` / `<Space>s=`                | Normal            | Exchange current split / equalize split sizes            | Uses `<C-w>x` / `<C-w>=`.                                                                            |
| Selected Alt/Meta + `<Up>` / `<Down>`    | Normal            | Increase / decrease window height by 2                   | One platform-selected modifier spelling.                                                             |
| Selected Alt/Meta + `<Right>` / `<Left>` | Normal            | Increase / decrease window width by 2                    | One platform-selected modifier spelling.                                                             |
| Selected Alt/Meta + `w/s/a/d`            | Normal            | Move focused floating window up/down/left/right          | Warns if current window is not floating.                                                             |
| `<Space>rc`                              | Normal            | Edit config `init.lua`                                   | User utility.                                                                                        |
| `<Space>fp`                              | Normal            | Copy current full file path to `+` register              | Requires a functioning clipboard provider.                                                           |
| `<Space>tt` / `<Space>tv` / `<Space>th`  | Normal            | Open terminal in tab / vertical split / horizontal split | User utilities.                                                                                      |
| `<Space>cd`                              | Normal            | Set window-local cwd to current buffer directory         | User utility; warns for invalid directory.                                                           |
| `<Space>fu`                              | Normal            | Convert buffer line endings to Unix                      | Removes trailing CR characters and sets `fileformat=unix`; save to write the file.                   |
| `<Space>fe`                              | Normal            | Pick Save/Reopen with Encoding, then an encoding         | Save writes the file; Reopen prompts before discarding unsaved edits.                                |
| `<Space>fl`                              | Normal            | Pick LF or CRLF and save the file                        | Normalizes mixed line endings before writing.                                                        |

The `alt_modifier` is chosen from `vim.uv.os_uname().sysname`: macOS gets `<M-...>`, other systems
get `<A-...>`. The config intentionally does not register both aliases because the user observed
different Alt/Meta behavior on macOS and Linux.

### Custom commands and command-line abbreviation

| Command / abbreviation          | Action                                        | Source             |
| ------------------------------- | --------------------------------------------- | ------------------ |
| `:BTab {buffer-number}`         | Open an existing buffer by ID in a new tab    | `core/keymaps.lua` |
| `:btab`                         | Command-line abbreviation for `:BTab`         | `core/keymaps.lua` |
| `:Cwd` / `:Twd` / `:Lwd`        | Print global / tab / window cwd               | `core/keymaps.lua` |
| `:CTags lang=... [exclude=...]` | Run configured Universal Ctags asynchronously | `core/keymaps.lua` |

## Bracket navigation

Source:
[`lua/plugins/mini-bracketed-config.lua`](../.config/nvim/lua/plugins/mini-bracketed-config.lua).
MiniBracketed loads eagerly. Lowercase suffixes go backward/forward; uppercase suffixes go to the
first/last target. Counts are supported, and navigation wraps by default.

| Previous / next | First / last | Mode                             | Target                                                |
| --------------- | ------------ | -------------------------------- | ----------------------------------------------------- |
| `[b` / `]b`     | `[B` / `]B`  | Normal                           | Listed buffer                                         |
| `[d` / `]d`     | `[D` / `]D`  | Normal, Visual, Operator-pending | Diagnostic                                            |
| `[q` / `]q`     | `[Q` / `]Q`  | Normal                           | Quickfix entry                                        |
| `[l` / `]l`     | `[L` / `]L`  | Normal                           | Location-list entry                                   |
| `[/` / `]/`     | —            | Normal, Visual, Operator-pending | Comment block                                         |
| `[x` / `]x`     | `[X` / `]X`  | Normal, Visual, Operator-pending | Merge-conflict marker                                 |
| `[f` / `]f`     | `[F` / `]F`  | Normal                           | File in the current file's directory                  |
| `[j` / `]j`     | `[J` / `]J`  | Normal, Visual, Operator-pending | Jumplist position within the current buffer           |
| `[m` / `]m`     | `[M` / `]M`  | Normal, Neovim 0.13+             | Extra multicursor                                     |
| `[o` / `]o`     | `[O` / `]O`  | Normal                           | Previously visited file                               |
| `[y` / `]y`     | `[Y` / `]Y`  | Normal                           | Yank-history entry replacing the latest pasted region |

Comment navigation recognizes linewise comments using `commentstring`. The `/` suffix replaces
native C-style comment motions and provides only previous/next mappings. Gitsigns keeps `[c` / `]c`;
`[e` / `]e` and `[w` / `]w` still filter diagnostics to errors and warnings. MiniBracketed's window,
Tree-sitter, indent, and undo targets are disabled, preserving native tag and include-search keys
and ordinary `u` / `<C-r>`. On Neovim 0.13+, `[m` / `]m` replace native method-navigation keys with
multicursor navigation. `<Space>bn` / `<Space>bp` remain buffer aliases.

Use `[y` / `]y` immediately after pasting to cycle the replacement text through yank history.

## Native multicursors (Neovim 0.13+)

| Keys         | Mode           | Action                                                                 |
| ------------ | -------------- | ---------------------------------------------------------------------- |
| `Q`          | Normal         | Toggle an extra cursor at the current position; disables follow mode   |
| `Q`          | Visual         | Add cursors on selected lines; enables follow mode                     |
| `q=`         | Normal         | Toggle follow mode so relative motions move every cursor               |
| `zq{motion}` | Normal, Visual | Place cursors at repeated motion targets; Visual mode limits the range |
| `<Space>mc`  | Normal         | Clear extra cursors in the current buffer                              |
| `gQ`         | Normal         | Restore the previous cursor session                                    |
| `[m` / `]m`  | Normal         | Previous / next extra cursor through MiniBracketed                     |
| `[M` / `]M`  | Normal         | First / last extra cursor through MiniBracketed                        |

`Q`, `q=`, `zq`, and `gQ` are native keys. `<Space>mc` is registered only on Neovim 0.13 or newer
and clears the native cursor namespace directly. It avoids the native `<C-l>` clear binding, which
MiniMove replaces with line/selection movement. `<Space>mf` still toggles MiniFiles. In 0.13, `Q`
replaces the older last-recorded-macro replay behavior; explicit `@{register}` remains available.

## LSP mappings

Registered buffer-locally in
[`lua/lsp/lsp-base-config.lua`](../.config/nvim/lua/lsp/lsp-base-config.lua) on LSP attach. Custom
readable keys are retained alongside Neovim's documented/default-style LSP mappings. This means
related operations can have more than one intentional spelling.

| Keys                                          | Mode           | Action                                                                    | Relationship                                                                    |
| --------------------------------------------- | -------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `gd`                                          | Normal         | Go to definition                                                          | Custom short alias; common built-in/Neovim LSP key.                             |
| `gy`                                          | Normal         | Go to type definition                                                     | Custom readable alias; `grt` is retained too.                                   |
| `gi`                                          | Normal         | Go to implementation                                                      | Custom short alias; `gri` retained too.                                         |
| `gpd` / `gpy` / `gpc` / `gpr` / `gpi`         | Normal         | Preview definition / type / declaration / references / implementation     | First use loads goto-preview and logger; buffer-local.                          |
| `gpq`                                         | Normal         | Close preview windows                                                     | Loads goto-preview on first use.                                                |
| `<C-s>h` / `<C-s>s`                           | Normal         | Hover / signature help                                                    | Human-readable LSP group.                                                       |
| `<C-s>rn`                                     | Normal         | Rename symbol                                                             | Human-readable LSP group; `grn` retained too.                                   |
| `<C-s>ic` / `<C-s>oc`                         | Normal         | Incoming / outgoing calls                                                 | Human-readable LSP group.                                                       |
| `<C-s>th`                                     | Normal         | Type hierarchy                                                            | Human-readable LSP group.                                                       |
| `<C-s>ca`                                     | Normal, Visual | Code action with preview picker                                           | fzf-lua built-in code-action diff preview; supports cursor and selected ranges. |
| `<C-s>ds` / `<C-s>dh` / `<C-s>dc` / `<C-s>cr` | Normal         | Document symbols / highlight / declaration / clear references             | Human-readable LSP group.                                                       |
| `<C-s>ws` / `<C-s>wd`                         | Normal         | Workspace symbols / diagnostics                                           | Human-readable LSP group.                                                       |
| `<C-s>l`                                      | Normal         | Toggle inlay hints for current buffer                                     | Passes `{ bufnr = 0 }`; its map description now reflects buffer scope.          |
| `<C-s>L`                                      | Normal         | Toggle inlay hints globally                                               | Calls `is_enabled()` / `enable()` without a buffer filter.                      |
| `<C-s>u` / `<C-s>U`                           | Normal         | Toggle symbol-usage display for current buffer / globally                 | First use loads symbol-usage plugin.                                            |
| `K`                                           | Normal         | Hover                                                                     | Reinstates Neovim's familiar LSP hover mapping.                                 |
| `gri` / `grn` / `grr` / `grt` / `gO`          | Normal         | Implementation / rename / references / type definition / document symbols | Neovim-style LSP map aliases deliberately retained.                             |
| `gra`                                         | Normal, Visual | Code action                                                               | Retained LSP-native spelling.                                                   |

Dynamic LSP maps are created when a server attaches, not at startup. `<C-s>l` toggles current-buffer
hints; `<C-s>L` toggles hints globally.

## Completion and snippets

Source: [`lua/lsp/blink-cmp-config.lua`](../.config/nvim/lua/lsp/blink-cmp-config.lua). Blink uses
Neovim's built-in snippet engine. Select a snippet from completion and accept it with `<C-y>`;
`<C-g>s` opens a completion menu containing only snippets.

| Keys                | Mode                           | Action                                                                                                                                      |
| ------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `<C-space>`         | Insert                         | Show completion; then show or hide documentation.                                                                                           |
| `<C-g>s`            | Insert                         | Show only snippets.                                                                                                                         |
| `<C-y>`             | Insert                         | Accept selected completion or snippet.                                                                                                      |
| `<C-s>`             | Insert                         | Show or hide Blink signature help.                                                                                                          |
| `<Tab>` / `<S-Tab>` | Insert                         | Jump to next / previous snippet placeholder. Outside snippets, Tab keeps its normal behavior and Shift-Tab accepts the selected completion. |
| `<C-n>` / `<C-p>`   | Insert, command line, terminal | Select next / previous completion without inserting a preview.                                                                              |

The command line uses command completions for `:` and `@`, and buffer text for `/` and `?` searches.
Insert-mode ghost text appears while typing and clears when the cursor moves without an edit.

## Diagnostics

Source:
[`lua/lsp/diagnostic-default-config.lua`](../.config/nvim/lua/lsp/diagnostic-default-config.lua).

| Keys        | Mode   | Action                                           | Overrides / conflicts                                    |
| ----------- | ------ | ------------------------------------------------ | -------------------------------------------------------- |
| `<Space>ed` | Normal | Toggle diagnostics globally                      | Custom diagnostic group.                                 |
| `<Space>et` | Normal | Toggle diagnostic virtual text for current line  | Custom diagnostic group.                                 |
| `<Space>el` | Normal | Toggle diagnostic virtual lines for current line | Custom diagnostic group.                                 |
| `<Space>eq` | Normal | Populate location list from diagnostics          | Custom diagnostic group.                                 |
| `<C-w>d`    | Normal | Open diagnostic float                            | Neovim's native mapping.                                 |
| `]d` / `[d` | Normal | Next / previous diagnostic                       | MiniBracketed; counts and first/last variants supported. |
| `]e` / `[e` | Normal | Next / previous error                            | Filters `vim.diagnostic.jump` to errors.                 |
| `]w` / `[w` | Normal | Next / previous warning                          | Filters `vim.diagnostic.jump` to warnings.               |

`<C-w>` and `]`/`[` are MiniClue triggers. The custom diagnostic keys use `<Space>e` so `<C-w>d`
remains a direct mapping.

## Mini.nvim mappings

These are plugin-native maps created by each module setup. Source modules are named in the plugin
inventory. MiniClue can display their descriptions where supplied.

| Keys                         | Mode                                            | Action                                          | Notes                                                                                                                                                   |
| ---------------------------- | ----------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gc`                         | Normal / Visual / Operator-pending              | Comment operator or selected lines; textobject  | `mini.comment`, using Neovim's standard comment key.                                                                                                    |
| `gcc`                        | Normal                                          | Comment current line                            | `mini.comment`, using Neovim's standard line-comment key.                                                                                               |
| `<C-h/j/k/l>`                | Normal / Visual                                 | Move line or selection left/down/up/right       | `mini.move`; intentionally replaces default Ctrl-window movement in Normal mode. Use `<C-w>h/j/k/l` for window navigation.                              |
| `S` / `J`                    | Normal                                          | Split / join current syntax-aware line          | `mini.splitjoin`; `toggle` mapping is disabled.                                                                                                         |
| `sa` / `sd` / `sr`           | Normal / Visual / Operator-pending as supported | Add / delete / replace surrounding              | `mini.surround`; `l` and `n` select previous/next target.                                                                                               |
| `sf` / `sF` / `sh`           | Normal                                          | Find right / left / highlight surrounding       | `mini.surround`.                                                                                                                                        |
| `<Space>xe/xx/xm/xr/xs`      | Normal / Visual                                 | Evaluate / exchange / multiply / replace / sort | `mini.operators`; each key starts with Space. Repeat the last key in Normal mode for a line, or follow with a motion. Sort compares case insensitively. |
| `(`, `[`, `{`, `)`, `]`, `}` | Insert                                          | Pair open/close behavior                        | `mini.pairs`; quotes `'`, `"`, and backtick are also customized for close-open behavior.                                                                |

Use Visual Line mode with `<Space>xs` to sort selected lines. Other selection types use
`mini.operators`' normal splitting behavior. The custom prefixes preserve LSP `gr…` and native `gx`.

## Editing and jumping

| Keys                      | Mode                             | Action                                   |
| ------------------------- | -------------------------------- | ---------------------------------------- |
| `<Space>is` / `<Space>it` | Normal, Visual                   | Convert indentation to spaces / tabs     |
| `<Space>fu`               | Visual                           | Remove trailing CR from selected lines   |
| `>` / `<`                 | Normal, Visual, Operator-pending | Leap forward / backward (two characters) |
| `f/F/t/T`                 | Normal, Visual, Operator-pending | Leap one-character find / till motions   |
| `;` / `,`                 | Normal, Visual, Operator-pending | Repeat / reverse last one-character find |

Indent conversion changes the current line or all lines touched by a Visual selection, including
Visual Block selections. It changes leading indentation only, then sets the buffer-local indentation
style for subsequent edits. `>` and `<` replace the built-in indent keys and use `f` / `b` to move
between Leap matches after a search; `s…` remains available for `mini.surround`. Leap's `f/F/t/T`
search one character within the visible window; `t/T` land beside the match. `;` repeats the last
one-character search in the same direction, and `,` searches in the opposite direction, even after a
`>`/`<` jump. Repeats stop at the visible window edge. Two-character Leap searches require a target
label after the two characters, even for a single match, because automatic jumping is disabled. Leap
dims the search area using the Kanagawa `Comment` highlight.

Visual `<Space>fu` only affects lines containing a literal trailing CR. Files read with DOS format
have a buffer-wide `fileformat` setting, so use Normal `<Space>fu` to convert those files.

`<Space>fe` uses `vim.ui.select`, which this config displays through fzf-lua. The encoding picker
offers UTF-8, UTF-8 with BOM, US-ASCII, Latin-1, Windows-1251, and an input for other encoding
names. Reopen reads the file again using the selected encoding. If the buffer has unsaved changes,
choose Save, Discard, or Cancel before reopening. `<Space>fl` changes the whole file's line endings
and writes it.

MiniTrailspace's `<Space>tw` is listed under feature mappings below. Most other Mini modules retain
their normal built-in mappings unless explicitly listed above.

## fzf-lua mappings

Defined globally in `lua/plugins/fzf-lua-config.lua`; fzf-lua is eagerly configured and overrides
`vim.ui.select`.

| Keys                                                      | Picker action                                                           |
| --------------------------------------------------------- | ----------------------------------------------------------------------- |
| `<Space>pr` / `<Space>pf` / `<Space>pg`                   | Resume / files / live grep                                              |
| `<Space>pb` / `<Space>pd` / `<Space>ps`                   | Buffers / workspace diagnostics / command history                       |
| `<Space>pp` / `<Space>pk` / `<Space>p"` / `<Space>ph`     | Project TODO markers / keymaps / registers / help                       |
| `<Space>plc` / `<Space>pld` / `<Space>pls`                | LSP declarations / definitions / document symbols                       |
| `<Space>pli` / `<Space>plr` / `<Space>plt` / `<Space>plS` | LSP implementations / references / type definitions / workspace symbols |

`<Space>pp` uses fzf-lua's grep picker to find standalone uppercase `TODO`, `FIXME`, `ERROR`,
`HACK`, `WARN`, `NOTE`, `HINT`, and `INFO` markers in saved files below the invocation's
window-local cwd. Colons are optional, and embedded names such as `TODO_WORD` do not match. Hidden
files are included, ignore files are respected, and `.git` is excluded. Unsaved and unnamed buffers
are excluded. Preview and Enter use fzf-lua's standard file navigation. This search has a fixed
ripgrep regex and is independent of MiniHipatterns highlighting. File and live grep pickers accept
`cwd` to search another directory. Both include hidden paths by default while respecting ignore
rules.

`<Space>pf` fuzzy-matches file paths. `<Space>pg` searches file contents with ripgrep patterns. Use
`:FzfLua grep_project` to fuzzy-filter project lines by their content; this scans every line first
and can be slower in large projects.

Inside an fzf-lua picker, `<F1>` shows the full key help. Common defaults are `<CR>` to open a
selection, `<Esc>` to close, `<F2>` for fullscreen, `<F3>` to wrap the preview, and `<F4>` to toggle
the preview. `<A-/>`, `<A-z>`, `<A-w>`, and `<A-p>` provide the same four actions without function
keys. The fzf prompt uses a nonblinking bar cursor, as do other Neovim terminal buffers. `<C-f>` /
`<C-b>` scroll the preview down / up by a page. File and grep pickers use `<A-h>` to toggle hidden
files, `<A-i>` to toggle ignore rules, and `<A-f>` to follow symlinks. File results can open in a
split with `<C-s>`, a vertical split with `<C-v>`, or a tab with `<C-t>`.

## Feature and lazy-loaded mappings

| Keys                                                  | Mode                      | Action                                                | Owner and loading                                                   |
| ----------------------------------------------------- | ------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------- |
| `<Space>nd`                                           | Normal, Visual            | Dismiss notifications                                 | MiniNotify; eager; LSP progress enabled.                            |
| `<Space>cf`                                           | Normal, Visual            | Format buffer or selection                            | Conform; available even when project format-on-save is disabled.    |
| `<Space>ast`                                          | Normal                    | Toggle auto-save                                      | Buffer UI group; also loads when the first file is read or created. |
| `<Space>ha` / `<Space>ht` / `<Space>hn` / `<Space>hp` | Normal                    | Harpoon add / menu / next / previous                  | Harpoon2 lazy group.                                                |
| `<C-s>` / `<C-h>` / `<C-t>`                           | Normal, Harpoon menu only | Open selected item vertically / horizontally / in tab | Buffer-local Harpoon UI maps.                                       |
| `<Space>np`                                           | Normal                    | Toggle centered layout                                | No-Neck-Pain lazy group.                                            |
| `<Space>sn`                                           | Normal                    | Open Snipe buffer menu                                | Snipe lazy group.                                                   |
| `<Space>S`                                            | Normal / Visual           | Toggle grug-far / prefill visual selection            | grug-far lazy group; ripgrep engine, ignore case.                   |
| `<Space>db` / `<Space>dB`                             | Normal                    | Toggle breakpoint / set conditional breakpoint        | DAP lazy group.                                                     |
| `<Space>dc` / `<Space>ds` / `<Space>dn` / `<Space>do` | Normal                    | Continue / step into / step over / step out           | DAP lazy group.                                                     |
| `<Space>dR` / `<Space>dt` / `<Space>d?`               | Normal                    | Restart / toggle REPL / evaluate expression           | DAP lazy group.                                                     |
| `<Space>tw`                                           | Normal                    | Trim trailing whitespace and final blank lines        | MiniTrailspace eager.                                               |
| `<Space>vw`                                           | Normal, Visual            | Toggle visible whitespace rendering                   | Visual Whitespace; loads on first file event or mapping use.        |
| `<Space>oT` / `<Space>of` / `<Space>ov` / `<Space>oh` | Normal                    | Open Oil in tab / float / vertical / horizontal split | Oil; eager.                                                         |

### Oil buffer mappings

Oil disables its default keymaps and uses the following mappings inside Oil buffers. They do not
override same keys in normal editing buffers.

| Keys                                       | Action                                                    |
| ------------------------------------------ | --------------------------------------------------------- |
| `<CR>` / `<C-s>` / `<C-h>` / `<C-t>`       | Open entry here / vertical split / horizontal split / tab |
| `<C-p>` / `<C-f>` / `<C-b>`                | Toggle preview / scroll preview down / up                 |
| `<Space>o?` / `<Space>or`                  | Help / refresh                                            |
| `<Space>ob` / `<Space>o-`                  | Open cwd / parent directory                               |
| `<Space>o.` / `<Space>o,`                  | Change cwd / window-local cwd                             |
| `<Space>ox` / `<Space>os`                  | Open external / change sort                               |
| `<Space>oth` / `<Space>ott` / `<Space>otc` | Toggle hidden / trash / detailed columns                  |

### Snipe buffer mappings

Inside the Snipe menu: `,` starts a tagged action; `,d`, `,v`, and `,h` close the selected buffer,
open it vertically, or horizontally. `<C-f>` / `<C-b>` page forward/back; `<CR>` selects; `<Esc>`
cancels; `D` closes; `<C-s>` / `<C-h>` open in vertical/horizontal splits. Hint characters come from
`sadflewcmpghio`; `.` disambiguates persistent tags.

## Buffer-local Git and Tree-sitter mappings

| Keys                        | Mode                       | Action                                           | Activation / conflict notes                                                          |
| --------------------------- | -------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------ |
| `]c` / `[c`                 | Normal, Git buffer         | Next / previous Git hunk                         | Gitsigns on attach; falls through to built-in diff motion when `vim.wo.diff`.        |
| `<Space>gs` / `<Space>gr`   | Normal, Visual, Git buffer | Stage / reset hunk                               | Buffer-local Gitsigns maps.                                                          |
| `<Space>gS` / `<Space>gR`   | Normal, Git buffer         | Stage / reset whole buffer                       | Gitsigns on attach.                                                                  |
| `<Space>gp` / `<Space>gi`   | Normal, Git buffer         | Preview hunk / inline preview                    | Gitsigns on attach.                                                                  |
| `<Space>gb` / `<Space>gB`   | Normal, Git buffer         | Blame current line with full info / blame buffer | Gitsigns on attach.                                                                  |
| `<Space>gd` / `<Space>gD`   | Normal, Git buffer         | Diff current buffer / diff against `~`           | Gitsigns on attach.                                                                  |
| `<Space>gq` / `<Space>gQ`   | Normal, Git buffer         | Add current buffer / all buffers to quickfix     | Gitsigns on attach.                                                                  |
| `<Space>gtw` / `<Space>gtb` | Normal, Git buffer         | Toggle word diff / current-line blame            | Gitsigns on attach.                                                                  |
| `gnn`                       | Normal                     | Start node selection                             | Native parent selection; counts supported; LSP fallback without a parser.            |
| `grn` / `grc` / `grm`       | Visual                     | Grow to parent / parent alias / shrink to child  | Native selection with counts and LSP fallback; Normal-mode `grn` remains LSP rename. |

## Explicit overrides and known ambiguities

- Search motions `n/N` and page motions `<C-d>/<C-u>` are intentional behavior-preserving overrides
  that add centering.
- `mini.comment` uses Neovim's standard `gc`/`gcc` comment keys; `gr{char}` keeps virtual
  replacement in LSP buffers. References use `grr`; declaration uses `<C-s>dc`.
- MiniMove intentionally claims `<C-h/j/k/l>` in Normal and Visual modes. This means Normal-mode
  `<C-w>` remains available for built-in window operations and is the recommended route.
- `<C-w>d` keeps Neovim's diagnostic float. The custom diagnostic actions use `<Space>e`.
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
map with the same `:verbose` command. `<Space>pk` exposes configured mappings through fzf-lua.

Notification history is available with `:lua MiniNotify.show_history()` or
`:lua vim.print(MiniNotify.get_all())`. `<Space>nd` clears active notifications while preserving
history. Built-in LSP-progress notifications use upstream formatting and completion expiry.
