# ~/.config/bash/functions.bash
# Reusable helpers and interactive shell functions.

# ---------------------------------------------------------------------------
# Command and initialization helpers
# ---------------------------------------------------------------------------

# Return success when the current shell is Brush.
is_brush() {
  [[ -n "${BRUSH_VERSION:-}" ]]
}

# Print the currently running interactive shell.
current_shell() {
  if is_brush; then
    printf 'brush %s\n' "$BRUSH_VERSION"
  else
    printf 'bash %s\n' "${BASH_VERSION:-unknown}"
  fi
}

load_bash_completion() {
  # Already loaded.
  [[ -n "${BASH_COMPLETION_VERSINFO:-}" ]] && return 0

  # Programmable completion is disabled in POSIX mode.
  shopt -oq posix && return 1

  # Prefer Homebrew completion when installed.
  if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    source_if_exists \
      "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" &&
      return 0
  fi

  # Fall back to Debian/Ubuntu completion.
  source_first \
    "/usr/share/bash-completion/bash_completion" \
    "/etc/bash_completion"
}

# Return success when every supplied command exists.
#
# Examples:
#   has_cmd git
#   has_cmd git fzf starship
#   has_cmd /home/linuxbrew/.linuxbrew/bin/brew
has_cmd() {
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
#
# Examples:
#   shell_init starship init bash
#   shell_init fzf --bash
#   shell_init direnv hook bash
shell_init() {
  local command_name
  local init_code

  (( $# >= 2 )) || {
    printf 'Usage: shell_init COMMAND ARGUMENT...\n' >&2
    return 2
  }

  command_name="$1"
  shift

  has_cmd "$command_name" || return 127

  init_code=$("$command_name" "$@") || return
  eval "$init_code"
}

# Source a file only when it exists and is readable.
source_if_exists() {
  local file="${1:-}"

  [[ -n "$file" && -r "$file" ]] || return 1
  source "$file"
}

# Source the first readable file from a list.
source_first() {
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
#
# Files are loaded in lexical order, so numeric prefixes can control order:
#   10-environment.bash
#   20-paths.bash
#   30-aliases.bash
source_conf_dirs() {
  local dir file
  local -a files
  local had_nullglob=0
  local had_failglob=0
  local LC_COLLATE=C

  shopt -q nullglob && had_nullglob=1
  shopt -q failglob && had_failglob=1

  # An empty directory should produce an empty array rather than an error
  # or a literal "*.bash" filename.
  shopt -s nullglob
  shopt -u failglob

  for dir in "$@"; do
    [[ -d "$dir" ]] || continue

    files=("$dir"/*.bash)

    for file in "${files[@]}"; do
      [[ -f "$file" && -r "$file" ]] || continue
      source "$file" || {
        printf 'WARNING, functions.bash: %s source failed\n' "${file##*/}" >&2
      }
    done
  done

  (( had_nullglob )) || shopt -u nullglob
  (( had_failglob )) && shopt -s failglob
}

# ---------------------------------------------------------------------------
# PATH helpers
# ---------------------------------------------------------------------------

current_file_dir() {
  local file="${BASH_SOURCE[1]:-}"

  [[ -n "$file" ]] || return 1

  (
    cd -P -- "$(dirname -- "$file")" 2>/dev/null &&
    pwd
  )
}

# Prepend existing directories to PATH.
#
# Features:
# - skips nonexistent directories
# - removes duplicate occurrences
# - moves existing occurrences to the front
# - preserves argument priority
#
# The first argument receives the highest priority.
path_prepend() {
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

# ---------------------------------------------------------------------------
# Prompt and history helpers
# ---------------------------------------------------------------------------

# Add a command to PROMPT_COMMAND without adding it twice.
#
# Supports both the traditional string form and the array form.
add_prompt_command() {
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
    *";$new_command;"*)
      ;;

    ';;')
      PROMPT_COMMAND="$new_command"
      ;;

    *)
      PROMPT_COMMAND="${PROMPT_COMMAND};$new_command"
      ;;
  esac
}

# Append this shell's commands and import commands written by other shells.
__sync_bash_history() {
  builtin history -a
  builtin history -c
  builtin history -r
}

# ---------------------------------------------------------------------------
# Windows Zone.Identifier cleanup
# ---------------------------------------------------------------------------

# Remove Windows download-zone metadata files recursively.
#
# Usage:
#   rm_zone_id
#   rm_zone_id ~/Downloads
rm_zone_id() {
  local root="${1:-.}"

  [[ -d "$root" ]] || {
    printf 'Not a directory: %s\n' "$root" >&2
    return 1
  }

  find "$root" \
    -type f \
    -name '*:Zone.Identifier' \
    -print \
    -delete
}

# ---------------------------------------------------------------------------
# Encoding detection
# ---------------------------------------------------------------------------

