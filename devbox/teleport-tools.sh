#!/usr/bin/env bash
# Install the toolchain needed to build, lint and test the Teleport repos --
# gravitational/core and gravitational/access-graph -- on a dev box.
#
#   teleport-tools                 # full (default)
#   teleport-tools backend
#   teleport-tools frontend
#   teleport-tools --dry-run       # resolve versions, install nothing
#
# Deliberately NOT part of devbox/tools.sh. That script is the baseline every
# beam wants (editor, shell, git) and finishes in well under a minute. This one
# pulls Go, Rust and Node -- roughly 1.5GB on disk and several minutes of
# wall clock -- which is pure waste on the beams used only to read logs or
# restructure a PR stack. So it ships on PATH always and runs only when asked,
# either directly or via `install.sh --full`.
#
# Safe to re-run: every step is skipped when the wanted version is already
# installed.

set -euo pipefail

# This is the one devbox script that normally runs through a symlink: link.sh
# points $BIN_DIR/teleport-tools at it so the command is always on PATH. That
# makes ${BASH_SOURCE[0]} the *link* ($HOME/.local/bin/teleport-tools), not
# this file, so taking its dirname directly would look for lib.sh next to the
# link and die with "No such file or directory". The link has to be resolved
# before lib.sh can be found -- which is also why this cannot be a lib.sh
# helper.
#
# Hand-rolled rather than `readlink -f` / `realpath`: this repo is shared with
# macOS, whose BSD userland has neither until Monterey 12.3. The loop handles a
# link that points at another link, and the `case` re-anchors a relative link
# target, which readlink reports relative to the directory holding the link.
_tt_src="${BASH_SOURCE[0]}"
while [ -L "$_tt_src" ]; do
    _tt_dir="$(cd -P "$(dirname "$_tt_src")" && pwd)"
    _tt_src="$(readlink "$_tt_src")"
    case "$_tt_src" in
        /*) ;;
         *) _tt_src="$_tt_dir/$_tt_src" ;;
    esac
done
DEVBOX_DIR="$(cd -P "$(dirname "$_tt_src")" && pwd)"
unset _tt_src _tt_dir

# shellcheck source=./lib.sh
. "$DEVBOX_DIR/lib.sh"

# ---------------------------------------------------------------------------
# Version pins
# ---------------------------------------------------------------------------
#
# These are only the *offline fallback*. The real source of truth is the repo
# itself, resolved at runtime by resolve_versions() below, because these pins
# move every few weeks and a stale Go minor is exactly the sort of thing that
# produces a confusing build failure an hour into a debugging session.
#
# Values current as of 2026-10-23, read from gravitational/core@master.
TP_GO_VERSION="${TP_GO_VERSION:-1.27.3}"
TP_GOLANGCI_VERSION="${TP_GOLANGCI_VERSION:-2.14.0}"
TP_NODE_VERSION="${TP_NODE_VERSION:-24.22.1}"
TP_PNPM_VERSION="${TP_PNPM_VERSION:-11.28.3}"
TP_RUST_VERSION="${TP_RUST_VERSION:-1.94.0}"
TP_PROTOC_VERSION="${TP_PROTOC_VERSION:-26.1}"
TP_WASM_OPT_VERSION="${TP_WASM_OPT_VERSION:-0.116.1}"
TP_HELM_UNITTEST_VERSION="${TP_HELM_UNITTEST_VERSION:-1.0.3}"

# Helm is pinned rather than tracked, and that is load-bearing: the buildbox
# that CI runs chart tests in installs helm v3.12.2, while helm/helm's latest
# release is now 4.x. Helm 4 is a different major with breaking template
# changes, so installing "latest" renders the charts differently from CI and
# turns `make test-helm` into a pile of spurious snapshot diffs. Parsed from
# build.assets/Dockerfile when reachable.
TP_HELM_VERSION="${TP_HELM_VERSION:-3.12.2}"

# The WASM target is the only cross-compilation target installed. core's
# rust-toolchain.toml also lists x86_64-pc-windows-gnu, which is skipped on
# purpose: it is only needed to cross-build the Windows tsh, which is a release
# concern rather than a local build/lint/test one.
RUST_WASM_TARGET="wasm32-unknown-unknown"

PROFILE="full"
DRY_RUN=0
FROM_REPO=""
VERSION_SOURCE="built-in pins"

usage() {
    cat <<'EOF'
Usage: teleport-tools [profile] [options]

Profiles:
  full        Everything below, plus helm + the helm-unittest plugin. (default)
  backend     Go, golangci-lint, buf, protoc, Rust (clippy/rustfmt), and the
              C toolchain that cgo builds need.
  frontend    Node, pnpm (via corepack), Rust + the wasm32 target, wasm-opt.

Options:
  --dry-run        Print the resolved tool versions and exit.
  --from-repo DIR  Read versions from a local core checkout instead of GitHub.
  -h, --help       Show this help.

Version resolution, in order of preference:
  1. --from-repo DIR          a local gravitational/core checkout
  2. gravitational/core       via gh, when `gh auth status` succeeds
  3. gravitational/teleport   public mirror; LAGS core by a release or two
  4. built-in pins            offline fallback

Every version can also be forced with an environment variable:
  TP_GO_VERSION, TP_GOLANGCI_VERSION, TP_NODE_VERSION, TP_PNPM_VERSION,
  TP_RUST_VERSION, TP_PROTOC_VERSION, TP_WASM_OPT_VERSION,
  TP_HELM_VERSION, TP_HELM_UNITTEST_VERSION
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        full|backend|frontend) PROFILE="$1" ;;
        --dry-run)   DRY_RUN=1 ;;
        --from-repo) FROM_REPO="${2:?--from-repo needs a path}"; shift ;;
        -h|--help)   usage; exit 0 ;;
        *) printf 'unknown argument: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Version resolution
# ---------------------------------------------------------------------------

# Print the first semver-looking token in a command's first output line.
#
# Needed because no two of these tools agree on how to be asked: `go version`
# takes no flag at all (`go --version` is an error), golangci-lint answers
# "golangci-lint has version 2.14.0 built with ...", protoc says "libprotoc
# 26.1", and helm needs `version --short`. Grepping a version out of whatever
# comes back is shorter than a per-tool table, and the only cost is that a tool
# printing an unrelated number first would be misread -- none of these do.
probe_version() {
    local cmd="$1"; shift
    have "$cmd" || return 1
    "$cmd" "$@" 2>/dev/null | head -1 \
        | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# Read a `NAME ?= value` assignment out of a Makefile fragment.
mk_var() {
    awk -v key="$2" '$1 == key && $2 == "?=" { print $3; exit }' "$1" 2>/dev/null
}

# Populate $1 with the four files that carry the version pins. Returns non-zero
# when no source could be reached, leaving the built-in pins in place.
fetch_version_files() {
    local dir="$1"

    # 1. A local checkout is both the fastest and the most accurate: it is the
    #    tree you are actually about to build.
    if [ -n "$FROM_REPO" ]; then
        [ -d "$FROM_REPO" ] || die "--from-repo: no such directory: $FROM_REPO"
        cp "$FROM_REPO/build.assets/versions.mk"          "$dir/" 2>/dev/null || true
        cp "$FROM_REPO/rust-toolchain.toml"               "$dir/" 2>/dev/null || true
        cp "$FROM_REPO/package.json"                      "$dir/" 2>/dev/null || true
        cp "$FROM_REPO/build.assets/helm-unittest.version" "$dir/" 2>/dev/null || true
        cp "$FROM_REPO/build.assets/Dockerfile"            "$dir/" 2>/dev/null || true
        [ -f "$dir/versions.mk" ] || die "--from-repo: $FROM_REPO does not look like a core checkout"
        VERSION_SOURCE="local checkout $FROM_REPO"
        return 0
    fi

    # 2. gravitational/core itself. Private, so this needs a gh login (ghlogin)
    #    -- but it is the only remote source that is actually authoritative.
    if have gh && gh auth status >/dev/null 2>&1; then
        local p ok=1
        for p in build.assets/versions.mk rust-toolchain.toml package.json \
                 build.assets/helm-unittest.version build.assets/Dockerfile; do
            gh api "repos/gravitational/core/contents/$p" --jq '.content' 2>/dev/null \
                | base64 -d > "$dir/$(basename "$p")" 2>/dev/null \
                || ok=0
        done
        if [ "$ok" = "1" ] && [ -s "$dir/versions.mk" ]; then
            VERSION_SOURCE="gravitational/core (via gh)"
            return 0
        fi
        warn "could not read gravitational/core; falling back to the public mirror"
    fi

    # 3. The public OSS repo. Shares build.assets with core but trails it, so
    #    this can hand back a Go or Node minor that core has already moved off.
    #    Better than nothing, worth flagging loudly in the summary.
    local base="https://raw.githubusercontent.com/gravitational/teleport/master"
    local p
    for p in build.assets/versions.mk rust-toolchain.toml package.json \
             build.assets/helm-unittest.version; do
        curl -fsSL --max-time 20 "$base/$p" -o "$dir/$(basename "$p")" 2>/dev/null || true
    done
    if [ -s "$dir/versions.mk" ]; then
        VERSION_SOURCE="public gravitational/teleport (may lag core)"
        return 0
    fi

    return 1
}

# Overwrite a pin only when the resolved value is non-empty, so a partially
# fetched or reformatted upstream file degrades to the fallback for that one
# tool rather than blanking it.
set_if() {
    # A nameref, so the caller passes the variable *name* and this assigns
    # through to it. shellcheck cannot see through `local -n`, hence SC2034.
    local -n target="$1"
    # shellcheck disable=SC2034  # assigns through the nameref above
    [ -n "${2:-}" ] && target="$2"
    return 0
}

resolve_versions() {
    local dir
    dir=$(mktemp -d) || return 0
    # shellcheck disable=SC2064  # expand $dir now, not at trap time
    trap "rm -rf '$dir'" RETURN

    fetch_version_files "$dir" || { warn "no version source reachable; using built-in pins"; return 0; }

    # GOLANG_VERSION is written as "go1.27.3"; everything downstream wants the
    # bare number, and the leading "go" comes back in the tarball URL.
    set_if TP_GO_VERSION       "$(mk_var "$dir/versions.mk" GOLANG_VERSION | sed 's/^go//')"
    set_if TP_GOLANGCI_VERSION "$(mk_var "$dir/versions.mk" GOLANGCI_LINT_VERSION | sed 's/^v//')"
    set_if TP_NODE_VERSION     "$(mk_var "$dir/versions.mk" NODE_VERSION)"
    set_if TP_PROTOC_VERSION   "$(mk_var "$dir/versions.mk" PROTOC_VERSION)"
    set_if TP_WASM_OPT_VERSION "$(mk_var "$dir/versions.mk" WASM_OPT_VERSION)"

    set_if TP_RUST_VERSION "$(awk '$1 == "channel" && $2 == "=" { gsub(/"/, "", $3); print $3; exit }' \
        "$dir/rust-toolchain.toml" 2>/dev/null)"

    # package.json pins pnpm as "pnpm@11.28.3+sha512.<hash>". Parsed with sed
    # rather than jq so this still resolves on a box where the apt step has not
    # run yet.
    set_if TP_PNPM_VERSION "$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"pnpm@\([0-9][^+"]*\).*/\1/p' \
        "$dir/package.json" 2>/dev/null | head -1)"

    set_if TP_HELM_UNITTEST_VERSION "$(sed 's/^v//' "$dir/helm-unittest.version" 2>/dev/null | head -1)"

    # The buildbox installs helm from a get.helm.sh URL with the version inline:
    #   curl -fsSL https://get.helm.sh/helm-v3.12.2-$(go env GOOS)-...
    set_if TP_HELM_VERSION "$(grep -oE 'helm-v[0-9]+\.[0-9]+\.[0-9]+' "$dir/Dockerfile" 2>/dev/null \
        | head -1 | sed 's/^helm-v//')"
}

