# ~/.config/bash/conf.d/03-thefuck.bash
# thefuck setup

if has-cmd thefuck; then
  shell-init env TF_SHELL=bash thefuck --alias || {
    printf 'WARNING, %s: thefuck init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi
