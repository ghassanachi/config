#!/usr/bin/env bash
# Install dev-box tooling. Safe to re-run: every step is skipped when already
# satisfied.
#
# Split between apt and upstream releases on a single rule: use apt wherever
# "old but works" is true, and upstream wherever the Debian version is absent
# or so stale it breaks how the config actually uses the tool. See README.md.

set -euo pipefail

DEVBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
. "$DEVBOX_DIR/lib.sh"

NVIM_FULL="${NVIM_FULL:-0}"

# ---------------------------------------------------------------------------
# apt
# ---------------------------------------------------------------------------
# trash-cli  0.17.1  ships /usr/bin/trash exactly, which the `rm` alias wants
# fd-find    8.6.0   binary is `fdfind` on Debian; shimmed below
# bat        0.22.1  binary is `batcat` on Debian; shimmed below
# direnv     2.32.1
# ripgrep    13.0    usually preinstalled
# unzip / ca-certificates / tar  general prerequisites

# jq is needed by link.sh to merge settings.json rather than clobber it.
apt_packages=(trash-cli fd-find bat direnv ripgrep unzip ca-certificates jq)

# build-essential is only needed by the full nvim stack: treesitter's :TSUpdate
# compiles parsers, telescope-fzf-native has build = 'make', and LuaSnip builds
# jsregexp. The lean path never invokes a compiler, so we skip ~250MB of
# toolchain on every beam that does not ask for it.
if [ "$NVIM_FULL" = "1" ]; then
    apt_packages+=(build-essential)
fi

