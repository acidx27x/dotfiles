#!/usr/bin/env bash

set -Eeuo pipefail

readonly MANAGED_MARKER="# Managed by acidx27x/dotfiles setup/codex.sh"
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: setup/codex.sh [--dry-run] [--help]

Install the portable Codex base config into /etc/codex and Stow the
repository-managed Codex files into the current user's home directory.

Options:
  --dry-run  Show the planned operations without changing files or using sudo.
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

trap on_error ERR

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

main() {
  local command_name script_dir dotfiles_root base_config codex_home_dir
  local system_config_dir system_config platform system_action

  parse_args "$@"

  for command_name in cmp grep stow uname; do
    require_command "$command_name"
  done

  platform="$(uname -s)"
  case "$platform" in
    Darwin | Linux)
      ;;
    *)
      die "Unsupported platform: $platform"
      ;;
  esac

  [[ -n "${HOME:-}" ]] || die 'HOME must be set.'

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
  dotfiles_root="$(cd -- "$script_dir/.." && pwd -P)"
  base_config="$dotfiles_root/codex-system/etc/codex/config.toml"
  codex_home_dir="$HOME/.codex"
  system_config_dir="/etc/codex"
  system_config="$system_config_dir/config.toml"

  [[ -f "$base_config" && -r "$base_config" ]] ||
    die "Portable base config is missing or unreadable: $base_config"
  grep -Fqx "$MANAGED_MARKER" "$base_config" ||
    die "Portable base config is missing its managed marker: $base_config"

  if [[ -L "$codex_home_dir" ]]; then
    die "$codex_home_dir must be a real directory, not a symbolic link."
  fi
  if [[ -e "$codex_home_dir" && ! -d "$codex_home_dir" ]]; then
    die "$codex_home_dir exists but is not a directory."
  fi

  if [[ -L "$system_config_dir" ]]; then
    die "$system_config_dir must be a real directory, not a symbolic link."
  fi
  if [[ -e "$system_config_dir" && ! -d "$system_config_dir" ]]; then
    die "$system_config_dir exists but is not a directory."
  fi

  system_action="install"
  if [[ -L "$system_config" ]]; then
    die "$system_config is a symbolic link; refusing to replace it."
  elif [[ -e "$system_config" ]]; then
    [[ -f "$system_config" && -r "$system_config" ]] ||
      die "$system_config exists but is not a readable regular file."

    if cmp -s "$base_config" "$system_config"; then
      system_action="none"
    elif grep -Fqx "$MANAGED_MARKER" "$system_config"; then
      system_action="update"
    else
      die "$system_config is not managed by this repository; refusing to replace it."
    fi
  fi

  if [[ "$system_action" != "none" ]]; then
    require_command install
    if ((EUID != 0)); then
      require_command sudo
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ ! -d "$codex_home_dir" ]]; then
      log_dry_run "Would create directory: $codex_home_dir"
    fi
    log_dry_run "Would run Stow preflight and restow package 'codex' into: $HOME"
    case "$system_action" in
      install)
        log_dry_run "Would install portable base config: $system_config"
        ;;
      update)
        log_dry_run "Would update repository-managed base config: $system_config"
        ;;
      none)
        log_dry_run "Portable base config is already current: $system_config"
        ;;
    esac
    return
  fi

  mkdir -p "$codex_home_dir"

  log_info "Checking the Codex Stow package for conflicts."
  (
    cd -- "$dotfiles_root"
    stow --restow --simulate --verbose --no-folding --target="$HOME" codex
  )

  if [[ "$system_action" == "none" ]]; then
    log_info "Portable base config is already current: $system_config"
  elif ((EUID == 0)); then
    install -d -m 0755 "$system_config_dir"
    install -m 0644 "$base_config" "$system_config"
  else
    sudo install -d -m 0755 "$system_config_dir"
    sudo install -m 0644 "$base_config" "$system_config"
  fi

  if [[ "$system_action" != "none" ]]; then
    log_info "Installed portable base config: $system_config"
  fi

  log_info "Restowing the Codex package into $HOME."
  (
    cd -- "$dotfiles_root"
    stow --restow --verbose --no-folding --target="$HOME" codex
  )

  log_info 'Codex setup complete.'
}

main "$@"
