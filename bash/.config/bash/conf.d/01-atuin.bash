# ~/.config/bash/conf.d/01-atuin.bash
# atuin setup must be done before fzf setup

_atuin_initialized=0  # can be checked later

if has-cmd atuin; then
  if shell-init atuin init bash --disable-up-arrow --disable-ai; then
    _atuin_initialized=1
  else
    printf 'WARNING, .bashrc: atuin init failed\n' >&2
  fi
fi

# Disable fzf's Ctrl-R binding only after Atuin has initialized successfully.
# Preserve a value explicitly configured in env.bash or .env.bash.
if (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi
