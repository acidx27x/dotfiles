#!/usr/bin/env bash

set -Eeuo pipefail

readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DRY_RUN=false
INSTALLER_FILE=""

usage() {
  cat <<'EOF'
Usage: setup/homebrew.sh [--dry-run] [--help]

Install Homebrew when needed, Stow the repository's Homebrew configuration,
and install the global Brewfile.

Options:
  --dry-run  Show the planned operations without changing files or downloading anything.
  -h, --help Show this help text.
EOF
}

log_info() {
  printf '[INFO] %s\n' "$*" >&2
}

log_dry_run() {
  printf '[DRY-RUN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

on_error() {
  local status=$?
  local line="${BASH_LINENO[0]:-${LINENO}}"

  trap - ERR
  printf '[ERROR] Setup failed near line %s (exit %s).\n' "$line" "$status" >&2
  exit "$status"
}

cleanup() {
  if [[ -n "$INSTALLER_FILE" && -f "$INSTALLER_FILE" ]]; then
    rm -f -- "$INSTALLER_FILE"
  fi
}

trap on_error ERR
trap cleanup EXIT

require_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 ||
    die "Required command not found: $command_name"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

find_brew() {
  local candidate
  local platform="$1"

  if [[ -n ${HOMEBREW_BREW_FILE:-} && -x "$HOMEBREW_BREW_FILE" ]]; then
    printf '%s\n' "$HOMEBREW_BREW_FILE"
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return
  fi

  case "$platform" in
    Darwin)
      for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$candidate" ]]; then
          printf '%s\n' "$candidate"
          return
        fi
      done
      ;;
    Linux)
      for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [[ -x "$candidate" ]]; then
          printf '%s\n' "$candidate"
          return
        fi
      done
      ;;
  esac

  return 1
}

main() {
  local brew_bin=""
  local brew_prefix
  local brewfile
  local command_name
  local dotfiles_root
  local platform
  local script_dir
  local stow_bin

  parse_args "$@"
  require_command uname

  platform="$(uname -s)"
  case "$platform" in
    Darwin | Linux) ;;
    *)
      die "Unsupported platform: $platform"
      ;;
  esac

  [[ ${HOME:-} == /* ]] || die 'HOME must be an absolute path.'
  ((EUID != 0)) || die 'Run this setup as a regular user, not root.'

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
  dotfiles_root="$(cd -- "$script_dir/.." && pwd -P)"
  brewfile="$dotfiles_root/brew/.config/homebrew/Brewfile"

  [[ -f "$brewfile" && -r "$brewfile" ]] ||
    die "Brewfile is missing or unreadable: $brewfile"

  if brew_bin="$(find_brew "$platform")"; then
    log_info "Using Homebrew: $brew_bin"
  elif [[ "$DRY_RUN" == "false" ]]; then
    for command_name in curl mktemp rm; do
      require_command "$command_name"
    done
    [[ -x /bin/bash ]] || die 'Required shell is not executable: /bin/bash'

    INSTALLER_FILE="$(mktemp "${TMPDIR:-/tmp}/homebrew-install.XXXXXX")"
    log_info "Downloading the official Homebrew installer."
    curl --fail --silent --show-error --location \
      --output "$INSTALLER_FILE" "$HOMEBREW_INSTALL_URL"
    log_info 'Running the official Homebrew installer.'
    /bin/bash "$INSTALLER_FILE"

    brew_bin="$(find_brew "$platform")" ||
      die 'Homebrew installation completed, but brew could not be found.'
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ -z "$brew_bin" ]]; then
      log_dry_run "Would download and run: $HOMEBREW_INSTALL_URL"
    fi
    log_dry_run "Would ensure GNU Stow is installed with Homebrew."
    log_dry_run "Would preflight and restow package 'brew' into: $HOME"
    log_dry_run "Would install the global Brewfile: $brewfile"
    return
  fi

  log_info 'Ensuring GNU Stow is installed.'
  "$brew_bin" install stow

  brew_prefix="$("$brew_bin" --prefix)"
  stow_bin="$brew_prefix/bin/stow"
  [[ -x "$stow_bin" ]] || die "Homebrew Stow executable not found: $stow_bin"

  log_info "Checking the Homebrew Stow package for conflicts."
  (
    cd -- "$dotfiles_root"
    "$stow_bin" --restow --simulate --verbose --no-folding --target="$HOME" brew
  )

  log_info "Restowing the Homebrew package into $HOME."
  (
    cd -- "$dotfiles_root"
    "$stow_bin" --restow --verbose --no-folding --target="$HOME" brew
  )

  log_info 'Installing the global Brewfile.'
  XDG_CONFIG_HOME="$HOME/.config" "$brew_bin" bundle --global --no-upgrade

  log_info 'Homebrew setup complete.'
  log_info 'Next: finish any remaining dotfile setup, then close this terminal and open a new one.'
}

main "$@"
