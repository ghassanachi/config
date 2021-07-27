# --- Abbreviations ------------------------------------------------

# General
abbr -a rm "trash" 
abbr -a ls 'lsd'
abbr -a yt 'youtube-dl'
abbr -a yta 'youtube-dl -x -f bestaudio/best'
abbr -a xee 'open -a "Xee³"'

# Coding
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

# --- Path Overide ---------------------------------------------------

set -x PATH /opt/local/bin /opt/lcal/sbin $PATH
# Personal bin
set -x PATH $PATH $HOME/.bin
#RUST
set -x PATH $HOME/.cargo/bin $PATH

# Android
set -x PATH $PATH $ANDROID_HOME/emulator
set -x PATH $PATH $ANDROID_HOME/tools
set -x PATH $PATH $ANDROID_HOME/tools/bin
set -x PATH $PATH $ANDROID_HOME/platform-tools

# --- Tmux launcher --------------------------------------------------

if status --is-interactive
	if test -d ~/dev/others/base16/templates/fish-shell
		set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
		builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
	end
	tmux attach 2> /dev/null; and exec true
end

# --- Shell Hooks ----------------------------------------------------

eval (direnv hook fish)

# j 
[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish

# Nvm for fish
 fnm env | source

# pyenv: use function since it it slow at starup
function pyi 
	status is-login; and pyenv init --path | source
	pyenv init - --no-rehash | source
end

# --- Functions ------------------------------------------------------

function amz
	set -x AWS_ACCESS_KEY_ID (aws configure get default.aws_access_key_id | head -n1)
	set -x AWS_SECRET_ACCESS_KEY (aws configure get default.aws_secret_access_key | head -n1)
	fish -c ($argv)
	set -e AWS_ACCESS_KEY_ID
	set -e AWS_SECRET_ACCESS_KEY
end

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

