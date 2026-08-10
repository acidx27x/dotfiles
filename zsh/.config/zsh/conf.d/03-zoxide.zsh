# ~/.config/zsh/conf.d/03-zoxide.zsh
# zoxide setup after prompt initialization.

# Keep zoxide state in the XDG data directory unless explicitly configured.
if [[ -z ${_ZO_DATA_DIR+x} ]]; then
  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
fi

# zoxide completion requires compinit to have run first.
if has-cmd zoxide; then
  shell-init zoxide init zsh --cmd z --hook pwd || {
    print -u2 -- 'WARNING, 03-zoxide.zsh: zoxide init failed.'
  }
fi
