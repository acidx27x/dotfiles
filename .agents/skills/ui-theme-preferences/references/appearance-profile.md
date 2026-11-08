# Appearance Profile

Captured from acidx27x's dotfiles and explicit preferences on 2026-11-08. Source paths below are
relative to the dotfiles repository root and provide provenance; the captured guidance does not
require that repository to be present. Existing configs are examples, not requirements for every
app. Explicit preferences take precedence, especially for cursor shapes and animation.

## Theme Families

| Context           | Current choice                                                         | Source                                                                        |
| ----------------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Neovim            | Kanagawa, with Dragon active and Lotus available for light backgrounds | `nvim/.config/nvim/lua/colorscheme/kanagawa-nvim-config.lua`                  |
| Zed               | Kanagawa Dragon; Catppuccin Latte icons                                | `zed/.config/zed/settings.shared.json`                                        |
| Btop              | `kanagawa-dragon`; inherits terminal background                        | `btop/.config/btop/btop.conf`                                                 |
| Lazygit           | Custom dark, Kanagawa-derived colors                                   | `lazygit/.config/lazygit/config.yml`                                          |
| WezTerm           | `duskfox`                                                              | `wezterm/.config/wezterm/appearance.lua`                                      |
| Shell file colors | Vivid `iceberg-dark` default                                           | `zsh/.config/zsh/colors.zsh`, `bash/.config/bash/colors.bash`                 |
| Starship          | Custom `iceberg_dark` palette                                          | `starship/.config/starship.toml`                                              |
| Broot             | Custom Iceberg Dark skin                                               | `broot/.config/broot/skins/iceberg-dark.hjson`                                |
| Bat and Delta     | `gruvbox-dark`; Delta adds custom diff colors                          | `bat/.config/bat/config`, `git/.gitconfig`                                    |
| Atuin             | `catppuccin-mocha-mauve`                                               | `atuin/.atuin/config.toml`, `atuin/.atuin/themes/catppuccin-mocha-mauve.toml` |
| Zellij            | `kanagawa`                                                             | `zellij/.config/zellij/config.kdl`                                            |
| Glow              | Native `dark` style                                                    | `glow/.config/glow/glow.yml`                                                  |

Preserve this mix rather than standardizing existing apps. For an unfamiliar app, choose a suitable
native dark, muted theme first. Use the nearest context above as a reference, with custom colors
only when the native choices fit poorly. A light icon theme or an available light variant does not
change the default preference for a dark application UI.

## Color References

These values come from existing custom mappings. They are useful starting points for an app that
supports per-role colors, not a new universal palette.

| Role                              | Iceberg reference from Starship and Broot | Kanagawa-derived reference from Lazygit            |
| --------------------------------- | ----------------------------------------- | -------------------------------------------------- |
| Dark surface                      | `#161821`, `#1e2132`                      | `#1F1F28` used behind commit markers               |
| Main text                         | `#c6c8d1`                                 | `#DCD7BA`                                          |
| Secondary text or inactive border | `#828597`, `#6b7089`                      | `#6F806E` inactive border                          |
| Selection background              | `#3d425b`; preview match `#444b71`        | `#4e657c`; inactive selection `#3D322B`            |
| Blue accent                       | `#84a0c6`                                 | Use the app's Kanagawa theme roles                 |
| Green or positive                 | `#b4be82`                                 | `#98BB6C`, also the bold active border             |
| Warm highlight                    | `#e2a478`                                 | `#E6C384` searching border; `#C0A36E` options text |
| Red or negative                   | `#e27878`                                 | `#E46876` unstaged changes                         |
| Aqua accent                       | `#89b8c2`                                 | Use the app's Kanagawa theme roles                 |
| Purple accent                     | `#ada0d3`, `#a093c7`                      | Use the app's Kanagawa theme roles                 |

Delta keeps gruvbox-dark syntax with green additions on `#293D32`, red deletions on `#392B30`,
neutral line numbers `#727169`, blue headers `#85A0C7`, and yellow header line numbers `#E6C384`.

Atuin's active custom theme uses text `#cdd6f4`, guidance `#9399b2`, mauve annotations and titles
`#cba6f7`, info `#a6e3a1`, warnings `#fab387`, and errors/important text `#f38ba8`.

Neovim preserves Kanagawa palette roles rather than hardcoding all colors: popup text `oldWhite` on
`dragonBlack0`, floating borders `waveBlue2`, types `dragonOrange2`, constants `carpYellow`,
parameters `waveAqua2`, identifiers `sakuraPink`, statements `dragonAqua`, comments `fujiGray`,
errors `waveRed`, and warnings `surimiOrange`. Diagnostics and TODO-style annotations are bold and
nonitalic; this does not establish a global ban on italics.

## Typography

WezTerm and Zed share `FiraCode Nerd Font` and enable these features:

```text
calt cv01 cv02 ss01 cv13 cv14 ss05 ss04 cv18 cv16 cv29 cv30 ss06 ss10
```

Preserve supported feature choices when reproducing this typography. Use the app's own feature
syntax. Nerd Font glyphs are used for files, folders, completion kinds, Git status, and prompts.

