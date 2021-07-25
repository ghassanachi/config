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

if status --is-interactive
	if test -d ~/dev/others/base16/templates/fish-shell
		set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
		builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
	end
	tmux 2> /dev/null; and exec true
end


# Global Settings
fish_vi_key_bindings
set -Ux EDITOR nvim

## General
set -xg PATH /opt/local/bin /opt/local/sbin $PATH

# Fzf
setenv FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
setenv FZF_CTRL_T_COMMAND  'fd --type f --hidden --follow --exclude .git'
setenv FZF_DEFAULT_OPTS '--height 20%'

#ffmpeg
set -gx LDFLAGS "-L/usr/local/opt/libffi/lib"
set -gx PKG_CONFIG_PATH "/usr/local/opt/libffi/lib/pkgconfig"

# Personal bin
set -gx PATH $PATH $HOME/.bin

# direnv
# eval (direnv hook fish)

# autojump
[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish


# fnm
#fnm env | source

# pyenv 
set -Ux PYENV_ROOT $HOME/.pyenv
set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
status is-login; and pyenv init --path | source
pyenv init - | source
status --is-interactive; and source (pyenv init -|psub)

# Languages
#RUST
set -gx PATH $HOME/.cargo/bin $PATH

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
set -gx PATH $PATH $GOPATH/bin:$GOROOT/bin

# SML NJ
set -gx SMLPATH /usr/local/smlnj
set -gx PATH $PATH $SMLPATH/bin


# Inspired by Jon load aws credentials
function amz
	set -gx AWS_ACCESS_KEY_ID (aws configure get default.aws_access_key_id | head -n1)
	set -gx AWS_SECRET_ACCESS_KEY (aws configure get default.aws_secret_access_key | head -n1)
	fish -c ($argv)
	set -gx AWS_ACCESS_KEY_ID
	set -gx AWS_SECRET_ACCESS_KEY
end

# inspired by jon (well pretty much just stollen)
# Fish git prompt
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate ''
set __fish_git_prompt_showupstream 'none'
set -g fish_prompt_pwd_dir_length 3

# colored man output
# from http://linuxtidbits.wordpress.com/2009/03/23/less-colors-for-man-pages/
setenv LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
setenv LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
setenv LESS_TERMCAP_me \e'[0m'           # end mode
setenv LESS_TERMCAP_se \e'[0m'           # end standout-mode
setenv LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
setenv LESS_TERMCAP_ue \e'[0m'           # end underline
setenv LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline
function fish_prompt
	set_color blue
	echo -n (hostname | sed s/.local// )
	if [ $PWD != $HOME ]
		set_color brblack
		echo -n ':'
		set_color yellow
		echo -n (basename $PWD)
	end
	set_color green
	printf '%s ' (__fish_git_prompt)
	set_color red
	echo -n '| '
	set_color normal
end

function fish_mode_prompt
  switch $fish_bind_mode
    case default
      set_color red
    case insert
      set_color green
    case replace_one
      set_color green
    case visual
      set_color brmagenta
    case '*'
      set_color red
  end
  echo -n "["(date "+%H:%M")"] "
  set_color normal
end

function fish_greeting
	echo
	echo -e (uname -rs | awk '{print " \\\\e[1mOS: \\\\e[0;32m"$0"\\\\e[0m"}')
	echo -e (uptime | sed 's/^up (.+) //' | awk '{print " \\\\e[1mUptime: \\\\e[0;32m"$1"\\\\e[0m"}')
	echo -e (uname -n | awk '{print " \\\\e[1mHostname: \\\\e[0;32m"$0"\\\\e[0m"}')

	set r (random 0 100)
	if [ $r -lt 5 ] # only occasionally show backlog (5%)
		echo -e " \e[1mBacklog\e[0;32m"
		set_color blue
		echo "  [project] <description>"
		echo
	end

	set_color normal
	echo -e " \e[1mTODOs\e[0;32m"
	echo
	if [ $r -lt 10 ]
		# unimportant, so show rarely
		set_color cyan
		# echo "  [project] <description>"
	end
	if [ $r -lt 25 ]
		# back-of-my-mind, so show occasionally
		set_color green
		# echo "  [project] <description>"
	end
	if [ $r -lt 50 ]
		# upcoming, so prompt regularly
		set_color yellow
		# echo "  [project] <description>"
	end

	# urgent, so prompt always
	set_color red
	# echo "  [project] <description>"

	echo

	if test -s ~/todo
		set_color magenta
		cat todo | sed 's/^/ /'
		echo
	end

	set_color normal
end

