#!/usr/bin/env bash

set -Eeuo pipefail

readonly RUSTUP_INSTALL_URL="https://sh.rustup.rs"
readonly RUST_HOME="/opt/rust"
readonly RUSTUP_HOME="$RUST_HOME/rustup"
readonly CARGO_HOME="$RUST_HOME/cargo"
readonly CARGO_INSTALL_ROOT="$RUST_HOME"
DRY_RUN=false
INSTALLER_FILE=""

usage() {
  cat <<'EOF'
Usage: setup/rust.sh [--dry-run] [--help]

Install rustup and the stable Rust toolchain into /opt/rust using the
paths exported by this repository's Bash and Zsh configuration.

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

run_rustup() {
  env \
    RUSTUP_HOME="$RUSTUP_HOME" \
    CARGO_HOME="$CARGO_HOME" \
    CARGO_INSTALL_ROOT="$CARGO_INSTALL_ROOT" \
    "$@"
}

main() {
  local command_name
  local group_name
  local platform
  local rustup_bin="$CARGO_HOME/bin/rustup"
  local user_name

  parse_args "$@"
  require_command uname

  platform="$(uname -s)"
  case "$platform" in
    Darwin | Linux)
      ;;
    *)
      die "Unsupported platform: $platform"
      ;;
  esac

  [[ ${HOME:-} == /* ]] || die 'HOME must be an absolute path.'
  ((EUID != 0)) || die 'Run this setup as a regular user, not root.'

  if [[ -L "$RUST_HOME" ]]; then
    die "$RUST_HOME must be a real directory, not a symbolic link."
  fi
  if [[ -e "$RUST_HOME" && ! -d "$RUST_HOME" ]]; then
    die "$RUST_HOME exists but is not a directory."
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ ! -d "$RUST_HOME" ]]; then
      log_dry_run "Would create user-owned directory: $RUST_HOME"
    fi
    if [[ ! -x "$rustup_bin" ]]; then
      log_dry_run "Would download and run: $RUSTUP_INSTALL_URL"
    fi
    log_dry_run "Would install or update the stable toolchain with the default profile."
    log_dry_run "Would set the default Rust toolchain to stable."
    return
  fi

  require_command env

  if [[ ! -d "$RUST_HOME" ]]; then
    for command_name in id install sudo; do
      require_command "$command_name"
    done
    user_name="$(id -un)"
    group_name="$(id -gn)"
    log_info "Creating user-owned Rust directory: $RUST_HOME"
    sudo install -d -m 0755 -o "$user_name" -g "$group_name" "$RUST_HOME"
  fi

  [[ -w "$RUST_HOME" ]] || die "Rust directory is not writable: $RUST_HOME"

  if [[ ! -x "$rustup_bin" ]]; then
    for command_name in curl mktemp rm; do
      require_command "$command_name"
    done
    [[ -x /bin/sh ]] || die 'Required shell is not executable: /bin/sh'

    INSTALLER_FILE="$(mktemp "${TMPDIR:-/tmp}/rustup-install.XXXXXX")"
    log_info 'Downloading the official rustup installer.'
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
      --output "$INSTALLER_FILE" "$RUSTUP_INSTALL_URL"
    log_info 'Installing rustup and the stable Rust toolchain.'
    run_rustup /bin/sh "$INSTALLER_FILE" \
      -y \
      --no-modify-path \
      --profile default \
      --default-toolchain stable
  else
    log_info 'Installing or updating the stable Rust toolchain.'
    run_rustup "$rustup_bin" toolchain install stable --profile default
    run_rustup "$rustup_bin" default stable
  fi

  [[ -x "$rustup_bin" ]] || die "rustup executable not found after setup: $rustup_bin"

  run_rustup "$rustup_bin" --version
  run_rustup "$CARGO_HOME/bin/rustc" --version
  run_rustup "$CARGO_HOME/bin/cargo" --version

  log_info 'Rust setup complete.'
  log_info 'Next: finish any remaining dotfile setup, then close this terminal and open a new one.'
}

main "$@"
