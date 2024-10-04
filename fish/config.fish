# --- Abbreviations ------------------------------------------------

# General
alias ls 'lsd'
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

# Rust
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths
set -U fish_user_paths $HOME/.cargo-target/release $fish_user_paths

set -Ux CARGO_TARGET_DIR $HOME/.cargo-target
set -Ux CARGO_INCREMENTAL 1
set -Ux RUSTFLAGS "-C target-cpu=native"
set -Ux RUST_BACKTRACE 1


# Deno
set -Ux DENO_INSTALL $HOME/.deno
set -U fish_user_paths $DENO_INSTALL/bin $fish_user_paths

#Go
set -Ux GOPATH $HOME/.go
set -x fish_user_paths $GOPATH/bin $fish_user_paths

# bun
set -Ux BUN_INSTALL $HOME/.bun
set -x fish_user_paths $BUN_INSTALL/bin $fish_user_paths


# --- Tmux launcher --------------------------------------------------

if status --is-interactive
	if not set -q TMUX
    	if tmux has-session -t home
	   	 exec tmux attach-session -t home
    	else
    	 exec tmux new-session -s home
    	end
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

# pyenv: use function since it it slow at starup
status is-login; and pyenv init --path | source
pyenv init - --no-rehash | source

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