# Detect the likely encoding of a text file.
detect_encoding() {
  local file="${1:-}"
  local encoding=""

  [[ -n "$file" ]] || {
    printf 'Usage: detect_encoding FILE\n' >&2
    return 2
  }

  [[ -f "$file" && -r "$file" ]] || {
    printf 'Not a readable regular file: %s\n' "$file" >&2
    return 1
  }

  if has_cmd uchardet; then
    encoding=$(uchardet "$file" 2>/dev/null || true)
  fi

  case "$encoding" in
    "" | unknown | UNKNOWN)
      has_cmd file || {
        printf 'Neither uchardet nor file is available.\n' >&2
        return 127
      }

      encoding=$(file -b --mime-encoding -- "$file") || return
      ;;
  esac

  case "$encoding" in
    binary | BINARY)
      printf 'binary\n'
      ;;

    us-ascii | US-ASCII | ascii | ASCII)
      printf 'UTF-8\n'
      ;;

    utf-8 | UTF-8)
      printf 'UTF-8\n'
      ;;

    unknown-8bit | UNKNOWN-8BIT | unknown | UNKNOWN | "")
      printf 'Could not determine encoding: %s\n' "$file" >&2
      return 2
      ;;

    *)
      printf '%s\n' "$encoding"
      ;;
  esac
}

_file_exists_and_rw() {
  local file="$1"

  [[ -f "$file" && -r "$file" && -w "$file" ]] || {
    printf 'Not a readable and writable regular file: %s\n' \
      "$file" >&2
    return 1
  }
}

# ---------------------------------------------------------------------------
# UTF-8 conversion
# ---------------------------------------------------------------------------

_to_utf8_impl() {
  local add_bom="$1"
  shift

  local file
  local encoding
  local temp
  local body
  local signature

  (( $# > 0 )) || {
    printf 'Usage: to_utf8[_bom] FILE...\n' >&2
    return 2
  }

  has_cmd iconv || {
    printf 'iconv is required.\n' >&2
    return 127
  }

  for file in "$@"; do
    _file_exists_and_rw "$file" || continue

    if ! encoding=$(detect_encoding "$file"); then
      printf 'Skipping file with unknown encoding: %s\n' \
        "$file" >&2
      continue
    fi

    if [[ "$encoding" == binary ]]; then
      printf 'Skipping binary file: %s\n' "$file" >&2
      continue
    fi

    temp=$(mktemp) || return 1
    body=""

    if ! iconv \
      -f "$encoding" \
      -t UTF-8 \
      "$file" > "$temp"
    then
      printf 'iconv failed for %s using encoding %s\n' \
        "$file" "$encoding" >&2

      rm -f -- "$temp"
      continue
    fi

    # Remove an existing UTF-8 BOM first.
    signature=$(
      LC_ALL=C od -An -tx1 -N3 "$temp" |
        tr -d ' \n'
    )

    if [[ "$signature" == efbbbf ]]; then
      body=$(mktemp) || {
        rm -f -- "$temp"
        return 1
      }

      if ! tail -c +4 -- "$temp" > "$body"; then
        rm -f -- "$temp" "$body"
        continue
      fi

      mv -f -- "$body" "$temp"
      body=""
    fi

    if (( add_bom )); then
      body=$(mktemp) || {
        rm -f -- "$temp"
        return 1
      }

      if ! {
        printf '\xEF\xBB\xBF'
        cat -- "$temp"
      } > "$body"
      then
        rm -f -- "$temp" "$body"
        continue
      fi

      mv -f -- "$body" "$temp"
      body=""
    fi

    if ! cat -- "$temp" > "$file"; then
      printf 'Failed to overwrite: %s\n' "$file" >&2
      rm -f -- "$temp"
      continue
    fi

    rm -f -- "$temp"

    if (( add_bom )); then
      printf 'Converted to UTF-8 with BOM from %s: %s\n' \
        "$encoding" "$file"
    else
      printf 'Converted to UTF-8 from %s: %s\n' \
        "$encoding" "$file"
    fi
  done
}

# Convert files to plain UTF-8, removing an existing BOM.
to_utf8() {
  _to_utf8_impl 0 "$@"
}

# Convert files to UTF-8 and ensure exactly one BOM is present.
to_utf8_bom() {
  _to_utf8_impl 1 "$@"
}

# ---------------------------------------------------------------------------
# ASCII conversion
# ---------------------------------------------------------------------------

to_us_ascii() {
  local file
  local encoding
  local temp

  (( $# > 0 )) || {
    printf 'Usage: to_us_ascii FILE...\n' >&2
    return 2
  }

  has_cmd iconv || {
    printf 'iconv is required.\n' >&2
    return 127
  }

  for file in "$@"; do
    _file_exists_and_rw "$file" || continue

    if ! encoding=$(detect_encoding "$file"); then
      printf 'Skipping file with unknown encoding: %s\n' \
        "$file" >&2
      continue
    fi

    if [[ "$encoding" == binary ]]; then
      printf 'Skipping binary file: %s\n' "$file" >&2
      continue
    fi

    temp=$(mktemp) || return 1

    if ! iconv \
      -f "$encoding" \
      -t 'US-ASCII//TRANSLIT' \
      "$file" > "$temp"
    then
      printf 'iconv failed for %s using encoding %s\n' \
        "$file" "$encoding" >&2

      rm -f -- "$temp"
      continue
    fi

    if ! cat -- "$temp" > "$file"; then
      printf 'Failed to overwrite: %s\n' "$file" >&2
      rm -f -- "$temp"
      continue
    fi

    rm -f -- "$temp"

    printf 'Converted to US-ASCII from %s: %s\n' \
      "$encoding" "$file"
  done
}
