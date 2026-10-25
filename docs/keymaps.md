# Neovim key mapping audit

`<leader>` and `<localleader>` are both Space. Modes use `N` (Normal), `V` (Visual), `S` (Select),
`O` (operator-pending), `I` (Insert), `C` (command line), and `T` (terminal input).

This reference includes every active mapping explicitly defined by the configuration, configured
plugin mapping tables, generated mappings that materially replace defaults, and inactive mappings in
dormant modules. Related mappings with the same action are grouped in one row.

## Runtime verification

The audit compared `nvim_get_keymap()` under the full config with `nvim --clean`, then inspected
buffer maps after:

- manually applying the LSP attach mapping function;
- opening an Oil buffer;
- opening a tracked Lua file and waiting for Gitsigns;
- setting a scratch buffer to the C++ filetype.

Runtime checks confirmed the global mappings, all LSP buffer maps, all listed Oil maps, all listed
Gitsigns maps, and the C++ angle-pair maps. Harpoon, Snipe, Floaterm, DAP UI, Blink command-line and
terminal modes, and a real LSP server session were not opened interactively; their dynamic mappings
are documented from the exact setup tables.

## Confirmed conflicts and ambiguities

| Severity    | Mapping                                                 | Finding                                                                                                                                         | Intent assessment                                         | Recommendation                                                                     |
| ----------- | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Critical    | `K`, `gri`, `grn`, `grr`, `grt`, `gO`, `gra`, I `<C-s>` | LSP attach creates nonrecursive buffer-local self mappings. They suppress Neovim's global LSP defaults rather than restoring them.              | Accidental implementation of an intentional restore.      | Delete them or map directly to the relevant `vim.lsp.buf` functions.               |
| Critical    | `<C-w>d`                                                | A global nonrecursive self mapping suppresses Neovim 0.12's “diagnostics under cursor” mapping.                                                 | Accidental implementation of an intentional restore.      | Remove it; keep `<C-w>do` only if an extra alias is wanted.                        |
| Warning     | LSP `gc`                                                | Buffer-local declaration mapping shadows Neovim's built-in comment operator and `gcc` family.                                                   | Likely accidental after Neovim added built-in commenting. | Use `gD`, `<leader>ld`, or the native LSP family.                                  |
| Warning     | LSP `gr`                                                | Exact references mapping is a prefix of `gra/gri/grn/grr/grt/grx`; it motivated the broken self mappings and can wait up to `timeoutlen` (5 s). | Legacy layout.                                            | Use native `grr` and remove exact `gr`.                                            |
| Warning     | N/V `J`, `S`                                            | mini.splitjoin replaces join-lines (`J`) and substitute-line (`S`); Visual behavior is also replaced.                                           | Intentional, but high-impact.                             | Keep only if established muscle memory; leader alternatives are easier to recover. |
| Warning     | N/V `<C-h/j/k/l>`                                       | mini.move replaces core Ctrl motions; `<C-l>` no longer clears/redraws.                                                                         | Intentional.                                              | Consider Alt or leader move keys.                                                  |
| Warning     | `s...`                                                  | mini.surround uses `s` as a prefix, delaying/replacing native substitute behavior. `timeoutlen=5000` makes a partial prefix especially slow.    | Intentional plugin layout with an expensive timeout.      | Shorten `timeoutlen` and/or use a non-native prefix.                               |
| Warning     | `<A-x>` and `<M-x>`                                     | Neovim treats Alt and Meta spellings as aliases. The second mapping replaces the first, so all eight pairs are duplicates.                      | Accidental duplication.                                   | Keep one spelling.                                                                 |
| Warning     | `]d`, `[d`                                              | Custom diagnostic jumps replace Neovim 0.12 defaults with the same behavior.                                                                    | Intentional/redundant.                                    | Remove unless the custom descriptions are valuable.                                |
| Improvement | `<Space>`                                               | Replaces the native Space motion in Normal/Visual mode to support leader use.                                                                   | Intentional and conventional.                             | Keep.                                                                              |
| Improvement | `n`, `N`, `<C-d>`, `<C-u>`                              | Preserve native action but add centering.                                                                                                       | Intentional.                                              | Keep if centering is preferred.                                                    |

## Core mappings

Source: `nvim/.config/nvim/lua/core/keymaps.lua`.

