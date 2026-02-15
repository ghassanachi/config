# --- Abbreviations ------------------------------------------------

# General
alias ls 'eza'
alias unset 'set --erase'
abbr -a rm "trash"
abbr -a cat "bat"

# Coding
abbr -a c   'cargo'
abbr -a ct  'cargo t'
abbr -a e   'nvim'
abbr -a vim 'nvim'
abbr -a ta  'tmux attach'
abbr -a tn  'tmux new -s'

# This is a bit janky but muscle memory is hard
# abbr -a yarn 'npm run'

# Git
abbr -a gco 'git'
abbr -a gb  'git branch'
abbr -a ga  'git add -p'
abbr -a gc  'git commit -m'
abbr -a gca 'git commit --amend -m'
abbr -a gco 'git checkout'
abbr -a gs  'git status'

# Push
abbr -a gp  'git push'
abbr -a gpa 'git push --all'
abbr -a gpA 'git push --all && git push --tags'
abbr -a gpt 'git push --tags'
abbr -a gpc 'git push --set-upstream origin (git branch --show-current)'

# Rebase
abbr -a gr  'git rebase'
abbr -a gra 'git rebase --abort'
abbr -a grc 'git rebase --continue'
abbr -a gri 'git rebase --interactive'
abbr -a grs 'git rebase --skip'

# Utils
abbr -a gah 'git stash; and git pull --rebase; and git stash pop'
abbr -a vimdiff 'nvim -d'

# --- Path Overide ---------------------------------------------------

set -U fish_user_paths /opt/local/bin $fish_user_paths
set -U fish_user_paths /usr/local/sbin $fish_user_paths
set -U fish_user_paths /usr/local/bin $fish_user_paths
set -U fish_user_paths $HOME/.bin $fish_user_paths
set -U fish_user_paths $HOME/.local/bin $fish_user_paths # uv

# Rust
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths
set -U fish_user_paths $HOME/.cargo-target/release $fish_user_paths

# Lua
set -U fish_user_paths /Library/TeX/texbin/ $fish_user_paths

# --- Program config ------------------------------------------------

# Rust
set -Ux CARGO_INCREMENTAL 1
set -Ux RUST_BACKTRACE 1
set -Ux CARGO_TARGET_DIR $HOME/.cargo-target
# set -Ux RUSTFLAGS "-C target-cpu=native"

# Deno
set -Ux DENO_INSTALL $HOME/.deno
set -U fish_user_paths $DENO_INSTALL/bin $fish_user_paths

# Go
set -Ux GOPATH $HOME/.go
set -x fish_user_paths $GOPATH/bin $fish_user_paths

# bun
set -Ux BUN_INSTALL $HOME/.bun
set -x fish_user_paths $BUN_INSTALL/bin $fish_user_paths

# General
set -Ux VISUAL nvim
set -Ux EDITOR nvim

# uv

# --- General Setup --------------------------------------------------

# colored man output
# from http://linuxtidbits.wordpress.com/2009/03/23/less-colors-for-man-pages/
set -Ux LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
set -Ux LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
set -Ux LESS_TERMCAP_me \e'[0m'           # end mode
set -Ux LESS_TERMCAP_se \e'[0m'           # end standout-mode
set -Ux LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
set -Ux LESS_TERMCAP_ue \e'[0m'           # end underline
set -Ux LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline

# --- Tmux launcher --------------------------------------------------

if status --is-interactive; and not set -q TMUX;
    if tmux has-session -t home
        exec tmux attach-session -t home
    else
        exec tmux new-session -s home
    end
end

# --- Shell Hooks ----------------------------------------------------

eval (direnv hook fish)

zoxide init --cmd j fish | source

# Nvm for fish
fnm env | source

# fzf for fish
fzf --fish | source

# Prompt manager
starship init fish | source

# --- Functions ------------------------------------------------------

function amz
	set -x AWS_ACCESS_KEY_ID (aws configure get default.aws_access_key_id | head -n1)
	set -x AWS_SECRET_ACCESS_KEY (aws configure get default.aws_secret_access_key | head -n1)
	fish -c ($argv)
	set -e AWS_ACCESS_KEY_ID
	set -e AWS_SECRET_ACCESS_KEY
end
# --- Shell Props ------------------------------------------------------
set fish_greeting


