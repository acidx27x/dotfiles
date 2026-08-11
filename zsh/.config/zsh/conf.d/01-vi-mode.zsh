# ~/.config/zsh/conf.d/01-vi-mode.zsh
# zsh-vi-mode setup

ZVM_INIT_MODE=sourcing
ZVM_READKEY_ENGINE=zle
ZVM_SYSTEM_CLIPBOARD_ENABLED=true
ZVM_CURSOR_STYLE_ENABLED=true

zvm_config() {
    ZVM_RESET_PROMPT_DISABLED=true
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
}

source-first \
  "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh}" \
  '/usr/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh' \
  '/usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh' \
  '/usr/share/zsh-vi-mode/zsh-vi-mode.zsh' \
  '/usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.zsh' \
  || true
