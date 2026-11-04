# ~/.config/zsh/conf.d/03-broot.zsh
# Broot directory switching.

if has-cmd broot; then
  br() {
    emulate -L zsh

    local cmd cmd_file exit_code

    cmd_file=$(mktemp) || return
    if broot --outcmd "$cmd_file" "$@"; then
      cmd=$(<"$cmd_file")
      command rm -f -- "$cmd_file"
      [[ -z $cmd ]] || eval "$cmd"
    else
      exit_code=$?
      command rm -f -- "$cmd_file"
      return $exit_code
    fi
  }
fi
