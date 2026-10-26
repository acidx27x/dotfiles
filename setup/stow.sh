#!/usr/bin/env bash

set -Eeuo pipefail

ACTION=""
DRY_RUN=false
REPLACE=false
ALL=false
PLATFORM=""
DOTFILES_ROOT=""
TARGET_HOME=""
STOW_BIN=""
PACKAGE_GROUPS=()
PROFILE=""
PROFILE_SPECIFIED=false
AVAILABLE_PACKAGES=()
SELECTED_PACKAGES=()

usage() {
  cat <<'EOF'
Usage: setup/stow.sh <deploy|undeploy|restow> [options]

Deploy, remove, or refresh GNU Stow packages in the current user's home directory.

Options:
  --package NAME[,NAME...]  Select one or more packages. May be repeated.
  --profile NAME            Select one profile.
  --replace                 Replace the complete deployed selection (deploy only).
  --all                     Select every package (undeploy only).
  --dry-run                 Preview without changing the filesystem.
  -h, --help                Show this help text.

A deploy with no selection uses the linux or macos profile for the current platform.
Package and profile selections are mutually exclusive.
EOF
}

log_info() {
  printf '[INFO] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

die_usage() {
  printf '[ERROR] %s\n' "$*" >&2
  printf "Run '%s --help' for usage.\n" "${0##*/}" >&2
  exit 2
}

is_excluded_package() {
  case "$1" in
    .agents | .aws | .codex | .git | brave | codex-system | setup | windows | wsl)
      return 0
      ;;
  esac

  return 1
}

