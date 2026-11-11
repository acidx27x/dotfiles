# tmux

## Statusline

The top statusline uses Kanagawa Dragon with Powerline arrows and left-aligned window tabs. Tab
backgrounds cycle through Dragon green, blue, violet, and orange by window number; the active tab
has a bright yellow background, bold text, and a `●` marker. The right side shows only battery and
weather, including temperature in Celsius and location. Weather updates automatically about every 20
minutes; the bar redraws every 5 seconds using cached data. It uses network-based location detection
and requires `curl` and internet access. Powerline arrows require a compatible font, such as
FiraCode Nerd Font.

Press **Ctrl+a, Shift+t** to open Ukiyo's interactive statusline settings menu for colors, modules,
and options. It is also available through **Ctrl+a, Space, Shift+t** in which-key. Keep persistent
settings in the `@ukiyo-*` options in `~/.tmux.conf`; **Ctrl+a, r** reloads them. Set
`@ukiyo-fixed-location` to a city name if network-based detection picks the wrong location. After
changing themes in the menu, reload to restore the custom tab colors.

A second row is always reserved below the tabs for tmux messages, command prompts, and
confirmations. It stays blank when there is no message or prompt.

## Window navigation

- **Alt+n / Alt+p** select the next / previous window, wrapping around.
- **Ctrl+a, Tab** toggles between the current and last-used window.
- **Ctrl+a, &** asks before closing the current window. The confirmation appears below the
  statusline; **y** closes the window and **n** or **Esc** cancels. Exiting a shell normally does
  not ask for confirmation.
- **Ctrl+a, Shift+f** opens tmux-fzf's window switcher directly. Type to filter, then press
  **Enter** to switch; **Esc** cancels. It includes windows from all sessions.
- **Ctrl+a, Space, f** opens the full tmux-fzf launcher with its management menus.

## Floating terminal

**Alt+f** toggles tmux-floax directly, without the prefix. It uses the plugin's default 80% width
and height. Hide it with **Alt+f** and reopen it to continue the same terminal session. **Ctrl+a,
Shift+p** opens its menu for resizing, fullscreen, and embedding the floating window. Requires tmux
3.3 or newer; install through TPM with **Ctrl+a, Shift+i**, then reload.

## Session pickers

The prefix is **Ctrl+a**. Both pickers open in a centered popup, 90% wide and 60% high.

| Keys                 | Action                                       |
| -------------------- | -------------------------------------------- |
| Ctrl+a, o            | Open SessionX                                |
| Ctrl+a, s            | Open Sesh's native picker                    |
| Ctrl+a, L            | Return to the previous session (`sesh last`) |
| Ctrl+a, Space, o / s | Open SessionX / Sesh through which-key       |
| Ctrl+a, F            | Open the tmux-fzf window switcher directly   |

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
**Ctrl+a, L** also provides a way back after a session closes.

Deploy the configuration from the repository root:

```bash
./setup/stow.sh deploy --package tmux,sesh
```

Both the Linux and macOS default Stow profiles include Sesh. The existing Bash or Zsh package must
also be deployed for its fzfrc. If TPM is not installed yet:

```bash
git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Inside tmux, press **Ctrl+a, r** to reload, then **Ctrl+a, Shift+i** to install plugins. Reload
again after installation. Detach with **Ctrl+a, d** and run `tmux attach` from an initialized Bash
or Zsh shell so tmux refreshes both fzf environment variables. Reloading alone does not refresh
them.

To verify interactively after deployment:

1. Run `tmux new-session -d -s picker-existing` to add a temporary selection target. In that
   session, run `seq 1 200` to provide preview content, then return with **Ctrl+a, L**.
2. Open **Ctrl+a, o**, check the popup and preview, use **Ctrl+u / Ctrl+d** for the list and
   **Ctrl+b / Ctrl+f** for the preview, then cancel with **Esc**. Try **Alt+z**, **Alt+b**, and the
   inherited Alt toggles. Reopen and select `picker-existing` with **Enter**.
3. Reopen SessionX, type `picker-new-session` (an unused name), and press **Enter**. Confirm the
   name with `tmux display-message -p '#S'` and check that the usual shell starts without
   application startup commands.
4. Open **Ctrl+a, s**, inspect its right preview, try the native navigation controls, and cancel
   with **Esc**. Reopen and select `picker-existing`. Resize the terminal below 111 columns so the
   90%-wide popup is narrower than 100 columns; confirm the preview hides.
5. Open **Ctrl+a, Space, o** and **Ctrl+a, Space, s** to check both which-key launchers. Detach and
   reattach from each initialized shell, then use `tmux show-environment FZF_DEFAULT_OPTS_FILE` and
   `tmux show-environment FZF_DEFAULT_OPTS` to check inheritance. Repeat the SessionX scrolling and
   Alt toggle checks with each shell's fzfrc.
6. Switch back to your original session and remove the temporary sessions with
   `tmux kill-session -t '=picker-existing'` and `tmux kill-session -t '=picker-new-session'`.

References: [SessionX configuration](https://github.com/omerxx/tmux-sessionx#configure-%EF%B8%8F)
and [Sesh picker configuration](https://github.com/joshmedeski/sesh#picker-tui).
