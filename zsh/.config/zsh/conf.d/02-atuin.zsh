# ~/.config/zsh/conf.d/02-atuin.zsh
# Atuin must initialize before fzf key bindings.

_atuin_initialized=0
_atuin_init_args=(init zsh --disable-ai)

# Herdr already manages the pane PTY. Keep Atuin's history hooks, but let fzf
# provide interactive history search there.
if [[ ${HERDR_ENV:-} == 1 ]]; then
  _atuin_init_args+=(--disable-up-arrow --disable-ctrl-r)
fi

if has-cmd atuin; then
  if shell-init atuin "${_atuin_init_args[@]}"; then
    _atuin_initialized=1
  else
    print -u2 -- 'WARNING, 02-atuin.zsh: atuin init failed.'
  fi
fi

# An empty exported value may be inherited by a Herdr pane from its parent.
if [[ ${HERDR_ENV:-} == 1 ]]; then
  unset FZF_CTRL_R_COMMAND
# Otherwise, disable fzf's Ctrl-R binding only after Atuin initialized.
elif (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi

unset _atuin_initialized _atuin_init_args
