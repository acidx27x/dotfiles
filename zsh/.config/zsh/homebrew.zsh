# ~/.config/zsh/homebrew.zsh
# Homebrew / Linuxbrew initialization.

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
