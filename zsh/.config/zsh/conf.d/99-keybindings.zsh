# ~/.config/zsh/conf.d/99-keybindings.zsh
# other key-binding integrations

bindkey ' ' magic-space

# Use Ctrl-H/J/K/L for movement only while selecting a completion.
bindkey -M menuselect '^H' backward-char
bindkey -M menuselect '^J' down-line-or-history
bindkey -M menuselect '^K' up-line-or-history
bindkey -M menuselect '^L' forward-char

# Browse history directly, including when the current command spans lines.
zvm_bindkey viins '^P' up-history
zvm_bindkey viins '^N' down-history

# Move and delete words without leaving insert mode.
zvm_bindkey viins '^[b' backward-word
zvm_bindkey viins '^[f' emacs-forward-word
zvm_bindkey viins '^[d' kill-word

# zvm edit buffer workaround
autoload -Uz edit-command-line
zle -N edit-command-line

_my_edit_command_line() {
  zle edit-command-line || return
}

zvm_define_widget _my_edit_command_line

zvm_bindkey viins '^X^E' _my_edit_command_line

if (($+functions[ffd])); then
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

if (($+functions[frg])); then
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
  emulate -L zsh

  zvm_bindkey vicmd '^P' up-history
  zvm_bindkey vicmd '^N' down-history
  zvm_bindkey vicmd '^X^E' _my_edit_command_line
  (($+functions[ffd])) && zvm_bindkey vicmd '^X^F' _my_ffd
  (($+functions[frg])) && zvm_bindkey vicmd '^X^G' _my_frg
}

zvm_after_lazy_keybindings_commands+=(_zvm_my_lazy_bindings)
