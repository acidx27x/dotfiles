# ~/.bashrc: interactive Bash/Brush configuration.

# Stop here for non-interactive shells.
case $- in
  *i*) ;;
  *) return ;;
esac

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Shared helper functions.
_functions_file="$XDG_CONFIG_HOME/bash/functions.bash"

if [[ -r "$_functions_file" ]]; then
  source "$_functions_file"
else
  printf 'Missing shell functions file: %s\n' "$_functions_file" >&2
  unset _functions_file
  return
fi

unset _functions_file

#
# History
#

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000
export HISTFILESIZE=100000

shopt -s histappend   # append instead of overwrite
shopt -s checkwinsize # if the terminal window size changed -> update
shopt -s cmdhist      # attempts to save a multi-line command as one history entry
shopt -s lithist      # preserves the actual line breaks in multi-line commands when saving them to history

# Recursive globbing: **/*.rs, src/**/*.toml
shopt -s globstar

# Extended glob patterns: rm -- !(*.important)
#shopt -s extglob

# Pattern that matches nothing produces an error
#shopt -s failglob

# Prevent accidental overwriting with >
# Use >|file to overwrite intentionally.
set -o noclobber

# Share history between simultaneously open terminals.
is_brush || add_prompt_command __sync_bash_history  # not working for brush

#
# Linuxbrew
#

# Load Linuxbrew first. Custom paths below then receive higher priority.
shell_init /home/linuxbrew/.linuxbrew/bin/brew shellenv bash || true

# Try to load brew completions first if init
load_bash_completion || true

#
# PATH and global environment
#

export VCPKG_ROOT="$HOME/soft/vcpkg"
path_prepend "$VCPKG_ROOT"

path_prepend \
  "/usr/lib/gcc-astra/bin" \
  "$HOME/.local/bin" \
  "$HOME/soft/metashell-5.0.0/usr/bin" \
  "$HOME/soft/swig-4.0.2/bin"

#
# Debian chroot
#

if [[ -z "${debian_chroot:-}" && -r /etc/debian_chroot ]]; then
  debian_chroot=$(< /etc/debian_chroot)
fi

#
# Colors
#

_colors_file="$XDG_CONFIG_HOME/bash/colors.bash"
_dircolors_args=(-b)

if [[ -r "$HOME/.dircolors" ]]; then
  _dircolors_args+=("$HOME/.dircolors")
fi

shell_init dircolors "${_dircolors_args[@]}" || true

source_if_exists "$_colors_file" || true

unset _dircolors_args
unset _colors_file

#
# Modern command aliases
#

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Replace ls with eza when available.
if has_cmd eza; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias l='eza -l --group-directories-first'
  alias tree='eza --tree --group-directories-first'
fi

if has_cmd bat; then
  alias batp='bat --paging=never'
fi
if has_cmd batcat; then
  alias batcatp='batcat --paging=never'
fi

#
# Personal aliases
#

# Loaded after default aliases, allowing ~/.bash_aliases to override them.
source_if_exists "$HOME/.bash_aliases" || true

#
# Bash completion
#

if ! shopt -oq posix; then
  source_first \
    "/usr/share/bash-completion/bash_completion" \
    "/etc/bash_completion" \
    || true
fi

#
# Modern shell integrations
#

shell_init atuin init bash --disable-up-arrow --disable-ai || true

# Fuzzy completion and key bindings.
# Ctrl-T → fzf file search
# Alt-C → fzf directory search
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border
  --info=inline
  --prompt='∼ '
  --pointer='▶'
  --marker='✓'
"

export FZF_CTRL_T_OPTS="
  --walker-skip=.git,node_modules,target,dist,.next
"

# Ctrl-R → Atuin history if available
if has_cmd atuin; then
  export FZF_CTRL_R_COMMAND=
fi

if shell_init fzf --bash; then
  __fzf_cd_wrapper() {
      local command

      command="$(__fzf_cd__)" || return
      [[ -n $command ]] || return

      eval "$command"
  }

  bind -m emacs-standard -x '"\ec":__fzf_cd_wrapper'
  bind -m vi-insert      -x '"\ec":__fzf_cd_wrapper'
  bind -m vi-command     -x '"\ec":__fzf_cd_wrapper'

  bind -x '"\ec":__fzf_cd_wrapper'
fi

# Starship replaces the hand-written PS1 configuration.
if ! shell_init starship init bash; then
  PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
fi

# Keep direnv last among prompt-related integrations.
# create .envrc and run 'direnv allow .' or 'direnv deny .' after
shell_init direnv hook bash || true
