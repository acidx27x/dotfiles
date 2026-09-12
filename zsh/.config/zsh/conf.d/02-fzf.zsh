# ~/.config/zsh/conf.d/02-fzf.zsh
# fzf key bindings, completion, previews, and helpers.
# Requires fzf 0.71 or newer for native `--popup` support.

export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/zsh/fzfrc"

if ! has-cmd fzf; then
  return 0
fi

typeset -g _fzf_fd_command=''
typeset -g _fzf_bat_command=''
typeset -g _fzf_eza_command=''
typeset -g _fzf_rg_command=''
typeset -g _fzf_nvim_command=''
typeset -g _fzf_printenv_command=''
typeset -g _fzf_dig_command=''

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

if has-cmd rg; then
  _fzf_rg_command=rg
fi

if has-cmd nvim; then
  _fzf_nvim_command=nvim
fi

if has-cmd printenv; then
  _fzf_printenv_command=printenv
fi

if has-cmd dig; then
  _fzf_dig_command=dig
fi

# fzf uses its built-in walker when these commands are unset.
unset FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND

FZF_CTRL_T_OPTS='--walker=file,dir,hidden --walker-skip=.git,node_modules'
if [[ -n $_fzf_bat_command && -n $_fzf_eza_command ]]; then
  FZF_CTRL_T_OPTS+=" --preview 'if [[ -d {} ]]; then \
$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200; \
elif [[ -f {} ]]; then \
$_fzf_bat_command --color=always -n --line-range :500 -- {}; \
fi'"
elif [[ -n $_fzf_bat_command ]]; then
  FZF_CTRL_T_OPTS+=" --preview '[[ -f {} ]] && \
$_fzf_bat_command --color=always -n --line-range :500 -- {}'"
elif [[ -n $_fzf_eza_command ]]; then
  FZF_CTRL_T_OPTS+=" --preview '[[ -d {} ]] && \
$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
fi
export FZF_CTRL_T_OPTS

FZF_ALT_C_OPTS='--walker=dir,hidden --walker-skip=.git,node_modules'
if [[ -n $_fzf_eza_command ]]; then
  FZF_ALT_C_OPTS+=" --preview \
'$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
fi
export FZF_ALT_C_OPTS

# Use native --popup instead of the legacy fzf-tmux wrapper.
unset FZF_TMUX FZF_TMUX_OPTS

# Ctrl-T -> fzf file and directory search.
# Alt-C  -> fzf directory search.
if ! shell-init fzf --zsh; then
  print -u2 -- 'WARNING, 02-fzf.zsh: fzf init failed.'
  unset _fzf_fd_command _fzf_bat_command _fzf_eza_command
  unset _fzf_rg_command _fzf_nvim_command
  unset _fzf_printenv_command _fzf_dig_command
  return 1
fi

_fzf_comprun() {
  emulate -L zsh

  local command_name=$1
  shift

  case $command_name in
    cd)
      if [[ -n $_fzf_eza_command ]]; then
        fzf \
          --preview "$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200" \
          "$@"
      else
        fzf "$@"
      fi
      ;;

    export | unset)
      if [[ -n $_fzf_printenv_command ]]; then
        fzf --preview "$_fzf_printenv_command {}" "$@"
      else
        fzf "$@"
      fi
      ;;

    ssh)
      if [[ -n $_fzf_dig_command ]]; then
        fzf --preview "$_fzf_dig_command {}" "$@"
      else
        fzf "$@"
      fi
      ;;

    *)
      if [[ -n $_fzf_bat_command ]]; then
        fzf \
          --preview "[[ -f {} ]] && $_fzf_bat_command --color=always -n --line-range :500 -- {}" \
          "$@"
      else
        fzf "$@"
      fi
      ;;
  esac
}

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

# Select an action for a path.
#
# Optional second argument is a line number. When present, the nvim action
# opens the file at that line. This is used by frg.
_fzf_open_path() {
  emulate -L zsh

  local input_path=$1
  local line=${2:-}
  local cmd reply
  local -a commands

  [[ -n $input_path && -e $input_path ]] || return

  if [[ -f $input_path ]]; then
    [[ -n $_fzf_bat_command ]] && commands+=(bat)
    commands+=(cat)
  fi

  commands+=(cd)

  [[ -n $_fzf_nvim_command ]] && commands+=(nvim)

  commands+=(remove echo)

  cmd=$(
    print -rl -- "${commands[@]}" |
      fzf \
        --prompt 'Select command> ' \
        --header-first \
        --header "$input_path"
  ) || return

  case $cmd in
    bat)
      "$_fzf_bat_command" -- "$input_path"
      ;;

    cat)
      command cat -- "$input_path"
      ;;

    cd)
      if [[ -f $input_path ]]; then
        builtin cd -- "${input_path:h}" || return
      elif [[ -d $input_path ]]; then
        builtin cd -- "$input_path" || return
      fi
      ;;

    nvim)
      if [[ -n $line && $line == <-> && -f $input_path ]]; then
        "$_fzf_nvim_command" "+$line" -- "$input_path"
      else
        "$_fzf_nvim_command" -- "$input_path"
      fi
      ;;

    remove)
      print -n -- "Remove ${(q)input_path}? [y/N] "
      read -r reply

      [[ $reply == [yY] || $reply == [yY][eE][sS] ]] || return

      command rm -rf -- "$input_path"
      ;;

    echo)
      print -r -- "$input_path"
      ;;

    *)
      return 1
      ;;
  esac
}

