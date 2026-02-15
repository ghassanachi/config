# fnm
set PATH "/Users/ghassangedeonachi/Library/Application Support/fnm" $PATH
fnm env | source

# fnm
set FNM_PATH "/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]
  fnm env | source
end
