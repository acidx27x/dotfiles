# ~/.config/zsh/conf.d/03-zoxide.zsh
# zoxide setup after prompt initialization.

export _ZO_DATA_DIR="$XDG_STATE_HOME/zoxide"

# zoxide completion requires compinit to have run first.
if has-cmd zoxide; then
  shell-init zoxide init zsh --cmd z --hook pwd || {
    print -u2 -- "WARNING, ${${(%):-%x}:t}: zoxide init failed."
  }
fi
