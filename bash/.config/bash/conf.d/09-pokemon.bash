# ~/.config/zsh/conf.d/09-pokemon.bash
# Installation: dotfiles/mise/README.md

if ! has-cmd pokemon-colorscripts; then
  return 0
fi

pokemon-colorscripts -r
