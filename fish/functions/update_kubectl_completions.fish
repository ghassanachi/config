function update_kubectl_completions
    curl -s -o $HOME/.config/fish/completions/kubectl.fish https://raw.githubusercontent.com/evanlucas/fish-kubectl-completions/master/completions/kubectl.fish 
end

