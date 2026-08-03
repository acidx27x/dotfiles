# ~/.config/bash/conf.d/02-fzf.bash
# fzf setup
#
# Clone https://github.com/junegunn/fzf-git.sh.git to conf.d.local
# and create link inside: ln -s fzf-git.sh/fzf-git.sh 02-fzf-git.bash

if ! has_cmd fzf; then
  printf 'WARNING, 02-fzf.bash: fzf is not available\n' >&2
  return 1
fi

for name in "fd" "eza" "bat"; do
  if ! has_cmd "$name"; then
    printf 'WARNING, 02-fzf.bash: fzf is not available, bacause %s is missing\n' "$name" >&2
    return 1
  fi
done

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=default
  --border
  --info=inline
  --color=hl:#2dd4bf
  --prompt='∼ '
  --pointer='▶'
  --marker='✓'
"

export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "

# Ctrl-T -> fzf file search
# Alt-C  -> fzf directory search
if ! shell_init fzf --bash; then
  printf 'WARNING, 02-fzf.bash: fzf init failed\n' >&2
  return 1
fi

bind -m emacs-standard -x '"\ec":__fzf_cd__'
bind -m vi-insert      -x '"\ec":__fzf_cd__'
bind -m vi-command     -x '"\ec":__fzf_cd__'

bind -x '"\ec":__fzf_cd__'

# opens documentation through fzf (eg: git,zsh etc.)
fman() {
  local cmd
  cmd=$(compgen -c | fzf) || return
  man "$cmd"
}

export FZF_GIT_SH="$_bash_config_dir/conf.local.d/fzf-git.sh/fzf-git.sh"
[ -f "$FZF_GIT_SH" ] || return 0

# call by hand if binds not working
fgf() { bash "$FZF_GIT_SH" --run files     "$@"; }
fgb() { bash "$FZF_GIT_SH" --run branches  "$@"; }
fgt() { bash "$FZF_GIT_SH" --run tags      "$@"; }
fgh() { bash "$FZF_GIT_SH" --run hashes    "$@"; }
fgs() { bash "$FZF_GIT_SH" --run stashes   "$@"; }
fgw() { bash "$FZF_GIT_SH" --run worktrees "$@"; }
