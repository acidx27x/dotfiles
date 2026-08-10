# ~/.config/zsh/plugins.zsh
# Optional ZLE plugins loaded after tracked and machine-local modules.

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

source-first \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh}" \
  '/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' \
  '/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' \
  || true

# Syntax highlighting must be the final ZLE integration.
source-first \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh}" \
  '/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' \
  '/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' \
  || true
