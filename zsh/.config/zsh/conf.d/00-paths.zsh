# ~/.config/zsh/conf.d/00-paths.zsh
# Basic paths variables

path-prepend "$HOME/.local/bin"
path-prepend "$RUST_HOME/bin" "$CARGO_HOME/bin"

# User defined paths
source-if-exists "$(current-file-dir)/.paths.zsh" || true
