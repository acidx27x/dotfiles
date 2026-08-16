# ~/.config/zsh/env.zsh
# Environment shared by interactive and non-interactive Zsh invocations.

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  print -u2 -- 'Error: HOME must be an absolute path.'
  return 1 2>/dev/null || exit 1
fi

if [[ ${XDG_CONFIG_HOME:-} == /* ]]; then
  _zsh_config_dir="$XDG_CONFIG_HOME/zsh"
else
  _zsh_config_dir="$HOME/.config/zsh"
fi

# Keep direct execution useful while .zshrc supplies these modules normally.
if (( ! $+functions[set-xdg-path] )); then
  source "$_zsh_config_dir/utils.zsh" || exit 1
fi

if (( ! $+functions[print-xdg-paths] )); then
  source "$_zsh_config_dir/functions.zsh" || exit 1
fi

unset _zsh_config_dir

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

# Misc
export EDITOR="${EDITOR:-nvim}"
export PAGER="${PAGER:-less}"

# Rust
# install with '--no-modify-path'
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path
export RUST_HOME="/opt/rust"
export RUSTUP_HOME="$RUST_HOME/rustup"
export CARGO_HOME="$RUST_HOME/cargo"
export CARGO_INSTALL_ROOT="$RUST_HOME"

# User defined env
source-if-exists "$(current-file-dir)/.env.bash" || true