| Key                                     | Mode    | Action                                                    | Default/ conflict                                     | Notes                                                                                                     |
| --------------------------------------- | ------- | --------------------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `<Space>`                               | N, V, S | No operation; leader prefix.                              | Overrides native Space motion.                        | Intentional.                                                                                              |
| `<leader>nh`                            | N       | Clear search highlight.                                   | Leader-only.                                          | Native `<C-l>` also clears highlighting before mini.move replaces it.                                     |
| `n` / `N`                               | N       | Next/previous search result, open folds, and center.      | Overrides native search keys with wrapped native RHS. | Intentional.                                                                                              |
| `<C-d>` / `<C-u>`                       | N       | Half-page down/up and center.                             | Overrides native scrolling with wrapped native RHS.   | Intentional.                                                                                              |
| `<leader>d` / `<leader>o` / `<leader>p` | N, V, S | No operation for the bare group prefix.                   | Leader-only; prefix of DAP/Oil/Pick groups.           | Discoverability guard.                                                                                    |
| `<leader>bd`                            | N       | `:bdelete`.                                               | Leader-only.                                          | Does not use installed mini.bufremove; may collapse layout.                                               |
| `<leader>bn` / `<leader>bp`             | N       | Next/previous buffer.                                     | Leader-only.                                          | Built-in alternatives `]b`/`[b` exist in 0.12.                                                            |
| `<leader>q` / `<leader>Q`               | N       | Close window / quit.                                      | Leader-only.                                          | The two actions are very similar and easy to confuse.                                                     |
| `<A-h>` / `<M-h>`                       | N       | Focus left window.                                        | Duplicate aliases; otherwise no core conflict.        | Same issue for j/k/l below.                                                                               |
| `<A-j>` / `<M-j>`                       | N       | Focus lower window.                                       | Duplicate aliases.                                    |                                                                                                           |
| `<A-k>` / `<M-k>`                       | N       | Focus upper window.                                       | Duplicate aliases.                                    |                                                                                                           |
| `<A-l>` / `<M-l>`                       | N       | Focus right window.                                       | Duplicate aliases.                                    |                                                                                                           |
| `<leader>sv` / `<leader>sh`             | N       | Vertical/horizontal split.                                | Leader-only.                                          | Mnemonics are consistent.                                                                                 |
| `<A-Up>` / `<M-Up>`                     | N       | Increase height by 2.                                     | Duplicate aliases.                                    |                                                                                                           |
| `<A-Down>` / `<M-Down>`                 | N       | Decrease height by 2.                                     | Duplicate aliases.                                    |                                                                                                           |
| `<A-Right>` / `<M-Right>`               | N       | Increase width by 2.                                      | Duplicate aliases.                                    |                                                                                                           |
| `<A-Left>` / `<M-Left>`                 | N       | Decrease width by 2.                                      | Duplicate aliases.                                    |                                                                                                           |
| `<A-w>` / `<M-w>`                       | N       | Move focused floating window up.                          | Duplicate aliases.                                    | Warns if current window is not floating; source has no `desc`.                                            |
| `<A-s>` / `<M-s>`                       | N       | Move focused floating window down.                        | Duplicate aliases.                                    | Source has no `desc`.                                                                                     |
| `<A-a>` / `<M-a>`                       | N       | Move focused floating window left.                        | Duplicate aliases.                                    | Source has no `desc`.                                                                                     |
| `<A-d>` / `<M-d>`                       | N       | Move focused floating window right.                       | Duplicate aliases.                                    | Source has no `desc`.                                                                                     |
| `<leader>rc`                            | N       | Edit `$XDG_CONFIG_HOME/nvim/init.lua`.                    | Leader-only.                                          | Works when the package is deployed to the standard config path.                                           |
| `<leader>fp`                            | N       | Copy full current path to `+` register.                   | Leader-only.                                          | Requires a working clipboard provider.                                                                    |
| `<leader>tt` / `tv` / `th`              | N       | Open terminal in tab / vertical split / horizontal split. | Leader-only.                                          | Consistent terminal group.                                                                                |
| `<leader>cd`                            | N       | Set window-local cwd to buffer directory.                 | Leader-only.                                          | Warning branch contains latent `path("'")` error.                                                         |
| command abbreviation `btab`             | C       | Expands to user command `BTab`.                           | Overrides lowercase command token in command line.    | Prefix abbreviations can also expand inside longer commands; use `cabbrev <expr>` if false matches occur. |