| Context                     | Current size and other details                                                  |
| --------------------------- | ------------------------------------------------------------------------------- |
| WezTerm                     | Size 14; Medium weight; line height 1.0; padding 10 left/right and 8 top/bottom |
| Zed editor                  | Buffer size 15.5; grayscale text rendering                                      |
| Zed UI and Markdown preview | Size 14.5; UI also uses FiraCode Nerd Font                                      |
| Zed auxiliary text          | Commit buffers, agent text, and integrated terminal use size 13.5               |

These are per-app references. Do not assume font sizes have identical units across apps or apply the
terminal's Medium weight to every UI.

## Borders, Focus, and Information

- Rounded borders recur in Neovim floating windows and fzf-lua, Lazygit, and Btop. Zed deliberately
  uses square text selections; Zellij disables pane frames while retaining tab and status bars in
  its custom layout. These choices apply to different surfaces.
- Neovim dims inactive windows. Zed uses active-pane border size 2.0 and inactive opacity 0.85.
  Lazygit differentiates active, inactive, and searching borders and selected rows.
- WezTerm keeps its fancy tab bar visible even with one tab, shows tab indices, and hides the
  new-tab button. Neovim keeps tab and per-window status lines visible. Avoid inferring a preference
  to hide all application chrome.
- Zed keeps breadcrumbs and useful status indicators while hiding menus and several toolbar actions.
  Completion documentation is not shown automatically in either Zed or Neovim.
- Neovim and Zed use relative line numbers, unwrapped editor text, and a 120-column reference. Zed
  shows boundary whitespace and differentiated indent guides. Apply these to editing contexts only.
- Shell fzf configs use a reverse layout, inline information, highlighted rows, a teal match accent
  `#2dd4bf`, and a right preview around 60% width. Neovim's fzf-lua uses a centered 80% window with
  rounded borders. Keep these dimensions contextual.
- WezTerm uses background opacity 1.0; Neovim popup and floating-window blend values are 0 (opaque).
  Btop disables its theme background to inherit the terminal surface. WezTerm's blur/Acrylic
  settings do not independently establish a preference for translucent windows.

Sources: `wezterm/.config/wezterm/appearance.lua`, `nvim/.config/nvim/lua/core/options.lua`,
`nvim/.config/nvim/lua/plugins/mini-statusline-config.lua`,
`nvim/.config/nvim/lua/plugins/mini-tabline-config.lua`,
`nvim/.config/nvim/lua/plugins/fzf-lua-config.lua`,
`nvim/.config/nvim/lua/lsp/blink-cmp-config.lua`, `zed/.config/zed/settings.shared.json`,
`zsh/.config/zsh/fzfrc`, `bash/.config/bash/fzfrc`, `powershell/.config/powershell/fzfrc`,
`zellij/.config/zellij/config.kdl`, `zellij/.config/zellij/layouts/custom.kdl`, and the Lazygit/Btop
sources above.

## Current Cursor and Motion Evidence

The authoritative cursor and motion preferences are in `SKILL.md`. The following records active
settings and implementation differences; it is not a list of preferences or fixes to apply.

- **WezTerm:** `default_cursor_style = "SteadyBar"` in `wezterm/.config/wezterm/terminal.lua`. The
  fallback was corrected from `SteadyBlock`; its steady behavior was preserved. This is not a rule
  for future apps and does not implement mode switching.
- **Zsh:** `zsh/.config/zsh/conf.d/01-vi-mode.zsh` enables cursor styling, uses a beam for insert
  and a block for normal, but uses underlines for visual, visual-line, and operator-pending modes.
  Those underlines conflict with the stated block preference for other modes.
- **Neovim:** The inherited default includes `n-v-c-sm:block`, `i-ci-ve:ver25`, and `r-cr-o:hor20`.
  The main insert/normal distinction matches; replace and operator-pending horizontal lines, and the
  visual-exclusive bar, are implementation differences. `nvim/.config/nvim/lua/core/options.lua`
  changes terminal mode to `t:ver25-blinkon0-TermCursor`, a steady vertical bar. A clean local
  Neovim invocation confirmed the inherited defaults when this profile was captured.
- **Zed:** `zed/.config/zed/settings.shared.json` explicitly disables editor cursor blinking and
  cursor animation, while integrated-terminal blinking is `"on"`. The user's configuration audit
  found inherited underline cursors in replace mode and a block terminal default unless the shell or
  app overrides it. These inherited shapes are implementation differences, not preferred shapes.
  Check the target version's defaults before configuring them.
- **Bash Readline:** `bash/.inputrc`, for Readline 7.0 and newer, explicitly uses `\e[6 q` for a
  steady insert-mode bar and `\e[2 q` for a steady command-mode block. This records the Readline
  path, not a requirement to force steady cursors or replace an active line editor such as ble.sh.
- **Atuin:** The `keymap_cursor` example in `atuin/.atuin/config.toml` is commented out. It is not
  an active cursor choice and establishes no preference for blinking block cursors in insert mode.
- **Other animation:** Lazygit explicitly enables its explosion animation and configures a spinner.
  These reinforce that existing disabled cursor settings are not a general reduced-motion policy.

Recheck live settings when a task requires them. Preserve blinking and movement animation separately
from shape, and do not change application configs merely to bring this evidence into agreement with
the profile.
