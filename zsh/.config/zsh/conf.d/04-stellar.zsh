# ~/.config/zsh/conf.d/04-stellar.zsh
# Stellar setup guidance.

if ! has-cmd stellar; then
  print -u2 -- 'INFO, 04-stellar.zsh: stellar is not installed; run `stellar-help` for setup.'
fi