Commented mappings for delete-to-black-hole and visual reindent are not active and are excluded from
the active tables.

## General plugin mappings

| Key           | Mode/scope          | Action                                     | Source                                         | Default/ conflict and notes                                                          |
| ------------- | ------------------- | ------------------------------------------ | ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| `<leader>nd`  | N, V, S             | Dismiss nvim-notify notifications.         | `plugins/nvim-notify-config.lua:13`            | Leader-only.                                                                         |
| `<leader>cf`  | N, V, S             | Synchronous Conform formatting, never LSP. | `plugins/conform-nvim-config.lua:47`           | Leader-only. `desc` is an undefined global, so effective mapping has no description. |
| `<leader>ast` | N                   | Toggle auto-save.                          | `plugins/auto-save-nvim-config.lua:45`         | Leader-only.                                                                         |
| `<leader>np`  | N                   | Toggle No Neck Pain.                       | `plugins/no-neck-pain-nvim-config.lua:20`      | Leader-only.                                                                         |
| `<leader>vw`  | N, V, S             | Toggle visual whitespace.                  | `plugins/visual-whitespace-nvim-config.lua:20` | Leader-only.                                                                         |
| `<leader>S`   | N                   | Toggle Spectre.                            | `plugins/nvim-spectre-config.lua:21`           | Leader-only; uppercase mnemonic.                                                     |
| `<leader>S`   | V, S                | Open Spectre using selection.              | `plugins/nvim-spectre-config.lua:28`           | Buffer selection is intentional.                                                     |
| `<leader>tf`  | N                   | Toggle floating terminal.                  | `plugins/floaterm-config.lua:36`               | Complements core `tt/tv/th`.                                                         |
| `<Esc>`       | N, Floaterm sidebar | No operation.                              | `plugins/floaterm-config.lua:14`               | Overrides native Normal Escape locally.                                              |
| `q`           | N, Floaterm sidebar | Toggle/close Floaterm.                     | `plugins/floaterm-config.lua:20`               | Overrides macro recording locally. Intentional UI convention.                        |

### mini.comment

Source: `plugins/mini-comment-config.lua:11`. These replace mini.comment's usual `gc` defaults, so
Neovim's built-in `gc` remains available until an LSP attaches and shadows it.

| Key           | Mode | Action                | Default/ conflict                                   |
| ------------- | ---- | --------------------- | --------------------------------------------------- |
| `<leader>cc`  | N    | Comment operator.     | Leader-only.                                        |
| `<leader>cc`  | V, S | Comment selection.    | Leader-only.                                        |
| `<leader>cc`  | O    | Comment text object.  | Leader-only; same prefix has mode-specific meaning. |
| `<leader>ccl` | N    | Comment current line. | Leader-only.                                        |

### mini.move, mini.splitjoin, and mini.surround

| Key                  | Mode    | Action                                    | Source                                | Default/ conflict                                                      |
| -------------------- | ------- | ----------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| `<C-h>` / `<C-l>`    | N       | Move current line left/right.             | `plugins/mini-move-config.lua:14`     | Overrides native Ctrl motions; `<C-l>` normally redraws/clears search. |
| `<C-j>` / `<C-k>`    | N       | Move current line down/up.                | same                                  | Overrides native Ctrl motions.                                         |
| `<C-h>` / `<C-l>`    | V       | Move selection left/right.                | `plugins/mini-move-config.lua:8`      | Overrides Visual Ctrl motions.                                         |
| `<C-j>` / `<C-k>`    | V       | Move selection down/up.                   | same                                  | Overrides Visual Ctrl motions.                                         |
| `S` / `J`            | N       | Split / join argument structure.          | `plugins/mini-splitjoin-config.lua:6` | Replaces substitute-line / join-lines.                                 |
| `S` / `J`            | V       | Split / join selected structure.          | same                                  | Replaces Visual core actions.                                          |
| `sa`                 | N, V    | Add surrounding.                          | `plugins/mini-surround-config.lua:6`  | Uses native `s` prefix.                                                |
| `sd` / `sdl` / `sdn` | N       | Delete surrounding / previous / next.     | same                                  | Uses native `s` prefix.                                                |
| `sr` / `srl` / `srn` | N       | Replace surrounding / previous / next.    | same                                  | Uses native `s` prefix.                                                |
| `sf` / `sfl` / `sfn` | N, V, O | Find right surrounding / previous / next. | same                                  | Uses native `s` prefix.                                                |
| `sF` / `sFl` / `sFn` | N, V, O | Find left surrounding / previous / next.  | same                                  | Uses native `s` prefix.                                                |
| `sh` / `shl` / `shn` | N       | Highlight surrounding / previous / next.  | same                                  | `sh` can be confused with the split group `<leader>sh`.                |

