# tmux

## Statusline

The top statusline uses Kanagawa Dragon with Powerline arrows and left-aligned window tabs. Tab
backgrounds cycle through Dragon green, blue, violet, and orange by window number; the active tab
has a bright yellow background, bold text, and a `●` marker. The right side shows only battery and
weather, including temperature in Celsius and location. Weather updates automatically about every 20
minutes; the bar redraws every 30 seconds using cached data. It uses network-based location
detection and requires `curl` and internet access. Powerline arrows require a compatible font, such
as FiraCode Nerd Font.

Press **Ctrl+b, Shift+t** to open Ukiyo's interactive statusline settings menu for colors, modules,
and options. It is also available through **Ctrl+b, Space, Shift+t** in which-key. Keep persistent
settings in the `@ukiyo-*` options in `~/.tmux.conf`; **Ctrl+b, r** reloads them. Set
`@ukiyo-fixed-location` to a city name if network-based detection picks the wrong location. After
changing themes in the menu, reload to restore the custom tab colors.

Windows with background activity show a `!` marker in their tab.

Workmux's working, waiting, and done symbols appear after the window name. The custom tab format
reads `@workmux_status` directly, matching `status_format: false` in the Workmux configuration.
Agent status still requires Workmux's agent hooks to be installed.

Shell commands that run longer than 10 seconds and finish in a background window show `✓` for
success or `✗` for failure. The marker clears when you visit that window, switch to its session, or
attach to it. This also covers commands in detached sessions; the existing `!` still means output
activity. Timing covers foreground shell commands and pipelines, including silent commands; jobs
launched with `&` are not tracked after the prompt returns.

Deploy the Bash or Zsh package with tmux, then start a new shell inside tmux (or reload its shell
configuration) to enable command tracking. Bash uses ble.sh or bash-preexec hooks; Zsh uses its
native preexec/precmd hooks. Reload tmux with **Ctrl+b, r** to update the tab format and clearing
hooks.

A second row is always reserved below the tabs for tmux messages, command prompts, and
confirmations. It shows a dim horizontal separator when there is no message or prompt.

## Plugin commands in which-key

Press **Ctrl+b, Space** to open which-key, then use:

| Keys         | Action                                                |
| ------------ | ----------------------------------------------------- |
| s            | SessionX picker                                       |
| Ctrl+l       | Previous session                                      |
| f            | Full tmux-fzf launcher                                |
| g            | Lazygit popup                                         |
| w, f         | tmux-fzf window picker                                |
| a            | Workmux dashboard, sidebar, and agent navigation      |
| m, h/j/k/l   | Smart Splits movement through the existing Alt keys   |
| m, H/J/K/L   | Smart Splits resizing through the existing Alt arrows |
| b, s / r     | Resurrect save / restore                              |
| P, i / u / c | TPM install / update / remove unused plugins          |
| T            | Ukiyo statusline settings                             |

Continuum saves and restores automatically; manual snapshots use the Backup menu. Reload with
**Ctrl+b, r** after editing the menu configuration.

## Lazygit

Press **Ctrl+b, g** or **Ctrl+b, Space, g** to open Lazygit in a 90% × 90% popup, starting in the
current pane's directory. Press **q** to quit Lazygit and close the popup. Requires `lazygit` on
tmux's `PATH`. Reload with **Ctrl+b, r** after deploying the configuration.

