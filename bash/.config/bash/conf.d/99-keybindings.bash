# ~/.config/bash/conf.d/99-keybindings.bash
# Other key-binding integrations.

# Brush uses Reedline rather than Bash's bind -x integration.
if is-brush; then
  return 0
fi

# Ctrl-X Ctrl-F -> select a file or directory with fzf.
if declare -F ffd >/dev/null; then
  bind -m vi-insert -x '"\C-x\C-f":ffd'
  bind -m vi-command -x '"\C-x\C-f":ffd'
fi

# Ctrl-X Ctrl-G -> search file contents with ripgrep and fzf.
if declare -F frg >/dev/null; then
  bind -m vi-insert -x '"\C-x\C-g":frg'
  bind -m vi-command -x '"\C-x\C-g":frg'
fi
