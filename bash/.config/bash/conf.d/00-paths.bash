# ~/.config/bash/conf.d/00-paths.bash
# Basic paths variables

path_prepend "$HOME/.local/bin"

_ec=$?

# User defined paths
source_if_exists "$(current_file_dir)/.paths.bash"

return "$_ec"
