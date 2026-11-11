# Windows Terminal migration

Two independent configurations share the same appearance, shortcuts, shell profiles, launch size,
and English UI. Their notification settings differ to match the supported Terminal version:

| Edition       | Config                  | Dotter package             | Launch |
| ------------- | ----------------------- | -------------------------- | ------ |
| Stable 1.25   | `settings.json`         | `windows-terminal`         | `wt`   |
| Preview 1.26+ | `settings.preview.json` | `windows-terminal-preview` | `wtp`  |

Stable uses silent taskbar flashing. Preview adds Notification Center toasts and OSC777 support.
Keep shared preferences aligned when editing the two files; they are ordinary Terminal JSON files.

## What carries over

| WezTerm preference                | Windows Terminal mapping                                       |
| --------------------------------- | -------------------------------------------------------------- |
| duskfox                           | Embedded Duskfox scheme, including cursor and selection colors |
| FiraCode Nerd Font Medium, 14     | `font.face`, `weight`, `size`; the same 14 OpenType features   |
| Natural line height               | Native font cell metrics; no cell-height override              |
| Padding 10 horizontal, 8 vertical | `padding: "10, 8, 10, 8"`                                      |
| Opaque background                 | `opacity: 100`, `useAcrylic: true`                             |
| 10,000 history lines              | `historySize: 10000`                                           |
| Bar cursor                        | `cursorShape: "bar"`                                           |
| Copy on selection                 | `copyOnSelect: true`; existing plain-text copying retained     |
| Visible tabs                      | `alwaysShowTabs: true`                                         |

The font must already be installed; the repository's Scoop setup includes it. Font rasterization and
apparent size can differ between DirectWrite and WezTerm even with matching numeric settings.
Copy-on-select also makes right-click paste immediately. Open hyperlinks with Ctrl+click.

## Startup, notifications, and titles

New windows request 256 columns by 128 rows and open centered in normal window mode. These are
terminal cells, not pixels; Windows may constrain the actual size to fit the monitor. The Terminal
interface uses English (`en-US`); this does not change the Windows keyboard layout or shell locale.
Azure Cloud Shell and WSL profile discovery are disabled through `disabledProfileSources`. Both
`Windows.Terminal.Wsl` and `Microsoft.WSL` are disabled to cover legacy discovery and newer
WSL-provided profiles. Distro names and GUIDs do not belong in the shared profile list.

Press `Ctrl+Shift+O` to open an fzf picker of this PC's installed WSL distributions. Enter launches
the selected distro in its Linux home directory in that tab; Escape cancels and closes the tab. The
picker runs `wsl.exe --list --quiet` each time, so no distro names are stored in the config. It
requires PowerShell 7, fzf, and the `powershell` Dotter package, which deploys
`~/.config/powershell/Select-WslDistribution.ps1`. The command palette remains on `Ctrl+Shift+P`.

In Preview, application BEL events flash the taskbar and send a Windows toast through
`bellStyle: ["taskbar", "notification"]`, without a terminal bell sound. Native toast notifications
require Terminal Preview 1.26 or later; stable 1.25 does not support the `notification` value.
Windows controls whether to show a banner and retain it in Notification Center. Enable notifications
for Windows Terminal Preview in Windows Settings, including showing them in Notification Center.
Stable uses `bellStyle: "taskbar"` and omits the unsupported OSC777 setting, so it has no native
Notification Center notifications.

For silent toasts, also turn off **Play a sound when a notification arrives** under Windows
Settings > System > Notifications > Windows Terminal Preview. The toast has its own Windows sound,
independent of Terminal's bell sound.

To keep banners visible longer, use Settings > Accessibility > Visual effects > Dismiss
notifications after this amount of time. Ordinary Terminal toasts do not support staying on screen
until clicked: Terminal emits the default toast scenario and exposes no reminder-scenario setting.
Enable **Show notifications in notification center** to keep alerts accessible with Win+N after
their banners disappear; repeated Terminal notifications can replace earlier entries.

`compatibility.allowOSC777: true` also lets applications send notifications with a custom title and
message. Bell-to-toast conversion works for applications that only beep, without a separate notifier
script. Notifications are suppressed while the Terminal window is focused and are rate-limited;
repeated notifications can replace an earlier entry. To test, run the command below in Preview and
switch to another application before the delay ends:

```powershell
Start-Sleep -Seconds 3; [Console]::Write([char]7)
```

