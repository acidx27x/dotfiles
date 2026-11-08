# Neovim mappings in Zed

This is the migration reference for [Neovim's complete keymap](../../nvim/docs/keymaps.md) and
[Zed's keymap](../.config/zed/keymap.json). It reflects what the Neovim Lua modules and their
plugins do, not just the labels shown by which-key. Zed Vim mode must be enabled for the Neovim
aliases. Leader aliases apply in Normal or Visual mode; find/till and Sneak also support pending
operators while preserving text-object keys. The editor and panel shortcuts
below use their stated contexts, while terminal input and completion menus keep their existing
handling.

Zed key sequences separate strokes with spaces: Neovim `<Space>pld` becomes `space p l d`, and
`<C-s>rn` becomes `ctrl-s r n`. Uppercase letters use `shift-`, such as `space s shift-h` for
`<Space>sH`. The keys below are written in Neovim notation for readability.

## Direct aliases and existing Zed keys

| Neovim keys                                    | Zed action or existing key                                  | Notes                                                                                                                                                                                                 |
| ---------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<Space>`, `gc`, `gcc`                         | Leader; Zed Vim's existing comment keys                     | Neovim and Zed both use `gc` as a comment operator and `gcc` for the current line. Existing `secondary-l secondary-c` line comment and `secondary-l secondary-shift-c` block comment bindings remain. |
| `<Space>cf`                                    | `editor::Format`, `editor::FormatSelections`                | Visual mode uses range formatting, subject to the formatter's support. Existing `secondary-l secondary-f` remains.                                                                                    |
| `<Space>sv/sh/sH/sJ/sK/sL/sx/s=`               | Split, move, swap, and equalize pane actions                | Pane layout operations match closely. Existing Zed pane and Alt focus/resize keys remain.                                                                                                             |
| `<Space>fp`, `<Space>nd`, `<Space>np`          | Copy path, clear notifications, centered layout             | Direct Zed actions.                                                                                                                                                                                   |
| `<Space>ha/ht/hn/hp`                           | Toggle, view, next, previous bookmark                       | These are useful Harpoon substitutes; Zed bookmarks are not Harpoon's ordered, project-persistent list. Existing bookmark bindings remain.                                                            |
| `<Space>db/ds/dn/do/dR/d?`                     | Breakpoint, step into/over/out, restart, evaluate selection | Zed debugger actions. Existing `Alt-D` debugger bindings remain.                                                                                                                                      |
| `gi`, `grt`                                    | Implementation, type definition                             | Added because Zed already provides the actions. `gi` replaces Zed Vim's “insert at previous location” on that key; `gri` remains an implementation key.                                               |
| `gd/gy/grn/grr/gri/gra/gO/K`, `]d/[d`, `]c/[c` | Zed Vim defaults                                            | Already cover definition, type definition, rename, references, implementation, code action, symbols, hover, diagnostics, and Git hunks. They are not duplicated.                                      |
| `sa/sd/sr`                                     | Zed Vim surround add/delete/change                          | Added as Normal-mode aliases; Zed's `ys`/`ds`/`cs` forms remain. A bare `s` can wait for chord disambiguation.                                                                                        |
| `gnn`, Visual `grn/grc/grm`                    | Larger/larger/smaller syntax node                           | Zed syntax selection is the closest Tree-sitter equivalent. Neovim's Visual `grc` implementation also grows to the parent, as `grn` does.                                                             |

## Useful approximations

| Neovim keys                                         | Zed binding                                                                                                             | Difference                                                                                                                                                                          |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<Space>bd/bn/bp/bb`                                | Close active item in all panes, next/previous tab, alternate file                                                       | Zed tabs and Neovim buffers have different lifetimes; `bd` closes the item in every pane. `]b` and `[b` are already Zed Vim tab navigation.                                         |
| `<Space>q/Q`                                        | Close active tab; quit Zed                                                                                              | Neovim's `q` closes a window and `Q` quits Neovim. Zed does not expose the same window/buffer model.                                                                                |
| `<Space>pf/pg/pb/pd/pr/pk/p\"/ph`                   | File finder, project search, all-tab switcher, diagnostics, last picker, keymap, registers, Zed website                 | fzf-lua's previews, history, and help picker differ from these Zed views. `ph` opens Zed's documentation website.                                                                  |
| `<Space>plc/pld/pls/pli/plr/plt/plS`                | Declaration, definition, outline, implementation, references, type definition, project symbols                          | fzf-lua lists locations first; the Zed navigation actions may jump directly or open a result view.                                                                                 |
| `<Space>rc`                                         | Open Zed's settings file                                                                                                | Opens the active editor's configuration rather than Neovim's `init.lua`.                                                                                                            |
| `<Space>tt`, Zed-only `<Space>tf`                   | Center terminal / terminal panel                                                                                        | `tt` opens a center terminal tab. The retained `tf` alias toggles Zed's docked terminal panel; Neovim no longer maps `tf`.                                                          |
| `<Space>et/eq`, `<C-w>d`                            | Toggle inline diagnostics, current-file diagnostics view, show or advance diagnostic                                    | Zed's inline toggle is not limited to the current line; its diagnostics view is not Neovim's location list; `Ctrl-W d` is not a diagnostic float.                                   |
| `<Space>S`                                          | Project search with replacement enabled                                                                                 | grug-far's UI and visual-selection behavior differ.                                                                                                                                  |
| `<Space>of`                                         | Focus the project panel                                                                                                 | Oil is an editable directory buffer, while the Zed project panel is a file tree. Split/float variants are left alone.                                                               |
| `<Space>gs/gr/gS/gR/gp/gb/gB/gd/gib`                | Toggle stage, restore hunk, stage file, restore file, show hunk diff, blame hover, file blame, file diff, inline blame  | `gs` toggles staging. `gp` expands a diff hunk rather than opening Gitsigns' preview. `gr` and `gR` discard changes, as their Neovim counterparts do. The old `gtb` chord is removed to free `gt`. |
| `<Space>dc/dt`                                      | Continue debugger / focus debugger console                                                                              | `dc` needs an existing stopped session; start a new session with Zed's existing `Alt-D r`. The console is not nvim-dap's REPL.                                                      |
| `gpd/gpy/gpc/gpr/gpi`                               | Split navigation or reference results                                                                                   | goto-preview's floating preview and `gpq` close operation have no Zed equivalent. The split actions open real tabs/panes.                                                           |
| `<C-s>h/s/rn/ic/oc/ca/ds/dc/ws/wd/l` in Normal mode | Hover, signature, rename, call hierarchy, code actions, outline, declaration, project symbols, diagnostics, inlay hints | `ca` has no fzf-lua code-action diff picker; `ds` opens the outline; `l` toggles editor inlay hints. Insert-mode `Ctrl-S` remains Zed's signature-help key.                             |

## Recent Neovim additions

| Keys | Mode | Zed action / behavior |
| ---- | ---- | --------------------- |
| `f/F/t/T` | Normal, Visual, Operator-pending | Multiline find/till using `vim::PushFindForward` / `vim::PushFindBackward`; `;` and `,` keep Zed's repeat behavior. |
| `>` / `<` | Normal, Visual, Operator-pending | `vim::PushSneak` / `vim::PushSneakBackward`, replacing the custom `Zf` / `Zb` chords. |
| `<Space>xx` | Normal, Visual | `vim::Exchange`: choose a motion/text object in Normal mode or exchange the Visual selection. Replaces the custom Visual `X` alias; native exchange keys remain available. |
| `<Space>is` / `<Space>it` | Normal, Visual | Convert indentation on the current or selected lines to spaces / tabs. |
| `<Space>fl` | Normal | `line_ending_selector::Toggle`: choose LF/CRLF and save. |
| `<Space>fe` | Normal | `encoding_selector::Toggle`: reload a saved file with the chosen encoding. This does not reproduce Neovim's Save with Encoding workflow; remote-server files are unsupported. |
| `<Space>pp` | Normal | Open project search with the standalone uppercase marker regex for FIXME, ERROR, HACK, WARN, TODO, NOTE, HINT, and INFO; ignored files stay excluded. Press Enter to run the search. |
| `<Space>mf` | Normal | Focus the project panel as a MiniFiles substitute; editable directory columns are unavailable. |
| `<Space>gU` | Normal | `git::UnstageFile`: unstage the whole current file. |
| `<Space>gP` | Normal | Expand/collapse selected diff hunks, the same approximation used by `<Space>gp`. |
| `<Space>gt` / `<Space>gT` | Normal | Focus the Git panel / open uncommitted changes across the project. These approximate Gitsigns' plain/unified changes trees. |

Sneak is a two-character jump without Leap's target labels. Multiline find/till searches are Zed's
native motions, so their range and matching behavior can differ from Leap. Text objects such as
`af`, `it`, and `i<` retain Zed's defaults. The existing `secondary-alt-h/l` indentation shortcuts
use direct Vim actions; in Visual mode they reselect with `gv` without invoking the new jump keys.

Only exchange is added from MiniOperators. Its evaluate, multiply, replace, and sort prefixes are
left unmapped; the existing editor-prefix line-sort shortcut remains available. MiniBracketed is
not copied: Zed keeps its bracket keys, including `[x`/`]x` for syntax selection and `[m`/`]m` for
method navigation.

## Editor and panel shortcuts

`secondary` means Cmd on macOS and Ctrl on Linux and Windows. The editor prefix is `secondary-l`;
the workspace prefix is `secondary-k`. Workspace picker and panel shortcuts exclude Terminal, except
`secondary-k secondary-t` (terminal panel) and `secondary-k secondary-e` (focus editor).

| Context                    | Keys                            | Action                                       |
| -------------------------- | ------------------------------- | -------------------------------------------- |
| Editor                     | `secondary-l secondary-i`       | Convert indentation to spaces                |
| Editor                     | `secondary-l secondary-shift-i` | Convert indentation to tabs                  |
| Editor                     | `secondary-l secondary-s`       | Sort selected lines without case sensitivity |
| Editor                     | `secondary-l secondary-=`       | Toggle centered layout                       |
| Editor                     | `secondary-l secondary-w`       | Save without formatting                      |
| Workspace outside Terminal | `secondary-k secondary-b`       | Open the all-tabs switcher                   |
| Workspace outside Terminal | `secondary-k secondary-f`       | Open the Project Search Picker               |
| Workspace outside Terminal | `secondary-k secondary-p`       | Open the file finder                         |
| Git Panel changes list     | `o`                             | View the selected file without a diff view   |
| Project Panel, not editing | `g h`                           | Show history for the selected file or folder |
| Editor, Vim Normal mode    | `]e` / `[e`                     | Next / previous error in the current file    |
| Editor, Vim Normal mode    | `]w` / `[w`                     | Next / previous warning in the current file  |

`secondary-k secondary-p` replaces Zed's Reopen Last Picker shortcut; `<Space>pr` still reopens the
last picker in Normal mode. The default `secondary-p` file-finder binding is removed in the
workspace and File Finder contexts. Terminal `secondary-p` handling and picker navigation stay
available. `]d` and `[d` remain Zed's all-severity diagnostic keys. Strict current-folder file
search is omitted because Zed's native file finder has no folder-scope keymap parameter.

## Completion stays as configured

Blink's Insert-mode `<C-space>` first opens completion and then toggles the selected item's
documentation; `<C-h>` toggles that documentation; `<C-s>` toggles signature help. Its `<C-y>`, Tab,
Shift-Tab, Ctrl-N/P, Ctrl-G S, and documentation/signature scrolling keys are separate behaviors.
The Zed keymap already uses Insert-mode `Ctrl-S` to **show** signature help and `Alt-E` to cancel
the active popup. Zed does not publish a dedicated signature-hide or completion-item
documentation-toggle action. `show_completion_documentation` remains `false` in
`settings.shared.json`. No Tab, Shift-Tab, Enter, completion-acceptance, or completion-navigation
binding was changed. `editor::OpenDocs` is documentation for the symbol at the cursor, not the
selected completion item, so it is not used as a substitute.

## Left to Zed defaults or unmapped

- Neovim's centered `n/N` and Ctrl-D/U are handled by the existing Zed keymap; `]b/[b` and surround
  Visual aliases also already exist there. MiniMove's `<C-h/j/k/l>` are left in Neovim; Zed keeps
  its existing Ctrl key behavior. Alt-arrow pane resizing moves five steps per press.
- `<Space>nh` search-highlight clear, `<Space>sf/st` float/tab conversion, Alt floating-window
  movement, `<Space>cd` window-local cwd, terminal split variants, and custom `:BTab`, `:Cwd`,
  `:Twd`, `:Lwd`, and `:CTags` commands need behavior outside a Zed keymap.
- MiniSplitjoin's syntax-aware `S/J`, MiniPairs' Insert-mode pairing rules, MiniSurround's
  `sf/sF/sh` target search, fzf-lua's command-history picker, auto-save toggle,
  MiniTrailspace trim, Visual Whitespace toggle, and Snipe's tagged menu have no equivalent keymap
  action. Existing Zed editing remains available.
- LSP type hierarchy, document highlight/clear references, global inlay-hint and symbol-usage
  toggles, and the goto-preview close key have no matching action. Gitsigns word diff, parent
  revision diff, quickfix lists, and Oil's writable directory buffer are likewise left unmapped.
- Oil, Harpoon, and Snipe keys **inside their own menus** are buffer-local plugin controls. No
  global Zed shortcuts are added for them.

The action names and keymap contexts above were checked against Zed's
[Vim mode documentation](https://zed.dev/docs/vim),
[key binding guide](https://zed.dev/docs/key-bindings),
[action list](https://zed.dev/docs/all-actions), and
[default Vim keymap](https://github.com/zed-industries/zed/blob/main/assets/keymaps/vim.json).
Syntax and binding structure are checked locally. Runtime behavior still needs a check inside Zed.
