# ~/.config/zsh/conf.d/02-fzf.zsh
# fzf key bindings, completion, previews, and helpers.

export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/zsh/fzfrc"

if ! has-cmd fzf; then
  return 0
fi

_fzf_fd_command=''
_fzf_bat_command=''

if has-cmd fd; then
  _fzf_fd_command=fd
elif has-cmd fdfind; then
  _fzf_fd_command=fdfind
fi

if has-cmd bat; then
  _fzf_bat_command=bat
elif has-cmd batcat; then
  _fzf_bat_command=batcat
fi

if [[ -n $_fzf_fd_command ]]; then
  export FZF_DEFAULT_COMMAND="$_fzf_fd_command --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_ALT_C_COMMAND="$_fzf_fd_command --type=d --hidden --strip-cwd-prefix --exclude .git"
else
  unset FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND
fi

if [[ -n $_fzf_bat_command ]]; then
  export FZF_CTRL_T_OPTS="--preview '$_fzf_bat_command --color=always -n --line-range :500 {}'"
else
  unset FZF_CTRL_T_OPTS
fi

if has-cmd eza; then
  export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
else
  unset FZF_ALT_C_OPTS
fi

export FZF_TMUX_OPTS=' -p90%,70% '

# Ctrl-T -> file search; Alt-C -> directory search.
if ! shell-init fzf --zsh; then
  print -u2 -- 'WARNING, 02-fzf.zsh: fzf init failed.'
  unset _fzf_fd_command _fzf_bat_command
  return 1
fi

_fzf_comprun() {
  emulate -L zsh

  local command_name=$1
  shift

  case $command_name in
    cd)
      if has-cmd eza; then
        fzf --preview 'eza --icons=always --tree --color=always {} | head -200' "$@"
      else
        fzf "$@"
      fi
      ;;

    export | unset)
      if has-cmd printenv; then
        fzf --preview 'printenv {}' "$@"
      else
        fzf "$@"
      fi
      ;;

    ssh)
      if has-cmd dig; then
        fzf --preview 'dig {}' "$@"
      else
        fzf "$@"
      fi
      ;;

    *)
      if has-cmd bat; then
        fzf --preview 'bat --color=always -n --line-range :500 {}' "$@"
      elif has-cmd batcat; then
        fzf --preview 'batcat --color=always -n --line-range :500 {}' "$@"
      else
        fzf "$@"
      fi
      ;;
  esac
}

unset _fzf_fd_command _fzf_bat_command

# Find and open documentation through fzf.
fman() {
  emulate -L zsh

  local cmd
  local -a command_names

  command_names=(
    ${(k)commands}
    ${(k)functions}
    ${(k)aliases}
    ${(k)builtins}
  )

  cmd=$(printf '%s\n' ${(ou)command_names} | fzf) || return
  man "$cmd"
}

typeset -g FZF_GIT_SH="$_zsh_config_dir/conf.local.d/fzf-git.sh/fzf-git.sh"
[[ -f $FZF_GIT_SH ]] || return 0

fgf() { bash "$FZF_GIT_SH" --run files     "$@"; }
fgb() { bash "$FZF_GIT_SH" --run branches  "$@"; }
fgt() { bash "$FZF_GIT_SH" --run tags      "$@"; }
fgh() { bash "$FZF_GIT_SH" --run hashes    "$@"; }
fgs() { bash "$FZF_GIT_SH" --run stashes   "$@"; }
fgw() { bash "$FZF_GIT_SH" --run worktrees "$@"; }

fghelp() {
  printf 'Available fzf-git functions and targets:\n'
  printf 'fgf: files\n'
  printf 'fgb: branches\n'
  printf 'fgt: tags\n'
  printf 'fgh: hashes\n'
  printf 'fgs: stashes\n'
  printf 'fgw: worktrees\n'
}
