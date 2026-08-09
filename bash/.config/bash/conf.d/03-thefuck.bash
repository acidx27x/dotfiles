# ~/.config/bash/conf.d/03-thefuck.bash
# thefuck setup

if has-cmd thefuck; then
  shell-init env TF_SHELL=bash thefuck --alias || {
    printf 'WARNING, .bashrc: thefuck init failed\n' >&2
  }
fi
