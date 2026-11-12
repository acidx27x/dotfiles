# WezTerm shortcuts

`Mod` means `Ctrl+Shift` on Windows/Linux and `Cmd` on macOS. `Alt` means `Option` on macOS.

Right-click has no terminal clipboard action; applications such as tmux receive it when mouse
reporting is enabled. Use `Mod+V` to paste.

## Useful defaults

| Windows/Linux          | macOS                  | Action                         |
| ---------------------- | ---------------------- | ------------------------------ |
| `Ctrl+Shift+C`         | `Cmd+C`                | Copy selection                 |
| `Ctrl+Shift+V`         | `Cmd+V`                | Paste                          |
| `Ctrl+Shift+T`         | `Cmd+T`                | New tab                        |
| `Ctrl+Shift+N`         | `Cmd+N`                | New window                     |
| `Ctrl+Shift+W`         | `Cmd+W`                | Close tab (overridden below)   |
| `Ctrl+Shift+F`         | `Cmd+F`                | Search                         |
| `Ctrl+Shift+X`         | `Ctrl+Shift+X`         | Copy mode                      |
| `Ctrl+Shift+Space`     | `Ctrl+Shift+Space`     | Quick select                   |
| `Ctrl+Shift+P`         | `Ctrl+Shift+P`         | Command palette                |
| `Ctrl+=` or `-`        | `Cmd+=` or `-`         | Increase or decrease font size |
| `Ctrl+Shift+Arrow`     | `Ctrl+Shift+Arrow`     | Move between panes             |
| `Ctrl+Shift+Alt+Arrow` | `Ctrl+Shift+Alt+Arrow` | Resize panes                   |
| `Ctrl+Shift+Z`         | `Ctrl+Shift+Z`         | Zoom current pane              |
| `Alt+Enter`            | `Option+Enter`         | Toggle fullscreen              |

## Custom shortcuts

| Shortcut             | Action                                                       |
| -------------------- | ------------------------------------------------------------ |
| `Mod+\\`             | Split right in the current domain                            |
| `Mod+/`              | Split down in the current domain                             |
| `Ctrl+Shift+Q`       | Select a pane using the overlay (all platforms)              |
| `Ctrl+Shift+H/J/K/L` | Focus left/down/up/right pane (all platforms)                |
| `Mod+S`              | Select a workspace                                           |
| `Mod+Alt+S`          | Create or switch to a named workspace                        |
| `Alt+Shift+H/J/K/L`  | Resize left/down/up/right pane (all platforms)               |
| `Mod+E`              | Enter pane resize mode                                       |
| `Mod+O`              | Open the launcher for domains, profiles, and workspaces      |
| `Mod+Alt+N`          | Open a new window in the current pane's domain and directory |
| `Mod+D`              | Detach the current domain                                    |
| `Mod+W`              | Close the focused pane with confirmation                     |

In resize mode, `h`, `j`, `k`, and `l` resize by three cells. Press `Enter` or `Escape` to exit; the
mode also expires after five seconds.

`Ctrl+Shift+H/J/K/L` complements the arrow bindings. K and L replace the clear-scrollback and
debug-overlay shortcuts; those actions remain in the command palette. The pane picker moves from
`Mod+A` to `Ctrl+Shift+Q`. On macOS, these movement and picker shortcuts use `Ctrl+Shift`,
preserving native `Cmd+H` and `Cmd+Q` behavior. `Ctrl+Tab` and `Ctrl+Shift+Tab` retain native tab
navigation.

The command palette includes named entries such as `User | Pane: Split right`,
`User | Window: New window`, `User | Edit: Copy`, and `User | Workspace: Switch`. These entries
reuse the shortcut actions; built-in palette entries remain available.

## Relationship to tmux and Windows Terminal

The terminal shortcuts act immediately, without a prefix. tmux retains `Ctrl+a` followed by a key.
When tmux runs inside a terminal, terminal shortcuts operate on the outer terminal's panes and tabs;
use `Ctrl+a` for tmux's panes, windows, and sessions. Plain `Ctrl+a` is not a terminal binding.

