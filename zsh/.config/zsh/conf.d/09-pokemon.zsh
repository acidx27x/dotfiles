# ~/.config/zsh/conf.d/09-pokemon.zsh
# git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git

if ! has-cmd pokemon-colorscripts; then
  return 0
fi

autoload -Uz add-zsh-hook

# call only once then delete
_pokemon_colorscripts_on_terminal_start() {
  pokemon-colorscripts -r
  add-zsh-hook -d precmd _pokemon_colorscripts_on_terminal_start
}

add-zsh-hook precmd _pokemon_colorscripts_on_terminal_start
