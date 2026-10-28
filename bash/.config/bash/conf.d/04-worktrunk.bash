# ~/.config/bash/conf.d/04-worktrunk.bash
# Worktrunk directory switching and completion.

if has-cmd wt; then
  shell-init wt config shell init bash || {
    printf 'WARNING, %s: Worktrunk init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi
