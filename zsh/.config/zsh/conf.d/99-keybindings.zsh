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

# Normal mode — after lazy bindings zsh-vi-mode
_zvm_my_lazy_bindings() {
  zvm_bindkey vicmd '^X^E' _my_edit_command_line
}

zvm_after_lazy_keybindings_commands+=(_zvm_my_lazy_bindings)
