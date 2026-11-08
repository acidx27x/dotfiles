---
name: ui-theme-preferences
description: >-
  Apply acidx27x's UI theme and appearance preferences when setting up or adjusting existing
  applications through config files. Use for themes, fonts, icons, borders, spacing, focus cues,
  and cursor shapes; not for new website or product UI design.
---

# UI Theme Preferences

Use these preferences as defaults for the requested application's appearance. Explicit user choices
take precedence over this profile and existing configs. Creating or updating this skill does not
authorize changing application configs; the evidence below is not a list of fixes to apply.

## Appearance Preferences

- Prefer dark backgrounds, muted accents, readable light text, and distinct focus, selection,
  diagnostic, and Git colors. Preserve the mix of theme families: Kanagawa Dragon for editors and
  monitoring, Iceberg for shell tools, duskfox for WezTerm, gruvbox-dark for previews and diffs, and
  Catppuccin Mocha Mauve for Atuin. These are contextual references, not a universal theme mandate.
- Prefer FiraCode Nerd Font, programming ligatures, and Nerd Font icons where supported. Preserve
  application-specific icon choices, including Zed's Catppuccin Latte icons with a dark editor
  theme.
- Favor rounded TUI panels and floating windows, clear active selections, and dimmed inactive panes.
  Keep contextual exceptions such as square text selections and borderless Zellij panes.
- Retain useful tabs, status bars, breadcrumbs, Git indicators, and error indicators. Reduce
  redundant controls without turning the UI into a distraction-free layout. Keep editor line
  numbers, guides, and wrapping choices specific to editors.
- Use opaque surfaces where configured and terminal-background inheritance where appropriate. Blur
  settings alone do not establish a preference for transparency.

Read [the appearance profile](references/appearance-profile.md) when choosing a theme family,
mapping colors, reproducing typography or layout details, or checking configuration evidence. It
captures the relevant values so this skill works without access to the original dotfiles.

## Cursor Shapes and Animation

- Prefer a vertical bar or horizontal underline in insert mode. Preserve an established line
  variant; otherwise use a vertical bar.
- Prefer a block cursor in other modes, including normal, visual, replace, and operator-pending
  modes, wherever the app supports configuring them.
- Let shells and terminal applications switch cursor shape according to their active mode. A
  terminal fallback alone cannot implement this rule.
- Treat cursor shape, blinking, and movement animation independently. There is no general preference
  to disable blinking or animation. Preserve existing or native motion settings unless explicitly
  requested.
- Explicitly stated preferences take precedence over existing configs. Record conflicting settings
  as implementation differences, not preferences.

## Apply to an Application

1. Inspect the app's current config, available themes, and supported appearance options. Distinguish
   active settings from comments and inherited defaults; check the current app version when relying
   on defaults or documentation.
2. Prefer a suitable native dark, muted theme using the closest relevant family as a reference. Use
   supported custom color settings when native choices fit poorly. Preserve semantic color roles;
   avoid forcing every app onto one palette or adding dependencies just to reproduce an example.
3. Make appearance changes only within the requested app and scope. Use its native mode-dependent
   cursor settings or existing shell/application cursor support. Do not enable modal editing, alter
   keybindings, or introduce unsupported settings to obtain cursor shapes.
4. Use the app's config validation when available. For cursor changes, check supported mode
   transitions rather than only the terminal fallback. Report unsupported preferences and any
   required reload or restart; do not claim an unobserved visual result was verified.