print_versions() {
    printf '\nResolved from: %s\n\n' "$VERSION_SOURCE"
    printf '  %-16s %s\n' \
        go              "$TP_GO_VERSION" \
        golangci-lint   "$TP_GOLANGCI_VERSION" \
        node            "$TP_NODE_VERSION" \
        pnpm            "$TP_PNPM_VERSION" \
        rust            "$TP_RUST_VERSION" \
        protoc          "$TP_PROTOC_VERSION" \
        wasm-opt        "$TP_WASM_OPT_VERSION" \
        helm            "$TP_HELM_VERSION" \
        helm-unittest   "$TP_HELM_UNITTEST_VERSION" \
        buf             "latest release"
    printf '\n'
}

# ---------------------------------------------------------------------------
# apt
# ---------------------------------------------------------------------------
# build-essential carries make and gcc, and is NOT guaranteed to be present:
# devbox/tools.sh installs it only under --full, and a stock beam has neither.
# Every Teleport target starts with make, so it is in the base set for all
# profiles rather than only the backend one.
#
# pkg-config       common.mk probes it (pkgconf or pkg-config) for cgo flags
# xz-utils         the Node tarball is .tar.xz; tar shells out to xz
# libpcsclite-dev  cgo builds under the `piv` tag (hardware key support)
# (shellcheck is also in the list -- `make lint-sh` runs it over every *.sh)

