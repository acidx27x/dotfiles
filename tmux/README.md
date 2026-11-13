# tmux

## Statusline

The top statusline uses Kanagawa Dragon with Powerline arrows and left-aligned window tabs. Tab
backgrounds cycle through Dragon green, blue, violet, and orange by window number; the active tab
has a bright yellow background, bold text, and a `●` marker. The right side shows only battery and
weather, including temperature in Celsius and location. Weather updates automatically about every 20
minutes; the bar redraws every 30 seconds using cached data. It uses network-based location
detection and requires `curl` and internet access. Powerline arrows require a compatible font, such
as FiraCode Nerd Font.

Press **Ctrl+s, Shift+t** to open Ukiyo's interactive statusline settings menu for colors, modules,
and options. It is also available through **Ctrl+s, Space, Shift+t** in which-key. Keep persistent
settings in the `@ukiyo-*` options in `~/.tmux.conf`; **Ctrl+s, r** reloads them. Set
`@ukiyo-fixed-location` to a city name if network-based detection picks the wrong location. After
changing themes in the menu, reload to restore the custom tab colors.

Windows with background activity show a `!` marker in their tab.

A second row is always reserved below the tabs for tmux messages, command prompts, and
confirmations. It shows a dim horizontal separator when there is no message or prompt.

## Plugin commands in which-key

Press **Ctrl+s, Space** to open which-key, then use:

| Keys         | Action                                                |
| ------------ | ----------------------------------------------------- |
| s / o        | Sesh / SessionX picker                                |
| Ctrl+l       | Previous session through Sesh                         |
| f            | Full tmux-fzf launcher                                |
| w, f         | tmux-fzf window picker                                |
| m, h/j/k/l   | Smart Splits movement through the existing Alt keys   |
| m, H/J/K/L   | Smart Splits resizing through the existing Alt arrows |
| b, s / r     | Resurrect save / restore                              |
| P, i / u / c | TPM install / update / remove unused plugins          |
| T            | Ukiyo statusline settings                             |

Continuum saves and restores automatically; manual snapshots use the Backup menu. Reload with
**Ctrl+s, r** after editing the menu configuration.

## Window navigation

- **Alt+n / Alt+p** select the next / previous window, wrapping around.
- **Alt+i / Alt+o** move the current window left / right, keeping it focused, without a prefix.
- **Ctrl+s, Tab** toggles between the current and last-used window.
- **Ctrl+s, &** asks before closing the current window. The confirmation appears below the
  statusline; **y** closes the window and **n** or **Esc** cancels. Exiting a shell normally does
  not ask for confirmation.
- **Ctrl+s, Shift+f** opens tmux-fzf's window switcher directly. Type to filter, then press
  **Enter** to switch; **Esc** cancels. It includes windows from all sessions.
- **Ctrl+s, Space, f** opens the full tmux-fzf launcher with its management menus.

## Copy mode and panes

Press **Ctrl+s, [** or **Ctrl+s, Esc** to enter vi copy mode. Use **v** to begin a selection, **V**
for whole lines, and **Ctrl+v** to toggle rectangular selection. **y** copies without leaving copy
mode; **Esc** cancels and returns to the terminal.

Press **Ctrl+s, ]** to paste the latest tmux buffer directly, or **Ctrl+s, =** to choose an older
buffer and press **Enter** to paste it. Release the prefix before pressing the next key; neither
shortcut needs the right-click menu.

Press **Ctrl+s, H/J/K/L** to resize panes left/down/up/right by five cells. These bindings repeat
without another prefix while pressed within tmux's repeat timeout. Existing Smart Splits Alt-arrow
resizing remains available. **Ctrl+s, < / >** swaps the current pane with the previous / next pane
in pane index order.

## Session pickers

The prefix is **Ctrl+s**. Both pickers open in a centered popup, 90% wide and 60% high.

| Keys                 | Action                                       |
| -------------------- | -------------------------------------------- |
| Ctrl+s, o            | Open SessionX                                |
| Ctrl+s, s            | Open Sesh's native picker                    |
| Ctrl+s, Ctrl+l       | Return to the previous session (`sesh last`) |
| Ctrl+s, Space, o / s | Open SessionX / Sesh through which-key       |
| Ctrl+s, F            | Open the tmux-fzf window switcher directly   |

