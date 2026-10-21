#!/bin/sh
# Dev-box bootstrap. Designed to be piped straight from the network:
#
#   curl -fsSL dev.ghassanachi.com | sh
#   curl -fsSL dev.ghassanachi.com | sh -s -- --full
#   curl -fsSL https://raw.githubusercontent.com/ghassanachi/config/master/devbox/install.sh | bash
#
# Deliberately POSIX sh (no arrays, no [[ ]]) so that `| sh` works as typed --
# a piped script cannot re-exec itself under bash, since its source is stdin
# rather than a file. tools.sh and link.sh are bash and are invoked as such.
#
# Because it may run with no repo present, this script is self-contained up to
# the point where it clones the config repo and hands off to devbox/tools.sh
# and devbox/link.sh. Safe to re-run.

set -eu

REPO_URL="${DEVBOX_REPO:-https://github.com/ghassanachi/config.git}"
REPO_REF="${DEVBOX_REF:-master}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/dotfiles}"

DO_TOOLS=1
DO_LINK=1
NVIM_FULL="${NVIM_FULL:-0}"

# alfred/ alone is 18MB of this repo's 19MB, and a dev box needs none of the
# macOS trees. A shallow + blobless + sparse clone pulls ~640KB instead of 50MB.
# Space-separated (not an array) to stay POSIX; intentionally word-split below.
SPARSE_PATHS="devbox tmux nvim bin claude agentic starship sqlite jj"

usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  --full          Install the complete nvim stack (LSP/mason, treesitter,
                  neotest, cmp) plus build-essential. Default is the lean
                  profile: same keymaps and options, no compiler, ~20s.
  --no-tools      Skip tool installation; only link configs.
  --no-link       Skip linking; only install tools.
  --ref <ref>     Branch or tag to install from (default: master).
  --dir <path>    Where to clone the config repo (default: ~/.config/dotfiles).
  -h, --help      Show this help.

Environment:
  DEVBOX_REPO, DEVBOX_REF, CONFIG_DIR, NVIM_FULL, BIN_DIR
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --full)     NVIM_FULL=1 ;;
        --no-tools) DO_TOOLS=0 ;;
        --no-link)  DO_LINK=0 ;;
        --ref)      REPO_REF="${2:?--ref needs a value}"; shift ;;
        --dir)      CONFIG_DIR="${2:?--dir needs a value}"; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) printf 'unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

export NVIM_FULL CONFIG_DIR

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

preflight() {
    arch=$(uname -m)
    [ "$arch" = "x86_64" ] || {
        printf 'error: only x86_64 is supported (found %s). The upstream asset\n' "$arch" >&2
        printf '       names in devbox/tools.sh would need arm64 variants.\n' >&2
        exit 1
    }

    command -v apt-get >/dev/null 2>&1 || {
        printf 'error: this installer targets Debian/Ubuntu (apt-get not found)\n' >&2
        exit 1
    }

    [ "$(id -u)" != "0" ] || {
        printf 'error: run as your normal user, not root -- configs are linked\n' >&2
        printf '       into $HOME and tools into ~/.local/bin\n' >&2
        exit 1
    }

    command -v curl >/dev/null 2>&1 || { printf 'error: curl is required\n' >&2; exit 1; }

    if [ "$DO_TOOLS" = "1" ]; then
        sudo -n true 2>/dev/null || printf 'note: sudo may prompt for a password (apt step)\n' >&2
    fi
}

# ---------------------------------------------------------------------------
# Clone
# ---------------------------------------------------------------------------

ensure_git() {
    command -v git >/dev/null 2>&1 && return 0
    printf '==> installing git\n'
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git ca-certificates >/dev/null
}

clone_config() {
    if [ -d "$CONFIG_DIR/.git" ]; then
        printf '==> updating %s\n' "$CONFIG_DIR"
        git -C "$CONFIG_DIR" fetch --depth 1 origin "$REPO_REF"
        git -C "$CONFIG_DIR" checkout -q --detach FETCH_HEAD
        # Refresh the sparse set in case this script added new paths since the
        # last run.
        # shellcheck disable=SC2086  # intentional word splitting
        git -C "$CONFIG_DIR" sparse-checkout set $SPARSE_PATHS 2>/dev/null || true
        return 0
    fi

    if [ -e "$CONFIG_DIR" ]; then
        printf 'error: %s exists but is not a git repo\n' "$CONFIG_DIR" >&2
        exit 1
    fi

    printf '==> cloning %s (%s)\n' "$REPO_URL" "$REPO_REF"
    mkdir -p "$(dirname "$CONFIG_DIR")"
    git clone \
        --depth 1 \
        --branch "$REPO_REF" \
        --filter=blob:none \
        --sparse \
        "$REPO_URL" "$CONFIG_DIR"
    # shellcheck disable=SC2086  # intentional word splitting
    git -C "$CONFIG_DIR" sparse-checkout set $SPARSE_PATHS
}

# ---------------------------------------------------------------------------

main() {
    preflight
    ensure_git
    clone_config

    devbox="$CONFIG_DIR/devbox"
    [ -d "$devbox" ] || { printf 'error: %s missing after clone\n' "$devbox" >&2; exit 1; }
    chmod +x "$devbox"/*.sh 2>/dev/null || true

    # tools.sh and link.sh use arrays, so they need bash specifically -- this
    # script itself may be running under dash via `| sh`.
    command -v bash >/dev/null 2>&1 || {
        printf 'error: bash is required for the install steps\n' >&2
        exit 1
    }

    if [ "$DO_TOOLS" = "1" ]; then
        bash "$devbox/tools.sh"
    fi
    if [ "$DO_LINK" = "1" ]; then
        bash "$devbox/link.sh"
    fi

    cat <<EOF

Done. Config: $CONFIG_DIR

Next:
  exec bash -l                 reload the shell (picks up ~/.local/bin, aliases, prompt)
  ghlogin                      GitHub device-code login, then wires git credentials
  tmux new -s work             start a session (F12 in your LOCAL tmux hands keys to this one)
EOF

    if [ "$NVIM_FULL" != "1" ]; then
        cat <<'EOF'

nvim is in lean mode: your keymaps, options, autocmds, gruvbox, telescope, oil,
harpoon, fugitive and undotree -- no LSP/treesitter, no compiler needed.
For the full stack: re-run with --full, or `NVIM_FULL=1 nvim`.
EOF
    fi
}

main "$@"
