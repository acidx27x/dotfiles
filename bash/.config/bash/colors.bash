# Choose a vivid theme before sourcing, for example:
#   export VIVID_THEME=ansi       # terminal-palette friendly
#   export VIVID_THEME=molokai
#
# Disable all configuration from this file:
#   export NO_COLOR=1
#
# This file intentionally uses "auto" color modes wherever possible so that
# redirected output and shell scripts do not receive unwanted ANSI escapes.

# Respect the NO_COLOR convention and unusable terminals.
if [[ -n ${NO_COLOR:-} || ${TERM:-} == dumb ]]; then
  return 0
fi

# Generic convention used by several BSD-style utilities. This enables color
# support without forcing escape sequences into pipes.
export CLICOLOR="${CLICOLOR:-1}"

# ---------------------------------------------------------------------------
# 1. LS_COLORS: vivid palette
# ---------------------------------------------------------------------------

VIVID_THEME="${VIVID_THEME:-iceberg-dark}"

if [[ -z ${LS_COLORS+x} ]]; then
  if has-cmd vivid; then
    if __vivid_colors="$(vivid generate "$VIVID_THEME" 2>/dev/null)"; then
      export LS_COLORS="$__vivid_colors"
    else
      printf 'WARNING, colors.bash: vivid theme not found: %s\n' "$VIVID_THEME" >&2
    fi
    unset __vivid_colors
  elif has-cmd dircolors; then
    # Fallback when vivid is not installed.
    if __dircolors_output="$(dircolors -b 2>/dev/null)" &&
       eval "$__dircolors_output"
    then
      :
    else
      printf 'WARNING, colors.bash: dircolors init failed\n' >&2
    fi
    unset __dircolors_output
  fi
fi

# These tools read LS_COLORS automatically when available:
#   eza  - reads LS_COLORS/EZA_COLORS; color mode defaults to auto
#   fd   - uses LS_COLORS for file-extension and file-type colors
#   bfs  - automatically colors terminal output according to LS_COLORS
#   tree - reads LS_COLORS/TREE_COLORS; some releases still need -C enabled
#
# ripgrep (rg), grep, bat, fzf, less, man, diff, and ip do NOT derive their
# complete palettes from LS_COLORS. Their setup appears below.

# Do not overwrite an alias already defined by the user unless requested.
BASH_COLOR_OVERRIDE_ALIASES="${BASH_COLOR_OVERRIDE_ALIASES:-0}"

__color_alias() {
  local name=$1 definition=$2
  if [[ $BASH_COLOR_OVERRIDE_ALIASES == 1 ]] || ! alias "$name" >/dev/null 2>&1; then
    alias "$name=$definition"
  fi
}

__color_help_has() {
  local command_name=$1 option=$2
  has-cmd "$command_name" || return 1
  command "$command_name" --help 2>&1 | grep -Fq -- "$option"
}

# ---------------------------------------------------------------------------
# 2. Commands that understand LS_COLORS but need color output enabled
# ---------------------------------------------------------------------------

# GNU ls/dir/vdir need --color=auto. BSD/macOS ls uses LSCOLORS instead and
# cannot consume vivid's LS_COLORS. If GNU coreutils is installed as gls,
# configure gls and optionally replace ls by setting BASH_COLOR_USE_GLS=1.
if command ls --color=auto -d . >/dev/null 2>&1; then
                  __color_alias ls   'ls --color=auto'
  has-cmd dir  && __color_alias dir  'dir --color=auto'
  has-cmd vdir && __color_alias vdir 'vdir --color=auto'
elif has-cmd gls&& command gls --color=auto -d . >/dev/null 2>&1; then
  __color_alias gls 'gls --color=auto'
  if [[ ${BASH_COLOR_USE_GLS:-0} == 1 ]]; then
    __color_alias ls 'gls --color=auto'
  fi
elif [[ $(uname -s 2>/dev/null) == Darwin ]]; then
  # Native macOS/BSD ls has its own limited palette format.
  __color_alias ls 'ls -G'
fi

# eza, fd, and bfs already use auto color and LS_COLORS; no aliases required.

# tree behavior differs across releases. Add -C only for terminal output, so
# piping "tree" to a file remains clean. A user-supplied later -n can disable it.
if has-cmd tree; then
  tree() {
    if [[ -t 1 ]]; then
      command tree -C "$@"
    else
      command tree "$@"
    fi
  }
fi

# ---------------------------------------------------------------------------
# 3. Search tools: grep and ripgrep use their own palettes
# ---------------------------------------------------------------------------

if __color_help_has grep '--color'; then
  __color_alias grep 'grep --color=auto'
  # GNU grep palette. vivid cannot generate GREP_COLORS directly.
  export GREP_COLORS="${GREP_COLORS:-ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36}"
