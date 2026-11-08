# ~/.config/bash/conf.d/03-starship.bash
# starship setup

# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

if has-cmd starship; then
  if shell-init starship init bash; then
    if [[ ${BLE_VERSION:-} ]]; then
      # Replace Starship's static Bash character with a mode-aware ble.sh unit.
      _blerc_starship_character_hook() {
        local reset=$'\\[\e[0m\\] '

        [[ $PS1 == *"❯$reset" ]] || return 0
        PS1=${PS1%"❯$reset"}
        # Starship may reuse the preceding color for the error symbol.
        if [[ $PS1 == *'\]' ]]; then
          PS1=${PS1%\\\[*}
        fi
        PS1=$PS1'\q{blerc/starship-character}'
      }

      # Starship generates PS1 first; this hook replaces its final character.
      blehook PRECMD-+=_blerc_starship_character_hook
    fi
  else
    printf 'WARNING, %s: starship init failed\n' "${BASH_SOURCE[0]##*/}" >&2
  fi
fi
