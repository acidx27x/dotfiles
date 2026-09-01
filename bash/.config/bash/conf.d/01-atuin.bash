# ~/.config/bash/conf.d/01-atuin.bash
# atuin setup must be done before fzf setup

_atuin_initialized=0  # can be checked later
_atuin_init_args=(init bash --disable-ai)

# Herdr already manages the pane PTY. Keep Atuin's history hooks, but let fzf
# provide interactive history search there.
if [[ ${HERDR_ENV:-} == 1 ]]; then
  _atuin_init_args+=(--disable-up-arrow --disable-ctrl-r)
fi

if has-cmd atuin; then
  if shell-init atuin "${_atuin_init_args[@]}"; then
    _atuin_initialized=1
  else
    printf 'WARNING, .bashrc: atuin init failed\n' >&2
  fi
fi

# An empty exported value may be inherited by a Herdr pane from its parent.
if [[ ${HERDR_ENV:-} == 1 ]]; then
  unset FZF_CTRL_R_COMMAND
# Otherwise, disable fzf's Ctrl-R binding only after Atuin initialized.
elif (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi

unset _atuin_init_args
