function update_docker_completions
    curl -s -o $HOME/.config/fish/completions/docker.fish https://raw.githubusercontent.com/docker/cli/master/contrib/completion/fish/docker.fish
end