### mini.pairs

Source: `plugins/mini-pairs-config.lua:8`; C++ additions are in `after/ftplugin/cpp.lua`.

| Key                | Mode/scope    | Action                                                        | Default/ conflict                                                                    |
| ------------------ | ------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `(`, `[`, `{`      | I             | Insert matching close delimiter when neighbor pattern allows. | Replaces literal insert for these keys.                                              |
| `)`, `]`, `}`      | I             | Skip/close matching delimiter when allowed.                   | Replaces literal insert.                                                             |
| `"`, `'`, backtick | I             | Close/open matching quote pair.                               | Replaces literal insert; single quote avoids alphabetic neighbors.                   |
| `<CR>`             | I             | mini.pairs newline handling.                                  | Plugin default generated by setup; replaces native newline handling.                 |
| `<BS>`             | I             | mini.pairs paired backspace.                                  | Plugin default generated by setup.                                                   |
| `<` / `>`          | I, C++ buffer | Open/close angle pair under custom neighbor rules.            | Buffer-local; can be ambiguous in comparisons and shift operators. Runtime verified. |

## Pickers and navigation plugins

### mini.pick

Source: `plugins/mini-pick-config.lua:40-77`.

| Key                   | Mode | Action                                 | Conflict/notes                                   |
| --------------------- | ---- | -------------------------------------- | ------------------------------------------------ |
| `<leader>pr`          | N    | Resume picker.                         | Leader-only.                                     |
| `<leader>pf`          | N    | Find files.                            | Leader-only; primary file finder.                |
| `<leader>pg`          | N    | Live grep.                             | Leader-only; requires `rg`.                      |
| `<leader>pb`          | N    | Buffers.                               | Overlaps Snipe/Harpoon conceptually, not by key. |
| `<leader>pd`          | N    | Diagnostics.                           | Leader-only.                                     |
| `<leader>ps`          | N    | History.                               | Leader-only.                                     |
| `<leader>pp`          | N    | Hipattern matches.                     | Leader-only.                                     |
| `<leader>pk`          | N    | Effective keymaps.                     | Useful discoverability entry point.              |
| `<leader>p"`          | N    | Registers.                             | Leader-only.                                     |
| `<leader>ph`          | N    | Help tags.                             | Leader-only.                                     |
| `<leader>plc` / `pld` | N    | LSP declaration / definition.          | Only useful with an attached server.             |
| `<leader>pls` / `pli` | N    | LSP document symbols / implementation. | Only useful with an attached server.             |
| `<leader>plr` / `plt` | N    | LSP references / type definition.      | Only useful with an attached server.             |
| `<leader>plS`         | N    | LSP workspace symbols.                 | Uppercase S distinguishes workspace.             |

### Neo-tree

Source: `plugins/neo-tree-config.lua:48-65`.

| Key                           | Mode | Action                                        | Conflict/notes                                           |
| ----------------------------- | ---- | --------------------------------------------- | -------------------------------------------------------- |
| `<leader>\|o` / `\|c` / `\|t` | N    | Open/focus left tree / close / toggle.        | Memorable visually but awkward on some keyboard layouts. |
| `<leader>\|rn`                | N    | Reveal current file in left tree.             | Leader-only.                                             |
| `<leader>\|rf`                | N    | Reveal current file in a float and force cwd. | Leader-only.                                             |

Neo-tree's plugin-default buffer-local tree mappings remain enabled. They are version-owned rather
than explicitly listed in this config; press `?` in a Neo-tree window for the effective reference.
No custom Neo-tree buffer key overrides were found.

### Oil

