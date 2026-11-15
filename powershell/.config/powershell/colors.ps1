# ~/.config/powershell/colors.ps1
# Terminal color defaults and theme references, matching Bash and Zsh.
#
# Theme settings:
#   vivid / LS_COLORS: iceberg-dark (override with $env:VIVID_THEME).
#   bat: gruvbox-dark, in the shared bat/config (deployed to $env:APPDATA/bat).
#   fzf: highlight #2dd4bf, in ~/.config/powershell/fzfrc.
#   Starship: shared ~/.config/starship.toml.
#   Terminal palette: configured by the terminal, not by this profile.
# Native Get-ChildItem uses $PSStyle.FileInfo, not vivid's LS_COLORS.

if ($env:NO_COLOR -or $env:TERM -eq 'dumb') {
  return
}

# Preserve terminal-provided values and existing color overrides.
if (-not $env:COLORTERM) { $env:COLORTERM = 'truecolor' }
if (-not $env:TERM) { $env:TERM = 'xterm-256color' }
if (-not $env:CLICOLOR) { $env:CLICOLOR = '1' }
if (-not $env:CARGO_TERM_COLOR) { $env:CARGO_TERM_COLOR = 'auto' }

if (-not $env:VIVID_THEME) { $env:VIVID_THEME = 'iceberg-dark' }

# Match ble.sh's Iceberg syntax, suggestion, and selection colors.
# Applied after PSReadLine is imported by conf.d/00-psreadline.ps1.
$psReadLineColors = @{
  Default          = "`e[38;2;198;200;209m"
  Command          = "`e[38;2;226;164;120m"
  String           = "`e[38;2;180;190;130m"
  Variable         = "`e[38;2;226;164;120m"
  Parameter        = "`e[38;2;173;160;211m"
  Keyword          = "`e[38;2;132;160;198m"
  Type             = "`e[38;2;132;160;198m"
  Number           = "`e[38;2;132;160;198m"
  Operator         = "`e[38;2;173;177;196m"
  Member           = "`e[38;2;173;160;211m"
  Comment          = "`e[38;2;107;112;137m"
  Error            = "`e[38;2;22;24;33;48;2;226;120;120m"
  Emphasis         = "`e[1;38;2;137;184;194m"
  Selection        = "`e[38;2;198;200;209;48;2;61;66;91m"
  InlinePrediction = "`e[38;2;130;133;151;48;2;30;33;50m"
}

# ripgrep has an independent palette; user arguments can override these defaults.
$ripgrepColorOptions = @(
  '--color=auto',
  '--colors=path:fg:cyan',
  '--colors=line:fg:green',
  '--colors=column:fg:green',
  '--colors=match:fg:red',
  '--colors=match:style:bold'
)

# Preserve safe ANSI colors in standalone less sessions, as in Bash.
if (" $env:LESS " -notmatch ' (?:-R|--RAW-CONTROL-CHARS) ') {
  $env:LESS = "$env:LESS -R".Trim()
}

# vivid provides Windows builds; fd and other LS_COLORS consumers use this palette.
if (-not (Test-Path Env:LS_COLORS) -and (Test-Command vivid)) {
  $vividColors = vivid generate $env:VIVID_THEME 2>$null
  if ($LASTEXITCODE -eq 0) {
    $env:LS_COLORS = $vividColors
  }
  else {
    Write-Warning "$($MyInvocation.MyCommand.Name): vivid generation failed: $env:VIVID_THEME"
  }
  Remove-Variable vividColors
}
