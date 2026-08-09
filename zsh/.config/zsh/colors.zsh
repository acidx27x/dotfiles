# Choose a vivid theme before sourcing, for example:
#   export VIVID_THEME=ansi
#   export VIVID_THEME=molokai
#
# Disable all configuration from this file with NO_COLOR=1.

if [[ -n ${NO_COLOR:-} || ${TERM:-} == dumb ]]; then
  return 0
fi

export CLICOLOR="${CLICOLOR:-1}"

# ---------------------------------------------------------------------------
# LS_COLORS
# ---------------------------------------------------------------------------

VIVID_THEME="${VIVID_THEME:-iceberg-dark}"

if [[ -z ${LS_COLORS+x} ]]; then
  if has-cmd vivid; then
    if __vivid_colors=$(vivid generate "$VIVID_THEME" 2>/dev/null); then
      export LS_COLORS=$__vivid_colors
    else
      print -u2 -- "WARNING, colors.zsh: vivid theme not found: $VIVID_THEME"
    fi
    unset __vivid_colors
  elif has-cmd dircolors; then
    if __dircolors_output=$(dircolors -b 2>/dev/null) &&
       eval "$__dircolors_output"; then
      :
    else
      print -u2 -- 'WARNING, colors.zsh: dircolors init failed.'
    fi
    unset __dircolors_output
  fi
fi

ZSH_COLOR_OVERRIDE_ALIASES="${ZSH_COLOR_OVERRIDE_ALIASES:-0}"

__color_alias() {
  emulate -L zsh

  local name=$1
  local definition=$2

  if [[ $ZSH_COLOR_OVERRIDE_ALIASES == 1 ]] || ! alias "$name" >/dev/null 2>&1; then
    alias "$name=$definition"
  fi
}

__color_help_has() {
  emulate -L zsh

  local command_name=$1
  local option=$2

  has-cmd "$command_name" || return 1
  command "$command_name" --help 2>&1 | grep -Fq -- "$option"
}

# ---------------------------------------------------------------------------
# Commands that understand LS_COLORS but need color enabled
# ---------------------------------------------------------------------------

if command ls --color=auto -d . >/dev/null 2>&1; then
  __color_alias ls 'ls --color=auto'
  has-cmd dir  && __color_alias dir  'dir --color=auto'
  has-cmd vdir && __color_alias vdir 'vdir --color=auto'
elif has-cmd gls && command gls --color=auto -d . >/dev/null 2>&1; then
  __color_alias gls 'gls --color=auto'
  if [[ ${ZSH_COLOR_USE_GLS:-0} == 1 ]]; then
    __color_alias ls 'gls --color=auto'
  fi
elif [[ $(uname -s 2>/dev/null) == Darwin ]]; then
  __color_alias ls 'ls -G'
fi

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
# Search tools
# ---------------------------------------------------------------------------

if __color_help_has grep '--color'; then
  __color_alias grep 'grep --color=auto'
  export GREP_COLORS="${GREP_COLORS:-ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36}"
fi

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
# bat and pagers
# ---------------------------------------------------------------------------

export BAT_THEME="${BAT_THEME:-gruvbox-dark}"
export BAT_STYLE="${BAT_STYLE:-auto}"
export BAT_PAGER="${BAT_PAGER:-less -R}"

case " ${LESS:-} " in
  *' -R '* | *' --RAW-CONTROL-CHARS '*) ;;
  *) export LESS="${LESS:+$LESS }-R" ;;
esac

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
# Other command-specific color switches
# ---------------------------------------------------------------------------

if __color_help_has diff '--color'; then
  __color_alias diff 'diff --color=auto'
fi

if has-cmd ip && command ip -help 2>&1 | grep -Fq -- '-color'; then
  __color_alias ip 'ip -color=auto'
fi

if __color_help_has watch '--color'; then
  watch() {
    command watch --color "$@"
  }
fi

if has-cmd git; then
  __color_alias git 'git -c color.ui=auto'
fi

export CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-auto}"

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

color-status() {
  emulate -L zsh

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

unfunction __color_help_has __color_alias 2>/dev/null
