#!/usr/bin/env bash
# ~/.config/tmux/scripts/sessionx-shell.sh — forget the restore target after a SessionX deletion.

case "$1" in
  --kill-session)
    session=$2
    last=''
    save_script=$(tmux show-option -gqv @persist-save-script-path)
    if [[ -x "$save_script" ]]; then
      # Resolve the path while the server is available, even when killing its last session.
      # shellcheck disable=SC1091
      source "${save_script%/*}/helpers.sh"
      last=$(last_session_file "$session")
    fi
    tmux kill-session -t "=$session" || exit
    [[ -z "$last" ]] || rm -f -- "$last" "$last.hash"
    ;;
  'tmux kill-session -t '*)
    tmux() {
      local kill_command
      printf -v kill_command 'bash %q --kill-session %q' "$0" "$3"
      command tmux run-shell "$kill_command"
    }
    # fzf quotes the selected target. Run the cleanup outside the popup it may close.
    eval "$1"
    ;;
  *) exec bash -c "$1" ;;
esac