apt_base=(build-essential pkg-config shellcheck xz-utils)
apt_backend=(libpcsclite-dev)

install_apt() {
    local want=("${apt_base[@]}")
    case "$PROFILE" in
        backend|full) want+=("${apt_backend[@]}") ;;
    esac

    local missing=() pkg
    for pkg in "${want[@]}"; do
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

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------
# Installed as a tree under OPT_DIR because the `go` binary locates GOROOT
# relative to its own real path. The repo-provided tools (buf, gotestsum, gci,
# goda) are *not* installed here: core's common.mk resolves them through
# `go tool -n`, so a correct Go is all they need.

install_go() {
    if [ "$(probe_version go version)" = "$TP_GO_VERSION" ]; then
        skip "go $TP_GO_VERSION"
        return 0
    fi
    step "go $TP_GO_VERSION"
    install_opt_tree \
        "https://go.dev/dl/go${TP_GO_VERSION}.linux-amd64.tar.gz" \
        go 1 bin/go bin/gofmt \
        && ok "go $TP_GO_VERSION -> $BIN_DIR/go"
}

install_golangci_lint() {
    if [ "$(probe_version golangci-lint --version)" = "$TP_GOLANGCI_VERSION" ]; then
        skip "golangci-lint $TP_GOLANGCI_VERSION"
        return 0
    fi
    step "golangci-lint $TP_GOLANGCI_VERSION"
    install_from_tarball \
        "https://github.com/golangci/golangci-lint/releases/download/v${TP_GOLANGCI_VERSION}/golangci-lint-${TP_GOLANGCI_VERSION}-linux-amd64.tar.gz" \
        golangci-lint && ok "golangci-lint $TP_GOLANGCI_VERSION"
}

