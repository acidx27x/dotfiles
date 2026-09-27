# ~/.config/zsh/conf.d/03-bat.zsh
# bat setup.

if has-cmd bat; then
  _bat_command=bat
elif has-cmd batcat; then
  _bat_command=batcat
else
  return 0
fi

alias bathelp="$_bat_command --plain --language=help"

if has-cmd batman; then
  shell-init batman --export-env || {
    print -u2 -- "WARNING, ${${(%):-%x}:t}: batman init failed."
  }
fi

if has-cmd batpipe; then
  eval "$(batpipe)" || {
    print -u2 -- "WARNING, ${${(%):-%x}:t}: batpipe init failed."
  }
fi

unset _bat_command