fi

# rg does NOT read LS_COLORS. This wrapper applies safe defaults; options typed
# by the user come last and can override these settings.
if has-cmd rg; then
  rg() {
    command rg \
      --color=auto \
      --colors='path:fg:cyan' \
      --colors='line:fg:green' \
      --colors='column:fg:green' \
      --colors='match:fg:red' \
      --colors='match:style:bold' \
      "$@"
  }
fi

# ---------------------------------------------------------------------------
# 4. Syntax-highlighted file output: bat has an independent theme engine
# ---------------------------------------------------------------------------

# "ansi" uses the terminal's basic palette and therefore pairs well with
# vivid's ansi theme. Override before sourcing if desired.
export BAT_THEME="${BAT_THEME:-gruvbox-dark}"
export BAT_STYLE="${BAT_STYLE:-auto}"
export BAT_PAGER="${BAT_PAGER:-less -R}"

# ---------------------------------------------------------------------------
# 5. ANSI-aware pipelines and pagers
# ---------------------------------------------------------------------------

# less does not create colors, but -R preserves safe ANSI color sequences.
case " ${LESS:-} " in
  *' -R '*|*' --RAW-CONTROL-CHARS '*) ;;
  *) export LESS="${LESS:+$LESS }-R" ;;
esac

# Colored man-page headings and emphasis through less termcap capabilities.
if has-cmd tput && tput colors >/dev/null 2>&1; then
  export LESS_TERMCAP_md="$(tput bold; tput setaf 6)"
  export LESS_TERMCAP_me="$(tput sgr0)"
  export LESS_TERMCAP_so="$(tput bold; tput setaf 3)"
  export LESS_TERMCAP_se="$(tput sgr0)"
  export LESS_TERMCAP_us="$(tput smul; tput setaf 2)"
  export LESS_TERMCAP_ue="$(tput sgr0)"
  export MANPAGER="${MANPAGER:-less -R}"
fi

# ---------------------------------------------------------------------------
# 6. Other common commands with independent color switches
# ---------------------------------------------------------------------------

# GNU diff has its own palette and requires --color=auto.
if __color_help_has diff '--color'; then
  __color_alias diff 'diff --color=auto'
fi

# iproute2 uses its own color switch and does not read LS_COLORS.
if has-cmd ip && command ip -help 2>&1 | grep -Fq -- '-color'; then
  __color_alias ip 'ip -color=auto'
fi

# procps-ng watch strips colors unless --color is enabled. This wrapper only
# enables the feature on versions that provide it.
if __color_help_has watch '--color'; then
  watch() {
    command watch --color "$@"
  }
fi

# Git has a separate color system. "auto" preserves clean redirected output.
# Use a per-invocation setting rather than modifying ~/.gitconfig.
if has-cmd git; then
  __color_alias git 'git -c color.ui=auto'
fi

# Compiler diagnostics use separate controls; these values request automatic
# terminal detection rather than forcing ANSI output into build logs.
export CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-auto}"

# Do NOT globally set FORCE_COLOR, CLICOLOR_FORCE, PY_COLORS=1,
# ANSIBLE_FORCE_COLOR, or SYSTEMD_COLORS=1 here. They can force escape codes
# into redirected files, logs, CI output, parsers, and command substitutions.

# ---------------------------------------------------------------------------
# 7. Diagnostics
# ---------------------------------------------------------------------------

color-status() {
  local command_name

  printf 'VIVID_THEME=%s\n' "$VIVID_THEME"
  if [[ -n ${LS_COLORS:-} ]]; then
    printf 'LS_COLORS=set (%d bytes)\n' "${#LS_COLORS}"
  else
    printf 'LS_COLORS=not set\n'
  fi

  printf '\nLS_COLORS readers:\n'
  for command_name in ls gls eza fd bfs tree; do
    if has-cmd "$command_name"; then
      printf '  %-8s installed\n' "$command_name"
    else
      printf '  %-8s missing\n' "$command_name"
    fi
  done

  printf '\nIndependent color systems:\n'
  for command_name in grep rg bat batcat fzf less man diff ip watch git; do
    if has-cmd "$command_name"; then
      printf '  %-8s installed\n' "$command_name"
    else
      printf '  %-8s missing\n' "$command_name"
    fi
  done

  printf '\nNotes:\n'
  printf '  eza/fd/bfs: pick up LS_COLORS automatically.\n'
  printf '  rg:         does not use LS_COLORS; wrapper supplies --colors.\n'
  printf '  bat/fzf:    have independent themes/options.\n'
  printf '  less:       preserves colors with -R; it does not create them.\n'
}

unset -f __color_help_has
# Keep __color_alias available only while this file is sourced.
unset -f __color_alias
