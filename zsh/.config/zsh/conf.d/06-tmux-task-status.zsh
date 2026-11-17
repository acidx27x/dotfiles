# ~/.config/zsh/conf.d/06-tmux-task-status.zsh
# Mark long commands that finish in a background tmux window.

[[ -n ${TMUX:-} && -n ${TMUX_PANE:-} ]] && has-cmd tmux || return 0

__tmux_task_started() {
  emulate -L zsh
  typeset -gi __tmux_task_started_at=$SECONDS
}

__tmux_task_finished() {
  local exit_status=$?
  emulate -L zsh
  local marker='✓'

  if [[ -n ${__tmux_task_started_at+x} ]] && ((SECONDS - __tmux_task_started_at > 10)); then
    ((exit_status == 0)) || marker='✗'
    command tmux if-shell -F -t "$TMUX_PANE" \
      '#{!:#{&&:#{session_attached},#{window_active}}}' \
      "set-option -w -t '$TMUX_PANE' @command_done '$marker'"
  fi

  unset __tmux_task_started_at
  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __tmux_task_started
add-zsh-hook precmd __tmux_task_finished