Based on
[jjasghar's popup binding](https://gist.github.com/jjasghar/d39f322a76732c42f9a3d1a8bdeecf10) and
[kesoji's tmux configuration](https://github.com/kesoji/dotfiles/blob/master/tmux.conf).

## Workmux

Workmux integration requires `workmux` on tmux's PATH. The dashboard opens in a 90% × 80% popup on
the Worktrees tab, including worktrees that only have shell panes.

| Keys           | Which-key sequence  | Action                    |
| -------------- | ------------------- | ------------------------- |
| Ctrl+b, Ctrl+s | Ctrl+b, Space, a, d | Dashboard (Worktrees tab) |
| Ctrl+b, Ctrl+t | Ctrl+b, Space, a, s | Toggle sidebar            |
| Ctrl+b, Ctrl+j | Ctrl+b, Space, a, j | Next agent                |
| Ctrl+b, Ctrl+k | Ctrl+b, Space, a, k | Previous agent            |

The sidebar is opt-in and shows agents across sessions by default, grouped by project using the
Workmux config. Toggling it does not start an agent. Next/previous navigation cycles agents and
follows the active sidebar filter; use SessionX or the dashboard for shell-only worktrees.

Focus the sidebar with the existing pane navigation or mouse. Inside it, use **j/k** to browse,
**Enter** to focus an agent, and **f** to toggle the current-session filter. Leave that filter off
to navigate agents across worktrees when each worktree has its own session.

Reload with **Ctrl+b, r** after deploying these changes. The Workmux config still opens one shell by
default; use `workmux add <branch> -l agent` to explicitly start Codex.

## Window navigation

- **Alt+n / Alt+p** select the next / previous window, wrapping around.
- **Alt+i / Alt+o** move the current window left / right, keeping it focused, without a prefix.
- **Ctrl+b, Tab** toggles between the current and last-used window.
- **Ctrl+b, &** asks before closing the current window. The confirmation appears below the
  statusline; **y** closes the window and **n** or **Esc** cancels. Exiting a shell normally does
  not ask for confirmation.
- **Ctrl+b, Shift+f** opens tmux-fzf's default category/action launcher in a 90% × 80% popup.
  Windows, panes, commands, keybindings, and clipboard are available.
- **Ctrl+b, Space, f** opens the same launcher. **Ctrl+b, Space, w, f** opens the window switcher
  directly, including windows from all sessions. Type to filter, then press **Enter** to switch;
  **Esc** cancels.

## Copy mode and panes

Press **Ctrl+b, [** or **Ctrl+b, Esc** to enter vi copy mode. Use **v** to begin a selection, **V**
for whole lines, and **Ctrl+v** to toggle rectangular selection. **y** copies without leaving copy
mode; **Esc** cancels and returns to the terminal.

Press **Ctrl+b, ]** to paste the latest tmux buffer directly, or **Ctrl+b, =** to choose an older
buffer and press **Enter** to paste it. Release the prefix before pressing the next key; neither
shortcut needs the right-click menu.

Press **Ctrl+b, H/J/K/L** to resize panes left/down/up/right by five cells. These bindings repeat
without another prefix while pressed within tmux's repeat timeout. Existing Smart Splits Alt-arrow
resizing remains available. **Ctrl+b, < / >** swaps the current pane with the previous / next pane
in pane index order.

## Snapshot picker

Press **Ctrl+b, Shift+b** to browse Resurrect snapshots in a 90% × 80% popup. The list shows
timestamps, session names, and window counts, newest first. A `●` marks the snapshot used by
automatic restore. The preview shows saved windows, panes, and working directories.

- **Ctrl+s** saves the current environment and refreshes the list, even when the list is empty.
- **Tab / Shift+Tab** marks or unmarks a snapshot and moves down or up.
- **Enter** asks before restoring one selected snapshot and makes it the automatic restore target.
  Selecting several snapshots shows a reminder to choose only one.
- **Alt+Backspace** lists the marked snapshots and asks once before deleting them. With no marks, it
  deletes the highlighted snapshot. If the automatic restore target was deleted, the newest
  remaining snapshot becomes the target. Deleting the final snapshot clears that target. Running
  sessions stay open.
- **Esc** closes the picker.

Restoring adds missing sessions, windows, and panes; existing panes stay in place. Start with a
fresh tmux instance to recover an older environment fully. Snapshots cover the whole server, rather
than individual sessions. Resurrect shares captured pane contents between snapshots, so older
layouts do not have independent scrollback backups. This configuration disables restoring programs.

The picker requires `fzf` and the installed Resurrect plugin. It follows Resurrect's snapshot
directory setting and inherits valid fzf preferences. After deploying the tmux package, reload with
**Ctrl+b, r**. Existing manual save and restore shortcuts remain **Ctrl+b, Shift+s** and **Ctrl+b,
Shift+r**.

## Session picker

The prefix is **Ctrl+b**. SessionX opens in a centered popup, 90% wide and 60% high, with a top
preview occupying 60% of the picker and Git branch labels enabled.

| Keys             | Action                                              |
| ---------------- | --------------------------------------------------- |
| Ctrl+b, s        | Open SessionX                                       |
| Ctrl+b, Ctrl+l   | Return to the previous session (`switch-client -l`) |
| Ctrl+b, Space, s | Open SessionX through which-key                     |
| Ctrl+b, F        | Open the default tmux-fzf launcher                  |

SessionX initially lists running sessions. **Enter** switches to the selected session; typing an
unused name and pressing **Enter** creates a session. **Esc** cancels. In the picker:

- **Ctrl+r** renames the highlighted session; **Alt+Backspace** kills it.
- **Alt+z** browses zoxide directories; selecting a directory creates or switches to its session.
- **Alt+b** returns to the session list.
- **Ctrl+w** lists windows; **Ctrl+t** changes the preview to a session/window tree.
- **Ctrl+u / Ctrl+d** scroll the list; **Ctrl+b / Ctrl+f** scroll the preview by half a page.

SessionX and tmux-fzf inherit `FZF_DEFAULT_OPTS_FILE` and `FZF_DEFAULT_OPTS` from the attaching Bash
or Zsh shell, reusing its fzfrc colors and bindings. SessionX uses a reverse layout. The inherited
**Alt+p** toggles the preview, and **Alt+o** changes its orientation.

The previous-session shortcut uses tmux's native last-session tracking and requires the previous
session to still exist. Closing the current session detaches its terminal from tmux instead of
switching it to another session (`detach-on-destroy on`). Sesh remains installed, and its dotfiles
configuration is retained for standalone use; tmux no longer binds it.

The Bash and Zsh `tmux` wrapper opens SessionX when called without arguments outside tmux. Calls
with arguments, calls inside tmux, and calls without the SessionX script installed run tmux
normally. Use `command tmux` to bypass the wrapper. Starting through the picker creates an initial
session, which remains running if you select another session; **Esc** stays in the initial session.

Deploy the configuration from the repository root:

```bash
./setup/stow.sh deploy --package tmux
```

The existing Bash or Zsh package must also be deployed for its fzfrc. SessionX requires `fzf`, with
`zoxide` on `PATH` for directory browsing. If TPM is not installed yet:

```bash
git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Inside tmux, press **Ctrl+b, r** to reload, then **Ctrl+b, Shift+i** to install plugins. Reload
again after installation. Use **Ctrl+b, Space, P, c** to remove unused TPM plugins. If an old
SessionX binding on **Ctrl+b, o** remains on an existing server, run `tmux unbind-key o` once.
Detach with **Ctrl+b, d** and run `tmux attach` from an initialized Bash or Zsh shell so tmux
refreshes both fzf environment variables. Reloading alone does not refresh them.

To verify interactively after deployment:

1. Run `tmux new-session -d -s picker-existing` to add a temporary selection target. In that
   session, run `seq 1 200` to provide preview content, then return with **Ctrl+b, Ctrl+l**.
2. Open **Ctrl+b, s**, check the popup, preview, list scrolling, and inherited Alt toggles, then
   cancel with **Esc**. Reopen and select `picker-existing` with **Enter**. Use **Ctrl+b, Ctrl+l**
   to return to your original session.
3. Open **Ctrl+b, Space, s** to check the which-key launcher. Use **Alt+z** to select a zoxide
   directory without an existing session and confirm that SessionX creates a session there. Test
   creation with an unused session name, and rename it using **Ctrl+r**.
4. Open **Ctrl+b, Shift+f** and confirm the 90% × 80% category launcher appears. Choose `window`,
   then its switch action, and select a window. Check **Ctrl+b, Space, f** and the direct window
   picker at **Ctrl+b, Space, w, f** too.
5. Detach and reattach from each initialized shell, then use
   `tmux show-environment FZF_DEFAULT_OPTS_FILE` and `tmux show-environment FZF_DEFAULT_OPTS` to
   check inheritance.
6. Close a temporary session while attached to it and confirm that tmux detaches rather than
   switching to another session. Reattach and remove any remaining temporary sessions.

References: [SessionX](https://github.com/omerxx/tmux-sessionx#configure-%EF%B8%8F) and
[tmux-fzf](https://github.com/sainnhe/tmux-fzf#customization).
