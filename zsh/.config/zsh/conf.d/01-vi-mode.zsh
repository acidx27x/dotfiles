# ~/.config/zsh/conf.d/01-vi-mode.zsh
# zsh-vi-mode setup before other key-binding integrations.

ZVM_INIT_MODE=sourcing
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

source-first \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh}" \
  '/usr/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh' \
  '/usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh' \
  '/usr/share/zsh-vi-mode/zsh-vi-mode.zsh' \
  '/usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.zsh' \
  || true

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