# buf is needed on PATH for access-graph, whose Makefile calls it directly
# (`buf generate --template=buf-go.gen.yaml`). core does not need this copy --
# it pins its own through build.assets/tools/buf -- and neither repo pins a CLI
# version for external use, so this tracks the latest release.
install_buf() {
    local tag
    tag=$(gh_latest_tag bufbuild/buf) || { warn "could not resolve buf version"; return 1; }
    version_matches buf "$tag" && { skip "buf $tag"; return 0; }
    step "buf $tag"
    install_from_tarball \
        "https://github.com/bufbuild/buf/releases/download/$tag/buf-Linux-x86_64.tar.gz" \
        buf && ok "buf $tag"
}

# protoc needs its include/ tree (the well-known types) alongside the binary,
# and ships a zip rather than a tarball, so it gets its own routine instead of
# install_opt_tree.
install_protoc() {
    if [ "$(probe_version protoc --version)" = "$TP_PROTOC_VERSION" ]; then
        skip "protoc $TP_PROTOC_VERSION"
        return 0
    fi
    have unzip || { warn "unzip absent; skipping protoc"; return 1; }

    step "protoc $TP_PROTOC_VERSION"
    local tmp
    tmp=$(mktemp -d) || return 1
    # shellcheck disable=SC2064  # expand $tmp now, not at trap time
    trap "rm -rf '$tmp'" RETURN

    curl -fsSL --max-time 180 \
        "https://github.com/protocolbuffers/protobuf/releases/download/v${TP_PROTOC_VERSION}/protoc-${TP_PROTOC_VERSION}-linux-x86_64.zip" \
        -o "$tmp/protoc.zip" || { warn "protoc download failed"; return 1; }
    unzip -q -o "$tmp/protoc.zip" -d "$tmp/protoc" || { warn "protoc unzip failed"; return 1; }

    mkdir -p "$OPT_DIR"
    rm -rf "${OPT_DIR:?}/protoc"
    mv "$tmp/protoc" "$OPT_DIR/protoc"
    mkdir -p "$BIN_DIR"
    ln -sfn "$OPT_DIR/protoc/bin/protoc" "$BIN_DIR/protoc"
    ok "protoc $TP_PROTOC_VERSION"
}