# Select a file or directory using fd + fzf.
#
# CTRL-S switches between file and directory mode.
_fzf_get_path_using_fd() {
  emulate -L zsh

  local fd_reload_options='--follow --hidden --exclude .git --exclude node_modules'
  local preview_command=''
  local toggle_bind=''
  local selected

  if [[ -z $_fzf_fd_command ]]; then
    print -u2 -- 'WARNING, 02-fzf.zsh: fd/fdfind is required'
    return 127
  fi

  if [[ -n $_fzf_bat_command && -n $_fzf_eza_command ]]; then
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        $_fzf_bat_command --color=always --style=plain -- {}
      else
        $_fzf_eza_command --tree --color=always --icons=always -- {}
      fi
    "
  elif [[ -n $_fzf_bat_command ]]; then
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        $_fzf_bat_command --color=always --style=plain -- {}
      else
        ls -la -- {}
      fi
    "
  elif [[ -n $_fzf_eza_command ]]; then
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        sed -n '1,200p' -- {}
      else
        $_fzf_eza_command --tree --color=always --icons=always -- {}
      fi
    "
  else
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        sed -n '1,200p' -- {}
      else
        ls -la -- {}
      fi
    "
  fi

  toggle_bind="ctrl-s:transform:
    if [[ \$FZF_PROMPT == 'Files> ' ]]; then
      print -f '%s%s\n' \
        'change-prompt(Directories> )+' \
        'reload($_fzf_fd_command --type directory $fd_reload_options)'
    else
      print -f '%s%s\n' \
        'change-prompt(Files> )+' \
        'reload($_fzf_fd_command --type file $fd_reload_options)'
    fi
  "

  selected=$(
    "$_fzf_fd_command" \
      --type file \
      --follow \
      --hidden \
      --exclude .git \
      --exclude node_modules |
      fzf \
        --prompt 'Files> ' \
        --header-first \
        --header 'CTRL-S: Switch between Files/Directories' \
        --bind "$toggle_bind" \
        --preview "$preview_command"
  ) || return

  print -r -- "$selected"
}

# Pick a file/directory with fd and then choose what to do with it.
ffd() {
  emulate -L zsh

  local selected_path

  selected_path=$(_fzf_get_path_using_fd) || return
  [[ -n $selected_path ]] || return

  _fzf_open_path "$selected_path"
}

# Select a ripgrep match using rg + fzf.
#
# Prints:
#   <path><TAB><line>
#
# Keeping the line number lets callers such as frg pass it to
# _fzf_open_path so the nvim action can jump directly to the match.
_fzf_get_path_using_rg() {
  emulate -L zsh

  local initial_query="$*"
  local rg_command
  local selected file line
  local -a fzf_options

  if [[ -z $_fzf_rg_command ]]; then
    print -u2 -- 'WARNING, 02-fzf.zsh: rg is required'
    return 127
  fi

  rg_command="$_fzf_rg_command \
    --column \
    --line-number \
    --no-heading \
    --with-filename \
    --color=always \
    --colors 'path:none' \
    --smart-case \
    --hidden \
    --no-messages \
    --glob '!**/.git/**' \
    --glob '!**/node_modules/**' \
    --field-match-separator='\\t' \
    -- \
  "

  fzf_options=(
    --ansi
    --disabled
    --delimiter=$'\t'
    '--with-nth=1,2,4..'
    --query "$initial_query"
    --prompt 'rg> '
    --header-first
    --header 'Type a ripgrep regex; Enter: select match'
    --bind "start:reload:[[ -n {q} ]] && $rg_command {q} || true"
    --bind "change:reload:sleep 0.1; [[ -n {q} ]] && $rg_command {q} || true"
  )

  # Keep the global popup configuration inside tmux/Zellij. Outside a
  # multiplexer, override the global adaptive --height=~60% with a fixed
  # height because reload-driven rg input starts nearly empty.
  if [[ -z ${TMUX:-} && -z ${ZELLIJ:-} ]]; then
    fzf_options+=(--height=60%)
  fi

  if [[ -n $_fzf_bat_command ]]; then
    fzf_options+=(
      --preview-label 'Preview'
      --preview "$_fzf_bat_command --color=always --style=plain --highlight-line {2} -- {1}"
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
    )
  fi

  # Feed an initial empty record so rg/reload is the source of candidates,
  # rather than FZF_DEFAULT_COMMAND or the built-in walker.
  selected=$(print | fzf "${fzf_options[@]}") || return

  file=${selected%%$'\t'*}
  selected=${selected#*$'\t'}
  line=${selected%%$'\t'*}

  if [[ -z $file || $line != <-> ]]; then
    print -u2 -- 'WARNING, 02-fzf.zsh: invalid ripgrep selection'
    return 1
  fi

  print -r -- "$file"$'\t'"$line"
}

# Search file contents with ripgrep + fzf, then choose what to do with the
# selected file. The nvim action opens at the selected match line.
frg() {
  emulate -L zsh

  local match
  local file line

  match=$(_fzf_get_path_using_rg "$@") || return
  [[ -n $match ]] || return

  file=${match%%$'\t'*}
  line=${match#*$'\t'}

  _fzf_open_path "$file" "$line"
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
  printf 'Available fzf-git functions and their targets:\n'
  printf 'fgf: files\n'
  printf 'fgb: branches\n'
  printf 'fgt: tags\n'
  printf 'fgh: hashes\n'
  printf 'fgs: stashes\n'
  printf 'fgw: worktrees\n'
}
