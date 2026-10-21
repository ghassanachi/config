#!/usr/bin/env bash
# Shared helpers for the devbox scripts. Sourced, not executed.

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _c_blue=$'\033[34m'; _c_green=$'\033[32m'; _c_yellow=$'\033[33m'
    _c_red=$'\033[31m';  _c_dim=$'\033[2m';    _c_off=$'\033[0m'
else
    _c_blue=; _c_green=; _c_yellow=; _c_red=; _c_dim=; _c_off=
fi

step() { printf '%s==>%s %s\n' "$_c_blue"   "$_c_off" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$_c_green" "$_c_off" "$*"; }
skip() { printf '%s  --%s %s\n' "$_c_dim"   "$_c_off" "$*"; }
warn() { printf '%s  !!%s %s\n' "$_c_yellow" "$_c_off" "$*" >&2; }
die()  { printf '%serror%s %s\n' "$_c_red"  "$_c_off" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OPT_DIR="${OPT_DIR:-$HOME/.local/opt}"

# ---------------------------------------------------------------------------
# Release helpers
# ---------------------------------------------------------------------------

# Resolve the latest tag for a GitHub repo.
#
# Deliberately uses the /releases/latest redirect rather than the REST API: the
# unauthenticated API allows only 60 requests/hour per IP, and a pool of beams
# shares egress. The redirect is unlimited. The Location header looks like
#   .../releases/tag/v0.23.5
# so the tag is simply its last path segment.
gh_latest_tag() {
    local repo="$1" tag
    tag=$(curl -fsSI --max-time 20 "https://github.com/$repo/releases/latest" \
        | awk 'tolower($0) ~ /^location:/ { gsub(/\r/, ""); n = split($0, p, "/"); print p[n] }')
    [ -n "$tag" ] || return 1
    printf '%s\n' "$tag"
}

# Download a tarball and install named binaries from it into BIN_DIR.
#
#   install_from_tarball <url> <binary-name>...
#
# Binaries are located by name anywhere in the archive rather than by a fixed
# path, because every project lays its tarball out differently: eza ships ./eza
# at the root, delta nests it under delta-<ver>-<triple>/, and gh puts it in
# gh_<ver>_linux_amd64/bin/. Searching by name means no per-tool path guessing.
#
# Extraction happens in a scratch dir that is always cleaned up, so a failed
# download can never leave a half-installed binary behind.
install_from_tarball() {
    local url="$1"; shift
    local tmp name found
    tmp=$(mktemp -d) || return 1
    # shellcheck disable=SC2064  # expand $tmp now, not at trap time
    trap "rm -rf '$tmp'" RETURN

    curl -fsSL --max-time 180 "$url" | tar -xz -C "$tmp" || {
        warn "download or extract failed: $url"
        return 1
    }

    mkdir -p "$BIN_DIR"
    for name in "$@"; do
        found=$(find "$tmp" -type f -name "$name" -perm -u+x -print -quit 2>/dev/null)
        [ -n "$found" ] || { warn "binary '$name' not found in archive"; return 1; }
        install -m 0755 "$found" "$BIN_DIR/$name" || return 1
    done
}

# Print the version of an installed tool, normalised to a bare number.
# Returns non-zero when the tool is absent.
tool_version() {
    local cmd="$1"
    have "$cmd" || return 1
    "$cmd" --version 2>/dev/null | head -1 \
        | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# True when the installed tool already matches the wanted tag (leading "v" is
# ignored, so "v0.23.5" and "0.23.5" compare equal).
version_matches() {
    local cmd="$1" want="${2#v}" got
    got=$(tool_version "$cmd") || return 1
    [ -n "$got" ] && [ "$got" = "$want" ]
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------

# link <target> <link-name>
#
# Uses -n so that re-running against an existing symlink-to-a-directory
# replaces the link itself rather than creating a link *inside* the directory
# it points at (the classic `ln -sf` dotfiles footgun).
link() {
    local target="$1" name="$2"
    [ -e "$target" ] || { warn "missing, not linked: $target"; return 0; }
    mkdir -p "$(dirname "$name")"

    if [ -L "$name" ] && [ "$(readlink "$name")" = "$target" ]; then
        skip "${name/#$HOME/~}"
        return 0
    fi
    # A real file/dir in the way is backed up rather than silently destroyed.
    if [ -e "$name" ] && [ ! -L "$name" ]; then
        mv "$name" "$name.devbox-backup.$(date +%s)"
        warn "backed up existing ${name/#$HOME/~}"
    fi
    ln -sfn "$target" "$name"
    ok "${name/#$HOME/~} -> ${target/#$HOME/~}"
}
