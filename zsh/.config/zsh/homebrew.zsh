# ~/.config/zsh/homebrew.zsh
# Homebrew / Linuxbrew initialization.

# Prepend Homebrew's global bin directories to PATH.
homebrew-path-prepend() {
  emulate -L zsh

  local brew_prefix=${HOMEBREW_PREFIX:-}

  if [[ -z $brew_prefix && ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefix=${HOMEBREW_BREW_FILE%/bin/brew}
  fi

  if [[ -z $brew_prefix ]]; then
    print -u2 -- 'homebrew-path-prepend: Homebrew prefix not found.'
    return 127
  fi

  if [[ ! -d $brew_prefix/bin ]]; then
    print -u2 -- "homebrew-path-prepend: bin directory not found: $brew_prefix/bin"
    return 1
  fi

  path-prepend "$brew_prefix/bin" "$brew_prefix/sbin"
  rehash
}

# Remove Homebrew-managed directories from PATH.
homebrew-path-remove() {
  emulate -L zsh

  local brew_prefix
  local entry
  local -a brew_prefixes=(
    /opt/homebrew
    /home/linuxbrew/.linuxbrew
    "$HOME/.linuxbrew"
  )
  local -a kept_path=()

  if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
    brew_prefixes+=("$HOMEBREW_PREFIX")
  elif [[ ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefixes+=("${HOMEBREW_BREW_FILE%/bin/brew}")
  fi

  typeset -gU path PATH

  for entry in "${path[@]}"; do
    for brew_prefix in "${brew_prefixes[@]}"; do
      if [[ $entry == "$brew_prefix" || $entry == "$brew_prefix"/* ]]; then
        continue 2
      fi
    done

    kept_path+=("$entry")
  done

  path=("${kept_path[@]}")
  export PATH
  rehash
}

# Prepend installed Homebrew formula bin directories to PATH.
homebrew-tool-path-prepend() {
  emulate -L zsh

  local formula
  local brew_prefix=${HOMEBREW_PREFIX:-}
  local formula_bin
  local -a formula_bins=()

  if (( $# == 0 )); then
    print -u2 -- 'Usage: homebrew-tool-path-prepend FORMULA...'
    return 2
  fi

  for formula in "$@"; do
    if [[ -z $formula || $formula == */* || $formula == . || $formula == .. ]]; then
      print -u2 -- 'Usage: homebrew-tool-path-prepend FORMULA...'
      return 2
    fi
  done

  if [[ -z $brew_prefix && ${HOMEBREW_BREW_FILE:-} == */bin/brew ]]; then
    brew_prefix=${HOMEBREW_BREW_FILE%/bin/brew}
  fi

  if [[ -z $brew_prefix ]]; then
    print -u2 -- 'homebrew-tool-path-prepend: Homebrew prefix not found.'
    return 127
  fi

  for formula in "$@"; do
    formula_bin="$brew_prefix/opt/$formula/bin"

    if [[ ! -d $formula_bin ]]; then
      print -u2 -- "homebrew-tool-path-prepend: formula bin directory not found: $formula_bin"
      return 1
    fi

    formula_bins+=("$formula_bin")
  done

  path-prepend "${formula_bins[@]}"
  rehash
}

# A non-login interactive shell normally inherits Homebrew's environment.
[[ -n ${HOMEBREW_PREFIX:-} ]] && return 0

_brew_bin="${HOMEBREW_BREW_FILE:-}"

if [[ -z $_brew_bin ]] && command -v brew >/dev/null 2>&1; then
  _brew_bin=$(command -v brew)
fi

if [[ -z $_brew_bin ]]; then
  case ${OSTYPE:-} in
    darwin*)
      for _candidate in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew
      do
        if [[ -x $_candidate ]]; then
          _brew_bin=$_candidate
          break
        fi
      done
      ;;

    linux*)
      for _candidate in \
        /home/linuxbrew/.linuxbrew/bin/brew \
        "$HOME/.linuxbrew/bin/brew"
      do
        if [[ -x $_candidate ]]; then
          _brew_bin=$_candidate
          break
        fi
      done
      ;;
  esac
fi

if [[ -n $_brew_bin && -x $_brew_bin ]]; then
  if _brew_init_code=$("$_brew_bin" shellenv); then
    eval "$_brew_init_code" || {
      print -u2 -- 'WARNING, homebrew.zsh: brew init failed.'
      unset _brew_init_code _candidate _brew_bin
      return 1
    }
  else
    print -u2 -- 'WARNING, homebrew.zsh: brew init failed.'
    unset _brew_init_code _candidate _brew_bin
    return 1
  fi
fi

unset _brew_init_code _candidate _brew_bin
