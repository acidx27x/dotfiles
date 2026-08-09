# ~/.zprofile: Zsh login-shell configuration.

_zsh_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

if [[ -r "$_zsh_config_dir/homebrew.zsh" ]]; then
  source "$_zsh_config_dir/homebrew.zsh" || {
    print -u2 -- 'WARNING, .zprofile: Homebrew initialization failed.'
  }
fi

unset _zsh_config_dir
