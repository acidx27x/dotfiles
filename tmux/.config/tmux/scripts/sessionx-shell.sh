#!/usr/bin/env bash
# ~/.config/tmux/scripts/sessionx-shell.sh — save Resurrect state after a SessionX deletion.

case "$1" in
  --save-after-kill)
    save_script=$(tmux show-option -gqv @resurrect-save-script-path)
    [[ -x "$save_script" ]] || exit 0

    # Use Resurrect's configured paths, including its XDG defaults.
    # shellcheck disable=SC1091
    source "${save_script%/*}/helpers.sh"
    tmux wait-for -L sessionx-resurrect-save || exit 1
    trap 'tmux wait-for -U sessionx-resurrect-save' EXIT

    sessions=$(tmux list-sessions -F '#{session_id}') || exit
    if [[ -z "$sessions" ]]; then
      # Skip automatic restore when the user deleted the last session.
      rm -f -- "$(last_resurrect_file)"
      exit
    fi

    # Resurrect uses second-resolution filenames. Give an existing save its own file.
    while [[ -e "$(_RESURRECT_FILE_PATH='' resurrect_file_path)" ]]; do
      sleep 0.1
    done
    bash "$save_script" quiet
    ;;
  'tmux kill-session -t '*)
    printf -v save_command 'bash %q --save-after-kill' "$0"
    tmux() {
      command tmux kill-session -t "=$3" \; run-shell "$save_command"
    }
    # fzf quotes the selected target. Queue the save on the server behind the successful kill.
    eval "$1"
    ;;
  *) exec bash -c "$1" ;;
esac
