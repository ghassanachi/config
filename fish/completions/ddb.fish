# Completion for the ddb dispatcher at ~/developer/tmp/aws/bin/ddb.
# Subcommands and their descriptions are pulled live from `ddb subcommands`
# and `ddb help`, so new ddb-* scripts show up automatically.

function __ddb_subcommands
    # Only works when ddb is on PATH (direnv provides it inside the project dir).
    if command -q ddb
        ddb help 2>/dev/null \
            | awk '/^  [a-z]/ { name=$1; $1=""; sub(/^ +/, ""); print name"\t"$0 }'
    end
end

complete -c ddb -f

# Top-level subcommands — only complete these when no subcommand has been given yet.
complete -c ddb -n '__fish_use_subcommand' -a '(__ddb_subcommands)'
complete -c ddb -n '__fish_use_subcommand' -a 'help' -d 'Show subcommand list'
