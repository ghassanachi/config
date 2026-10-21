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
    # ~/.gitconfig is NOT linked -- see include_gitconfig below.
    link "$CONFIG_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    link "$CONFIG_DIR/sqlite"                "$HOME/.config/sqlite3"
    link "$CONFIG_DIR/jj/config.toml"        "$HOME/.config/jj/config.toml"

    # Claude Code. CLAUDE.md and settings.json are handled specially below --
    # a dev box ships its own versions of both and they carry information the
    # personal config does not. keybindings are pure UX, so a plain link.
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
    # bashrc only prepends PATH entries that exist, so make sure the bin dir is
    # there even when tools were skipped (--no-tools).
    mkdir -p "${BIN_DIR:-$HOME/.local/bin}"

    # set.lua enables `undofile` with undodir=~/.vim/undodir; nvim will not
    # create the directory itself and errors on every write without it.
    mkdir -p "$HOME/.vim/undodir"
    # shellcheck disable=SC2088  # display string, not a path to expand
    ok "~/.vim/undodir"
}

# Append a marker-delimited block rather than replacing the file: the stock
# bashrc has useful defaults, and a marker block stays idempotent across
# re-runs (the old block is stripped first).
#
# Done for BOTH ~/.bashrc and ~/.profile, which is not redundant: bash reads
# ~/.bashrc for interactive non-login shells and ~/.profile for login shells,
# and tmux starts login shells. Debian's stock ~/.profile happens to chain to
# ~/.bashrc, but relying on that means a replaced or absent ~/.profile
# silently costs you every alias inside tmux. devbox/bashrc carries its own
# already-sourced guard, so covering both files is free.
hook_shell_rc() {
    local rc="$1" label="$2"
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

    ok "$label sources devbox/bashrc"
}

hook_bashrc() {
    # shellcheck disable=SC2088  # display strings, not paths to expand
    hook_shell_rc "$HOME/.bashrc" "~/.bashrc"
    # shellcheck disable=SC2088
    hook_shell_rc "$HOME/.profile" "~/.profile  (login shells, e.g. tmux)"
}

CLAUDE_MD_MARKER_START="<!-- >>> devbox (managed by config/devbox) >>> -->"
CLAUDE_MD_MARKER_END="<!-- <<< devbox (managed by config/devbox) <<< -->"

# A dev box provides its own ~/.claude/CLAUDE.md documenting the environment
# (API env vars, teleport resources, how to publish apps). The personal
# CLAUDE.md is 269 lines of coding guidelines with zero overlap, so replacing
# one with the other loses real information. Compose them instead: keep
# whatever is there and append an @import of the personal file, which also
# means the import stays live with the repo.
compose_claude_md() {
    local personal="$CONFIG_DIR/claude/CLAUDE.md"
    local target="$HOME/.claude/CLAUDE.md"
    [ -f "$personal" ] || { warn "missing, not imported: $personal"; return 0; }

    mkdir -p "$HOME/.claude"

    # An earlier run (or an older version of this script) may have left a
    # symlink. The import supersedes it and preserves nothing, so drop it.
    [ -L "$target" ] && rm -f "$target"
    [ -f "$target" ] || touch "$target"

    if grep -qF "$CLAUDE_MD_MARKER_START" "$target"; then
        local tmp
        tmp=$(mktemp)
        sed "/^${CLAUDE_MD_MARKER_START}$/,/^${CLAUDE_MD_MARKER_END}$/d" "$target" > "$tmp"
        cat "$tmp" > "$target"
        rm -f "$tmp"
    fi

    {
        printf '\n%s\n' "$CLAUDE_MD_MARKER_START"
        printf '@%s\n' "$personal"
        printf '%s\n' "$CLAUDE_MD_MARKER_END"
    } >> "$target"

    # shellcheck disable=SC2088  # display string, not a path to expand
    ok "~/.claude/CLAUDE.md imports personal config (environment docs kept)"
}

# settings.json cannot be composed the way CLAUDE.md can, and a straight
# symlink is actively harmful here: the dev box sets env keys that matter on a
# headless machine (CLAUDE_CODE_SKIP_BROWSER) plus availableModels/
# fallbackModel describing what the box can actually run, while the personal
# file pins `model`. Linking over it can leave a pin the box cannot satisfy.
# So: merge, with the personal file as the base and the environment-specific
# keys from whatever was already there winning.
merge_claude_settings() {
    local personal="$CONFIG_DIR/claude/settings.json"
    local target="$HOME/.claude/settings.json"
    [ -f "$personal" ] || return 0

    have jq || { warn "jq absent; leaving $target alone"; return 0; }
    mkdir -p "$HOME/.claude"

    if [ ! -e "$target" ]; then
        cp "$personal" "$target"
        # shellcheck disable=SC2088  # display string, not a path to expand
        ok "~/.claude/settings.json (from personal config)"
        return 0
    fi

    [ -L "$target" ] && rm -f "$target" && cp "$personal" "$target"

    local tmp
    tmp=$(mktemp)
    # Personal settings as the base; existing env merged over it, and the
    # model-availability keys preserved verbatim when present.
    if jq -s '
        .[0] as $personal | .[1] as $existing |
        $personal
        + ($existing | {env: ((($personal.env // {}) + ($existing.env // {})))})
        + ($existing | with_entries(select(.key | IN("availableModels", "fallbackModel"))))
    ' "$personal" "$target" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        cat "$tmp" > "$target"
        # shellcheck disable=SC2088
        ok "~/.claude/settings.json merged (kept env + model availability)"
    else
        warn "could not merge settings.json; left as-is"
    fi
    rm -f "$tmp"
}

# ~/.gitconfig is included, not symlinked.
#
# `gh auth setup-git` writes a credential helper into the global git config. If
# ~/.gitconfig were a symlink into this repo, that machine-local credential
# wiring would be written into the *tracked* file -- dirtying the repo, and
# being discarded the next time this script re-linked it. Worse, the token
# plumbing would silently stop working after a re-run.
#
# An [include] keeps the shared settings versioned while leaving ~/.gitconfig a
# real, machine-local file. Include is also resolved before the including
# file's own later entries, so anything gh (or you) adds locally wins.
include_gitconfig() {
    local shared="$DEVBOX_DIR/gitconfig"
    [ -f "$shared" ] || { warn "missing, not included: $shared"; return 0; }

    # An earlier version of this script symlinked it; convert to a real file.
    if [ -L "$HOME/.gitconfig" ]; then
        rm -f "$HOME/.gitconfig"
        warn "replaced the ~/.gitconfig symlink with an include"
    fi

    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$shared"; then
        # shellcheck disable=SC2088  # display string, not a path to expand
        skip "~/.gitconfig already includes devbox/gitconfig"
        return 0
    fi

    git config --global --add include.path "$shared"
    # shellcheck disable=SC2088  # display string, not a path to expand
    ok "~/.gitconfig includes devbox/gitconfig"
}

main() {
    link_configs
    include_gitconfig
    compose_claude_md
    merge_claude_settings
    make_dirs
    hook_bashrc
}

main "$@"
