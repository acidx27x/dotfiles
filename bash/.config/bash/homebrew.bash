# ~/.config/bash/homebrew.bash
# Homebrew / Linuxbrew initialization.

# Prepend Homebrew's global bin directories to PATH.
homebrew-path-prepend() {
  local brew_prefix="${HOMEBREW_PREFIX:-}"

  if [[ -z "$brew_prefix" && ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefix=${HOMEBREW_BREW_FILE%/bin/brew}
  fi

  if [[ -z "$brew_prefix" ]]; then
    printf 'homebrew-path-prepend: Homebrew prefix not found.\n' >&2
    return 127
  fi

  if [[ ! -d "$brew_prefix/bin" ]]; then
    printf 'homebrew-path-prepend: bin directory not found: %s\n' "$brew_prefix/bin" >&2
    return 1
  fi

  path-prepend "$brew_prefix/bin" "$brew_prefix/sbin"
  hash -r
}
export -f homebrew-path-prepend

# Remove Homebrew-managed directories from PATH.
homebrew-path-remove() {
  local brew_prefix
  local entry
  local joined_path
  local -a brew_prefixes=(
    /opt/homebrew
    /home/linuxbrew/.linuxbrew
    "$HOME/.linuxbrew"
  )
  local -a kept_entries=()
  local -a path_entries=()

  if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    brew_prefixes+=("$HOMEBREW_PREFIX")
  elif [[ ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefixes+=("${HOMEBREW_BREW_FILE%/bin/brew}")
  fi

  IFS=: read -r -a path_entries <<< "${PATH-}"

  for entry in "${path_entries[@]}"; do
    for brew_prefix in "${brew_prefixes[@]}"; do
      if [[ "$entry" == "$brew_prefix" || "$entry" == "$brew_prefix"/* ]]; then
        continue 2
      fi
    done

    kept_entries+=("$entry")
  done

  joined_path=$(IFS=:; printf '%s' "${kept_entries[*]}")
  PATH="$joined_path"
  export PATH
  hash -r
}
export -f homebrew-path-remove

# Prepend one installed Homebrew formula's bin directory to PATH.
homebrew-tool-path-prepend() {
  local formula="${1:-}"
  local brew_prefix="${HOMEBREW_PREFIX:-}"
  local formula_bin

  if (( $# != 1 )) ||
     [[ -z "$formula" || "$formula" == */* || "$formula" == . || "$formula" == .. ]]; then
    printf 'Usage: homebrew-tool-path-prepend FORMULA\n' >&2
    return 2
  fi

  if [[ -z "$brew_prefix" && ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefix=${HOMEBREW_BREW_FILE%/bin/brew}
  fi

  if [[ -z "$brew_prefix" ]]; then
    printf 'homebrew-tool-path-prepend: Homebrew prefix not found.\n' >&2
    return 127
  fi

  formula_bin="$brew_prefix/opt/$formula/bin"

  if [[ ! -d "$formula_bin" ]]; then
    printf 'homebrew-tool-path-prepend: formula bin directory not found: %s\n' "$formula_bin" >&2
    return 1
  fi

  path-prepend "$formula_bin"
  hash -r
}
export -f homebrew-tool-path-prepend

# HOMEBREW_BREW_FILE may be set in env.bash or .env.bash for a
# custom Homebrew installation.
_brew_bin="${HOMEBREW_BREW_FILE:-}"

# Use Homebrew already available through PATH.
if [[ -z "$_brew_bin" ]] && has-cmd brew; then
  _brew_bin=$(command -v brew)
fi

# Otherwise check the standard installation locations.
if [[ -z "$_brew_bin" ]]; then
  case ${OSTYPE:-} in
    darwin*)
      # Apple Silicon, then Intel macOS.
      for _candidate in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew
      do
        if [[ -x "$_candidate" ]]; then
          _brew_bin="$_candidate"
          break
        fi
      done
      ;;

    linux*)
      for _candidate in \
        /home/linuxbrew/.linuxbrew/bin/brew \
        "$HOME/.linuxbrew/bin/brew"
      do
        if [[ -x "$_candidate" ]]; then
          _brew_bin="$_candidate"
          break
        fi
      done
      ;;
  esac
fi

if [[ -n "$_brew_bin" && -x "$_brew_bin" ]]; then
  # `brew shellenv` does not take a shell-name argument.
  shell-init "$_brew_bin" shellenv || {
    printf 'WARNING, homebrew.bash: brew init failed\n' >&2
  }
fi

unset _candidate _brew_bin
