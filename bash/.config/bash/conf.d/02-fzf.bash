# ~/.config/bash/conf.d/02-fzf.bash
# fzf setup
#
# Requires fzf 0.71 or newer for native `--popup` support.
# Clone https://github.com/junegunn/fzf-git.sh.git to conf.local.d
# and create link inside: ln -s fzf-git.sh/fzf-git.sh 02-fzf-git.bash

export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/bash/fzfrc"

if ! has-cmd fzf; then
  return 0
fi

_fzf_fd_command=""
_fzf_bat_command=""
_fzf_eza_command=""

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

if has-cmd eza; then
  _fzf_eza_command=eza
fi

if [[ -n "$_fzf_fd_command" ]]; then
  export FZF_DEFAULT_COMMAND="$_fzf_fd_command --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_fzf_fd_command --type=d --hidden --strip-cwd-prefix --exclude .git"
else
  # fzf uses its built-in walker when these commands are unset.
  unset FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND
fi

if [[ -n "$_fzf_bat_command" && -n "$_fzf_eza_command" ]]; then
  export FZF_CTRL_T_OPTS="--preview 'if [[ -d {} ]]; then $_fzf_eza_command --icons=always --tree --color=always -- {} | head -200; elif [[ -f {} ]]; then $_fzf_bat_command --color=always -n --line-range :500 -- {}; fi'"
elif [[ -n "$_fzf_bat_command" ]]; then
  export FZF_CTRL_T_OPTS="--preview '[[ -f {} ]] && $_fzf_bat_command --color=always -n --line-range :500 -- {}'"
elif [[ -n "$_fzf_eza_command" ]]; then
  export FZF_CTRL_T_OPTS="--preview '[[ -d {} ]] && $_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
else
  unset FZF_CTRL_T_OPTS
fi

if [[ -n "$_fzf_eza_command" ]]; then
  export FZF_ALT_C_OPTS="--preview '$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
else
  unset FZF_ALT_C_OPTS
fi

# Use native --popup instead of the legacy fzf-tmux wrapper.
unset FZF_TMUX FZF_TMUX_OPTS

# Ctrl-T -> fzf file search
# Alt-C  -> fzf directory search
if ! shell-init fzf --bash; then
  printf 'WARNING, 02-fzf.bash: fzf init failed\n' >&2
  unset _fzf_fd_command _fzf_bat_command _fzf_eza_command
  return 1
fi

_fzf_comprun() {
  local command_name=$1
  shift

  case "$command_name" in
    cd)
      if has-cmd eza; then
        fzf --preview 'eza --icons=always --tree --color=always -- {} | head -200' "$@"
      else
        fzf "$@"
      fi
      ;;

    export|unset)
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
        fzf --preview '[[ -f {} ]] && bat --color=always -n --line-range :500 -- {}' "$@"
      elif has-cmd batcat; then
        fzf --preview '[[ -f {} ]] && batcat --color=always -n --line-range :500 -- {}' "$@"
      else
        fzf "$@"
      fi
      ;;
  esac
}

unset _fzf_fd_command _fzf_bat_command _fzf_eza_command

# Open documentation through fzf (for example: git or zsh).
fman() {
  local cmd
  cmd=$(compgen -c | fzf) || return
  man "$cmd"
}

# Search file contents and open the selected match in Neovim.
frg() {
  local initial_query="$*"
  local bat_command=""
  local rg_command
  local selected file line
  local -a fzf_options

  if ! has-cmd rg; then
    printf 'frg: rg is required\n' >&2
    return 127
  fi

  if ! has-cmd nvim; then
    printf 'frg: nvim is required\n' >&2
    return 127
  fi

  if has-cmd bat; then
    bat_command=bat
  elif has-cmd batcat; then
    bat_command=batcat
  fi

  rg_command="rg --column --line-number --no-heading --with-filename --color=always --smart-case --hidden --no-messages --glob '!.git/**' --field-match-separator='\\t' --"
  fzf_options=(
    --ansi
    --disabled
    --delimiter=$'\t'
    '--with-nth=1,2,4..'
    --query "$initial_query"
    --prompt 'rg> '
    --header 'Type a ripgrep regex; Enter: open in Neovim'
    --bind "start,change:reload:[[ -n {q} ]] && $rg_command {q} || true"
  )

  if [[ -n "$bat_command" ]]; then
    fzf_options+=(
      --preview "$bat_command --color=always --style=numbers --highlight-line {2} -- {1}"
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
    )
  fi

  selected=$(fzf "${fzf_options[@]}") || return
  file=${selected%%$'\t'*}
  selected=${selected#*$'\t'}
  line=${selected%%$'\t'*}

  if [[ -z "$file" || ! "$line" =~ ^[0-9]+$ ]]; then
    printf 'frg: invalid selection\n' >&2
    return 1
  fi

  nvim "+$line" -- "$file"
}

FZF_GIT_SH="$_bash_config_dir/conf.local.d/fzf-git.sh/fzf-git.sh"
export -n FZF_GIT_SH
[[ -f "$FZF_GIT_SH" ]] || return 0

# call by hand if binds not working
fgf() { bash "$FZF_GIT_SH" --run files     "$@"; }
fgb() { bash "$FZF_GIT_SH" --run branches  "$@"; }
fgt() { bash "$FZF_GIT_SH" --run tags      "$@"; }
fgh() { bash "$FZF_GIT_SH" --run hashes    "$@"; }
fgs() { bash "$FZF_GIT_SH" --run stashes   "$@"; }
fgw() { bash "$FZF_GIT_SH" --run worktrees "$@"; }
fghelp() {
  printf 'Available fzf-git functions and its targets:\n'
  printf 'fgf: files\n'
  printf 'fgb: branches\n'
  printf 'fgt: tags\n'
  printf 'fgh: hashes\n'
  printf 'fgs: stashes\n'
  printf 'fgw: worktrees\n'
}
