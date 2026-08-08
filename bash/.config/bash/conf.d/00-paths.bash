# ~/.config/bash/conf.d/00-paths.bash
# Basic paths variables

path-prepend "$HOME/.local/bin"

_ec=$?

# User defined paths
source-if-exists "$(current-file-dir)/.paths.bash"

return "$_ec"
