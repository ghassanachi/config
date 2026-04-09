#!/bin/bash

# NeoVim/Vim Config
rm $HOME/.config/nvim 2> /dev/null
ln -s $HOME/developer/config/nvim/ $HOME/.config/nvim

# Make cache directory
mkdir $HOME/.vimdid 2> /dev/null

rm $HOME/.bin 2> /dev/null
ln -s $HOME/developer/config/bin  $HOME/.bin

# Fish Config
rm $HOME/.config/fish 2> /dev/null
ln -s $HOME/developer/config/fish/ $HOME/.config/fish

# starship prompt
rm $HOME/.config/starship.toml 2> /dev/null
ln -s $HOME/developer/config/starship/starship.toml $HOME/.config/starship.toml

# karabiner config
rm $HOME/.config/karabiner 2> /dev/null
ln -s $HOME/developer/config/karabiner/ $HOME/.config/karabiner

#  yabai config
rm $HOME/.config/yabai 2> /dev/null
ln -s $HOME/developer/config/yabai/ $HOME/.config/yabai

#  skhd config
rm $HOME/.config/skhd 2> /dev/null
ln -s $HOME/developer/config/skhd/ $HOME/.config/skhd

#  aerospace
rm $HOME/.config/aerospace 2> /dev/null
ln -s $HOME/developer/config/aerospace $HOME/.config/aerospace

# profile
ln -sf $HOME/developer/config/profile/profile $HOME/.profile

# Obsidian
# rm $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc 2> /dev/null
# cp $HOME/developer/config/obsidian/.obsidian.vimrc $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc

# Tmux Conf and Local
ln -sf $HOME/developer/config/tmux/tmux.conf $HOME/.tmux.conf
ln -sf "$HOME/developer/config/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

# Alacritty Conf
rm $HOME/.config/alacritty 2> /dev/null
ln -s $HOME/developer/config/alacritty/ $HOME/.config/alacritty

# Ghostty Conf
rm $HOME/.config/ghostty 2> /dev/null
ln -s $HOME/developer/config/ghostty $HOME/.config/ghostty

# Jetbrains idea config
ln -sf $HOME/developer/config/jetbrains/.ideavimrc $HOME/.ideavimrc

# sketchybar
rm $HOME/.config/sketchybar 2> /dev/null
ln -s $HOME/developer/config/sketchybar/ $HOME/.config/sketchybar

# agentic
ln -s $HOME/developer/config/agentic/claude/CLAUDE.md $HOME/.claude/CLAUDE.md


echo ""
echo "Config Files Linked"
echo ""