Global source: `plugins/oil-nvim-config.lua:172-175`. Buffer source:
`plugins/oil-nvim-config.lua:61-117`. `use_default_keymaps=false`, so the following buffer table is
the complete configured Oil mapping set.

| Key                           | Scope    | Action                                   | Default/ conflict and notes                          |
| ----------------------------- | -------- | ---------------------------------------- | ---------------------------------------------------- |
| `<leader>ot` / `of`           | Global N | Open Oil in tab / float.                 | Leader-only.                                         |
| `<leader>ov` / `oh`           | Global N | Open Oil in vertical / horizontal split. | Leader-only.                                         |
| `<leader>o?`                  | Oil N    | Show help.                               | Buffer-local.                                        |
| `<CR>`                        | Oil N    | Select entry.                            | Overrides native line motion locally; conventional.  |
| `<C-s>` / `<C-h>` / `<C-t>`   | Oil N    | Select in vertical / horizontal / tab.   | Buffer-local; `<C-h>` does not navigate to parent.   |
| `<C-p>`                       | Oil N    | Toggle preview.                          | Overrides native previous completion locally.        |
| `<C-f>` / `<C-b>`             | Oil N    | Scroll preview down/up.                  | Descriptions incorrectly say up/down respectively.   |
| `<leader>or`                  | Oil N    | Refresh.                                 | Buffer-local.                                        |
| `<leader>ob` / `o-`           | Oil N    | Open cwd / parent.                       | `o-` is the replacement for Oil's common parent key. |
| `<leader>o.` / `o,`           | Oil N    | Change global cwd / window-local cwd.    | `o,` description incorrectly says “tab”.             |
| `<leader>ox` / `os`           | Oil N    | Open external / change sort.             | External open depends on system handler.             |
| `<leader>oth` / `ott` / `otc` | Oil N    | Toggle hidden / trash / detail columns.  | Consistent nested toggle group.                      |

### Harpoon

Source: `plugins/harpoon-config.lua:19-45`.

| Key                         | Scope          | Action                                             | Conflict/notes                                           |
| --------------------------- | -------------- | -------------------------------------------------- | -------------------------------------------------------- |
| `<leader>ha`                | Global N       | Add current file.                                  | Leader-only.                                             |
| `<leader>ht`                | Global N       | Toggle quick menu.                                 | Leader-only.                                             |
| `<leader>hn`                | Global N       | Calls `prev()`.                                    | **Confirmed mislabeled** as next; likely action bug.     |
| `<leader>hp`                | Global N       | Calls `next()`.                                    | **Confirmed mislabeled** as previous; likely action bug. |
| `<C-s>` / `<C-h>` / `<C-t>` | Harpoon menu N | Open selected item in vertical / horizontal / tab. | Buffer-local; parallels Oil.                             |

### Snipe

Source: `plugins/snipe-nvim-config.lua:18-60`. The first key is global; the rest operate only inside
the Snipe menu.

| Key                               | Scope    | Action                                                   | Conflict/notes                     |
| --------------------------------- | -------- | -------------------------------------------------------- | ---------------------------------- |
| `<leader>sn`                      | Global N | Open buffer menu.                                        | Leader-only.                       |
| `,` then tag then `d` / `v` / `h` | Snipe    | Close tagged buffer / vertical split / horizontal split. | Custom leader inside menu.         |
| `<C-f>` / `<C-b>`                 | Snipe    | Next/previous page.                                      | Buffer-local, conventional paging. |
| `<CR>` / `<Esc>`                  | Snipe    | Open under cursor / cancel.                              | Buffer-local.                      |
| `D`                               | Snipe    | Close selected buffer.                                   | Buffer-local.                      |
| `<C-s>` / `<C-h>`                 | Snipe    | Open vertical / horizontal split.                        | Buffer-local.                      |

## Git mappings

Source: `plugins/gitsigns-nvim-config.lua:18-70`. All are registered buffer-locally only after
Gitsigns attaches. Runtime attachment was verified on a tracked Lua file.

