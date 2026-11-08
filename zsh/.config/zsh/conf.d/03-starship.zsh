# ~/.config/zsh/conf.d/03-starship.zsh
# starship prompt with a native Zsh fallback

# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

_starship_initialized=0

if has-cmd starship; then
  if shell-init starship init zsh; then
    _starship_initialized=1
  else
    print -u2 -- \
      "WARNING, ${${(%):-%x}:t}: starship init failed; using native prompt."
  fi
fi

if ((! _starship_initialized)); then
  autoload -Uz add-zsh-hook vcs_info

  zstyle ':vcs_info:git:*' enable git
  zstyle ':vcs_info:git:*' formats ' %F{yellow}[%b]%f'
  zstyle ':vcs_info:git:*' actionformats ' %F{yellow}[%b|%a]%f'

  add-zsh-hook precmd vcs_info

  PROMPT='${debian_chroot:+($debian_chroot)}%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %# '
  RPROMPT='%(?..%F{red}%?%f )%D{%H:%M}'
fi

unset _starship_initialized
