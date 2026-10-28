# Neovim workflows

These examples combine built-in Vim commands with this config's mappings. `<Space>` is the leader
key. Type commands beginning with `:` in Normal mode; press `<Esc>` to leave Insert mode first.
The [keymap reference](keymaps.md) lists all custom and plugin mappings.

## Quickfix: work through matches across files

Quickfix is a list of file locations shared across the editor. Searches, compiler errors, and
plugins can fill it. For example, from the project directory:

```vim
:vimgrep /TODO/j **/*.lua
:copen
```

`j` leaves the cursor where it is while collecting matches. In the quickfix window, press `<CR>`
on an entry to jump to it. Use these commands from any Normal-mode window:

| Command | Action |
| --- | --- |
| `:cnext` / `:cprev` | Jump to the next / previous entry. |
| `:cfirst` / `:clast` | Jump to the first / last entry. |
| `:copen` / `:cclose` | Show / hide the list without clearing it. |
| `:colder` / `:cnewer` | Switch between earlier / later quickfix lists. |

In a Git file, `<Space>gq` fills quickfix with changes for the current buffer; `<Space>gQ` uses
all buffers. Run `:copen` to inspect the result. `:make` also fills quickfix when the project's
`makeprg` and `errorformat` are suitable.

For a replacement across files found by a search, review the list first, then run:

```vim
:cfdo %s/old/new/ge | update
```

`:cfdo` runs once per file in the current list. `e` skips files without a match, and `update`
writes changed files. To act on each quickfix entry instead, use `:cdo`.

### Location lists

A location list belongs to one window, which is useful when each split needs its own results.
`<C-w>dl` fills the current window's location list with diagnostics. `:lvimgrep /TODO/j **/*.lua`
fills it from a search. Use `:lopen`, `:lnext`, `:lprev`, and `:lclose` as the location-list
counterparts of the quickfix commands.

## Terminal windows

| Keys or command | Result |
| --- | --- |
| `<Space>th` / `:new \| terminal` | Open a terminal in a horizontal split. |
| `<Space>tv` / `:vnew \| terminal` | Open one in a vertical split. |
| `<Space>tt` / `:tabnew \| terminal` | Open one in a new tab. |
| `<Space>tf` | Toggle the configured floating terminal. |
| `:terminal` | Open a terminal in the current window. |

Inside a terminal, type directly to the shell. Press `<C-\><C-n>` to enter Terminal-Normal mode;
you can then scroll or use Normal-mode commands such as `<C-w>h/j/k/l` to change windows. Press
`i` to send keys to the terminal again. From Terminal-Normal mode, `:close` closes its window.
Exiting the shell successfully deletes its terminal buffer in this config. The floating terminal's
sidebar also uses `q` to toggle it while the sidebar is in Normal mode.

## Windows, buffers, and tabs

A buffer holds a file or terminal; a window displays a buffer; a tab holds a window layout. Opening
a second window does not create a second copy of the file.

| Task | Keys or command |
| --- | --- |
| Split current window left/right or above/below | `<Space>sv` / `<Space>sh` |
| Focus another split | `<C-w>h/j/k/l` or Alt/Meta + `h/j/k/l` in Normal mode |
| Move a split to an edge | `<Space>sH/J/K/L` |
| Exchange splits / equalize sizes | `<Space>sx` / `<Space>s=` |
| Turn a split into a float or dock a float | `<Space>sf` |
| Move current window to a new tab | `<Space>st` |
| Close the current window | `<Space>q` or `:close` |
| List buffers / switch by number | `:ls` / `:buffer {number}` |
| Pick a buffer / previous or next buffer | `<Space>pb` / `<Space>bp` or `<Space>bn` |
| Return to the alternate buffer / delete current buffer | `<Space>bb` / `<Space>bd` |
| List tabs / go to next or previous tab | `:tabs` / `gt` or `gT` |

`<Space>sf` opens a float over the base window if the current tab has only one normal window.
`<Space>st` then opens the current buffer in a new tab. This config places new horizontal splits
below and vertical splits to the right.

## Search and edit

| Keys or command | Action |
| --- | --- |
| `/pattern` / `?pattern` | Search forward / backward in the current buffer. |
| `*` / `#` | Search forward / backward for the word under the cursor. |
| `n` / `N` | Repeat the search in the same / opposite direction. |
| `<Space>nh` | Clear search highlighting. |
| `<Space>pg` | Live grep across project files with MiniPick. |
| `:%s/old/new/gc` | Confirm each replacement in the current buffer. |
| `:g/pattern/d` | Delete every line matching a pattern in the current buffer. |

Use quickfix above when you need a persistent, navigable list of matches across files. MiniPick is
useful for jumping to one result quickly.

## Marks, registers, macros, and folds

| Keys or command | Action |
| --- | --- |
| `ma` then `'a` or `` `a `` | Set mark `a`, then return to its line or exact position. |
| `<C-o>` / `<C-i>` | Move backward / forward through the jump list. |
| `"ayy` then `"ap` | Yank a line into register `a`, then paste it. |
| `<Space>p"` | Browse registers with MiniPick. |
| `qa` ... `q`, then `@a` | Record keystrokes in macro register `a`, stop, then replay. |
| `@@` | Replay the last macro. |
| `za` / `zM` / `zR` | Toggle one fold / close all / open all folds. |

Folds start open in this config. Tree-sitter or an attached LSP supplies fold ranges for supported
files. MiniClue shows hints for marks, registers, `<C-w>`, and `z` sequences. Use `:help quickfix`,
`:help terminal`, or `:help windows` for the built-in details.
