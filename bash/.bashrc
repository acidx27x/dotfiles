# ~/.bashrc: interactive Bash configuration.

# Stop here for non-interactive shells.
case $- in
  *i*) ;;
  *) return ;;
esac

# ---------------------------------------------------------------------------
# Shell environment
# ---------------------------------------------------------------------------

if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
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
if (( BASH_VERSINFO[0] >= 4 )); then
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
# Debian chroot
# ---------------------------------------------------------------------------

if [[ ${OSTYPE:-} == linux* &&
      -z ${debian_chroot:-} &&
      -r /etc/debian_chroot ]]; then
  debian_chroot=$(< /etc/debian_chroot)
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

# Loaded after default aliases, allowing ~/.bash_aliases to override them.
source-if-exists "$HOME/.bash_aliases" || true

# ---------------------------------------------------------------------------
# Bash completion
# ---------------------------------------------------------------------------

if load-bash-completion; then
  _completion_status=0
else
  _completion_status=$?
fi

if (( _completion_status != 0 && _completion_status != 127 )); then
  printf 'WARNING, .bashrc: load completion init failed\n' >&2
fi

unset _completion_status

# ---------------------------------------------------------------------------
# Atuin history
# ---------------------------------------------------------------------------

_atuin_initialized=0

if has-cmd atuin; then
  if shell-init atuin init bash --disable-up-arrow --disable-ai; then
    _atuin_initialized=1
  else
    printf 'WARNING, .bashrc: atuin init failed\n' >&2
  fi
fi

# Disable fzf's Ctrl-R binding only after Atuin has initialized successfully.
# Preserve a value explicitly configured in env.bash or .env.bash.
if (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi

unset _atuin_initialized

# ---------------------------------------------------------------------------
# Tool auto setup
# ---------------------------------------------------------------------------

# Shared, tracked configuration.
source-conf-dirs "$_bash_config_dir/conf.d" || true

# Machine-specific configuration, loaded afterward so it can override
# settings from conf.d.
source-conf-dirs "$_bash_config_dir/conf.local.d" || true

# ---------------------------------------------------------------------------
# Tool small setup
# ---------------------------------------------------------------------------

if has-cmd thefuck; then
  shell-init env TF_SHELL=bash thefuck --alias || {
    printf 'WARNING, .bashrc: thefuck init failed\n' >&2
  }
fi

# Starship replaces the fallback PS1 when available.
PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

if has-cmd starship; then
  shell-init starship init bash || {
    printf 'WARNING, .bashrc: starship init failed\n' >&2
  }
fi

# Keep zoxide's database under XDG_DATA_HOME unless explicitly configured.
if [[ -z ${_ZO_DATA_DIR+x} ]]; then
  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
fi

if has-cmd zoxide; then
  shell-init zoxide init bash --cmd z --hook pwd || {
    printf 'WARNING, .bashrc: zoxide init failed\n' >&2
  }
fi

# Keep direnv last among prompt-related integrations.
# Create .envrc and run `direnv allow .` or `direnv deny .` afterward.
if has-cmd direnv; then
  shell-init direnv hook bash || {
    printf 'WARNING, .bashrc: direnv init failed\n' >&2
  }
fi

unset _bash_config_dir
