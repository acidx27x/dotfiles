# ~/.config/zsh/conf.d/04-worktrunk.zsh
# Worktrunk directory switching and completion.

if has-cmd wt; then
  shell-init wt config shell init zsh || {
    print -u2 -- "WARNING, ${${(%):-%x}:t}: Worktrunk init failed."
  }
fi