| Action                        | tmux (after `Ctrl+a`) | WezTerm / Windows Terminal (Windows/Linux)                   |
| ----------------------------- | --------------------- | ------------------------------------------------------------ |
| Split right / down            | `\|` / `-`            | `Ctrl+Shift+\` / `Ctrl+Shift+/`                              |
| Focus pane                    | `h/j/k/l`             | `Ctrl+Shift+H/J/K/L` or `Ctrl+Shift+Arrow`                   |
| Select pane by overlay        | `q`, then pane number | `Ctrl+Shift+Q` in WezTerm; no overlay in Windows Terminal    |
| Zoom pane                     | `z`                   | `Ctrl+Shift+Z`                                               |
| New window / tab              | `c`                   | `Ctrl+Shift+T`                                               |
| Previous / next window or tab | `p` / `n`             | `Ctrl+Shift+Tab` / `Ctrl+Tab`                                |
| Close pane                    | `x` (confirmation)    | `Ctrl+Shift+W` (confirmation in WezTerm)                     |
| Select session / workspace    | `s` (sesh picker)     | `Ctrl+Shift+S` in WezTerm; no equivalent in Windows Terminal |

Windows Terminal's new tab uses its default profile; WezTerm's uses the current pane's domain. See
the [Windows Terminal shortcuts and limits](../windows/terminal/README.md#shortcuts).

## Workspaces and current directory

WezTerm calls its session-like grouping a **workspace**. A workspace groups windows and can be
selected with `Mod+S` or from the `Mod+O` launcher. `Mod+Alt+S` prompts for a name: a new name
creates a workspace using the default program/domain, and an existing name switches to it. Escape or
an empty name leaves the current workspace unchanged. It is live mux state, not a saved snapshot
that this config restores after WezTerm exits. With `SSHMUX`, `Mod+D` detaches the remote domain;
its panes stay available to attach again later. See the
[workspace guide](https://wezterm.org/recipes/workspaces.html) and
[DetachDomain](https://wezterm.org/config/lua/keyassignment/DetachDomain.html).

`Mod+T` (the default new-tab shortcut) and custom `Mod+Alt+N` use the current pane's domain. The
custom split shortcuts do too. WezTerm can use the current directory when it can determine the
pane's cwd; shell integration reports it with OSC 7. Without a reported or otherwise detectable cwd,
WezTerm falls back to that domain's default cwd or the user's home directory. See
[default cwd](https://wezterm.org/config/lua/config/default_cwd.html) and
[shell integration](https://wezterm.org/shell-integration.html).

- **WSL:** Start the tab in a WSL domain. WezTerm's WSL domain supports tracking the Linux shell's
  cwd for new tabs and panes.
- **SSH multiplexing (`SSHMUX:host`):** New tabs and windows stay in that remote WezTerm domain and
  use its remote cwd.
- **Plain SSH (`SSH:host`):** The remote shell must emit OSC 7, and the host alias must be listed in
  `UNIX_HOSTS` so WezTerm can respawn a shell in that remote directory. This setting only applies to
  plain SSH domains.

For a new window in the default domain, use `Ctrl+Shift+N` on Windows/Linux or `Cmd+N` on macOS. For
one in the current domain, use `Mod+Alt+N`.

## Machine-specific settings

Edit `wezterm/.config/wezterm/local_settings.lua` in the dotfiles checkout to set machine-specific
options. The file is ignored by Git, so its contents stay on that machine. A clean checkout works
without it.

For example, uncomment and edit just the options you need:

```lua
local settings = {
  DEFAULT_WSL_DISTRO = "Ubuntu-24.04",
  WSL_ALIASES = {
    ["Ubuntu-24.04"] = "WSL:Ubuntu Dev",
  },
  UNIX_HOSTS = { "devbox" },
  DEFAULT_PROG = {
    windows = { "pwsh.exe", "-NoLogo" },
    linux = { "/usr/bin/fish", "-l" },
    macos = { "/opt/homebrew/bin/fish", "-l" },
  },
  SSH_DOMAIN_OVERRIDES = {
    ["SSHMUX:devbox"] = {
      remote_wezterm_path = "/usr/local/bin/wezterm",
      local_echo_threshold_ms = 20,
    },
  },
}

return settings
```

Remove the example entries you do not need. `DEFAULT_WSL_DISTRO` is the exact distro name from
`wsl -l -v`. `WSL_ALIASES` overrides only the listed distro names; aliases for other distros remain
unchanged. `DEFAULT_PROG` accepts a command and its arguments for each platform, and omitted
platforms keep their built-in shell.

For SSH, `UNIX_HOSTS` entries are aliases from your SSH config's `Host` lines. They enable
`assume_shell = "Posix"` only for the matching plain `SSH:<alias>` domain, not SSHMUX domains.
`SSH_DOMAIN_OVERRIDES` uses the exact generated domain name, such as `SSH:devbox` or
`SSHMUX:devbox`, and supports `remote_wezterm_path` and `local_echo_threshold_ms`.

Stow deploys the local file with the WezTerm config files; run its `restow` action if you create the
file after deploying. The Windows Dotter mapping covers the config directory, so it includes the
file when present. Reload WezTerm's configuration after editing it.

The README stays in the Stow package as documentation; Dotter maps only `.config/wezterm`, so it
does not deploy this README.
