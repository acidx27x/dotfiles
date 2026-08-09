# ~/.config/zsh/conf.d/00-paths.zsh
# User executable paths.

path-prepend "$HOME/.local/bin"

# Machine-local path overrides.
source-if-exists "$XDG_CONFIG_HOME/zsh/conf.d/.paths.zsh" || true
