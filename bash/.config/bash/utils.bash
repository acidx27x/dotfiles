# ~/.config/bash/utils.bash
# Reusable helpers for Bash configuration.

# Return success when the current shell is Brush.
is-brush() {
  [[ -n "${BRUSH_VERSION:-}" ]]
}

# Load Bash completion from Homebrew or a system location.
load-bash-completion() {
  local completion_file

  [[ -n "${BASH_COMPLETION_VERSINFO:-}" ]] && return 0
  shopt -oq posix && return 0

  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    completion_file="$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

    if [[ -r "$completion_file" ]]; then
      source "$completion_file"
      return
    fi
  fi

  for completion_file in \
    "/usr/share/bash-completion/bash_completion" \
    "/etc/bash_completion"
  do
    if [[ -r "$completion_file" ]]; then
      source "$completion_file"
      return
    fi
  done

  return 127
}

# Return success when every supplied command exists.
has-cmd() {
  local name

  (( $# > 0 )) || return 1

  for name in "$@"; do
    if [[ "$name" == */* ]]; then
      [[ -x "$name" ]] || return 1
    else
      command -v "$name" >/dev/null 2>&1 || return 1
    fi
  done
}

# Evaluate initialization code printed by a command.
shell-init() {
  local command_name
  local init_code

  (( $# >= 2 )) || {
    printf 'Usage: shell-init COMMAND ARGUMENT...\n' >&2
    return 2
  }

  command_name="$1"
  shift

  has-cmd "$command_name" || return 127

  init_code=$("$command_name" "$@") || return
  eval "$init_code"
}

# Source a file only when it exists and is readable.
source-if-exists() {
  local file="${1:-}"

  [[ -n "$file" && -r "$file" ]] || return 1
  source "$file"
}

# Source the first readable file from a list.
source-first() {
  local file

  for file in "$@"; do
    if [[ -r "$file" ]]; then
      source "$file"
      return 0
    fi
  done

  return 1
}

# Source all readable *.bash files from one or more directories.
source-conf-dirs() {
  local dir file
  local -a files
  local had_nullglob=0
  local had_failglob=0
  local source_status=0
  local LC_COLLATE=C

  shopt -q nullglob && had_nullglob=1
  shopt -q failglob && had_failglob=1

  shopt -s nullglob
  shopt -u failglob

  for dir in "$@"; do
    [[ -d "$dir" ]] || continue

    files=("$dir"/*.bash)

    for file in "${files[@]}"; do
      [[ -f "$file" && -r "$file" ]] || continue
      source "$file" || {
        source_status=1
        printf 'WARNING, utils.bash: %s source failed\n' "${file##*/}" >&2
      }
    done
  done

  if (( had_nullglob )); then
    shopt -s nullglob
  else
    shopt -u nullglob
  fi

  if (( had_failglob )); then
    shopt -s failglob
  else
    shopt -u failglob
  fi

  return "$source_status"
}

# Print the directory containing the file that called this helper.
current-file-dir() {
  local file="${BASH_SOURCE[1]:-}"

  [[ -n "$file" ]] || return 1

  (
    cd -P -- "$(dirname -- "$file")" 2>/dev/null &&
    pwd
  )
}

# Prepend existing directories to PATH without duplicates.
path-prepend() {
  local -a directories=("$@")
  local -a path_entries=()
  local -a updated_entries=()

  local directory
  local entry
  local joined_path
  local i

  IFS=: read -r -a path_entries <<< "${PATH-}"

  for ((i = ${#directories[@]} - 1; i >= 0; i--)); do
    directory="${directories[i]}"

    [[ -n "$directory" && -d "$directory" ]] || continue

    updated_entries=("$directory")

    for entry in "${path_entries[@]}"; do
      if [[ "$entry" != "$directory" ]]; then
        updated_entries+=("$entry")
      fi
    done

    path_entries=("${updated_entries[@]}")
  done

  joined_path=$(IFS=:; printf '%s' "${path_entries[*]}")

  PATH="$joined_path"
  export PATH
}

# Add a command to PROMPT_COMMAND without adding it twice.
add-prompt-command() {
  local new_command="${1:-}"
  local existing
  local declaration

  [[ -n "$new_command" ]] || return 1

  declaration=$(declare -p PROMPT_COMMAND 2>/dev/null || true)

  if [[ "$declaration" == 'declare -a'* ]]; then
    for existing in "${PROMPT_COMMAND[@]}"; do
      [[ "$existing" == "$new_command" ]] && return 0
    done

    PROMPT_COMMAND+=("$new_command")
    return 0
  fi

  case ";${PROMPT_COMMAND-};" in
    *";$new_command;"*) ;;
    ';;') PROMPT_COMMAND="$new_command" ;;
    *) PROMPT_COMMAND="${PROMPT_COMMAND};$new_command" ;;
  esac
}

# Append local history and import history written by other shells.
__sync_bash_history() {
  builtin history -a
  builtin history -c
  builtin history -r
}

# Set one XDG path, replacing invalid relative values with a default.
set-xdg-path() {
  local variable=$1
  local default_value=$2
  local current_value=${!variable}

  if [[ -z $current_value || $current_value != /* ]]; then
    printf -v "$variable" '%s' "$default_value"
  fi

  export "$variable"
}

# Set an XDG colon-separated path after removing relative entries.
set-xdg-path-list() {
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

# Resolve one XDG user directory, using xdg-user-dir when available.
set-xdg-user-dir() {
  local variable=$1
  local directory_name=$2
  local fallback=$3
  local current_value=${!variable}
  local detected_value=""

  if [[ $current_value == /* ]]; then
    export "$variable"
    return
  fi

  if command -v xdg-user-dir >/dev/null 2>&1; then
    detected_value=$(xdg-user-dir "$directory_name" 2>/dev/null || :)
  fi

  [[ $detected_value == /* ]] || detected_value=$fallback
  printf -v "$variable" '%s' "$detected_value"
  export "$variable"
}

# Print documented functions that are available in the current shell.
_print-function-catalog() {
  local title="$1"
  local name
  local description

  shift
  printf '%s\n' "$title"

  while (( $# >= 2 )); do
    name="$1"
    description="$2"
    shift 2

    if declare -F "$name" >/dev/null; then
      printf '  %-24s %s\n' "$name" "$description"
    fi
  done
}

# List configuration utilities with short descriptions.
utils-help() {
  _print-function-catalog 'Bash configuration utilities:' \
    add-prompt-command 'Add a command to PROMPT_COMMAND once.' \
    current-file-dir 'Print the calling config file directory.' \
    has-cmd 'Check that every supplied command exists.' \
    is-brush 'Check whether the current shell is Brush.' \
    load-bash-completion 'Load Homebrew or system Bash completion.' \
    path-prepend 'Prepend existing directories to PATH.' \
    set-xdg-path 'Set one absolute XDG path.' \
    set-xdg-path-list 'Set an XDG search path list.' \
    set-xdg-user-dir 'Resolve one XDG user directory.' \
    shell-init 'Evaluate initialization code from a command.' \
    source-conf-dirs 'Source readable Bash modules in lexical order.' \
    source-first 'Source the first readable file in a list.' \
    source-if-exists 'Source a file when it is readable.' \
    utils-help 'List available Bash configuration utilities.'
}
