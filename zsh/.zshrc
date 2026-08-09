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

# A non-login interactive shell normally inherits Homebrew's environment.
# Initialize it here only when that did not happen.
if [[ -z ${HOMEBREW_PREFIX:-} ]] && ! has-cmd brew; then
  source "$_zsh_config_dir/homebrew.zsh" || {
    print -u2 -- 'WARNING, .zshrc: Homebrew initialization failed.'
  }
fi

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

# Loaded after defaults so machine-local aliases can override them.
source-if-exists "$HOME/.zsh_aliases" || true

# ---------------------------------------------------------------------------
# Native completion and ZLE
# ---------------------------------------------------------------------------

if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
  if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" "${fpath[@]}")
  fi
  if [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh-completions" "${fpath[@]}")
  fi
fi
# Make fpath global and remove duplicate entries.
typeset -gU fpath

autoload -Uz compinit
zmodload zsh/complist

# Keep completion cache files under XDG cache.
_zsh_completion_cache="$XDG_CACHE_HOME/zsh/completion"
if [[ -d "$_zsh_completion_cache" ]] || mkdir -p -- "$_zsh_completion_cache"; then
  # Trust configured completion paths, including Homebrew's group-writable prefix.
  compinit -u -d "$_zsh_completion_cache/zcompdump-$ZSH_VERSION" || {
    print -u2 -- 'WARNING, .zshrc: completion initialization failed.'
  }
else
  print -u2 -- "WARNING, .zshrc: could not create completion cache: $_zsh_completion_cache"
  compinit -u || print -u2 -- 'WARNING, .zshrc: completion initialization failed.'
fi

zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$_zsh_completion_cache"
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

unset _zsh_completion_cache

# ---------------------------------------------------------------------------
# Atuin history
# ---------------------------------------------------------------------------

_atuin_initialized=0

if has-cmd atuin; then
  if shell-init atuin init zsh --disable-up-arrow --disable-ai; then
    _atuin_initialized=1
  else
    print -u2 -- 'WARNING, .zshrc: atuin init failed.'
  fi
fi

# Disable fzf's Ctrl-R binding only after Atuin initialized successfully.
if (( _atuin_initialized )) && [[ -z ${FZF_CTRL_R_COMMAND+x} ]]; then
  export FZF_CTRL_R_COMMAND=
fi

unset _atuin_initialized

# ---------------------------------------------------------------------------
# Tool setup
# ---------------------------------------------------------------------------

source-conf-dirs "$_zsh_config_dir/conf.d" || true
source-conf-dirs "$_zsh_config_dir/conf.local.d" || true

if has-cmd thefuck; then
  shell-init env TF_SHELL=zsh thefuck --alias || {
    print -u2 -- 'WARNING, .zshrc: thefuck init failed.'
  }
fi

# Starship owns both prompt sides when available. Use native Zsh otherwise.
_starship_initialized=0

if has-cmd starship; then
  if shell-init starship init zsh; then
    _starship_initialized=1
    setopt PROMPT_SUBST
  else
    print -u2 -- 'WARNING, .zshrc: starship init failed; using native prompt.'
  fi
fi

# Fall back to a native Zsh prompt if Starship failed/missing.
if (( ! _starship_initialized )); then
  autoload -Uz add-zsh-hook vcs_info
  setopt PROMPT_SUBST

  zstyle ':vcs_info:git:*' enable git
  zstyle ':vcs_info:git:*' formats ' %F{yellow}[%b]%f'
  zstyle ':vcs_info:git:*' actionformats ' %F{yellow}[%b|%a]%f'

  add-zsh-hook precmd vcs_info

  PROMPT='${debian_chroot:+($debian_chroot)}%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %# '
  RPROMPT='%(?..%F{red}%?%f )%D{%H:%M}'
fi

unset _starship_initialized

# Keep zoxide state in the XDG data directory unless explicitly configured.
if [[ -z ${_ZO_DATA_DIR+x} ]]; then
  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
fi

# zoxide completion requires compinit to have run first.
if has-cmd zoxide; then
  shell-init zoxide init zsh --cmd z --hook pwd || {
    print -u2 -- 'WARNING, .zshrc: zoxide init failed.'
  }
fi

# Keep direnv last among prompt-related integrations.
if has-cmd direnv; then
  shell-init direnv hook zsh || {
    print -u2 -- 'WARNING, .zshrc: direnv init failed.'
  }
fi

unset _zsh_state_dir _zsh_config_dir

# ---------------------------------------------------------------------------
# Optional plugins
# ---------------------------------------------------------------------------

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZVM_SYSTEM_CLIPBOARD_ENABLED=true
for name in \
  autosuggestions \
  syntax-highlighting \
  vi-mode; do
  source-first \
    "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-$name/zsh-$name.zsh}" \
    "/usr/share/zsh-$name/zsh-$name.zsh" \
    "/usr/share/zsh/plugins/zsh-$name/zsh-$name.zsh" \
    || true
done

# Avoid zsh-vi-mode's reset-prompt redraw corrupting multiline prompts.
if (( $+functions[zvm_postpone_reset_prompt] )); then
  zvm_postpone_reset_prompt() {
    if [[ $1 == true ]]; then
      ZVM_POSTPONE_RESET_PROMPT=0
    else
      ZVM_POSTPONE_RESET_PROMPT=-1
    fi
  }
fi
