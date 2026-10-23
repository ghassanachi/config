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

# Install a whole archive as a tree under OPT_DIR, then symlink binaries out of
# it into BIN_DIR.
#
#   install_opt_tree <url> <dir-name> <strip-components> <rel-bin-path>...
#
# Needed instead of install_from_tarball whenever a binary cannot be lifted out
# of the archive on its own because it depends on siblings in the tree: go needs
# its GOROOT (lib/, pkg/, src/), node needs lib/node_modules, protoc needs
# include/ for the well-known types, and nvim needs runtime/. Each resolves
# those relative to its *own* real path, which is why a symlink into the tree
# works while a copied-out binary does not.
#
# The archive is downloaded to a file and then extracted, rather than piped
# straight into tar, so that the same call handles both .tar.gz (go, protoc) and
# .tar.xz (node). tar only auto-detects compression on a *seekable* input: fed
# from a pipe it gives up with "Archive is compressed. Use -z option" instead.
# The cost is the tarball briefly on disk (~80MB for Go), which beats either a
# per-caller compression flag or a second helper.
#
# .tar.xz additionally needs the `xz` binary present for tar to shell out to.
#
# TODO: install_nvim in tools.sh predates this and still hand-rolls the same
# steps; it could be folded onto this helper next time it needs touching.
install_opt_tree() {
    local url="$1" name="$2" strip="$3"; shift 3
    local tmp rel
    tmp=$(mktemp -d) || return 1

    # tar shells out to `xz` for .tar.xz and reports only "Child returned status
    # 2" when it is missing, which is a miserable thing to debug. Say it plainly.
    case "$url" in
        *.tar.xz|*.txz)
            have xz || {
                warn "xz is required for $url (apt install xz-utils)"
                rm -rf "$tmp"
                return 1
            }
            ;;
    esac

    # A longer timeout than install_from_tarball: these are whole toolchains
    # (the Go tarball alone is ~80MB) rather than single static binaries.
    mkdir -p "$tmp/x"
    if curl -fsSL --max-time 600 "$url" -o "$tmp/archive"; then
        tar -xf "$tmp/archive" -C "$tmp/x" --strip-components="$strip" || {
            warn "extract failed: $url"
            rm -rf "$tmp"
            return 1
        }
    else
        warn "download failed: $url"
        rm -rf "$tmp"
        return 1
    fi
    rm -f "$tmp/archive"

    # Replace rather than merge: a stale tree from a previous version would
    # otherwise leave orphaned files that shadow the new ones.
    # ${var:?} so a caller that somehow passed an empty OPT_DIR or name cannot
    # turn this into `rm -rf /`.
    mkdir -p "$OPT_DIR"
    rm -rf "${OPT_DIR:?}/${name:?}"
    mv "$tmp/x" "$OPT_DIR/$name" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"

    mkdir -p "$BIN_DIR"
    for rel in "$@"; do
        [ -e "$OPT_DIR/$name/$rel" ] || { warn "'$rel' not found in $name archive"; return 1; }
        ln -sfn "$OPT_DIR/$name/$rel" "$BIN_DIR/$(basename "$rel")" || return 1
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
