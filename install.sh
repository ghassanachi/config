#!/bin/bash

# NeoVim/Vim Config
rm $HOME/.config/nvim 2> /dev/null
ln -s $HOME/dev/config/nvim/ $HOME/.config/nvim


# Make cache directory
mkdir $HOME/.vimdid 2> /dev/null

# Fish Config
rm $HOME/.config/fish 2> /dev/null
ln -s $HOME/dev/config/fish/ $HOME/.config/fish

# Tmux Conf and Local
ln -sf $HOME/dev/config/tmux/tmux.conf $HOME/.tmux.conf
ln -sf "$HOME/dev/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"


echo "" 
echo "Config Files Linked"
echo "" 


