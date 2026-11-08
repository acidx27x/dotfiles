# ~/.config/bash/conf.d/01-mise.bash
# Make managed CLI tools available before other modules use them.

if has-cmd mise; then
  if ! shell-init mise activate bash --shims; then
    printf 'WARNING, %s: mise initialization failed\n' "${BASH_SOURCE[0]##*/}" >&2
  fi
fi
