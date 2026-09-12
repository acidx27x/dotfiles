# ~/.zshrc: interactive Zsh configuration.

[[ -o interactive ]] || return

# ---------------------------------------------------------------------------
# Shell environment
# ---------------------------------------------------------------------------

if [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
  _ghostty_integration="${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
  [[ -r "$_ghostty_integration" ]] && source "$_ghostty_integration"
  unset _ghostty_integration
fi

# ---------------------------------------------------------------------------
# Base environment
# ---------------------------------------------------------------------------

_zsh_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

source "$_zsh_config_dir/utils.zsh"
source "$_zsh_config_dir/functions.zsh"

source "$_zsh_config_dir/homebrew.zsh" || {
  print -u2 -- 'WARNING, .zshrc: Homebrew initialization failed.'
}

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

_zsh_state_dir="$XDG_STATE_HOME/zsh"

if [[ -d "$_zsh_state_dir" ]] || mkdir -p -- "$_zsh_state_dir"; then
  HISTFILE="$_zsh_state_dir/history"
else
  print -u2 -- "WARNING, .zshrc: could not create history directory: $_zsh_state_dir"
  HISTFILE=/dev/null
fi

HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# SHARE_HISTORY performs incremental append/import itself.
unsetopt INC_APPEND_HISTORY
unsetopt INC_APPEND_HISTORY_TIME

# ---------------------------------------------------------------------------
# Native Zsh options
# ---------------------------------------------------------------------------

setopt NO_CLOBBER

# Globbing: recursive ** and glob qualifiers are native and need no option.
# Enable Zsh's richer glob pattern syntax.
setopt EXTENDED_GLOB
setopt NUMERIC_GLOB_SORT
setopt NOMATCH
unsetopt GLOB_DOTS
unsetopt NULL_GLOB
unsetopt CSH_NULL_GLOB

# Directory shortcuts and a clean directory stack.
# Typing a directory path alone changes into that directory.
setopt AUTO_CD
setopt AUTO_PUSHD
setopt CDABLE_VARS
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS
setopt PUSHD_SILENT

# Correct command names, but never rewrite every argument.
# Offer spelling correction for command names.
setopt CORRECT
unsetopt CORRECT_ALL
SPROMPT='Correct %F{red}%R%f to %F{green}%r%f? [nyae] '

# Completion behavior.
setopt AUTO_LIST
# Repeated Tab presses cycle through completion choices.
setopt AUTO_MENU
setopt COMPLETE_IN_WORD

# Keep old right prompts out of copied command output.
# Remove the old right prompt after accepting a command.
setopt TRANSIENT_RPROMPT

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

source "$_zsh_config_dir/colors.zsh"

# ---------------------------------------------------------------------------
# Personal aliases
# ---------------------------------------------------------------------------

alias zsh-reload='source ~/.zshrc'
alias zsh-options='setopt'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias rcp='rsync --recursive --times --progress --stats --human-readable'
alias rmv='rsync --recursive --times --progress --stats --human-readable --remove-source-files'

alias lg='lazygit'

alias pclear='pyroclear -r --no-save'

alias hl='rg --passthru'

alias -g NO='>/dev/null'
alias -g NE='2>/dev/null'
alias -g NA='>/dev/null 2>&1'

if [[ "$OSTYPE" == darwin* ]]; then
  alias -g C='| pbcopy'
elif [[ -n "$WAYLAND_DISPLAY" ]]; then
  alias -g C='| wl-copy'
else
  alias -g C='| xclip -selection clipboard'
fi

alias cn='container'

# Loaded after defaults so machine-local aliases can override them.
source-if-exists "$HOME/.zsh_aliases" || true

# ---------------------------------------------------------------------------
# Native completion and ZLE
# ---------------------------------------------------------------------------

if load-zsh-completion; then
  _completion_status=0
else
  _completion_status=$?
fi

if (( _completion_status != 0 && _completion_status != 127 )); then
  print -u2 -- 'WARNING, .zshrc: completion initialization failed.'
fi

unset _completion_status

# Try normal completion first, then corrected completion.
zstyle ':completion:*' completer _complete _correct
zstyle ':completion:*:correct:*' max-errors 1 numeric
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z} r:|[-_./]=* r:|=*'
# Show selectable completion menu when there are 2+ matches.
zstyle ':completion:*' menu select=2
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

if [[ -n ${LS_COLORS:-} ]]; then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
  zstyle ':completion:*:default' list-colors ''
fi

# ---------------------------------------------------------------------------
# Tool setup
# ---------------------------------------------------------------------------

# use promt subst anyway, but blocked by emulate -L zsh inside function
setopt PROMPT_SUBST

# Shared, tracked configuration.
source-conf-dirs "$_zsh_config_dir/conf.d" || true

# Machine-specific configuration, loaded afterward so it can override
# settings from conf.d.
source-conf-dirs "$_zsh_config_dir/conf.local.d" || true

# ---------------------------------------------------------------------------
# Optional zsh builtins
# ---------------------------------------------------------------------------

# zmv - Advanced Batch Rename/Move
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# Helpful aliases for zmv
alias zcp='zmv -C'  # Copy with patterns
alias zln='zmv -L'  # Link with patterns

# ---------------------------------------------------------------------------
# Optional plugins
# ---------------------------------------------------------------------------

source "$_zsh_config_dir/plugins.zsh" || {
  print -u2 -- 'WARNING, .zshrc: optional plugin initialization failed.'
}

unset _zsh_state_dir _zsh_config_dir