| Key                   | Mode | Action                                                                   | Default/ conflict                                      |
| --------------------- | ---- | ------------------------------------------------------------------------ | ------------------------------------------------------ |
| `]c` / `[c`           | N    | Next/previous hunk; preserve native diff change navigation in diff mode. | Intentional override with correct fallback.            |
| `<leader>gs` / `gr`   | N, V | Stage/reset current hunk or selected range.                              | Leader-only; Visual range handling is explicit.        |
| `<leader>gS` / `gR`   | N    | Stage/reset buffer.                                                      | Leader-only.                                           |
| `<leader>gp` / `gi`   | N    | Preview hunk / inline preview.                                           | Leader-only.                                           |
| `<leader>gb` / `gB`   | N    | Full current-line blame / full blame view.                               | Leader-only.                                           |
| `<leader>gd` / `gD`   | N    | Diff against index / previous revision.                                  | Leader-only; distinct from LSP `gd` because of leader. |
| `<leader>gq` / `gQ`   | N    | Current-file / all-files hunks in quickfix.                              | Leader-only.                                           |
| `<leader>gtw` / `gtb` | N    | Toggle word diff / inline blame.                                         | Nested toggle group.                                   |

## Tree-sitter incremental selection

Source: `plugins/nvim-treesitter-config.lua:33-40`. These mappings belong to the frozen master
branch and must be reevaluated during the required main-branch migration.

| Key   | Mode | Action                       | Default/ conflict                                                     |
| ----- | ---- | ---------------------------- | --------------------------------------------------------------------- |
| `gnn` | N    | Start incremental selection. | Extends the `gn` family.                                              |
| `grn` | V    | Increment to parent node.    | Same spelling as Neovim's Normal-mode LSP rename, but different mode. |
| `grc` | V    | Increment to scope.          | `gr` family ambiguity in Visual mode.                                 |
| `grm` | V    | Decrement node selection.    | `gr` family ambiguity in Visual mode.                                 |

## Diagnostics

Source: `lsp/diagnostic-default-config.lua:40-75`.

| Key         | Mode | Action                                                  | Default/ conflict                                            |
| ----------- | ---- | ------------------------------------------------------- | ------------------------------------------------------------ |
| `<C-w>dt`   | N    | Toggle diagnostics globally.                            | Extends native `<C-w>d` prefix.                              |
| `<C-w>dft`  | N    | Toggle virtual text between all lines and current line. | Long prefix; description says global correctly.              |
| `<C-w>dfl`  | N    | Toggle current-line virtual lines.                      | Long prefix.                                                 |
| `<C-w>dl`   | N    | Populate location list.                                 | Long prefix.                                                 |
| `<C-w>do`   | N    | Open diagnostic float.                                  | Alias for desired native `<C-w>d` behavior.                  |
| `]d` / `[d` | N    | Next/previous diagnostic.                               | Redundant override of Neovim 0.12 defaults.                  |
| `<C-w>d`    | N    | Nonrecursive self mapping.                              | **Broken restore:** shadows native diagnostic float mapping. |

## LSP attach mappings

Source: `lsp/lsp-base-config.lua:3-80`. All mappings are buffer-local and are added for each LSP
client attachment. The `buffer` map option is deprecated in Neovim 0.12; use `buf`.

### Direct navigation and previews

| Key                   | Mode | Action                                                    | Default/ conflict                                             |
| --------------------- | ---- | --------------------------------------------------------- | ------------------------------------------------------------- |
| `gd`                  | N    | Definition.                                               | Familiar legacy LSP mapping; no 0.12 global default conflict. |
| `gy`                  | N    | Type definition.                                          | Custom mnemonic.                                              |
| `gc`                  | N    | Declaration.                                              | **Shadows built-in comment operator family.**                 |
| `gr`                  | N    | References.                                               | **Prefix conflict with native `gr...` LSP defaults.**         |
| `gi`                  | N    | Implementation.                                           | Legacy mapping; native 0.12 mapping is `gri`.                 |
| `gpd` / `gpy` / `gpc` | N    | Preview definition / type / declaration.                  | Goto Preview, buffer-local.                                   |
| `gpr` / `gpi` / `gpq` | N    | Preview references / implementation / close all previews. | Goto Preview, buffer-local.                                   |

### `<C-s>` LSP group