# ---------------------------------------------------------------------------
# Node / pnpm
# ---------------------------------------------------------------------------
# A beam ships some Node already (24.13.0 at the time of writing) but not the
# pinned one, and `engines.node` only constrains the major -- so the stock one
# usually "works" right up until it does not. Installing the pin is cheap
# certainty. BIN_DIR precedes the system path in devbox/bashrc, so these
# symlinks win.
#
# pnpm is deliberately NOT installed as a fixed version. Both repos set
# `packageManager` in package.json (core is on 11.28.3, access-graph on 11.20.0)
# and corepack's shim reads that field per project, so one shim serves both and
# neither drifts.

install_node() {
    if [ "$(probe_version node --version)" = "$TP_NODE_VERSION" ]; then
        skip "node $TP_NODE_VERSION"
    else
        step "node $TP_NODE_VERSION"
        install_opt_tree \
            "https://nodejs.org/dist/v${TP_NODE_VERSION}/node-v${TP_NODE_VERSION}-linux-x64.tar.xz" \
            node 1 bin/node bin/npm bin/npx bin/corepack \
            || return 1
        ok "node $TP_NODE_VERSION -> $BIN_DIR/node"
    fi

    have corepack || { warn "corepack absent; cannot wire pnpm"; return 1; }

    # Shims land directly in BIN_DIR rather than in the Node tree's bin/, which
    # keeps them on PATH without a second PATH entry. The shim corepack writes
    # is a *relative* symlink into the Node tree, and install_opt_tree recreates
    # that tree at the same path, so a Node upgrade does not strand it.
    corepack enable --install-directory "$BIN_DIR" pnpm >/dev/null 2>&1 \
        || { warn "corepack enable failed"; return 1; }
    ok "pnpm shim -> $BIN_DIR/pnpm (version per repo packageManager)"

    # Pre-fetch the version core currently pins so the first `pnpm install` in
    # a repo is not also a pnpm download. Best-effort: a failure here costs a
    # few seconds later, nothing more.
    if corepack install --global "pnpm@$TP_PNPM_VERSION" >/dev/null 2>&1; then
        ok "pnpm $TP_PNPM_VERSION pre-fetched"
    else
        skip "pnpm $TP_PNPM_VERSION not pre-fetched (downloads on first use)"
    fi
}

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------
# Rust is in BOTH profiles, which is worth saying out loud: the backend needs
# it for rdp-client and fdpass-teleport (and for `make lint-rust` / `test-rust`,
# which silently become no-ops when cargo is missing -- a green build that
# tested nothing), while the frontend needs it to compile the ironrdp WASM
# module used by desktop access.
#
# rustup rather than a pinned tarball, because both repos carry a
# rust-toolchain.toml and rustup honours it per-directory. That makes the
# version installed here a sensible default rather than a constraint, and means
# a toolchain bump in the repo just works.

install_rust() {
    if have rustup; then
        skip "rustup present"
    else
        step "rustup + rust $TP_RUST_VERSION"
        # --no-modify-path: devbox/bashrc already prepends ~/.cargo/bin, and
        # letting rustup-init append its own block to ~/.profile would duplicate
        # that and fight the marker-block scheme in link.sh.
        curl -fsSL --max-time 300 https://sh.rustup.rs \
            | sh -s -- -y --no-modify-path --profile minimal \
                --default-toolchain "$TP_RUST_VERSION" \
                --component clippy --component rustfmt >/dev/null 2>&1 \
            || { warn "rustup install failed"; return 1; }
        ok "rustup + rust $TP_RUST_VERSION"
    fi

    # Make cargo/rustup visible for the rest of this run even though the login
    # shell has not been reloaded.
    case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH"; export PATH ;; esac
    have rustup || { warn "rustup not on PATH after install"; return 1; }

    # Idempotent, and also covers the case where rustup pre-existed with a
    # different default or without the lint components.
    rustup toolchain install "$TP_RUST_VERSION" \
        --component clippy --component rustfmt --profile minimal >/dev/null 2>&1 \
        || { warn "could not install rust $TP_RUST_VERSION"; return 1; }
    rustup default "$TP_RUST_VERSION" >/dev/null 2>&1 || true
    ok "rust $TP_RUST_VERSION (clippy, rustfmt)"
}

