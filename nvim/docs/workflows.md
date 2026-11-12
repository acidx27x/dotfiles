# Neovim workflows

These examples combine built-in Vim commands with this config's mappings. `<Space>` is the leader
key. Type commands beginning with `:` in Normal mode; press `<Esc>` to leave Insert mode first. The
[keymap reference](keymaps.md) lists all custom and plugin mappings.

## Quickfix: work through matches across files

Quickfix is a list of file locations shared across the editor. Searches, compiler errors, and
plugins can fill it. Replace `{pattern}` and `{files}` with a search pattern and file glob:

```vim
:vimgrep /{pattern}/j {files}
:copen
```

`j` leaves the cursor where it is while collecting matches. In the quickfix window, press `<CR>` on
an entry to jump to it. Use these commands from any Normal-mode window:

| Command               | Action                                         |
| --------------------- | ---------------------------------------------- |
| `:cnext` / `:cprev`   | Jump to the next / previous entry.             |
| `:cfirst` / `:clast`  | Jump to the first / last entry.                |
| `:copen` / `:cclose`  | Show / hide the list without clearing it.      |
| `:colder` / `:cnewer` | Switch between earlier / later quickfix lists. |

MiniBracketed provides `[q` / `]q` for previous/next entries and `[Q` / `]Q` for first/last. Counts
are supported and navigation wraps at the ends.

In a Git file, `<Space>gq` fills quickfix with changes for the current buffer; `<Space>gQ` uses all
buffers. Run `:copen` to inspect the result. `:make` also fills quickfix when the project's
`makeprg` and `errorformat` are suitable.

For a replacement across files found by a search, review the list first, then run:

```vim
:cfdo %s/old/new/ge | update
```

`:cfdo` runs once per file in the current list. `e` skips files without a match, and `update` writes
changed files. To act on each quickfix entry instead, use `:cdo`.

### Location lists

A location list belongs to one window, which is useful when each split needs its own results.
`<Space>eq` fills the current window's location list with diagnostics.
`:lvimgrep /{pattern}/j {files}` fills it from a search. Use `:lopen`, `:lnext`, `:lprev`, and
`:lclose` as the location-list counterparts of the quickfix commands. MiniBracketed provides `[l` /
`]l` and `[L` / `]L` for previous/next and first/last entries.

## Terminal windows

| Keys or command                     | Result                                 |
| ----------------------------------- | -------------------------------------- |
| `<Space>th` / `:new \| terminal`    | Open a terminal in a horizontal split. |
| `<Space>tv` / `:vnew \| terminal`   | Open one in a vertical split.          |
| `<Space>tt` / `:tabnew \| terminal` | Open one in a new tab.                 |
| `:terminal`                         | Open a terminal in the current window. |

Inside a terminal, type directly to the shell. Press `<C-\><C-n>` to enter Terminal-Normal mode; you
can then scroll or use Normal-mode commands such as `<C-w>h/j/k/l` to change windows. Press `i` to
send keys to the terminal again. From Terminal-Normal mode, `:close` closes its window. Exiting the
shell successfully deletes its terminal buffer in this config.

## Windows, buffers, and tabs

A buffer holds a file or terminal; a window displays a buffer; a tab holds a window layout. Opening
a second window does not create a second copy of the file.

| Task                                                   | Keys or command                                       |
| ------------------------------------------------------ | ----------------------------------------------------- |
| Split current window left/right or above/below         | `<Space>sv` / `<Space>sh`                             |
| Focus another split                                    | `<C-w>h/j/k/l` or Alt/Meta + `h/j/k/l` in Normal mode |
| Move a split to an edge                                | `<Space>sH/J/K/L`                                     |
| Exchange splits / equalize sizes                       | `<Space>sx` / `<Space>s=`                             |
| Turn a split into a float or dock a float              | `<Space>sf`                                           |
| Move current window to a new tab                       | `<Space>st`                                           |
| Close the current window                               | `<Space>q` or `:close`                                |
| List buffers / switch by number                        | `:ls` / `:buffer {number}`                            |
| Pick a buffer / previous or next buffer                | `<Space>pb` / `<Space>bp` or `<Space>bn`              |
| Return to the alternate buffer / delete current buffer | `<Space>bb` / `<Space>bd`                             |
| List tabs / go to next or previous tab                 | `:tabs` / `gt` or `gT`                                |

`<Space>sf` opens a float over the base window if the current tab has only one normal window.
`<Space>st` then opens the current buffer in a new tab. `:BTab {number}` (or `:btab`) opens that
exact existing buffer with native `:tab sbuffer`, including unnamed, modified, and terminal buffers.
Completion offers valid numeric IDs; invalid IDs do not create a tab. This config places new
horizontal splits below and vertical splits to the right.

## Explorer working directories

In Oil or MiniFiles, use `g~` to set the tab's cwd to the displayed directory, or `` g` `` to set
only the editing window's cwd. Floating explorers apply these changes to their editing window.
MiniFiles uses the focused directory column, including empty directories. Browsing alone does not
change cwd; Oil's backtick still sets the global cwd.

