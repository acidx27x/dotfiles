# ~/.config/bash/conf.d/03-zoxide.bash
# zoxide setup

export _ZO_DATA_DIR="$XDG_STATE_HOME/zoxide"

# zoxide completion requires compinit to have run first.
if has-cmd zoxide; then
  shell-init zoxide init bash --cmd z --hook pwd || {
    printf 'WARNING, %s: zoxide init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi
