# ~/.config/zsh/conf.d/09-pokemon.bash
# git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git

if ! has-cmd pokemon-colorscripts; then
  return 0
fi

pokemon-colorscripts -r