install_rust_wasm_target() {
    have rustup || { warn "rustup absent; skipping wasm target"; return 1; }
    rustup target add --toolchain "$TP_RUST_VERSION" "$RUST_WASM_TARGET" >/dev/null 2>&1 \
        || { warn "could not add $RUST_WASM_TARGET"; return 1; }
    ok "rust target $RUST_WASM_TARGET"
}

# `make build-wasm` runs wasm-opt over the compiled ironrdp module -- the only
# target in core that needs it, so this step matters for Desktop Access work and
# for nothing else.
#
# core's own ensure-wasm-opt target does `cargo install wasm-opt@<version>`,
# which builds the whole of binaryen's C++ from source through the crate's cc
# build script: ten-plus minutes on a beam, and it used to be by far the longest
# step in this script. The crate is only a thin wrapper, and upstream binaryen
# ships the identical tool as a prebuilt static binary per release, so that is
# fetched instead -- about a minute, and the result is byte-for-byte the same
# optimiser CI runs.
#
# The two version schemes have to be bridged to do that: the crate numbers
# releases 0.<binaryen-major>.<crate-patch> (0.116.1), while the release tag and
# the binary itself use binaryen's own major alone (version_116). Only the major
# identifies the upstream release, so the crate patch is dropped.
#
# The archive is ~80MB because it carries every binaryen tool plus a static
# libbinaryen; only wasm-opt is lifted out of it (14MB, statically linked, no
# sibling files needed at runtime). x86_64 is hardcoded, consistent with the Go
# and Node steps above.
#
# The version check is only "is it present", unchanged from the cargo era: good
# enough because binaryen majors do not change wasm-opt's behaviour on our
# input, and a mismatched-but-working wasm-opt is not worth a 10-minute rebuild.
#
# Not installed: wasm-bindgen-cli. core reads its version out of Cargo.lock and
# installs it itself in ensure-wasm-deps, which cannot be done without the
# checkout in hand.
install_wasm_opt() {
    if have wasm-opt; then
        skip "wasm-opt present"
        return 0
    fi

    local major="$TP_WASM_OPT_VERSION"
    case "$major" in
        0.*) major=$(printf '%s\n' "$major" | cut -d. -f2) ;;
          *) major=$(printf '%s\n' "$major" | cut -d. -f1) ;;
    esac

    step "wasm-opt (binaryen version_$major, prebuilt)"
    if install_from_tarball \
        "https://github.com/WebAssembly/binaryen/releases/download/version_${major}/binaryen-version_${major}-x86_64-linux.tar.gz" \
        wasm-opt
    then
        ok "wasm-opt (binaryen version_$major)"
    else
        warn "wasm-opt install failed; build it from source with: cargo install --locked wasm-opt@$TP_WASM_OPT_VERSION"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Helm (full profile only)
# ---------------------------------------------------------------------------
# Only `make test-helm` needs these, so they sit in the full profile rather
# than the backend one.

install_helm() {
    if [ "$(probe_version helm version --short)" = "$TP_HELM_VERSION" ]; then
        skip "helm $TP_HELM_VERSION"
        return 0
    fi
    step "helm $TP_HELM_VERSION"
    install_from_tarball "https://get.helm.sh/helm-v${TP_HELM_VERSION}-linux-amd64.tar.gz" helm \
        && ok "helm $TP_HELM_VERSION"
}

