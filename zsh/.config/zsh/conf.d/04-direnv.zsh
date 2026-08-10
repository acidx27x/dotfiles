# ~/.config/zsh/conf.d/04-direnv.zsh
# direnv setup last among prompt-related integrations.

if has-cmd direnv; then
  shell-init direnv hook zsh || {
    print -u2 -- 'WARNING, 04-direnv.zsh: direnv init failed.'
  }
fi
