# ~/.config/zsh/env.zsh
# Environment shared by interactive and non-interactive Zsh invocations.

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  print -u2 -- 'Error: HOME must be an absolute path.'
  return 1
fi

# Set one XDG path, replacing invalid relative values with a default.
set-xdg-path() {
  emulate -L zsh

  local variable=$1
  local default_value=$2
  local current_value=${(P)variable}

  if [[ -z $current_value || $current_value != /* ]]; then
    current_value=$default_value
  fi

  typeset -gx "$variable=$current_value"
}

# Set an XDG colon-separated path after removing relative entries.
set-xdg-path-list() {
  emulate -L zsh

  local variable=$1
  local default_value=$2
  local current_value=${(P)variable}
  local entry
  local -a entries valid_entries

  [[ -n $current_value ]] || current_value=$default_value
  entries=("${(@s.:.)current_value}")

  for entry in "${entries[@]}"; do
    [[ $entry == /* ]] && valid_entries+=("$entry")
  done

  if (( ${#valid_entries} == 0 )); then
    valid_entries=("${(@s.:.)default_value}")
  fi

  current_value="${(j.:.)valid_entries}"
  typeset -gx "$variable=$current_value"
}

# Resolve one XDG user directory, using xdg-user-dir when available.
set-xdg-user-dir() {
  emulate -L zsh

  local variable=$1
  local directory_name=$2
  local fallback=$3
  local current_value=${(P)variable}
  local detected_value=''

  if [[ $current_value == /* ]]; then
    typeset -gx "$variable=$current_value"
    return
  fi

  if command -v xdg-user-dir >/dev/null 2>&1; then
    detected_value=$(xdg-user-dir "$directory_name" 2>/dev/null || true)
  fi

  [[ $detected_value == /* ]] || detected_value=$fallback
  typeset -gx "$variable=$detected_value"
}

# ---------------------------------------------------------------------------
# XDG Base Directory Specification
# ---------------------------------------------------------------------------

set-xdg-path XDG_DATA_HOME   "$HOME/.local/share"
set-xdg-path XDG_CONFIG_HOME "$HOME/.config"
set-xdg-path XDG_STATE_HOME  "$HOME/.local/state"
set-xdg-path XDG_CACHE_HOME  "$HOME/.cache"

set-xdg-path-list XDG_DATA_DIRS   '/usr/local/share:/usr/share'
set-xdg-path-list XDG_CONFIG_DIRS '/etc/xdg'

export XDG_USER_BIN_HOME="$HOME/.local/bin"

# XDG_RUNTIME_DIR has no portable fallback.
if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
  if [[ $XDG_RUNTIME_DIR != /* ]]; then
    print -u2 -- "Warning: ignoring relative XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    unset XDG_RUNTIME_DIR
  else
    export XDG_RUNTIME_DIR
  fi
fi

# Keep PATH unique while preserving Zsh's native tied path array.
typeset -gU path PATH
if [[ -d $XDG_USER_BIN_HOME ]]; then
  path=("$XDG_USER_BIN_HOME" "${path[@]}")
fi
export PATH

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

# Application configuration and data.
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export ANSIBLE_HOME="$XDG_DATA_HOME/ansible"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$XDG_USER_BIN_HOME"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# Application history.
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"
export SQLITE_HISTORY="$XDG_STATE_HOME/sqlite_history"
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"

export EDITOR="${EDITOR:-nvim}"
export PAGER="${PAGER:-less}"

# Machine-local environment overrides.
_env_file_dir="${${(%):-%x}:A:h}"
if [[ -r "$_env_file_dir/.env.zsh" ]]; then
  source "$_env_file_dir/.env.zsh"
fi
unset _env_file_dir
