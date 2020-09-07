# Global Settings
fish_vi_key_bindings

## PROGRAMS
# MacPorts

set -xg PATH /opt/local/bin /opt/local/sbin $PATH

# Fzf
setenv FZF_DEFAULT_COMMAND 'fd --type f --follow --exclude .git'
setenv FZF_CTRL_T_COMMAND  'fd --type f --follow --exclude .git'
setenv FZF_DEFAULT_OPTS '--height 20%'

# Editor
set -Ux EDITOR nvim

# direnv
eval (direnv hook fish)

# Openssl 
# set -g fish_user_paths "/usr/local/opt/openssl@1.1/bin" $fish_user_paths
# set -gx LDFLAGS "-L/usr/local/opt/openssl@1.1/lib"
# set -gx CPPFLAGS "-I/usr/local/opt/openssl@1.1/include"
# set -gx PKG_CONFIG_PATH "/usr/local/opt/openssl@1.1/lib/pkgconfig"

#RUST
set -gx PATH $HOME/.cargo/bin $PATH

#Personal Scripts
set -gx PATH $PATH $HOME/.bin

# Android 
set -gx ANDROID_HOME $HOME/Library/Android/sdk
set -gx PATH $PATH $ANDROID_HOME/emulator
set -gx PATH $PATH $ANDROID_HOME/tools
set -gx PATH $PATH $ANDROID_HOME/tools/bin
set -gx PATH $PATH $ANDROID_HOME/platform-tools

# Flutter
set -gx PATH $PATH $HOME/tools/flutter/bin

# Golang
set -gx GOPATH $HOME/go
set -gx GOROOT /usr/local/opt/go/libexec
set -gx PATH $GOPATH/bin:$GOROOT/bin $PATH

# libffi
set -gx LDFLAGS "-L/usr/local/opt/libffi/lib"
set -gx CPPFLAGS "-I/usr/local/opt/libffi/include"

set -gx PKG_CONFIG_PATH "/usr/local/opt/libffi/lib/pkgconfig"

fnm env --multi | source

# autojump
[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish

# fnm
fnm env --multi | source

# pyenv 
status --is-interactive; and source (pyenv init -|psub)

# Abbreviations
abbr -a rm "trash"
# Lsd
abbr -a ls 'lsd'
# youtube-dl
abbr -a yt 'youtube-dl'
abbr -a yta 'youtube-dl -x -f bestaudio/best'
# General
abbr -a c cargo
abbr -a ct 'cargo t'
abbr -a e nvim
abbr -a vim 'nvim'
abbr -a ta 'tmux attach'
abbr -a tn 'tmux new -s'
# Git
abbr -a g git
abbr -a ga 'git add -p'
abbr -a gb 'git branch'
abbr -a gc 'git commit -m'
abbr -a gca 'git commit --amend -m'
abbr -a gco 'git checkout'
abbr -a gp 'git push'
abbr -a gs 'git status'
abbr -a vimdiff 'nvim -d'
abbr -a gah 'git stash; and git pull --rebase; and git stash pop'

# Alias
alias xee 'open -a "Xee³"'
