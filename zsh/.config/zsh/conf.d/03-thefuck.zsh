# ~/.config/zsh/conf.d/03-thefuck.zsh
# thefuck setup.

if has-cmd thefuck; then
  shell-init env TF_SHELL=zsh thefuck --alias || {
    print -u2 -- 'WARNING, 03-thefuck.zsh: thefuck init failed.'
  }
fi
