#!/usr/bin/env bash
# Symlink the dev-box-relevant configs into place. Safe to re-run.
#
# This is deliberately NOT the root install.sh: that one is macOS-oriented and
# links things a Linux dev box has no use for (alacritty, karabiner, yabai,
# sketchybar, ...). Most importantly it links profile/profile, which is *fish*
# syntax -- linking that to ~/.profile on Linux breaks every bash login shell.

set -euo pipefail

DEVBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$DEVBOX_DIR")"
# shellcheck source=./lib.sh
. "$DEVBOX_DIR/lib.sh"

BASHRC_MARKER_START="# >>> devbox (managed by config/devbox) >>>"
BASHRC_MARKER_END="# <<< devbox (managed by config/devbox) <<<"

link_configs() {
    step "linking configs"

    # tmux: the *server* config (inner tmux), not tmux.conf which is the
    # local/outer one holding the F12 nesting toggle.
    link "$CONFIG_DIR/tmux/tmux.server.conf" "$HOME/.tmux.conf"

    link "$CONFIG_DIR/nvim"                  "$HOME/.config/nvim"
    link "$CONFIG_DIR/bin"                   "$HOME/.bin"
    link "$DEVBOX_DIR/gitconfig"             "$HOME/.gitconfig"
    link "$CONFIG_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    link "$CONFIG_DIR/sqlite"                "$HOME/.config/sqlite3"
    link "$CONFIG_DIR/jj/config.toml"        "$HOME/.config/jj/config.toml"

    # Claude Code
    link "$CONFIG_DIR/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
    link "$CONFIG_DIR/claude/settings.json"   "$HOME/.claude/settings.json"
    link "$CONFIG_DIR/claude/keybindings.json" "$HOME/.claude/keybindings.json"

    # Claude Code skills, one symlink per skill (same approach as the root
    # install.sh, so both stay consistent).
    if [ -d "$CONFIG_DIR/agentic/skills" ]; then
        mkdir -p "$HOME/.claude/skills"
        local skill_dir skill_name
        for skill_dir in "$CONFIG_DIR"/agentic/skills/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            link "${skill_dir%/}" "$HOME/.claude/skills/$skill_name"
        done
    fi
}

make_dirs() {
    # set.lua enables `undofile` with undodir=~/.vim/undodir; nvim will not
    # create the directory itself and errors on every write without it.
    mkdir -p "$HOME/.vim/undodir"
    # shellcheck disable=SC2088  # display string, not a path to expand
    ok "~/.vim/undodir"
}

# Append a marker-delimited block to ~/.bashrc rather than replacing the file:
# the beam's stock bashrc has useful defaults, and a marker block stays
# idempotent across re-runs (the old block is stripped first).
hook_bashrc() {
    local rc="$HOME/.bashrc"
    [ -f "$rc" ] || touch "$rc"

    if grep -qF "$BASHRC_MARKER_START" "$rc"; then
        # Strip the previous block so a re-run never stacks duplicates.
        local tmp
        tmp=$(mktemp)
        sed "/^${BASHRC_MARKER_START}$/,/^${BASHRC_MARKER_END}$/d" "$rc" > "$tmp"
        cat "$tmp" > "$rc"
        rm -f "$tmp"
    fi

    {
        printf '%s\n' "$BASHRC_MARKER_START"
        printf '%s\n' "[ -f \"$DEVBOX_DIR/bashrc\" ] && . \"$DEVBOX_DIR/bashrc\""
        printf '%s\n' "$BASHRC_MARKER_END"
    } >> "$rc"

    # shellcheck disable=SC2088  # display string, not a path to expand
    ok "~/.bashrc sources devbox/bashrc"
}

main() {
    link_configs
    make_dirs
    hook_bashrc
}

main "$@"