| Key                     | Mode | Action                                                    | Default/ conflict and notes                                                               |
| ----------------------- | ---- | --------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `<C-s>h` / `<C-s>s`     | N    | Hover / signature help.                                   | Terminal flow-control transport may affect Ctrl-S in some environments.                   |
| `<C-s>rn`               | N    | Rename.                                                   | Duplicate of intended native `grn`.                                                       |
| `<C-s>ic` / `oc`        | N    | Incoming / outgoing calls.                                | Grouped consistently.                                                                     |
| `<C-s>th`               | N    | Type hierarchy.                                           | Grouped consistently.                                                                     |
| `<C-s>ca`               | N, V | Actions Preview code action picker.                       | Defined first as built-in code action, then intentionally overwritten by plugin callback. |
| `<C-s>ds` / `dh` / `cr` | N    | Document symbols / document highlight / clear references. | Grouped consistently.                                                                     |
| `<C-s>ws` / `wd`        | N    | Workspace symbols / workspace diagnostics.                | Grouped consistently.                                                                     |
| `<C-s>l`                | N    | Toggle inlay hints for current buffer.                    | Description incorrectly says “global”.                                                    |
| `<C-s>L`                | N    | Toggle inlay hints without a buffer filter.               | Description omits “global”; the two descriptions appear reversed.                         |
| `<C-s>u` / `U`          | N    | Toggle symbol usage for buffer / globally.                | Plugin is initialized disabled.                                                           |

### Broken restore mappings

| Key                           | Mode | Intended action                                                | Effective issue                                                                               |
| ----------------------------- | ---- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `K`                           | N    | Native LSP hover.                                              | `K -> K`, nonrecursive, so it invokes underlying keyword lookup rather than the shadowed map. |
| `gri` / `grn` / `grr` / `grt` | N    | Native implementation / rename / references / type definition. | Each maps nonrecursively to itself and suppresses the global LSP callback.                    |
| `gO`                          | N    | Native document symbols.                                       | Nonrecursive self mapping suppresses the global callback.                                     |
| `gra`                         | N, V | Native code action.                                            | Nonrecursive self mapping suppresses the global callback.                                     |
| `<C-s>`                       | I    | Native signature help.                                         | Nonrecursive self mapping suppresses the global callback.                                     |

## Completion mappings

Source: `lsp/blink-cmp-config.lua:16-41`, `:189-206`, and `:227-244`. Blink mappings are active only
in their completion contexts and have custom fallback rules.

### Insert completion

The unspecified preset is Blink's `default` preset. The rows below include the surviving preset keys
and every local override.

| Key               | Mode | Action                                      | Default/ conflict and notes                                                                               |
| ----------------- | ---- | ------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `<C-space>`       | I    | Show completion; show/hide docs on repeats. | Replaces built-in completion start behavior with Blink.                                                   |
| `<C-h>`           | I    | Show/hide documentation.                    | Overrides insert backspace-equivalent behavior.                                                           |
| `<S-Tab>`         | I    | Select and accept; fallback.                | Overrides preset snippet-backward behavior; snippets are disabled.                                        |
| `<Tab>`           | I    | Blink mapping disabled.                     | Falls through to Neovim/snippet default; deliberate.                                                      |
| `<C-e>`           | I    | Hide menu, then fallback.                   | Custom uses `hide`, while Blink preset uses `cancel`.                                                     |
| `<C-y>`           | I    | Accept selection, then fallback.            | Overrides built-in literal/control behavior.                                                              |
| `<CR>`            | I    | Blink mapping disabled.                     | Native/other mapping handles Enter.                                                                       |
| `<C-n>` / `<C-p>` | I    | Select next/previous without auto-insert.   | Custom callbacks have no explicit fallback; may consume native completion keys when no item is available. |
| `<Up>` / `<Down>` | I    | Select previous/next, then fallback.        | Inherited Blink default preset.                                                                           |
| `<C-b>` / `<C-f>` | I    | Scroll docs up/down, then fallback.         | Overrides native insert scrolling while menu/docs apply.                                                  |
| `<C-k>`           | I    | Blink mapping disabled.                     | Removes default Blink signature toggle.                                                                   |
| `<C-s>`           | I    | Show/hide signature.                        | Collides with Neovim's global LSP signature key by design.                                                |
| `<C-u>` / `<C-d>` | I    | Scroll signature up/down, then fallback.    | Overrides native insert deletion/indent behavior while signature UI applies.                              |

### Command line completion

