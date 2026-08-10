# ~/.config/zsh/conf.d/02-atuin.zsh
# Atuin must initialize before fzf key bindings.

_atuin_initialized=0

if has-cmd atuin; then
  if shell-init atuin init zsh --disable-up-arrow --disable-ai; then
    _atuin_initialized=1
  else
    print -u2 -- 'WARNING, 02-atuin.zsh: atuin init failed.'
  fi
fi

# Disable fzf's Ctrl-R binding only after Atuin initialized successfully.
if (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi

unset _atuin_initialized
