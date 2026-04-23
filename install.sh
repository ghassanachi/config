#!/bin/bash

DEFAULT_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
read -p "Config directory [$DEFAULT_CONFIG_DIR]: " CONFIG_DIR
CONFIG_DIR="${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
echo "Using config directory: $CONFIG_DIR"
echo ""

# NeoVim/Vim Config
rm $HOME/.config/nvim 2> /dev/null
ln -s $CONFIG_DIR/nvim/ $HOME/.config/nvim

# Make cache directory
mkdir $HOME/.vimdid 2> /dev/null

rm $HOME/.bin 2> /dev/null
ln -s $CONFIG_DIR/bin  $HOME/.bin

# Fish Config
rm $HOME/.config/fish 2> /dev/null
ln -s $CONFIG_DIR/fish/ $HOME/.config/fish

# starship prompt
rm $HOME/.config/starship.toml 2> /dev/null
ln -s $CONFIG_DIR/starship/starship.toml $HOME/.config/starship.toml

# karabiner config
rm $HOME/.config/karabiner 2> /dev/null
ln -s $CONFIG_DIR/karabiner/ $HOME/.config/karabiner

#  yabai config
rm $HOME/.config/yabai 2> /dev/null
ln -s $CONFIG_DIR/yabai/ $HOME/.config/yabai

#  skhd config
rm $HOME/.config/skhd 2> /dev/null
ln -s $CONFIG_DIR/skhd/ $HOME/.config/skhd

#  aerospace
rm $HOME/.config/aerospace 2> /dev/null
ln -s $CONFIG_DIR/aerospace $HOME/.config/aerospace

# profile
ln -sf $CONFIG_DIR/profile/profile $HOME/.profile

# Obsidian
# rm $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc 2> /dev/null
# cp $CONFIG_DIR/obsidian/.obsidian.vimrc $HOME/Documents/Obsidian\ Vault/.obsidian.vimrc

# Tmux Conf and Local
ln -sf $CONFIG_DIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf "$CONFIG_DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"

# Alacritty Conf
rm $HOME/.config/alacritty 2> /dev/null
ln -s $CONFIG_DIR/alacritty/ $HOME/.config/alacritty

# Ghostty Conf
rm $HOME/.config/ghostty 2> /dev/null
ln -s $CONFIG_DIR/ghostty $HOME/.config/ghostty

# Jetbrains idea config
ln -sf $CONFIG_DIR/jetbrains/.ideavimrc $HOME/.ideavimrc

# sketchybar
rm $HOME/.config/sketchybar 2> /dev/null
ln -s $CONFIG_DIR/sketchybar/ $HOME/.config/sketchybar

# Claude Code
ln -sf $CONFIG_DIR/claude/CLAUDE.md $HOME/.claude/CLAUDE.md
ln -sf $CONFIG_DIR/claude/keybindings.json $HOME/.claude/keybindings.json
ln -sf $CONFIG_DIR/claude/settings.json $HOME/.claude/settings.json

# sqlite3
rm $HOME/.config/sqlite3 2> /dev/null
ln -s $CONFIG_DIR/sqlite/ $HOME/.config/sqlite3


echo ""
echo "Config Files Linked"
echo ""