# helm-unittest ships no plugin signature, so Helm's own signature verification
# cannot cover it. core's Makefile works around that by checksumming the release
# archive against build.assets/helm-unittest.sha256 before unpacking, and this
# mirrors that: the checksum file is fetched alongside, and a mismatch aborts.
# When the checksum file cannot be reached the install still proceeds, but says
# so -- an unverified plugin is worth a line of output.
install_helm_unittest() {
    have helm || { warn "helm absent; skipping helm-unittest"; return 1; }

    local installed
    installed=$(helm plugin list 2>/dev/null | awk '$1 == "unittest" { print $2; exit }')
    if [ "$installed" = "$TP_HELM_UNITTEST_VERSION" ]; then
        skip "helm-unittest $TP_HELM_UNITTEST_VERSION"
        return 0
    fi

    step "helm-unittest $TP_HELM_UNITTEST_VERSION"
    local archive="helm-unittest-linux-amd64-${TP_HELM_UNITTEST_VERSION}.tgz"
    local tmp
    tmp=$(mktemp -d) || return 1
    # shellcheck disable=SC2064  # expand $tmp now, not at trap time
    trap "rm -rf '$tmp'" RETURN

    curl -fsSL --max-time 180 \
        "https://github.com/helm-unittest/helm-unittest/releases/download/v${TP_HELM_UNITTEST_VERSION}/${archive}" \
        -o "$tmp/$archive" || { warn "helm-unittest download failed"; return 1; }

    if curl -fsSL --max-time 20 \
        "https://raw.githubusercontent.com/gravitational/teleport/master/build.assets/helm-unittest.sha256" \
        -o "$tmp/sums" 2>/dev/null && grep -q "[[:space:]]${archive}\$" "$tmp/sums"; then
        ( cd "$tmp" && grep "[[:space:]]${archive}\$" sums | sha256sum -c - >/dev/null 2>&1 ) \
            || { warn "helm-unittest checksum MISMATCH; not installing"; return 1; }
        ok "helm-unittest archive checksum verified"
    else
        warn "no checksum available for $archive; installing unverified"
    fi

    local plugin_dir
    plugin_dir="$(helm env HELM_PLUGINS 2>/dev/null | tr -d '"')/helm-unittest"
    [ -n "${plugin_dir%/helm-unittest}" ] || { warn "could not resolve HELM_PLUGINS"; return 1; }
    rm -rf "$plugin_dir"
    mkdir -p "$plugin_dir"
    tar -xz -f "$tmp/$archive" -C "$plugin_dir" || { warn "helm-unittest unpack failed"; return 1; }
    ok "helm-unittest $TP_HELM_UNITTEST_VERSION"
}

# ---------------------------------------------------------------------------

# Which routines each profile runs, in order. Rust deliberately appears in both
# backend and frontend; the steps are idempotent, so `full` running it once is
# all that is needed.
profile_steps() {
    case "$1" in
        backend)
            printf '%s\n' install_go install_golangci_lint install_buf \
                          install_protoc install_rust
            ;;
        frontend)
            printf '%s\n' install_node install_rust install_rust_wasm_target \
                          install_wasm_opt
            ;;
        full)
            # wasm-opt last on purpose: it is the biggest download and the
            # narrowest in use (only `make build-wasm`), so an interrupted full
            # run still leaves everything else installed.
            printf '%s\n' install_go install_golangci_lint install_buf \
                          install_protoc install_node install_rust \
                          install_rust_wasm_target \
                          install_helm install_helm_unittest \
                          install_wasm_opt
            ;;
    esac
}

main() {
    have curl || die "curl is required"

    # PATH first, before anything probes for a tool. This has to precede
    # resolve_versions: gh lives in BIN_DIR, and if BIN_DIR is not yet on PATH
    # (invoking this by absolute path from a non-login shell) then `have gh`
    # fails, version resolution silently drops to the public mirror, and you
    # get a Go minor that core has already moved off. ~/go/bin matters because
    # `go install` lands there.
    local d
    for d in "$BIN_DIR" "$HOME/.cargo/bin" "$HOME/go/bin"; do
        case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
    done
    export PATH

    resolve_versions

    if [ "$DRY_RUN" = "1" ]; then
        printf 'profile: %s\n' "$PROFILE"
        print_versions
        printf 'would run:\n'
        profile_steps "$PROFILE" | sed 's/^install_/  /'
        return 0
    fi

    have sudo || die "sudo is required for the apt step"

    printf '==> teleport-tools: %s profile\n' "$PROFILE"
    print_versions

    mkdir -p "$BIN_DIR" "$OPT_DIR"

    install_apt

    # One tool failing (transient network, an asset rename upstream) should not
    # abort the rest -- same contract as devbox/tools.sh.
    local failed=() fn
    while read -r fn; do
        "$fn" || failed+=("${fn#install_}")
    done < <(profile_steps "$PROFILE")

    if [ ${#failed[@]} -gt 0 ]; then
        warn "failed to install: ${failed[*]} (re-run to retry)"
    fi

    cat <<EOF

Done ($PROFILE). Open a new shell, or run: exec bash -l

Note: docker is not available on a beam, so access-graph's \`make postgres-start\`
and the docker-compose dev stack cannot run here. Go/pnpm builds, lint and unit
tests all work.
EOF
}

main "$@"
