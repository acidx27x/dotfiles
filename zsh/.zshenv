# ~/.zshenv: environment shared by all Zsh invocations.

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  print -u2 -- 'Error: HOME must be an absolute path.'
  return 1 2>/dev/null || exit 1
fi

if [[ ${XDG_CONFIG_HOME:-} == /* ]]; then
  _zsh_config_dir="$XDG_CONFIG_HOME/zsh"
else
  _zsh_config_dir="$HOME/.config/zsh"
fi

if [[ -r "$_zsh_config_dir/env.zsh" ]]; then
  source "$_zsh_config_dir/env.zsh" || {
    print -u2 -- 'Error: could not initialize the Zsh environment.'
    return 1 2>/dev/null || exit 1
  }
else
  print -u2 -- "Error: missing Zsh environment file: $_zsh_config_dir/env.zsh"
  return 1 2>/dev/null || exit 1
fi

unset _zsh_config_dir
