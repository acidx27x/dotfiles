# ~/.config/bash/conf.d/03-broot.bash
# Broot directory switching.

if has-cmd broot; then
  br() {
    local cmd cmd_file status

    cmd_file=$(mktemp) || return
    if broot --outcmd "$cmd_file" "$@"; then
      cmd=$(<"$cmd_file")
      command rm -f -- "$cmd_file"
      [[ -z "$cmd" ]] || eval "$cmd"
    else
      status=$?
      command rm -f -- "$cmd_file"
      return "$status"
    fi
  }
fi
