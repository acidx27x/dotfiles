# ~/.config/bash/conf.d/03-bat.bash
# bat setup

if has-cmd bat; then
  _bat_command=bat
elif has-cmd batcat; then
  _bat_command=batcat
else
  return 0
fi

alias bathelp="$_bat_command --plain --language=help"

# bat-extras:
#  batdiff
#  batgrep
#  batman
#  batpipe
#  batwatch
#  prettybat

if has-cmd batman; then
  shell-init batman --export-env || {
    printf 'WARNING, 03-bat.bash: batman init failed\n' >&2
  }
fi

if has-cmd batpipe; then
  eval "$(batpipe)" || {
    printf 'WARNING, 03-bat.bash: batpipe init failed\n' >&2
  }
fi
