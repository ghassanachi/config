#!/bin/bash

# NeoVim/Vim Config
rm $HOME/.config/nvim 2> /dev/null
ln -s $HOME/dev/config/nvim/ $HOME/.config/nvim

# Make cache directory
mkdir $HOME/.vimdid 2> /dev/null

rm $HOME/.bin 2> /dev/null
ln -s $HOME/dev/config/bin  $HOME/.bin


# Fish Config
rm $HOME/.config/fish 2> /dev/null
ln -s $HOME/dev/config/fish/ $HOME/.config/fish

# starship prompt
rm $HOME/.config/starship.toml 2> /dev/null
ln -s $HOME/dev/config/starship/starship.toml $HOME/.config/starship.toml

# karabiner config
rm $HOME/.config/karabiner 2> /dev/null
ln -s $HOME/dev/config/karabiner/ $HOME/.config/karabiner

#  yabai config
rm $HOME/.config/yabai 2> /dev/null
ln -s $HOME/dev/config/yabai/ $HOME/.config/yabai

#  skhd config
rm $HOME/.config/skhd 2> /dev/null
ln -s $HOME/dev/config/skhd/ $HOME/.config/skhd

# profile
ln -sf $HOME/dev/config/profile/profile $HOME/.profile

rm $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc 2> /dev/null
cp $HOME/dev/config/obsidian/.obsidian.vimrc $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc

# Tmux Conf and Local
ln -sf $HOME/dev/config/tmux/tmux.conf $HOME/.tmux.conf
ln -sf "$HOME/dev/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

# Alacritty Conf
rm $HOME/.config/alacritty 2> /dev/null
ln -s $HOME/dev/config/alacritty/ $HOME/.config/alacritty

# Jetbrains idea config
ln -sf $HOME/dev/config/jetbrains/.ideavimrc $HOME/.ideavimrc

# sketchybar
rm $HOME/.config/sketchybar 2> /dev/null
ln -s $HOME/dev/config/sketchybar/ $HOME/.config/sketchybar


echo ""
echo "Config Files Linked"
echo ""