This test must be checked in the desktop session; config validation alone cannot verify delivery.
See the [1.26 release notes](https://github.com/microsoft/terminal/releases/tag/v1.26.2734.0).

Applications can update tab titles because `suppressApplicationTitle` is explicitly `false`. A bell
alone does not rename a tab: an application must send a title escape sequence as well. Manually
renaming a tab can override application titles until that custom title is cleared.

See Microsoft's
[startup settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/startup)
and
[bell settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-advanced).

## Shortcuts

| Keys                 | Action                                                                 |
| -------------------- | ---------------------------------------------------------------------- |
| Ctrl+Shift+\\        | Split right using the focused pane's profile                           |
| Ctrl+Shift+/         | Split down using the focused pane's profile                            |
| Ctrl+Shift+Arrow     | Move between panes                                                     |
| Ctrl+Shift+H/J/K/L   | Focus left/down/up/right pane                                          |
| Ctrl+Shift+Alt+Arrow | Resize panes                                                           |
| Ctrl+Shift+Z         | Zoom the focused pane                                                  |
| Ctrl+Shift+W         | Close the focused pane; closes the tab/window when it is the last pane |
| Ctrl+Shift+O         | Pick an installed WSL distribution and launch it in a new tab          |
| Ctrl+Shift+C / V     | Copy / paste                                                           |
| Ctrl+Shift+F / P     | Find / command palette                                                 |

Ctrl+Shift+T duplicates the current tab. Native shortcuts remain available, including Ctrl+Shift+D
for another duplicate-tab binding and Ctrl+Shift+N for a new window. Ctrl+C, Ctrl+V, and Enter pass
through to applications as in the previous Terminal config. Shortcuts involving punctuation should
be checked with your active Windows keyboard layout.

The command palette includes labels such as `User | Pane: Split right`,
`User | Window: New window`, and `User | Edit: Copy`. Stable and Preview share the same configured
actions and bindings. `Ctrl+Tab` and `Ctrl+Shift+Tab` retain native tab navigation.

Plain `Ctrl+a` passes through to tmux. When tmux is running, these terminal shortcuts still act on
Windows Terminal's panes and tabs; use `Ctrl+a` followed by the tmux key for actions inside tmux.
See the [tmux shortcut comparison](../../wezterm/README.md#relationship-to-tmux-and-windows-terminal).

## Compatibility limits

- **Remote sessions:** duplicate splits reuse a Terminal profile. They cannot discover an SSH
  command entered interactively or inherit its remote environment. Terminal does not implement
  WezTerm SSHMUX, domain detach/reattach, or its Lua workspace/status callbacks. Use your existing
  tmux or Zellij inside WSL/SSH when persistent sessions are needed.
- **Directories:** duplicating a profile does not clone shell state. Directory inheritance needs
  shell integration that reports the working directory (OSC 9;9). Existing shells may not report it;
  otherwise expect the profile's starting directory. WSL paths need appropriate translation.
- **Keyboard protocol:** Terminal 1.25 supports Kitty keyboard negotiation natively. The old
  Ctrl+Space `sendInput` action has been removed, and Ctrl+Space is explicitly unbound at the
  Terminal level so it reaches the application. Apps that negotiate Kitty input receive the
  appropriate modified-key encoding; legacy apps retain native input. No global Shift+Enter
  escape-sequence override is needed. Older shells, SSH paths, and multiplexers may still limit what
  reaches an application. Recheck completion and modified Enter after upgrading.
- **Cursor:** the bar fallback maps directly, but this version has no profile `cursorBlink` setting.
  Blink behavior follows the terminal/system and application control sequences; a steady cursor is
  not guaranteed. Mode switching still needs shell/editor support.
- **Panes and tabs:** WezTerm's timed h/j/k/l resize table, numbered pane picker, per-pane close
  confirmation, tab index display, hidden new-tab button, and exact tab width have no equivalent
  configured here. Use arrow or Ctrl+Shift+H/J/K/L bindings for pane navigation. Ctrl+Shift+W can
  close a running process without WezTerm's confirmation. Ctrl+Shift+Q/S/E/D, Ctrl+Shift+Alt+S, and
  Ctrl+Shift+Alt+N are not remapped to approximate these behaviors.

## Performance choices and diagnosis

`rendering.software: false` lets Terminal use Windows' default display adapter, including a software
adapter on systems without a hardware GPU. Terminal 1.25 has no separate fallback-only switch. Its
renderer recognizes software adapters and selects its Direct2D backend automatically in that case.
This is not a guarantee of recovery from every driver failure. If a problematic driver still
prevents rendering, set `rendering.software` to `true` temporarily to force WARP, then restart
Terminal. Keeping that switch false normally preserves hardware acceleration when it is available.
See the
[1.25 renderer implementation](https://github.com/microsoft/terminal/blob/v1.25.2733.0/src/renderer/atlas/AtlasEngine.r.cpp).

Terminal 1.25.2733.0 includes faster app-catalog queries on supported Windows versions, lower DWM
memory use per window, fixes for rendering lag after resume and some GPU memory leaks, and removal
of the new-tab animation that made the app appear slower. These improvements come from the binary
upgrade and require no additional settings. Native Kitty input also replaces the hardcoded key
workaround. Layout and scrollback persistence remain opt-in; this config does not enable saving
terminal history to disk on exit.

The 10,000-line history matches WezTerm and is bounded per session; memory grows with pane count and
content. If high-output workloads become sluggish, compare 1,000 history lines temporarily.
Ligatures and stylistic sets are retained for readability. Disable font features temporarily only to
isolate a font/shaping issue. Animations and native prompt marking retain their defaults: no
evidence here establishes that they are causing latency.

To distinguish terminal overhead from shell startup, compare a new `pwsh.exe -NoLogo -NoProfile`
session against your normal profile. For redraw problems, compare the same Neovim/TUI workload in
both terminals at the same window size, with one pane, the same font, and the same shell. Run the
output workload more than once and compare CPU/GPU use, responsiveness, and elapsed time. No GUI
benchmark or visual parity check has been performed by this migration.

## Deployment

The two packages target Scoop's portable stable and Preview editions. Install either or both:

```powershell
scoop install extras/windows-terminal
scoop install versions/windows-terminal-preview
# If already installed through Scoop:
scoop update windows-terminal
scoop update windows-terminal-preview
```

The Scoop manifests enable portable mode and persist their `settings` directories. Dotter targets
`%SCOOP%\persist\windows-terminal\settings\settings.json` for stable and
`%SCOOP%\persist\windows-terminal-preview\settings\settings.json` for Preview. Both survive
version-directory changes and can coexist with separate settings. The repository's PowerShell
profile initializes `SCOOP` from the installed Scoop command when it is unset, preserving an
existing value. Reopen PowerShell after deploying the profile. To reload just the environment
defaults in an already configured session:

```powershell
. .\powershell\.config\powershell\env.ps1
```

Both packages are included in Dotter's `all` profile; first deployment reports any existing
unmanaged settings file as a conflict. Back up that file before replacing it with a managed link.
Only `settings.json` is linked, leaving portable state files outside the repository. Launch the
Scoop Start menu shortcut for the desired edition. Scoop provides `wt` for stable and `wtp` for
Preview; check `Get-Command wt -All` if the old Store edition still opens.

Portable Terminal cannot be registered as Windows' default terminal application. Store/MSIX Terminal
can; it can coexist with Scoop, but uses separate settings and receives separate updates. Scoop's
manifest also offers optional context-menu registration, which is distinct from default-terminal
registration.

The previous path,
`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`, belongs
to the Store edition. `Microsoft.WindowsTerminal_8wekyb3d8bbwe` is its package family name:
`Microsoft.WindowsTerminal` identifies the app and `8wekyb3d8bbwe` is Microsoft's publisher ID,
derived from its publisher identity. It is not a machine ID, version, or random folder chosen by
this repository. The Store config and the separate unpackaged Anaconda settings file remain separate
from Scoop's portable settings.

Preview either deployment with:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Package windows-terminal -WhatIf
pwsh -NoProfile -File .\setup\dotter.ps1 -Package windows-terminal-preview -WhatIf
```

Remove `-WhatIf` to deploy. Deployment is additive: either package leaves the other edition
deployed. To deploy both at once, use `-Package windows-terminal,windows-terminal-preview`. Include
`powershell` when deploying the WSL picker helper:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Package 'powershell,windows-terminal-preview'
```

To apply a Preview copy without enrolling it in Dotter, run from the repository root:

```powershell
$target = Join-Path $env:SCOOP 'persist\windows-terminal-preview\settings\settings.json'
if (Test-Path -LiteralPath $target) {
  $backup = "$target.before-wezterm-migration-$(Get-Date -Format yyyyMMdd-HHmmss).bak"
  Copy-Item -LiteralPath $target -Destination $backup -ErrorAction Stop
}
New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
Copy-Item -LiteralPath .\windows\terminal\settings.preview.json -Destination $target -Force -ErrorAction Stop
```

This copy remains an unmanaged file. To enroll it in Dotter later, move it aside after backing it
up, then deploy the `windows-terminal-preview` package. For a stable copy, use `settings.json` and
the `persist\windows-terminal\settings` destination instead. Do not force Dotter to overwrite an
unmanaged file.

After deployment, reopen Terminal and check: no settings warning, correct duskfox colors and icons,
copy/paste, both splits, pane navigation, PowerShell completion, WSL startup, and Neovim
insert/normal cursor transitions. Settings usually reload automatically, but new sessions are needed
for shell startup changes. The backup is also the rollback source.
