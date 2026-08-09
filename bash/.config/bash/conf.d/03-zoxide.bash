# ~/.config/bash/conf.d/03-zoxide.bash
# zoxide setup

if has-cmd zoxide; then
  # Keep zoxide's database under XDG_DATA_HOME unless explicitly configured.
  if [[ -z ${_ZO_DATA_DIR+x} ]]; then
    export _ZO_DATA_DIR="$XDG_STATE_HOME/zoxide"
  fi

  shell-init zoxide init bash --cmd z --hook pwd || {
    printf 'WARNING, .bashrc: zoxide init failed\n' >&2
  }
fi
