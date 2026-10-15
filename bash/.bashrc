# ~/.bashrc: interactive Bash configuration.

# Stop here for non-interactive shells.
case $- in
*i*) ;;
*) return ;;
esac

# ---------------------------------------------------------------------------
# Shell environment
# ---------------------------------------------------------------------------

if [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

# ---------------------------------------------------------------------------
# Base environment
# ---------------------------------------------------------------------------

_bash_config_dir="$HOME/.config/bash"

source "$_bash_config_dir/utils.bash"
source "$_bash_config_dir/functions.bash"

# Silence Apple's warning when the system Bash is used.
if [[ ${OSTYPE:-} == darwin* ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi

source "$_bash_config_dir/env.bash"

# Share history between simultaneously open terminals.
# Brush uses a precmd hook because history -n is unsupported.
is-brush || add-prompt-command __sync_bash_history

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000

shopt -s histappend   # append instead of overwrite
shopt -s checkwinsize # update dimensions after terminal resize
shopt -s cmdhist      # save a multi-line command as one history entry
shopt -s lithist      # preserve line breaks in multi-line history entries

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

# Recursive globbing was added in Bash 4; macOS may still use Bash 3.2.
if ((BASH_VERSINFO[0] >= 4)); then
  shopt -s globstar
fi

# Extended glob patterns: rm -- !(*.important)
shopt -s extglob

# Pattern that matches nothing produces an error.
# shopt -s failglob

# Prevent accidental overwriting with >.
# Use >|file to overwrite intentionally.
set -o noclobber

# ---------------------------------------------------------------------------
# Homebrew / Linuxbrew
# ---------------------------------------------------------------------------

source "$_bash_config_dir/homebrew.bash"

# ---------------------------------------------------------------------------
# ble.sh line editor
# ---------------------------------------------------------------------------

_ble_loaded=0

if ! is-brush; then
  for _ble_file in \
    "$XDG_DATA_HOME/blesh/ble.sh" \
    "${HOMEBREW_PREFIX:-/usr/local}/opt/blesh/share/blesh/ble.sh" \
    "${HOMEBREW_PREFIX:-/usr/local}/share/blesh/ble.sh" \
    "/usr/share/blesh/ble.sh"; do
    if [[ -r "$_ble_file" ]]; then
      if source -- "$_ble_file" \
        --attach=none \
        --rcfile "$_bash_config_dir/blerc.bash"; then
        _ble_loaded=1
      else
        printf 'WARNING, %s: ble.sh init failed\n' "${BASH_SOURCE[0]##*/}" >&2
      fi

      break
    fi
  done
fi

unset _ble_file

# ---------------------------------------------------------------------------
# Debian chroot
# ---------------------------------------------------------------------------

if [[ ${OSTYPE:-} == linux* &&
  -z ${debian_chroot:-} &&
  -r /etc/debian_chroot ]]; then
  debian_chroot=$(</etc/debian_chroot)
fi

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

_colors_file="$_bash_config_dir/colors.bash"

source "$_colors_file"

unset _colors_file

# ---------------------------------------------------------------------------
# Personal aliases
# ---------------------------------------------------------------------------

alias bash-reload='source ~/.bashrc'
alias bash-options='set -o; shopt'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias rcp='rsync --recursive --times --progress --stats --human-readable'
alias rmv='rsync --recursive --times --progress --stats --human-readable --remove-source-files'

alias lg='lazygit'

alias pclear='pyroclear -r --no-save'

alias hl='rg --passthru'

if [[ "$OSTYPE" == darwin* ]]; then
  alias C='pbcopy'
elif [[ -n "$WAYLAND_DISPLAY" ]]; then
  alias C='wl-copy'
else
  alias C='xclip -selection clipboard'
fi

# Loaded after default aliases, allowing ~/.bash_aliases to override them.
source-if-exists "$HOME/.bash_aliases" || true

# ---------------------------------------------------------------------------
# Bash completion and preexec
# ---------------------------------------------------------------------------

if load-bash-completion; then
  _completion_status=0
else
  _completion_status=$?
fi

if ((_completion_status != 0 && _completion_status != 127)); then
  printf 'WARNING, %s: load completion init failed\n' \
    "${BASH_SOURCE[0]##*/}" >&2
fi

unset _completion_status

if ! is-brush && ((_ble_loaded == 0)); then # Brush and ble.sh use their own hooks.
  load-bash-preexec || {
    printf '%s%s\n' \
      "WARNING, ${BASH_SOURCE[0]##*/}: load preexec init failed, " \
      'some complicated tools like atuin may work incorrectly' >&2
  }
fi

# Starship replaces the fallback PS1 when available.
PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# ---------------------------------------------------------------------------
# Tool auto setup
# ---------------------------------------------------------------------------

# Shared, tracked configuration.
source-conf-dirs "$_bash_config_dir/conf.d" || true

# Machine-specific configuration, loaded afterward so it can override
# settings from conf.d.
source-conf-dirs "$_bash_config_dir/conf.local.d" || true

unset _bash_config_dir

# Keep this last so ble.sh sees hooks installed by Atuin, fzf, and Starship.
if ((_ble_loaded)); then
  unset _ble_loaded
  ble-attach
else
  unset _ble_loaded
fi
