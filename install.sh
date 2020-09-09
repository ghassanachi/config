#!/bin/bash

# NeoVim/Vim Config
rm $HOME/.config/nvim 2> /dev/null
ln -s $HOME/dev/config/nvim/ $HOME/.config/nvim

# Make cache directory
mkdir $HOME/.vimdid 2> /dev/null

# Fish Config
rm $HOME/.config/fish 2> /dev/null
ln -s $HOME/dev/config/fish/ $HOME/.config/fish

# karabiner config
rm $HOME/.config/karabiner 2> /dev/null
ln -s $HOME/dev/config/karabiner/ $HOME/.config/karabiner

# phoenix config
rm $HOME/.config/phoenix 2> /dev/null
ln -s $HOME/dev/config/phoenix/ $HOME/.config/phoenix

# Tmux Conf and Local
ln -sf $HOME/dev/config/tmux/tmux.conf $HOME/.tmux.conf
ln -sf "$HOME/dev/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

# Alacritty Conf
rm $HOME/.config/alacritty 2> /dev/null
ln -s $HOME/dev/config/alacritty/ $HOME/.config/alacritty

# Jetbrains idea config
ln -sf $HOME/dev/config/jetbrains/.ideavimrc $HOME/.ideavimrc

echo "" 
echo "Config Files Linked"
echo "" 


