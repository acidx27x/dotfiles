# ~/.config/zsh/conf.d/99-keybindings.zsh
# other key-binding integrations

bindkey ' ' magic-space

# zvm edit buffer workaround
autoload -Uz edit-command-line
zle -N edit-command-line

_my_edit_command_line() {
  zle edit-command-line || return
}

zvm_define_widget _my_edit_command_line

zvm_bindkey viins '^X^E' _my_edit_command_line

if (( $+functions[ffd] )); then
  _my_ffd() {
    emulate -L zsh

    zle -I
    ffd
    zle reset-prompt
    return 0
  }

  zvm_define_widget _my_ffd
  zvm_bindkey viins '^X^F' _my_ffd
fi

if (( $+functions[frg] )); then
  _my_frg() {
    emulate -L zsh

    zle -I
    frg
    zle reset-prompt
    return 0
  }

  zvm_define_widget _my_frg
  zvm_bindkey viins '^X^G' _my_frg
fi

# Normal mode — after lazy bindings zsh-vi-mode
_zvm_my_lazy_bindings() {
  zvm_bindkey vicmd '^X^E' _my_edit_command_line
  (( $+functions[ffd] )) && zvm_bindkey vicmd '^X^F' _my_ffd
  (( $+functions[frg] )) && zvm_bindkey vicmd '^X^G' _my_frg
}

zvm_after_lazy_keybindings_commands+=(_zvm_my_lazy_bindings)
