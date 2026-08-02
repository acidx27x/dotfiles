# ~/.config/bash/env.bash
# Basic xdg standart env variables
#
# The scripts preserve valid existing values and supplies defaults when needed.

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  printf 'Error: HOME must be an absolute path.\n' >&2

  if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    return 1
  else
    exit 1
  fi
fi

# Set a single XDG path.
# Relative paths are invalid and are replaced with the standard default.
set_xdg_path() {
  local variable=$1
  local default_value=$2
  local current_value=${!variable}

  if [[ -z $current_value || $current_value != /* ]]; then
    printf -v "$variable" '%s' "$default_value"
  fi

  export "$variable"
}

# Set an XDG colon-separated search path.
# Invalid relative entries are removed.
set_xdg_path_list() {
  local variable=$1
  local default_value=$2
  local current_value=${!variable}
  local entry
  local -a entries=()
  local -a valid_entries=()

  [[ -n $current_value ]] || current_value=$default_value

  IFS=: read -r -a entries <<< "$current_value"

  for entry in "${entries[@]}"; do
    [[ $entry == /* ]] && valid_entries+=("$entry")
  done

  if ((${#valid_entries[@]} == 0)); then
    IFS=: read -r -a valid_entries <<< "$default_value"
  fi

  current_value=$(IFS=:; printf '%s' "${valid_entries[*]}")
  printf -v "$variable" '%s' "$current_value"
  export "$variable"
}

# ---------------------------------------------------------------------------
# XDG Base Directory Specification
# ---------------------------------------------------------------------------

set_xdg_path XDG_DATA_HOME   "$HOME/.local/share"
set_xdg_path XDG_CONFIG_HOME "$HOME/.config"
set_xdg_path XDG_STATE_HOME  "$HOME/.local/state"
set_xdg_path XDG_CACHE_HOME  "$HOME/.cache"

set_xdg_path_list XDG_DATA_DIRS   "/usr/local/share:/usr/share"
set_xdg_path_list XDG_CONFIG_DIRS "/etc/xdg"

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

set_xdg_user_dir() {
  local variable=$1
  local directory_name=$2
  local fallback=$3
  local current_value=${!variable}
  local detected_value=""

  # Keep an existing absolute value.
  if [[ $current_value == /* ]]; then
    export "$variable"
    return
  fi

  # Use xdg-user-dir when available. This handles localization and
  # ~/.config/user-dirs.dirs.
  if command -v xdg-user-dir >/dev/null 2>&1; then
    detected_value=$(xdg-user-dir "$directory_name" 2>/dev/null || :)
  fi

  [[ $detected_value == /* ]] || detected_value=$fallback

  printf -v "$variable" '%s' "$detected_value"
  export "$variable"
}

set_xdg_user_dir XDG_DESKTOP_DIR     DESKTOP     "$HOME/Desktop"
set_xdg_user_dir XDG_DOWNLOAD_DIR    DOWNLOAD    "$HOME/Downloads"
set_xdg_user_dir XDG_TEMPLATES_DIR   TEMPLATES   "$HOME/Templates"
set_xdg_user_dir XDG_PUBLICSHARE_DIR PUBLICSHARE "$HOME/Public"
set_xdg_user_dir XDG_DOCUMENTS_DIR   DOCUMENTS   "$HOME/Documents"
set_xdg_user_dir XDG_MUSIC_DIR       MUSIC       "$HOME/Music"
set_xdg_user_dir XDG_PICTURES_DIR    PICTURES    "$HOME/Pictures"
set_xdg_user_dir XDG_VIDEOS_DIR      VIDEOS      "$HOME/Movies"

# ---------------------------------------------------------------------------
# Optional: print all resolved paths when this script is executed directly
# ---------------------------------------------------------------------------

print_xdg_paths() {
  printf '%-24s %s\n' \
    "XDG_DATA_HOME"        "$XDG_DATA_HOME" \
    "XDG_CONFIG_HOME"      "$XDG_CONFIG_HOME" \
    "XDG_STATE_HOME"       "$XDG_STATE_HOME" \
    "XDG_CACHE_HOME"       "$XDG_CACHE_HOME" \
    "XDG_RUNTIME_DIR"      "${XDG_RUNTIME_DIR:-<not set>}" \
    "XDG_DATA_DIRS"        "$XDG_DATA_DIRS" \
    "XDG_CONFIG_DIRS"      "$XDG_CONFIG_DIRS" \
    "XDG_USER_BIN_HOME"    "$XDG_USER_BIN_HOME" \
    "XDG_DESKTOP_DIR"      "$XDG_DESKTOP_DIR" \
    "XDG_DOWNLOAD_DIR"     "$XDG_DOWNLOAD_DIR" \
    "XDG_TEMPLATES_DIR"    "$XDG_TEMPLATES_DIR" \
    "XDG_PUBLICSHARE_DIR"  "$XDG_PUBLICSHARE_DIR" \
    "XDG_DOCUMENTS_DIR"    "$XDG_DOCUMENTS_DIR" \
    "XDG_MUSIC_DIR"        "$XDG_MUSIC_DIR" \
    "XDG_PICTURES_DIR"     "$XDG_PICTURES_DIR" \
    "XDG_VIDEOS_DIR"       "$XDG_VIDEOS_DIR"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  print_xdg_paths
fi

# Config
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Data
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export ANSIBLE_HOME="$XDG_DATA_HOME/ansible"
export GOPATH="$XDG_DATA_HOME/go"
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
source_if_exists "$(current_file_dir)/.env.bash" || true
