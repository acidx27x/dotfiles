# Windows Terminal migration

## What carries over

| WezTerm preference                | Windows Terminal mapping                                       |
| --------------------------------- | -------------------------------------------------------------- |
| duskfox                           | Embedded Duskfox scheme, including cursor and selection colors |
| FiraCode Nerd Font Medium, 14     | `font.face`, `weight`, `size`; the same 14 OpenType features   |
| Natural line height               | Native font cell metrics; no cell-height override              |
| Padding 10 horizontal, 8 vertical | `padding: "10, 8, 10, 8"`                                      |
| Opaque background                 | `opacity: 100`, `useAcrylic: true`                             |
| 10,000 history lines              | `historySize: 10000`                                           |
| Bar cursor, silent bell           | `cursorShape: "bar"`, `bellStyle: "none"`                      |
| Copy on selection                 | `copyOnSelect: true`; existing plain-text copying retained     |
| Visible tabs                      | `alwaysShowTabs: true`                                         |

The font must already be installed; the repository's Scoop setup includes it. Font rasterization and
apparent size can differ between DirectWrite and WezTerm even with matching numeric settings.
Copy-on-select also makes right-click paste immediately. Open hyperlinks with Ctrl+click.

## Shortcuts

| Keys                 | Action                                                                 |
| -------------------- | ---------------------------------------------------------------------- |
| Ctrl+Shift+\\        | Split right using the focused pane's profile                           |
| Ctrl+Shift+/         | Split down using the focused pane's profile                            |
| Ctrl+Shift+Arrow     | Move between panes                                                     |
| Ctrl+Shift+Alt+Arrow | Resize panes                                                           |
| Ctrl+Shift+Z         | Zoom the focused pane                                                  |
| Ctrl+Shift+W         | Close the focused pane; closes the tab/window when it is the last pane |
| Ctrl+Shift+O         | Command palette; search for a profile's new-tab action                 |
| Ctrl+Shift+C / V     | Copy / paste                                                           |
| Ctrl+Shift+F / P     | Find / command palette                                                 |

Native shortcuts remain available, including Ctrl+Shift+T for a default-profile tab, Ctrl+Shift+D
for a duplicate tab, and Ctrl+Shift+N for a new window. Ctrl+C, Ctrl+V, and Enter continue to pass
through to applications as in the previous Terminal config. Shortcuts involving punctuation should
be checked with your active Windows keyboard layout.

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
  configured here. Use arrow bindings for pane operations. Ctrl+Shift+W can close a running process
  without WezTerm's confirmation. Ctrl+Shift+A/E/D and Ctrl+Shift+Alt+N are not remapped to
  approximate these behaviors.

## Performance choices and diagnosis

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

This package now targets **Scoop's stable portable Terminal**. Install or update it first:

```powershell
scoop install extras/windows-terminal
# If already installed through Scoop:
scoop update windows-terminal
```

The Scoop manifest enables portable mode and persists its `settings` directory. Dotter targets
`%SCOOP%\persist\windows-terminal\settings\settings.json`, which survives version-directory changes.
The repository's PowerShell profile initializes `SCOOP` from the installed Scoop command when it is
unset, preserving an existing value. Reopen PowerShell after deploying the profile. To reload just
the environment defaults in an already configured session:

```powershell
. .\powershell\.config\powershell\env.ps1
```

The package is included in Dotter's `all` profile; first deployment reports any existing unmanaged
settings file as a conflict. Back up that file before replacing it with a managed link. Only
`settings.json` is linked, leaving portable state files outside the repository. Launch the Scoop
Start menu shortcut, or verify `Get-Command wt -All` to avoid opening the old Store copy by
accident.

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

Preview with:

```powershell
pwsh -NoProfile -File .\setup\dotter.ps1 -Package windows-terminal -WhatIf
```

To apply a copy without enrolling it in Dotter, run from the repository root:

```powershell
$target = Join-Path $env:SCOOP 'persist\windows-terminal\settings\settings.json'
if (Test-Path -LiteralPath $target) {
  $backup = "$target.before-wezterm-migration-$(Get-Date -Format yyyyMMdd-HHmmss).bak"
  Copy-Item -LiteralPath $target -Destination $backup -ErrorAction Stop
}
New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
Copy-Item -LiteralPath .\windows\terminal\settings.json -Destination $target -Force -ErrorAction Stop
```

This copy remains an unmanaged file. To enroll it in Dotter later, move it aside after backing it
up, then deploy the `windows-terminal` package. Do not force Dotter to overwrite an unmanaged file.

After deployment, reopen Terminal and check: no settings warning, correct duskfox colors and icons,
copy/paste, both splits, pane navigation, PowerShell completion, WSL startup, and Neovim
insert/normal cursor transitions. Settings usually reload automatically, but new sessions are needed
for shell startup changes. The backup is also the rollback source.
