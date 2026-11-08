# ~/.config/zsh/conf.d/01-mise.zsh
# Make managed CLI tools available before other modules use them.

if has-cmd mise; then
  if ! shell-init mise activate zsh --shims; then
    print -u2 -- "WARNING, ${${(%):-%x}:t}: mise initialization failed."
  fi
fi