parse_args() {
  (($# > 0)) || die_usage 'An action is required.'

  case "$1" in
    deploy | undeploy | restow)
      ACTION="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die_usage "Unknown action: $1"
      ;;
  esac
  shift

  while (($# > 0)); do
    case "$1" in
      --package)
        (($# > 1)) || die_usage '--package requires a value.'
        PACKAGE_GROUPS+=("$2")
        shift
        ;;
      --profile)
        (($# > 1)) || die_usage '--profile requires a value.'
        [[ "$PROFILE_SPECIFIED" == "false" ]] ||
          die_usage '--profile may be specified only once.'
        PROFILE="$2"
        PROFILE_SPECIFIED=true
        shift
        ;;
      --replace)
        REPLACE=true
        ;;
      --all)
        ALL=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die_usage "Unknown argument: $1"
        ;;
    esac
    shift
  done

  if [[ "$REPLACE" == "true" && "$ACTION" != "deploy" ]]; then
    die_usage '--replace is valid only with deploy.'
  fi
  if [[ "$ALL" == "true" && "$ACTION" != "undeploy" ]]; then
    die_usage '--all is valid only with undeploy.'
  fi
  if [[ "$ALL" == "true" ]] && {
    ((${#PACKAGE_GROUPS[@]} > 0)) || [[ "$PROFILE_SPECIFIED" == "true" ]]
  }; then
    die_usage '--all cannot be combined with --package or --profile.'
  fi
  if ((${#PACKAGE_GROUPS[@]} > 0)) && [[ "$PROFILE_SPECIFIED" == "true" ]]; then
    die_usage '--package and --profile are mutually exclusive.'
  fi
}

detect_platform() {
  case "$(uname -s)" in
    Linux)
      PLATFORM=linux
      ;;
    Darwin)
      PLATFORM=macos
      ;;
    *)
      die 'This wrapper supports only Linux and macOS.'
      ;;
  esac
}

discover_packages() {
  local package_dir
  local package_name

  for package_dir in "$DOTFILES_ROOT"/*; do
    [[ -d "$package_dir" ]] || continue
    package_name="${package_dir##*/}"
    is_excluded_package "$package_name" && continue
    AVAILABLE_PACKAGES+=("$package_name")
  done

  ((${#AVAILABLE_PACKAGES[@]} > 0)) || die 'No Stow package directories were found.'
}

available_package_list() {
  local package_name
  local separator=""

  for package_name in "${AVAILABLE_PACKAGES[@]}"; do
    printf '%s%s' "$separator" "$package_name"
    separator=', '
  done
  printf '\n'
}

available_profile_list() {
  local profile_file
  local profile_name
  local separator=""

  for profile_file in "$DOTFILES_ROOT"/stow/profiles/*.txt; do
    [[ -f "$profile_file" ]] || continue
    profile_name="${profile_file##*/}"
    printf '%s%s' "$separator" "${profile_name%.txt}"
    separator=', '
  done
  printf '\n'
}

validate_name() {
  local kind="$1"
  local name="$2"

  case "$name" in
    '' | -* | .* | *[!A-Za-z0-9._-]*)
      die_usage "Invalid $kind name: '$name'"
      ;;
  esac
}

package_exists() {
  local candidate="$1"
  local package_name

  for package_name in "${AVAILABLE_PACKAGES[@]}"; do
    [[ "$candidate" == "$package_name" ]] && return 0
  done

  return 1
}

add_package() {
  local candidate="$1"
  local package_name

  validate_name package "$candidate"
  if ! package_exists "$candidate"; then
    die_usage "Unknown or excluded Stow package '$candidate'. Available packages: $(
      available_package_list
    )"
  fi

  for package_name in "${SELECTED_PACKAGES[@]}"; do
    [[ "$candidate" == "$package_name" ]] && return
  done
  SELECTED_PACKAGES+=("$candidate")
}

resolve_package_group() {
  local group="$1"
  local candidate

  while :; do
    case "$group" in
      *,*)
        candidate="${group%%,*}"
        group="${group#*,}"
        ;;
      *)
        candidate="$group"
        group=""
        ;;
    esac

    [[ -n "$candidate" ]] || die_usage 'Package lists cannot contain empty names.'
    add_package "$candidate"
    [[ -n "$group" ]] || break
  done
}

resolve_profile() {
  local profile_name="$1"
  local profile_path
  local package_name
  local line_number=0
  local package_count=0

  validate_name profile "$profile_name"
  profile_path="$DOTFILES_ROOT/stow/profiles/$profile_name.txt"
  if [[ ! -f "$profile_path" ]]; then
    die_usage "Unknown Stow profile '$profile_name'. Available profiles: $(
      available_profile_list
    )"
  fi

  while IFS= read -r package_name || [[ -n "$package_name" ]]; do
    line_number=$((line_number + 1))
    package_name="${package_name%$'\r'}"
    case "$package_name" in
      '' | \#*)
        continue
        ;;
    esac
    case "$package_name" in
      *[[:space:]]*)
        die_usage "Profile '$profile_name' line $line_number must contain one package name."
        ;;
    esac
    add_package "$package_name"
    package_count=$((package_count + 1))
  done <"$profile_path"

  ((package_count > 0)) || die_usage "Profile '$profile_name' does not select any packages."
}

resolve_selection() {
  local group
  local package_name

  if [[ "$ALL" == "true" ]]; then
    for package_name in "${AVAILABLE_PACKAGES[@]}"; do
      SELECTED_PACKAGES+=("$package_name")
    done
    return
  fi

  if [[ "$ACTION" == "deploy" && ${#PACKAGE_GROUPS[@]} -eq 0 &&
    "$PROFILE_SPECIFIED" == "false" ]]; then
    PROFILE="$PLATFORM"
    PROFILE_SPECIFIED=true
  fi

  for group in "${PACKAGE_GROUPS[@]}"; do
    resolve_package_group "$group"
  done
  [[ "$PROFILE_SPECIFIED" == "false" ]] || resolve_profile "$PROFILE"

  ((${#SELECTED_PACKAGES[@]} > 0)) ||
    die_usage "$ACTION requires --package or --profile. Use --all to remove everything."
}

run_stow() {
  local simulate="$1"
  local status
  local -a command_args

  command_args=(
    "--dir=$DOTFILES_ROOT"
    "--target=$TARGET_HOME"
    --no-folding
    --verbose
  )
  [[ "$simulate" == "true" ]] && command_args+=(--simulate)

  if [[ "$REPLACE" == "true" ]]; then
    command_args+=(--delete)
    command_args+=("${AVAILABLE_PACKAGES[@]}")
    command_args+=(--stow)
    command_args+=("${SELECTED_PACKAGES[@]}")
  else
    case "$ACTION" in
      deploy)
        command_args+=(--stow)
        ;;
      undeploy)
        command_args+=(--delete)
        ;;
      restow)
        command_args+=(--restow)
        ;;
    esac
    command_args+=("${SELECTED_PACKAGES[@]}")
  fi

  # Use the tracked ignore file without loading .stowrc options from the user or caller.
  # The explicit deployment target remains TARGET_HOME.
  if (
    cd -- /
    HOME="$DOTFILES_ROOT/stow" "$STOW_BIN" "${command_args[@]}"
  ); then
    return
  else
    status=$?
  fi

  return "$status"
}

main() {
  local script_dir
  local status

  parse_args "$@"
  detect_platform

  [[ ${HOME:-} == /* ]] || die 'HOME must be an absolute path.'
  TARGET_HOME="$HOME"
  [[ -d "$TARGET_HOME" ]] || die "HOME does not exist: $TARGET_HOME"

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
  DOTFILES_ROOT="$(cd -- "$script_dir/.." && pwd -P)"
  [[ -r "$DOTFILES_ROOT/stow/.stow-global-ignore" ]] ||
    die 'The tracked GNU Stow ignore file is missing or unreadable.'
  if [[ -e "$DOTFILES_ROOT/stow/.stowrc" || -L "$DOTFILES_ROOT/stow/.stowrc" ||
    -e /.stowrc || -L /.stowrc ]]; then
    die 'A Stow resource file would weaken the wrapper safety policy.'
  fi

  if ! STOW_BIN="$(command -v stow)"; then
    printf '[ERROR] Required command not found: stow\n' >&2
    exit 127
  fi

  discover_packages
  resolve_selection

  log_info "Preflighting $ACTION for: ${SELECTED_PACKAGES[*]}"
  if run_stow true; then
    :
  else
    status=$?
    printf '[ERROR] Stow preflight failed; no changes were applied.\n' >&2
    exit "$status"
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info 'Dry run complete; no changes were applied.'
    return
  fi

  log_info "Applying $ACTION into: $TARGET_HOME"
  if run_stow false; then
    log_info 'Stow operation complete.'
  else
    status=$?
    printf '[ERROR] Stow apply failed with exit status %s.\n' "$status" >&2
    exit "$status"
  fi
}

main "$@"
