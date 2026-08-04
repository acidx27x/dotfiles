# ~/.config/bash/conf.d/03-bat.bash
# bat setup

if has_cmd bat; then
  _bat_command=bat
elif has_cmd batcat; then
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

if has_cmd batman; then
  shell_init batman --export-env || {
    printf 'WARNING, 03-bat.bash: batman init failed\n' >&2
  }
fi

if has_cmd batpipe; then
  eval "$(batpipe)" || {
    printf 'WARNING, 03-bat.bash: batpipe init failed\n' >&2
  }
fi

