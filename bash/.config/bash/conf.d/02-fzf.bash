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

# Discover optional commands once and reuse the resolved names below.
_fzf_fd_command=""
_fzf_bat_command=""
_fzf_eza_command=""
_fzf_rg_command=""
_fzf_nvim_command=""
_fzf_printenv_command=""
_fzf_dig_command=""

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

if [[ -n "$_fzf_bat_command" && -n "$_fzf_eza_command" ]]; then
  export FZF_CTRL_T_OPTS="--walker=file,dir,hidden \
--walker-skip=.git,node_modules \
--preview 'if [[ -d {} ]]; then \
$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200; \
elif [[ -f {} ]]; then \
$_fzf_bat_command --color=always -n --line-range :500 -- {}; \
fi'"
elif [[ -n "$_fzf_bat_command" ]]; then
  export FZF_CTRL_T_OPTS="--walker=file,dir,hidden \
--walker-skip=.git,node_modules \
--preview '[[ -f {} ]] && \
$_fzf_bat_command --color=always -n --line-range :500 -- {}'"
elif [[ -n "$_fzf_eza_command" ]]; then
  export FZF_CTRL_T_OPTS="--walker=file,dir,hidden \
--walker-skip=.git,node_modules \
--preview '[[ -d {} ]] && \
$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
else
  export FZF_CTRL_T_OPTS='--walker=file,dir,hidden --walker-skip=.git,node_modules'
fi

if [[ -n "$_fzf_eza_command" ]]; then
  export FZF_ALT_C_OPTS="--walker=dir,hidden \
--walker-skip=.git,node_modules \
--preview '$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200'"
else
  export FZF_ALT_C_OPTS='--walker=dir,hidden --walker-skip=.git,node_modules'
fi

# Use native --popup instead of the legacy fzf-tmux wrapper.
unset FZF_TMUX FZF_TMUX_OPTS

# Ctrl-T -> fzf file and directory search.
# Alt-C  -> fzf directory search.
if ! shell-init fzf --bash; then
  printf 'WARNING, 02-fzf.bash: fzf init failed\n' >&2
  unset _fzf_fd_command _fzf_bat_command _fzf_eza_command
  unset _fzf_rg_command _fzf_nvim_command
  unset _fzf_printenv_command _fzf_dig_command
  return 1
fi

_fzf_comprun() {
  local command_name=$1
  shift

  case "$command_name" in
    cd)
      if [[ -n "$_fzf_eza_command" ]]; then
        fzf \
          --preview "$_fzf_eza_command --icons=always --tree --color=always -- {} | head -200" \
          "$@"
      else
        fzf "$@"
      fi
      ;;

    export|unset)
      if [[ -n "$_fzf_printenv_command" ]]; then
        fzf --preview "$_fzf_printenv_command {}" "$@"
      else
        fzf "$@"
      fi
      ;;

    ssh)
      if [[ -n "$_fzf_dig_command" ]]; then
        fzf --preview "$_fzf_dig_command {}" "$@"
      else
        fzf "$@"
      fi
      ;;

    *)
      if [[ -n "$_fzf_bat_command" ]]; then
        fzf \
          --preview "[[ -f {} ]] && $_fzf_bat_command --color=always -n --line-range :500 -- {}" \
          "$@"
      else
        fzf "$@"
      fi
      ;;
  esac
}

# Open documentation through fzf (for example: git or zsh).
fman() {
  local cmd
  cmd=$(compgen -c | fzf) || return
  man "$cmd"
}

