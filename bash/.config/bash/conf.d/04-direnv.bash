# ~/.config/bash/conf.d/04-direnv.bash
# direnv setup

# Keep direnv last among prompt-related integrations.
# Create .envrc and run `direnv allow .` or `direnv deny .` afterward.
if has-cmd direnv; then
  shell-init direnv hook bash || {
    printf 'WARNING, .bashrc: direnv init failed\n' >&2
  }
fi
