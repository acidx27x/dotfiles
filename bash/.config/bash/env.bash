# ~/.config/bash/env.bash
# Basic XDG standard environment variables
#
# The script preserves valid existing values and supplies defaults when needed.

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  printf 'Error: HOME must be an absolute path.\n' >&2

  if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    return 1
  else
    exit 1
  fi
fi

_env_file_dir="$(
  cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null &&
  pwd
)" || {
  printf 'Error: could not resolve the env.bash directory.\n' >&2

  if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    return 1
  else
    exit 1
  fi
}

# Keep direct execution useful while .bashrc supplies these modules normally.
if ! declare -F set-xdg-path >/dev/null; then
  source "$_env_file_dir/utils.bash" || exit 1
fi

if [[ ${BASH_SOURCE[0]} == "$0" ]] &&
   ! declare -F print-xdg-paths >/dev/null
then
  source "$_env_file_dir/functions.bash" || exit 1
fi

# ---------------------------------------------------------------------------
# XDG Base Directory Specification
# ---------------------------------------------------------------------------

set-xdg-path XDG_DATA_HOME   "$HOME/.local/share"
set-xdg-path XDG_CONFIG_HOME "$HOME/.config"
set-xdg-path XDG_STATE_HOME  "$HOME/.local/state"
set-xdg-path XDG_CACHE_HOME  "$HOME/.cache"

set-xdg-path-list XDG_DATA_DIRS   "/usr/local/share:/usr/share"
set-xdg-path-list XDG_CONFIG_DIRS "/etc/xdg"

# ~/.local/bin is the standard location for user-specific executables,
# but the XDG specification does not define an XDG_BIN_HOME variable.
XDG_USER_BIN_HOME="$HOME/.local/bin"
export XDG_USER_BIN_HOME

# XDG_RUNTIME_DIR has no portable default. It should normally be created and
# exported by the login/session manager, commonly as /run/user/$UID on Linux.
if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
  if [[ $XDG_RUNTIME_DIR != /* ]]; then
    printf 'Warning: ignoring relative XDG_RUNTIME_DIR: %s\n' "$XDG_RUNTIME_DIR" >&2
    unset XDG_RUNTIME_DIR
  else
    export XDG_RUNTIME_DIR
  fi
fi

# ---------------------------------------------------------------------------
# XDG user directories
# ---------------------------------------------------------------------------

set-xdg-user-dir XDG_DESKTOP_DIR     DESKTOP     "$HOME/Desktop"
set-xdg-user-dir XDG_DOWNLOAD_DIR    DOWNLOAD    "$HOME/Downloads"
set-xdg-user-dir XDG_TEMPLATES_DIR   TEMPLATES   "$HOME/Templates"
set-xdg-user-dir XDG_PUBLICSHARE_DIR PUBLICSHARE "$HOME/Public"
set-xdg-user-dir XDG_DOCUMENTS_DIR   DOCUMENTS   "$HOME/Documents"
set-xdg-user-dir XDG_MUSIC_DIR       MUSIC       "$HOME/Music"
set-xdg-user-dir XDG_PICTURES_DIR    PICTURES    "$HOME/Pictures"

case ${OSTYPE:-} in
  darwin*) _xdg_videos_fallback="$HOME/Movies" ;;
  *)       _xdg_videos_fallback="$HOME/Videos" ;;
esac

set-xdg-user-dir XDG_VIDEOS_DIR VIDEOS "$_xdg_videos_fallback"

unset _xdg_videos_fallback

# Print all resolved paths when this script is executed directly.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  print-xdg-paths
fi

# Config
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# Data
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export ANSIBLE_HOME="$XDG_DATA_HOME/ansible"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$XDG_USER_BIN_HOME"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Hist
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"

# Misc
export EDITOR="${EDITOR:-nvim}"
export PAGER="${PAGER:-less}"

# User defined env
source-if-exists "$_env_file_dir/.env.bash" || true

unset _env_file_dir