The `cmdline` preset contributes Tab, Shift-Tab, Ctrl-Space, Ctrl-Y, Ctrl-E, and End. The
configuration overrides Ctrl-N/Ctrl-P and disables Left/Right.

| Key                  | Mode | Action                                              | Notes                             |
| -------------------- | ---- | --------------------------------------------------- | --------------------------------- |
| `<Tab>` / `<S-Tab>`  | C    | Show/insert/accept single, then next/previous.      | Blink cmdline preset.             |
| `<C-space>`          | C    | Show completion, then fallback.                     | Blink cmdline preset.             |
| `<C-n>` / `<C-p>`    | C    | Custom next/previous selection without auto-insert. | No explicit fallback.             |
| `<C-y>` / `<C-e>`    | C    | Select-and-accept / cancel, then fallback.          | Blink cmdline preset.             |
| `<End>`              | C    | Hide menu, then fallback.                           | Blink cmdline preset.             |
| `<Left>` / `<Right>` | C    | Blink mappings disabled.                            | Preserves native cursor movement. |

### Terminal completion

Terminal mode also selects the cmdline preset, then disables Tab, Shift-Tab, Left, and Right and
overrides Ctrl-N/Ctrl-P.

| Key                                        | Mode | Action                                       | Notes                                      |
| ------------------------------------------ | ---- | -------------------------------------------- | ------------------------------------------ |
| `<C-space>`                                | T    | Show terminal buffer completion.             | From cmdline preset.                       |
| `<C-n>` / `<C-p>`                          | T    | Next/previous selection without auto-insert. | Custom callbacks, no explicit fallback.    |
| `<C-y>` / `<C-e>` / `<End>`                | T    | Accept / cancel / hide with fallback.        | From cmdline preset.                       |
| `<Tab>` / `<S-Tab>` / `<Left>` / `<Right>` | T    | Blink mappings disabled.                     | Terminal application receives native keys. |

## DAP mappings

Global source: `dap/nvim-dap-config.lua:15-25`; DAP UI source: `dap/nvim-dap-ui-config.lua:28`.

| Key                        | Mode | Action                                      | Conflict/notes                                            |
| -------------------------- | ---- | ------------------------------------------- | --------------------------------------------------------- |
| `<leader>db` / `dB`        | N    | Toggle breakpoint / conditional breakpoint. | Leader-only.                                              |
| `<leader>dc`               | N    | Continue/start.                             | Leader-only.                                              |
| `<leader>ds` / `dn` / `do` | N    | Step into / over / out.                     | `dn` means next/over rather than a standard DAP mnemonic. |
| `<leader>dt`               | N    | Toggle DAP REPL.                            | Leader-only.                                              |
| `<leader>dR`               | N    | Restart.                                    | Leader-only.                                              |
| `<leader>d?`               | N    | Evaluate expression under cursor in DAP UI. | Leader-only.                                              |

## Inactive mapping

`plugins/trailing-whitespace-nvim-config.lua:123` defines `<leader>tw` in Normal/Visual mode to
toggle its local whitespace implementation, but `plugins/config.lua` does not require that module.
The mapping is not registered. Hardtime and cppdbg dormant configs define no local mappings.

## Recommended everyday layout

The existing layout can remain largely intact after the necessary fixes. The smallest coherent set
to remember is:

| Task                                          | Key                                               |
| --------------------------------------------- | ------------------------------------------------- |
| Find file / live grep / buffers               | `<leader>pf` / `<leader>pg` / `<leader>pb`        |
| Open Oil / Neo-tree                           | `<leader>of` / `<leader>\|t`                      |
| Format                                        | `<leader>cf`                                      |
| Git next/previous hunk                        | `]c` / `[c`                                       |
| Git stage/reset hunk                          | `<leader>gs` / `<leader>gr`                       |
| LSP definition / references / rename / action | `gd` / native `grr` / `grn` / `gra` after cleanup |
| Diagnostics                                   | `]d` / `[d` / `<C-w>d` after cleanup              |
| Terminal                                      | `<leader>tf` or `<leader>tt`                      |
| DAP breakpoint / continue / step over         | `<leader>db` / `<leader>dc` / `<leader>dn`        |

For discoverability, `<leader>pk` lists mappings, `:map <key>` shows the effective mapping, and
`:verbose map <key>` shows the last defining script.
