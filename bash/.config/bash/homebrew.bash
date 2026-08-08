# ~/.config/bash/homebrew.bash
# Homebrew / Linuxbrew initialization.

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
