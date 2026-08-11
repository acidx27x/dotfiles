# ~/.config/zsh/conf.d/01-vi-mode.zsh
# zsh-vi-mode setup before other key-binding integrations.

ZVM_INIT_MODE=sourcing
ZVM_SYSTEM_CLIPBOARD_ENABLED=true
ZVM_CURSOR_STYLE_ENABLED=true

zvm_config() {
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
  ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
  ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
  ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
}

edit-and-execute-command() {
  zle edit-command-line || return
  zle accept-line
}

zvm_after_init() {
  autoload -Uz edit-command-line
  zle -N edit-command-line
  zle -N edit-and-execute-command
  zvm_bindkey viins '^X^E' edit-and-execute-command
  zvm_bindkey vicmd '^X^E' edit-and-execute-command
}

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
