# ~/.config/zsh/conf.d/03-starship.zsh
# starship prompt with a native Zsh fallback

# Show Stellar installation and theme instructions.
stellar-help() {
  printf 'Stellar manages remote Starship themes.\n\n'

  if has-cmd stellar; then
    printf 'Status: installed (%s)\n' "$(command -v stellar)"
  else
    printf 'Status: not installed\n\n'
    printf 'Install:\n'
    printf '  %s\n' \
      'curl -fsSL https://raw.githubusercontent.com/a3chron/stellar/main/install.sh | bash'
  fi

  printf '\nApply theme:\n'
  printf '  stellar apply a3chron/ctp-green\n'
  printf '\nConfiguration:\n'
  printf '  Stellar caches the remote theme and manages\n'
  printf '  ~/.config/starship.toml as a symlink.\n'
}

_starship_initialized=0

if has-cmd starship; then
  if shell-init starship init zsh; then
    _starship_initialized=1
  else
    print -u2 -- 'WARNING, 03-starship.zsh: starship init failed; using native prompt.'
  fi
fi

if (( ! _starship_initialized )); then
  autoload -Uz add-zsh-hook vcs_info

  zstyle ':vcs_info:git:*' enable git
  zstyle ':vcs_info:git:*' formats ' %F{yellow}[%b]%f'
  zstyle ':vcs_info:git:*' actionformats ' %F{yellow}[%b|%a]%f'

  add-zsh-hook precmd vcs_info

  PROMPT='${debian_chroot:+($debian_chroot)}%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %# '
  RPROMPT='%(?..%F{red}%?%f )%D{%H:%M}'
fi

if ! has-cmd stellar; then
  print -u2 -- 'INFO, 03-starship.zsh: stellar is not installed; run `stellar-help` for setup.'
fi

unset _starship_initialized
