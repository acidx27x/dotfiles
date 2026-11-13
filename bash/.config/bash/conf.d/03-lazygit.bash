# ~/.config/bash/conf.d/03-lazygit.bash
# Forward clipboard copies through tmux's terminal, including over SSH.

if [[ -n ${TMUX:-} && -z ${LG_CONFIG_FILE:-} ]] && has-cmd tmux; then
  _lazygit_config_dir="${CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/lazygit}"
  if [[ -f $_lazygit_config_dir/config.yml && -f $_lazygit_config_dir/tmux.yml ]]; then
    export LG_CONFIG_FILE="$_lazygit_config_dir/config.yml,$_lazygit_config_dir/tmux.yml"
  fi
  unset _lazygit_config_dir
fi