install_apt() {
    local missing=() pkg
    for pkg in "${apt_packages[@]}"; do
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed" || missing+=("$pkg")
    done

    if [ ${#missing[@]} -eq 0 ]; then
        skip "apt packages already installed"
        return 0
    fi

    step "apt: installing ${missing[*]}"
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" >/dev/null
    ok "apt packages installed"
}

# Debian renames two binaries; shim them so muscle memory (and the FZF_*
# commands, which call `fd`) keeps working.
install_shims() {
    mkdir -p "$BIN_DIR"
    local pair src dst
    for pair in "fd:fdfind" "bat:batcat"; do
        dst="${pair%%:*}"; src="${pair##*:}"
        if have "$dst" && [ ! -L "$BIN_DIR/$dst" ]; then
            skip "$dst already on PATH"
        elif have "$src"; then
            ln -sfn "$(command -v "$src")" "$BIN_DIR/$dst"
            ok "shim $dst -> $src"
        fi
    done
}

# ---------------------------------------------------------------------------
# Upstream: neovim
# ---------------------------------------------------------------------------
# Debian bookworm ships 0.7.2. The config requires far newer: lazy_init.lua
# uses vim.uv, and treesitter.lua pins branch = "main", which needs 0.11+.
# Installed as a full tree (not a lone binary) because nvim needs its bundled
# runtime/ directory.

install_nvim() {
    local tag url
    tag=$(gh_latest_tag neovim/neovim) || { warn "could not resolve neovim version"; return 1; }

    if version_matches nvim "$tag"; then
        skip "neovim $tag"
        return 0
    fi

    step "neovim $tag"
    url="https://github.com/neovim/neovim/releases/download/$tag/nvim-linux-x86_64.tar.gz"

    local tmp
    tmp=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" RETURN

    curl -fsSL --max-time 300 "$url" | tar -xz -C "$tmp" --strip-components=1 || {
        warn "neovim download failed"
        return 1
    }

    mkdir -p "$OPT_DIR"
    rm -rf "$OPT_DIR/nvim"
    mv "$tmp" "$OPT_DIR/nvim"
    trap - RETURN
    mkdir -p "$BIN_DIR"
    ln -sfn "$OPT_DIR/nvim/bin/nvim" "$BIN_DIR/nvim"
    ok "neovim $tag -> $BIN_DIR/nvim"
}

# ---------------------------------------------------------------------------
# Upstream: version-stamped tarballs
# ---------------------------------------------------------------------------
# Each asset name embeds the version, so resolve the tag first. Note the
# inconsistent "v" handling between tags and filenames, hence ${tag#v}.

install_eza() {
    local tag
    tag=$(gh_latest_tag eza-community/eza) || return 1
    version_matches eza "$tag" && { skip "eza $tag"; return 0; }
    step "eza $tag"
    install_from_tarball \
        "https://github.com/eza-community/eza/releases/download/$tag/eza_x86_64-unknown-linux-gnu.tar.gz" \
        eza && ok "eza $tag"
}

install_delta() {
    local tag
    tag=$(gh_latest_tag dandavison/delta) || return 1
    version_matches delta "$tag" && { skip "delta $tag"; return 0; }
    step "delta $tag"
    install_from_tarball \
        "https://github.com/dandavison/delta/releases/download/$tag/delta-${tag#v}-x86_64-unknown-linux-gnu.tar.gz" \
        delta && ok "delta $tag"
}

install_fzf() {
    local tag
    tag=$(gh_latest_tag junegunn/fzf) || return 1
    version_matches fzf "$tag" && { skip "fzf $tag"; return 0; }
    # Debian's 0.38 predates `fzf --bash` (added in 0.48.0), which the shell
    # integration in devbox/bashrc relies on.
    step "fzf $tag"
    install_from_tarball \
        "https://github.com/junegunn/fzf/releases/download/$tag/fzf-${tag#v}-linux_amd64.tar.gz" \
        fzf && ok "fzf $tag"
}

install_gh() {
    local tag
    tag=$(gh_latest_tag cli/cli) || return 1
    version_matches gh "$tag" && { skip "gh $tag"; return 0; }
    step "gh $tag"
    install_from_tarball \
        "https://github.com/cli/cli/releases/download/$tag/gh_${tag#v}_linux_amd64.tar.gz" \
        gh && ok "gh $tag"
}

# ---------------------------------------------------------------------------
# Upstream: official install scripts
# ---------------------------------------------------------------------------
# zoxide and starship both ship installers that honour a target bin dir, which
# is less brittle than tracking their asset naming ourselves.

install_zoxide() {
    # Debian has 0.4.3 (~5 years stale) and `init --cmd j` is not reliable there.
    if have zoxide; then skip "zoxide $(tool_version zoxide)"; return 0; fi
    step "zoxide"
    curl -fsSL --max-time 180 https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
        | sh -s -- --bin-dir "$BIN_DIR" >/dev/null 2>&1 \
        && ok "zoxide $(tool_version zoxide || echo installed)"
}

install_starship() {
    if have starship; then skip "starship $(tool_version starship)"; return 0; fi
    step "starship"
    curl -fsSL --max-time 180 https://starship.rs/install.sh \
        | sh -s -- --bin-dir "$BIN_DIR" --yes >/dev/null 2>&1 \
        && ok "starship $(tool_version starship || echo installed)"
}

# ---------------------------------------------------------------------------

main() {
    have curl || die "curl is required"
    have sudo || die "sudo is required for the apt step"

    mkdir -p "$BIN_DIR" "$OPT_DIR"
    # Make freshly installed tools visible to the version checks below, even
    # though the login shell has not been reloaded yet.
    case ":$PATH:" in *":$BIN_DIR:"*) ;; *) PATH="$BIN_DIR:$PATH"; export PATH ;; esac

    install_apt
    install_shims

    # A single tool failing (transient network, asset rename) should not abort
    # the whole bootstrap; report and carry on.
    local failed=()
    local fn
    for fn in install_nvim install_eza install_delta install_fzf install_gh \
              install_zoxide install_starship; do
        "$fn" || failed+=("${fn#install_}")
    done

    if [ ${#failed[@]} -gt 0 ]; then
        warn "failed to install: ${failed[*]} (re-run to retry)"
    fi
}

main "$@"
