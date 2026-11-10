# beams-proxy completions (bin/beams-proxy)
complete -c beams-proxy -f
complete -c beams-proxy -n '__fish_use_subcommand' -a 'start stop restart status logs help'
complete -c beams-proxy -n '__fish_seen_subcommand_from start stop restart status' -a 'openai anthropic all'
complete -c beams-proxy -n '__fish_seen_subcommand_from logs' -a 'openai anthropic'
