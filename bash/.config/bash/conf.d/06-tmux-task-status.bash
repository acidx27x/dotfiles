# ~/.config/bash/conf.d/06-tmux-task-status.bash
# Mark long commands that finish in a background tmux window.

[[ -n ${TMUX:-} && -n ${TMUX_PANE:-} ]] && has-cmd tmux || return 0

__tmux_task_started() {
  __tmux_task_started_at=$SECONDS
}

__tmux_task_finished() {
  local exit_status=$?
  local marker='✓'

  if [[ -n ${__tmux_task_started_at+x} ]] && ((SECONDS - __tmux_task_started_at > 10)); then
    ((exit_status == 0)) || marker='✗'
    command tmux if-shell -F -t "$TMUX_PANE" \
      '#{!:#{&&:#{session_attached},#{window_active}}}' \
      "set-option -w -t '$TMUX_PANE' @command_done '$marker'"
  fi

  unset __tmux_task_started_at
  return "$exit_status"
}

if [[ -n ${BLE_VERSION:-} ]]; then
  blehook PREEXEC!=__tmux_task_started
  blehook POSTEXEC!=__tmux_task_finished
elif [[ -n ${bash_preexec_imported:-} ]]; then
  [[ " ${preexec_functions[*]} " == *' __tmux_task_started '* ]] ||
    preexec_functions+=(__tmux_task_started)
  [[ " ${precmd_functions[*]} " == *' __tmux_task_finished '* ]] ||
    precmd_functions+=(__tmux_task_finished)
fi
