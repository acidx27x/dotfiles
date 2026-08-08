# ~/.config/bash/conf.d/04-stellar.bash
# Stellar setup guidance.

if ! has-cmd stellar; then
  printf 'INFO, 04-stellar.bash: stellar is not installed; run `stellar-help` for setup.\n' >&2
fi
