# WezTerm shortcuts

`Mod` means `Ctrl+Shift` on Windows/Linux and `Cmd` on macOS. `Alt` means `Option` on macOS.

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
| `Ctrl+Shift+L`         | `Ctrl+Shift+L`         | Debug overlay                  |
| `Ctrl+=` or `-`        | `Cmd+=` or `-`         | Increase or decrease font size |
| `Ctrl+Shift+Arrow`     | `Ctrl+Shift+Arrow`     | Move between panes             |
| `Ctrl+Shift+Alt+Arrow` | `Ctrl+Shift+Alt+Arrow` | Resize panes                   |
| `Ctrl+Shift+Z`         | `Ctrl+Shift+Z`         | Zoom current pane              |
| `Alt+Enter`            | `Option+Enter`         | Toggle fullscreen              |

## Custom shortcuts

| Shortcut    | Action                                                       |
| ----------- | ------------------------------------------------------------ |
| `Mod+\\`    | Split right in the current domain                            |
| `Mod+/`     | Split down in the current domain                             |
| `Mod+A`     | Select a pane                                                |
| `Mod+E`     | Enter pane resize mode                                       |
| `Mod+O`     | Open the launcher for domains, profiles, and workspaces      |
| `Mod+Alt+N` | Open a new window in the current pane's domain and directory |
| `Mod+D`     | Detach the current domain                                    |
| `Mod+W`     | Close the focused pane with confirmation                     |

In resize mode, `h`, `j`, `k`, and `l` resize by three cells. Press `Enter` or `Escape` to exit; the
mode also expires after five seconds.

## Workspaces and current directory

WezTerm calls its session-like grouping a **workspace**. A workspace groups windows and can be
selected from the `Mod+O` launcher. It is live mux state, not a saved snapshot that this config
restores after WezTerm exits. With `SSHMUX`, `Mod+D` detaches the remote domain; its panes stay
available to attach again later. See the
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
