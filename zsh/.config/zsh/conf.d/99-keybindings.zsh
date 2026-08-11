# ~/.config/zsh/conf.d/99-keybindings.zsh
# other key-binding integrations

autoload -Uz edit-command-line
zle -N edit-command-line

edit-and-execute-command() {
  zle edit-command-line || return
  zle accept-line
}

zvm_define_widget edit-and-execute-command

# Insert mode можно ставить сразу.
zvm_bindkey viins '^X^E' edit-and-execute-command

# Normal mode — после lazy bindings zsh-vi-mode.
_zvm_my_lazy_bindings() {
  zvm_bindkey vicmd '^X^E' edit-and-execute-command
}

zvm_after_lazy_keybindings_commands+=(_zvm_my_lazy_bindings)
