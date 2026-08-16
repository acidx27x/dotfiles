# ~/.config/bash/conf.d/00-paths.bash
# Basic paths variables

path-prepend "$HOME/.local/bin"
path-prepend "$RUST_HOME/bin" "$CARGO_HOME/bin"

# User defined paths
source-if-exists "$(current-file-dir)/.paths.bash" || true
