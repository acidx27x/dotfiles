# Zellij shortcuts

The source of truth is [config.kdl](.config/zellij/config.kdl). This config clears Zellij's default
bindings, so only the configured shortcuts apply. `Ctrl+P`, then `n` means press the keys in
sequence; `Ctrl+P` by itself enters Pane mode. `Shift` is written explicitly when required.

Autolock switches to Locked mode when a focused program needs the keyboard. Most shortcuts below
work outside Locked mode. Press `Ctrl+G` to lock or unlock manually.

## Common shortcuts

| Shortcut                     | Action                                             |
| ---------------------------- | -------------------------------------------------- |
| `Ctrl+G`                     | Toggle Locked and Normal modes                     |
| `Alt+H/J/K/L` or `Alt+Arrow` | Focus an adjacent pane; left/right can switch tabs |
| `Alt+N`                      | New pane                                           |
| `Alt+F`                      | Show or hide floating panes                        |
| `Alt++` or `Alt+=`           | Increase pane size                                 |
| `Alt+-`                      | Decrease pane size                                 |
| `Alt+[` / `Alt+]`            | Previous / next swap layout                        |
| `Alt+I` / `Alt+O`            | Move the current tab left / right                  |
| `Alt+P` / `Alt+Shift+P`      | Toggle pane grouping / mark a group                |
| `Ctrl+Q`                     | Quit Zellij                                        |

| Shortcut | Mode entered |
| -------- | ------------ |
| `Ctrl+P` | Pane         |
| `Ctrl+T` | Tab          |
| `Ctrl+N` | Resize       |
| `Ctrl+H` | Move         |
| `Ctrl+S` | Scroll       |
| `Ctrl+O` | Session      |
| `Ctrl+B` | Tmux         |

| Shortcut      | Plugin                         |
| ------------- | ------------------------------ |
| `Ctrl+Y`      | Room: search tabs              |
| `Alt+Y`       | Forgot: keybinding reference   |
| `Alt+Shift+Y` | Zellij Palette: search actions |
| `Alt+Shift+H` | Harpoon: favorite panes        |

## Pane mode (`Ctrl+P`)

| Key                 | Action                                 |
| ------------------- | -------------------------------------- |
| `h/j/k/l` or arrows | Focus a pane                           |
| `;`                 | Focus the last pane                    |
| `n`                 | New pane                               |
| `r` / `d`           | Split right / down                     |
| `s`                 | New stacked pane                       |
| `x`                 | Close focused pane                     |
| `c`                 | Rename pane                            |
| `f` / `Shift+f`     | Fullscreen / fullscreen without UI     |
| `e`                 | Toggle tiled or floating for this pane |
| `w`                 | Show or hide floating panes            |
| `i`                 | Toggle pinned floating pane            |
| `p`                 | Switch focus                           |
| `z`                 | Toggle pane frames                     |

## Tab mode (`Ctrl+T`)

| Key                       | Action                              |
| ------------------------- | ----------------------------------- |
| `h/k` or left/up arrow    | Previous tab                        |
| `j/l` or right/down arrow | Next tab                            |
| `1`–`9`                   | Go to tab by position               |
| `n` / `x`                 | New / close tab                     |
| `r`                       | Rename tab                          |
| `s`                       | Toggle synchronized input           |
| `b`                       | Break pane into a new tab           |
| `[` / `]`                 | Break pane to the left / right      |
| `Tab`                     | Toggle between current and last tab |

## Resize (`Ctrl+N`) and Move (`Ctrl+H`) modes

| Mode   | Key                 | Action                                      |
| ------ | ------------------- | ------------------------------------------- |
| Resize | `h/j/k/l` or arrows | Increase size toward left/down/up/right     |
| Resize | `Shift+h/j/k/l`     | Decrease size toward left/down/up/right     |
| Resize | `+` / `=` / `-`     | Increase / increase / decrease overall size |
| Move   | `h/j/k/l` or arrows | Move pane left/down/up/right                |
| Move   | `n` / `Tab` / `p`   | Move pane forward / forward / backward      |

## Scroll (`Ctrl+S`) and Search (`Ctrl+S`, then `s` and `Enter`) modes

| Mode   | Key                       | Action                                     |
| ------ | ------------------------- | ------------------------------------------ |
| Both   | `j/k` or down/up arrow    | Scroll down/up                             |
| Both   | `h/l` or left/right arrow | Page up/down                               |
| Both   | `u/d`                     | Half page up/down                          |
| Both   | `Ctrl+B` / `Ctrl+F`       | Page up/down                               |
| Scroll | `[` / `]`                 | Previous / next shell prompt               |
| Scroll | `m`                       | Select command at scroll position          |
| Scroll | `c` / `e`                 | Copy last command output / edit scrollback |
| Scroll | `s`                       | Start search                               |
| Search | `n` / `p`                 | Next / previous result                     |
| Search | `c` / `o` / `w`           | Toggle case / whole word / wrap            |

`PageUp` and `PageDown` also work in Scroll and Search modes. In Scroll mode, `Alt+H/J/K/L` or
`Alt+Arrow` focuses another pane and returns to Normal mode.

## Session (`Ctrl+O`) and Tmux (`Ctrl+B`) modes

| Mode    | Key                   | Action                                                  |
| ------- | --------------------- | ------------------------------------------------------- |
| Session | `a` / `c` / `l` / `p` | About / configuration / layout manager / plugin manager |
| Session | `s` / `w`             | Share / session manager                                 |
| Session | `f`                   | Toggle host fullscreen                                  |
| Session | `[` / `]`             | Focus guest / host session                              |
| Session | `d`                   | Detach                                                  |
| Tmux    | `h/j/k/l` or arrows   | Focus a pane, then return to Normal                     |
| Tmux    | `c` / `n` / `p`       | New / next / previous tab                               |
| Tmux    | `"` / `%`             | Split down / right                                      |
| Tmux    | `o` / `z`             | Next pane / toggle fullscreen                           |
| Tmux    | `x`                   | Close focused pane                                      |
| Tmux    | `,` / `[`             | Rename tab / enter Scroll mode                          |
| Tmux    | `Space`               | Next swap layout                                        |
| Tmux    | `d`                   | Detach                                                  |
| Tmux    | `Ctrl+B`              | Send a literal `Ctrl+B` to the pane                     |

`Enter` or `Esc` returns from most modes to Normal. In a rename prompt, `Enter` accepts the name;
`Esc` undoes the rename and returns to Tab or Pane mode. `Ctrl+C` returns to Normal from rename
prompts. In Scroll and Search modes, `Ctrl+C` jumps to the bottom of scrollback and returns to
Normal.

## Approving a plugin permission prompt

If a floating plugin asks for permission but you cannot focus its pane:

1. Run `zellij action list-panes --all` and find the plugin's `PANE_ID` (for example, `plugin_3`).
2. Check the requested permissions. Only if you trust the plugin and accept those permissions, send
   `y` directly to its pane:

   ```sh
   zellij action write-chars --pane-id plugin_3 "y"
   ```

3. If that does not work, try:

   ```sh
   zellij action send-keys --pane-id plugin_3 "y"
   ```

Replace `plugin_3` with the ID from your own output; plugin IDs can change between sessions. `Alt+F`
shows or hides all floating panes but does not switch focus between them.
`zellij action focus-pane-id plugin_3` may not focus a plugin's permission dialog.
