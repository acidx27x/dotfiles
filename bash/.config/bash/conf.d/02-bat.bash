# ~/.config/bash/conf.d/02-bat.bash
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
    printf 'WARNING, %s: batman init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi

if has-cmd batpipe; then
  eval "$(batpipe)" || {
    printf 'WARNING, %s: batpipe init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  }
fi
