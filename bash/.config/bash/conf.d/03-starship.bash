# ~/.config/bash/conf.d/03-starship.bash
# starship setup

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

if has-cmd starship; then
  shell-init starship init bash || {
    printf 'WARNING, %s: starship init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi

if ! has-cmd stellar; then
  printf 'INFO, %s: stellar is not installed; run `stellar-help` for setup.\n' \
    "${BASH_SOURCE[0]##*/}" >&2
fi
