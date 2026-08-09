# ~/.config/zsh/utils.zsh
# Reusable helpers for Zsh configuration.

# Return success when every supplied command exists.
has-cmd() {
  emulate -L zsh

  local name
  (( $# > 0 )) || return 1

  for name in "$@"; do
    if [[ $name == */* ]]; then
      [[ -x $name ]] || return 1
    else
      command -v "$name" >/dev/null 2>&1 || return 1
    fi
  done
}

# Evaluate initialization code printed by a command.
shell-init() {
  emulate -L zsh

  local command_name
  local init_code

  (( $# >= 2 )) || {
    print -u2 -- 'Usage: shell-init COMMAND ARGUMENT...'
    return 2
  }

  command_name=$1
  shift

  has-cmd "$command_name" || return 127
  init_code=$("$command_name" "$@") || return
  eval "$init_code"
}

# Source a file only when it exists and is readable.
source-if-exists() {
  emulate -L zsh

  local file=${1:-}
  [[ -n $file && -r $file ]] || return 1
  source "$file"
}

# Source the first readable file from a list.
source-first() {
  emulate -L zsh

  local file
  for file in "$@"; do
    if [[ -r $file ]]; then
      source "$file"
      return 0
    fi
  done
  return 1
}

# Source readable *.zsh files from one or more directories in lexical order.
source-conf-dirs() {
  emulate -L zsh

  local dir file
  local source_status=0
  local LC_ALL=C
  local -a files

  for dir in "$@"; do
    [[ -d $dir ]] || continue
    files=("$dir"/*.zsh(N))

    for file in "${files[@]}"; do
      [[ -f $file && -r $file ]] || continue
      source "$file" || {
        source_status=1
        print -u2 -- "WARNING, utils.zsh: ${file:t} source failed"
      }
    done
  done

  return $source_status
}

# Prepend existing directories to PATH without duplicates.
path-prepend() {
  emulate -L zsh

  local -a directories=("$@")
  local directory
  local i

  typeset -gU path PATH

  for (( i = ${#directories}; i >= 1; i-- )); do
    directory=${directories[i]}
    [[ -n $directory && -d $directory ]] || continue
    path=("$directory" "${path[@]}")
  done

  export PATH
}

# Print documented functions that are available in the current shell.
_print-function-catalog() {
  emulate -L zsh

  local title=$1
  local name description

  shift
  print -r -- "$title"

  while (( $# >= 2 )); do
    name=$1
    description=$2
    shift 2

    if (( $+functions[$name] )); then
      printf '  %-24s %s\n' "$name" "$description"
    fi
  done
}

# List configuration utilities with short descriptions.
utils-help() {
  _print-function-catalog 'Zsh configuration utilities:' \
    has-cmd 'Check that every supplied command exists.' \
    path-prepend 'Prepend existing directories to PATH.' \
    set-xdg-path 'Set one absolute XDG path.' \
    set-xdg-path-list 'Set an XDG search path list.' \
    set-xdg-user-dir 'Resolve one XDG user directory.' \
    shell-init 'Evaluate initialization code from a command.' \
    source-conf-dirs 'Source readable Zsh modules in lexical order.' \
    source-first 'Source the first readable file in a list.' \
    source-if-exists 'Source a file when it is readable.' \
    utils-help 'List available Zsh configuration utilities.'
}
