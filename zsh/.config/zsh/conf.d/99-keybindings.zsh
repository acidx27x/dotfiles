# ~/.config/zsh/conf.d/99-keybindings.zsh
# other key-binding integrations

bindkey ' ' magic-space

# Use Ctrl-H/J/K/L for movement only while selecting a completion.
bindkey -M menuselect '^H' backward-char
bindkey -M menuselect '^J' down-line-or-history
bindkey -M menuselect '^K' up-line-or-history
bindkey -M menuselect '^L' forward-char

# Keep unfinished commands in one editable buffer instead of opening PS2.
_zvm_accept_line() {
  emulate -L zsh -o extended_glob

  local command_text=$PREBUFFER$BUFFER
  local -i complete=0

  # Compile the input without executing it; unfinished commands have no body.
  if [[ $command_text != (|*[^\\])(\\\\)#\\ ]]; then
    { functions[_zvm_parse_command]=$command_text; } 2>/dev/null
    if (($+functions[_zvm_parse_command])); then
      unfunction _zvm_parse_command
      # A bare for-header or unfinished heredoc also accepts this suffix.
      { functions[_zvm_parse_command]=$command_text$'\ndo\ndone'; } 2>/dev/null
      (($+functions[_zvm_parse_command])) || complete=1
    fi
  fi
  if (($+functions[_zvm_parse_command])); then
    unfunction _zvm_parse_command
  fi

  if ((complete)); then
    zle accept-line
  else
    zle self-insert-unmeta
  fi
}

# Let the native widgets handle suggestion and highlighting updates.
zle -N ._zvm_accept_line _zvm_accept_line
zvm_bindkey viins '^M' ._zvm_accept_line
zvm_bindkey viins '^J' ._zvm_accept_line

# Fish/Emacs editing keys in vi insert mode.
zvm_bindkey viins '^A' beginning-of-line
zvm_bindkey viins '^E' end-of-line
zvm_bindkey viins '^B' backward-char
zvm_bindkey viins '^F' forward-char
zvm_bindkey viins '^U' backward-kill-line
zvm_bindkey viins '^K' kill-line
zvm_bindkey viins '^W' backward-kill-word
zvm_bindkey viins '^Y' yank
zvm_bindkey viins '^[y' yank-pop
zvm_bindkey viins '^T' transpose-chars
zvm_bindkey viins '^[t' transpose-words
zvm_bindkey viins '^[u' up-case-word
zvm_bindkey viins '^_' undo

# Browse history directly, including when the current command spans lines.
zvm_bindkey viins '^P' up-history
zvm_bindkey viins '^N' down-history

# Move and delete words without leaving insert mode.
zvm_bindkey viins '^[b' backward-word
zvm_bindkey viins '^[f' emacs-forward-word
zvm_bindkey viins '^[d' kill-word
zvm_bindkey viins '^[^?' backward-kill-word

# zvm edit buffer workaround
autoload -Uz edit-command-line
zle -N edit-command-line

_my_edit_command_line() {
  zle edit-command-line || return
}

zvm_define_widget _my_edit_command_line

zvm_bindkey viins '^X^E' _my_edit_command_line
zvm_bindkey viins '^[e' _my_edit_command_line

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

  zvm_bindkey vicmd '^M' ._zvm_accept_line
  zvm_bindkey vicmd '^J' ._zvm_accept_line
  zvm_bindkey vicmd '^P' up-history
  zvm_bindkey vicmd '^N' down-history
  zvm_bindkey vicmd '^X^E' _my_edit_command_line
  (($+functions[ffd])) && zvm_bindkey vicmd '^X^F' _my_ffd
  (($+functions[frg])) && zvm_bindkey vicmd '^X^G' _my_frg
}

zvm_after_lazy_keybindings_commands+=(_zvm_my_lazy_bindings)
