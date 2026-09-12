# ~/.bash_profile: Bash login-shell configuration.

case $- in
  *i*)
    if [[ -r "$HOME/.bashrc" ]]; then
      source "$HOME/.bashrc"
    fi
    ;;
  *)
    _bash_config_dir="$HOME/.config/bash"

    source "$_bash_config_dir/utils.bash"
    source "$_bash_config_dir/functions.bash"
    source "$_bash_config_dir/env.bash"
    source "$_bash_config_dir/homebrew.bash"

    unset _bash_config_dir
    ;;
esac