Use `g~` for one project per tab and `` g` `` to narrow the next `<Space>pf` or `<Space>pg` search
in one window. `:verbose pwd` shows the effective directory and its scope. Setting the tab cwd also
clears the editing window's local override; other windows with local overrides keep them.

## Search and edit

| Keys or command         | Action                                                      |
| ----------------------- | ----------------------------------------------------------- |
| `/pattern` / `?pattern` | Search forward / backward in the current buffer.            |
| `*` / `#`               | Search forward / backward for the word under the cursor.    |
| `n` / `N`               | Repeat the search in the same / opposite direction.         |
| `<Space>nh`             | Clear search highlighting.                                  |
| `<Space>pg`             | Live grep across project files with fzf-lua.                |
| `:%s/old/new/gc`        | Confirm each replacement in the current buffer.             |
| `:g/pattern/d`          | Delete every line matching a pattern in the current buffer. |

Use quickfix above when you need a persistent, navigable list of matches across files. fzf-lua is
useful for jumping to one result quickly.

To find a file and browse its directory, use `<Space>pf`, search for the filename, then press
`<C-o>` to reveal it in Oil. Enter still opens the file normally. While browsing Oil, `gf` starts
the same file picker recursively beneath the displayed directory without changing cwd. If Oil is
floating, it closes first and the picker returns selections to the underlying editing window.

### Project TODO markers

`<Space>pp` opens fzf-lua's grep picker for standalone uppercase `TODO`, `FIXME`, `ERROR`, `HACK`,
`WARN`, `NOTE`, `HINT`, and `INFO` markers below the current window's cwd. A colon is optional:
`TODO` and `TODO:` both match, while `TODO_WORD` does not. Type in the picker to fuzzy-filter the
results, preview files, and press Enter to jump to a match. `<Space>pr` resumes the picker.

The search uses a fixed ripgrep regex in `fzf-lua-config.lua`, honors the `rg` executable override,
includes hidden files, respects ignore files, and excludes `.git`. It searches saved disk contents;
save a buffer first to include its latest edits. `<Space>pg` remains the general live project
search. MiniHipatterns still highlights markers and hex colors in buffers; its configuration does
not control project search. No custom file scanner or temporary buffers are used.

### Search and replace

Normal `<Space>S` toggles grug-far; Visual `<Space>S` prefills the selection. Searches start in the
invocation's window-local cwd, use ripgrep with `--ignore-case`, and honor the `rg` override in
`lua/local_paths.lua`. Use the Files Filter and Paths fields to limit the search, review the diff,
then invoke grug-far's Replace action. `sd` is no longer required. Harpoon still requires Plenary.

### Notifications, selection, saves, and tags

MiniNotify uses native formatting and durations, wraps messages within 80 columns, and enables
built-in LSP progress with upstream progress formatting and completion duration. `<Space>nd` clears
active notifications. `:lua MiniNotify.show_history()` opens history; `MiniNotify.get_all()` returns
it for scripting. Progress tasks and ordinary notifications can appear together.

`gnn` starts native node selection. Visual `grn` and `grc` grow to a parent; `grm` shrinks to a
child. Counts are supported. Without a Tree-sitter parser, native selection falls back to LSP
selection ranges. Normal `grn` remains LSP rename. `<C-s>ca` in Normal or Visual mode opens
fzf-lua's built-in code-action diff preview; Enter applies the selected action. Native `gra` remains
available.

Manual saves and autosaves trim final blank lines with MiniTrailspace and retain a final newline.
This cleanup preserves interior whitespace and skips binary and special buffers. Manual saves still
follow the Conform formatting policy; autosaves do not trigger formatting.

`:CTags lang=C++ [exclude=generated]` runs manually and asynchronously using `vim.system`. It keeps
`.tags` in the invocation's cwd, even if you change directories before completion, and reports the
exit result with captured stdout and stderr. Default exclusions remain `build`, `dist`, and `run`.
The `ctags` executable override takes priority over `ctags-universal` and `ctags` on `PATH`.

## Marks, registers, macros, and folds

| Keys or command            | Action                                                      |
| -------------------------- | ----------------------------------------------------------- |
| `ma` then `'a` or `` `a `` | Set mark `a`, then return to its line or exact position.    |
| `<C-o>` / `<C-i>`          | Move backward / forward through the jump list.              |
| `"ayy` then `"ap`          | Yank a line into register `a`, then paste it.               |
| `<Space>p"`                | Browse registers with fzf-lua.                              |
| `qa` ... `q`, then `@a`    | Record keystrokes in macro register `a`, stop, then replay. |
| `@@`                       | Replay the last macro.                                      |
| `za` / `zM` / `zR`         | Toggle one fold / close all / open all folds.               |

Folds start open in this config. Tree-sitter or an attached LSP supplies fold ranges for supported
files. MiniClue shows hints for marks, registers, `<C-w>`, and `z` sequences. Use `:help quickfix`,
`:help terminal`, or `:help windows` for the built-in details.

## Native multicursor editing (Neovim 0.13+)

For selected lines, use `V` and a motion to select them, then press `Q`. Add text with `I` or `A`,
or use a text edit such as `ciwreplacement<Esc>`; the action applies at every cursor. `q=` toggles
whether relative motions move all cursors. Clear the session with `<Space>mc`; `gQ` restores it.

To choose positions individually, press `Q` at each position. To select all occurrences of the word
under the cursor, use `zq*`; `gv` then selects the match at every cursor. `[m` / `]m` navigate the
extra cursors in place of the native method-navigation keys. MiniMove retains `<C-h/j/k/l>`.
