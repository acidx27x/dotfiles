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

# Print the directory containing the file that called this helper.
current-file-dir() {
  local file="${funcsourcetrace[1]%:*}"

  [[ -n "$file" ]] || return 1

  (
    cd -P -- "$(dirname -- "$file")" 2>/dev/null &&
    pwd
  )
}

# Initialize native Zsh completion once for this dotfiles configuration.
load-zsh-completion() {
  emulate -L zsh

  local completion_cache="$XDG_CACHE_HOME/zsh/completion"
  local -a completion_paths

  (( $# == 0 )) || {
    print -u2 -- 'Usage: load-zsh-completion'
    return 2
  }

  (( ${_DOTFILES_ZSH_COMPLETION_INITIALIZED:-0} )) && return 0

  if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]] &&
      completion_paths+=("$HOMEBREW_PREFIX/share/zsh-completions")
    [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]] &&
      completion_paths+=("$HOMEBREW_PREFIX/share/zsh/site-functions")
  fi

  typeset -gU fpath
  fpath=("${completion_paths[@]}" "${fpath[@]}")

  zmodload zsh/complist || return
  autoload -Uz compinit

  if { [[ -d $completion_cache && -w $completion_cache ]] ||
       { mkdir -p -- "$completion_cache" 2>/dev/null && [[ -w $completion_cache ]]; } }
  then
    # Trust every configured completion path, including Homebrew paths.
    compinit -u -d "$completion_cache/zcompdump-$ZSH_VERSION" || return
    zstyle ':completion:*' use-cache yes
    zstyle ':completion:*' cache-path "$completion_cache"
  else
    print -u2 -- "WARNING, load-zsh-completion: could not create completion cache: $completion_cache"
    compinit -u -D || return
  fi

  typeset -g _DOTFILES_ZSH_COMPLETION_INITIALIZED=1
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
    load-zsh-completion 'Initialize native Zsh completion once.' \
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