# Select an action for a path.
#
# Optional second argument is a line number. When present, the nvim action
# opens the file at that line. This is used by frg.
_fzf_open_path() {
  local input_path=$1
  local line=${2:-}
  local cmd
  local reply
  local -a commands

  [[ -n "$input_path" && -e "$input_path" ]] || return

  commands=()

  if [[ -f "$input_path" ]]; then
    [[ -n "$_fzf_bat_command" ]] && commands+=(bat)
    commands+=(cat)
  fi

  commands+=(cd)

  [[ -n "$_fzf_nvim_command" ]] && commands+=(nvim)

  commands+=(remove echo)

  cmd=$(
    printf '%s\n' "${commands[@]}" |
      fzf \
        --prompt 'Select command> ' \
        --header-first \
        --header "$input_path"
  ) || return

  case "$cmd" in
    bat)
      "$_fzf_bat_command" -- "$input_path"
      ;;

    cat)
      cat -- "$input_path"
      ;;

    cd)
      if [[ -f "$input_path" ]]; then
        builtin cd -- "$(dirname -- "$input_path")" || return
      elif [[ -d "$input_path" ]]; then
        builtin cd -- "$input_path" || return
      fi
      ;;

    nvim)
      if [[ -n "$line" && "$line" =~ ^[0-9]+$ && -f "$input_path" ]]; then
        "$_fzf_nvim_command" "+$line" -- "$input_path"
      else
        "$_fzf_nvim_command" -- "$input_path"
      fi
      ;;

    remove)
      printf 'Remove %q? [y/N] ' "$input_path"
      read -r reply

      [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]] || return

      rm -rf -- "$input_path"
      ;;

    echo)
      printf '%s\n' "$input_path"
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
  local fd_reload_options="--follow --hidden --exclude .git --exclude node_modules"
  local preview_command=""
  local toggle_bind=""
  local selected

  if [[ -z "$_fzf_fd_command" ]]; then
    printf 'WARNING, 02-fzf.bash: fd/fdfind is required\n' >&2
    return 127
  fi

  if [[ -n "$_fzf_bat_command" && -n "$_fzf_eza_command" ]]; then
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        $_fzf_bat_command --color=always --style=plain -- {}
      else
        $_fzf_eza_command --tree --color=always --icons=always -- {}
      fi
    "
  elif [[ -n "$_fzf_bat_command" ]]; then
    preview_command="
      if [[ \$FZF_PROMPT == 'Files> ' ]]; then
        $_fzf_bat_command --color=always --style=plain -- {}
      else
        ls -la -- {}
      fi
    "
  elif [[ -n "$_fzf_eza_command" ]]; then
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
      printf '%s%s\n' \
        'change-prompt(Directories> )+' \
        'reload($_fzf_fd_command --type directory $fd_reload_options)'
    else
      printf '%s%s\n' \
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

  printf '%s\n' "$selected"
}

# Pick a file/directory with fd and then choose what to do with it.
ffd() {
  local path

  path=$(_fzf_get_path_using_fd) || return
  [[ -n "$path" ]] || return

  _fzf_open_path "$path"
}

# Select a ripgrep match using rg + fzf.
#
# Prints:
#   <path><TAB><line>
#
# Keeping the line number lets callers such as frg pass it to
# _fzf_open_path so the nvim action can jump directly to the match.
_fzf_get_path_using_rg() {
  local initial_query="$*"
  local rg_command
  local selected file line
  local -a fzf_options

  if [[ -z "$_fzf_rg_command" ]]; then
    printf 'WARNING, 02-fzf.bash: rg is required\n' >&2
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
  if [[ -z "${TMUX:-}" && -z "${ZELLIJ:-}" ]]; then
    fzf_options+=(--height=60%)
  fi

  if [[ -n "$_fzf_bat_command" ]]; then
    fzf_options+=(
      --preview-label 'Preview'
      --preview "$_fzf_bat_command --color=always --style=plain --highlight-line {2} -- {1}"
      --preview-window 'up,60%,border-bottom,+{2}+3/3'
    )
  fi

  # Feed an initial empty record so rg/reload is the source of candidates,
  # rather than FZF_DEFAULT_COMMAND or the built-in walker.
  selected=$(printf '\n' | fzf "${fzf_options[@]}") || return

  file=${selected%%$'\t'*}
  selected=${selected#*$'\t'}
  line=${selected%%$'\t'*}

  if [[ -z "$file" || ! "$line" =~ ^[0-9]+$ ]]; then
    printf 'WARNING, 02-fzf.bash: invalid ripgrep selection\n' >&2
    return 1
  fi

  printf '%s\t%s\n' "$file" "$line"
}

# Search file contents with ripgrep + fzf, then choose what to do with the
# selected file. The nvim action opens at the selected match line.
frg() {
  local match
  local file line

  match=$(_fzf_get_path_using_rg "$@") || return
  [[ -n "$match" ]] || return

  file=${match%%$'\t'*}
  line=${match#*$'\t'}

  _fzf_open_path "$file" "$line"
}

FZF_GIT_SH="$_bash_config_dir/conf.local.d/fzf-git.sh/fzf-git.sh"
export -n FZF_GIT_SH
[[ -f "$FZF_GIT_SH" ]] || return 0

# Call by hand if binds are not working.
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
