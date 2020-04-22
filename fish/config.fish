# Global Settings
fish_vi_key_bindings
#set SPACEFISH_VI_MODE_SHOW false
set TERM xterm-256color


## PROGRAMS
# MacPorts

set -xg PATH /opt/local/bin /opt/local/sbin $PATH


# Editor
set -Ux EDITOR nvim

# direnv
eval (direnv hook fish)

#NODE
set -x NODE_PATH (npm root -g)


set -g fish_user_paths "/usr/local/opt/openssl@1.1/bin" $fish_user_paths
set -gx LDFLAGS "-L/usr/local/opt/openssl@1.1/lib"
set -gx CPPFLAGS "-I/usr/local/opt/openssl@1.1/include"
set -gx PKG_CONFIG_PATH "/usr/local/opt/openssl@1.1/lib/pkgconfig"

#RUST
set PATH $HOME/.cargo/bin $PATH

#Personal Scripts
set PATH $PATH $HOME/.bin

# Android 
set ANDROID_HOME $HOME/Library/Android/sdk
set PATH $PATH $ANDROID_HOME/emulator
set PATH $PATH $ANDROID_HOME/tools
set PATH $PATH $ANDROID_HOME/tools/bin
set PATH $PATH $ANDROID_HOME/platform-tools

# Flutter
set PATH $PATH $HOME/tools/flutter/bin



#Aliases
abbr -a vim 'nvim'
abbr -a e 'nvim'
#Abbreviations
abbr -a rm "trash"
#Lsd
abbr -a ls 'lsd'
abbr -a ll 'lsd -l'
abbr -a la 'lsd -a'
abbr -a lll 'lsa -la'
abbr -a lt 'ls --tree'
#udemy-dl
abbr -a udemy-dl 'python ~/.bin/udemy-dl/udemy-dl.py'
abbr -a lzd 'lazydocker'
abbr -a tk 'tk'
abbr -a xee 'open -a "Xee³"'





set -gx GOPATH $HOME/go
set -gx GOROOT $HOME/.go
set -gx PATH $GOPATH/bin $PATH
# g-install: do NOT edit, see https://github.com/stefanmaric/g
set -g fish_user_paths "/usr/local/sbin" $fish_user_paths