SessionX inherits `FZF_DEFAULT_OPTS_FILE` and `FZF_DEFAULT_OPTS` from the attaching Bash or Zsh
shell. It reuses that shell's fzfrc colors and bindings, with its own reverse layout, prompt,
pointer, 90% × 60% popup, and top preview occupying 60%. Selection is limited to one session. Git
branch labels are disabled, including when returning to the session list with **Alt+b**. To enable
them, set `@sessionx-git-branch` to `on` in `.tmux.conf`, reload, and reopen SessionX.

In SessionX:

- **Ctrl+u / Ctrl+d** scroll the session list by half a page.
- **Ctrl+b / Ctrl+f** scroll the preview by half a page.
- **Alt+b** returns to the initial session list; **Alt+z** browses zoxide directories.
- **Enter** connects to the selected session. Type an unused name and press **Enter** to create it.
  Automatic acceptance and zoxide fallback remain off, so arbitrary names are supported.
- **Alt+w** toggles preview wrapping; **Alt+l** toggles list wrapping; **Alt+p** toggles the
  preview; **Alt+o** switches preview orientation. **Esc** cancels. Other keys retain SessionX
  defaults.

Sesh uses its native right-side preview and keyboard controls. The preview occupies at least 60% of
the picker and hides below 100 columns. Its native configuration supports the prompt, pointer,
icons, window names, and preview settings here, but cannot import fzfrc, set the full palette, or
remap scrolling keys. Caching remains disabled; no project paths or startup commands are configured.
**Ctrl+s, Ctrl+l** also provides a way back after a session closes.

Deploy the configuration from the repository root:

```bash
./setup/stow.sh deploy --package tmux,sesh
```

Both the Linux and macOS default Stow profiles include Sesh. The existing Bash or Zsh package must
also be deployed for its fzfrc. If TPM is not installed yet:

```bash
git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Inside tmux, press **Ctrl+s, r** to reload, then **Ctrl+s, Shift+i** to install plugins. Reload
again after installation. Detach with **Ctrl+s, d** and run `tmux attach` from an initialized Bash
or Zsh shell so tmux refreshes both fzf environment variables. Reloading alone does not refresh
them.

To verify interactively after deployment:

1. Run `tmux new-session -d -s picker-existing` to add a temporary selection target. In that
   session, run `seq 1 200` to provide preview content, then return with **Ctrl+s, Ctrl+l**.
2. Open **Ctrl+s, o**, check the popup and preview, use **Ctrl+u / Ctrl+d** for the list and
   **Ctrl+b / Ctrl+f** for the preview, then cancel with **Esc**. Try **Alt+z**, **Alt+b**, and the
   inherited Alt toggles. Reopen and select `picker-existing` with **Enter**.
3. Reopen SessionX, type `picker-new-session` (an unused name), and press **Enter**. Confirm the
   name with `tmux display-message -p '#S'` and check that the usual shell starts without
   application startup commands.
4. Open **Ctrl+s, s**, inspect its right preview, try the native navigation controls, and cancel
   with **Esc**. Reopen and select `picker-existing`. Resize the terminal below 111 columns so the
   90%-wide popup is narrower than 100 columns; confirm the preview hides.
5. Open **Ctrl+s, Space, o** and **Ctrl+s, Space, s** to check both which-key launchers. Detach and
   reattach from each initialized shell, then use `tmux show-environment FZF_DEFAULT_OPTS_FILE` and
   `tmux show-environment FZF_DEFAULT_OPTS` to check inheritance. Repeat the SessionX scrolling and
   Alt toggle checks with each shell's fzfrc.
6. Switch back to your original session and remove the temporary sessions with
   `tmux kill-session -t '=picker-existing'` and `tmux kill-session -t '=picker-new-session'`.

References: [SessionX configuration](https://github.com/omerxx/tmux-sessionx#configure-%EF%B8%8F)
and [Sesh picker configuration](https://github.com/joshmedeski/sesh#picker-tui).
