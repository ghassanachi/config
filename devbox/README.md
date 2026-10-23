# devbox

Bootstrap for ephemeral Linux dev boxes (Teleport beams). One command turns a
bare Debian box into the usual environment: tmux, nvim, git/gh, and the shell
muscle memory.

```sh
curl -fsSL https://raw.githubusercontent.com/ghassanachi/config/master/devbox/install.sh | bash
```

Re-running is safe — every step is skipped when already satisfied.

## Options

```sh
# everything: full nvim stack + build-essential + the Teleport toolchain
curl -fsSL .../devbox/install.sh | bash -s -- --full

# the Teleport toolchain without the nvim stack
... | bash -s -- --teleport
... | bash -s -- --teleport=backend

# link configs without installing tools, or vice versa
... | bash -s -- --no-tools
... | bash -s -- --no-link

# install from a branch, or clone somewhere else
... | bash -s -- --ref my-branch --dir ~/src/config
```

Environment overrides: `DEVBOX_REPO`, `DEVBOX_REF`, `CONFIG_DIR`, `NVIM_FULL`,
`BIN_DIR`, `DEVBOX_TELEPORT`.

## What it does

1. **Preflight** — requires Debian/Ubuntu, x86_64, a non-root user, and curl.
2. **Clone** `~/.config/dotfiles`, shallow + blobless + sparse. Only the paths a
   dev box needs are checked out: **640KB cloned instead of a full clone**.
3. **Tools** — see the table below. Everything that is not an apt package lands
   in `~/.local/bin`, so only the apt step needs sudo.
4. **Link** — symlinks into `$HOME`, appends a marker block to `~/.bashrc`, and
   creates `~/.vim/undodir` (which `set.lua` requires for `undofile`).
5. **Teleport toolchain** — only with `--full` / `--teleport`. See below.

`~/.gitconfig` is the one config that is **included rather than symlinked**:

```ini
[include]
	path = ~/.config/dotfiles/devbox/gitconfig
```

`gh auth setup-git` writes a credential helper into the global git config. Were
`~/.gitconfig` a symlink into the repo, that machine-local credential wiring
would be written into the tracked file and then discarded on the next re-link,
silently breaking authentication. The include keeps shared settings versioned
while `~/.gitconfig` stays a real, machine-local file.

## Tooling: apt vs upstream

apt wherever "old but works" is true, upstream where the Debian version is
absent or stale enough to break how the config actually uses the tool.

| apt | why |
|---|---|
| `trash-cli` | ships `/usr/bin/trash` exactly, which the `rm` alias wants |
| `fd-find` | binary is `fdfind`; a `~/.local/bin/fd` shim is created |
| `bat` | binary is `batcat`; a `~/.local/bin/bat` shim is created |
| `direnv`, `ripgrep`, `jq`, `unzip` | version-insensitive |

| upstream | why apt will not do |
|---|---|
| `neovim` | bookworm has **0.7.2**; `treesitter.lua` pins `branch = "main"`, needing 0.11+ |
| `fzf` | bookworm has **0.38**, which predates `fzf --bash` (added in 0.48.0) |
| `zoxide` | bookworm has **0.4.3**, ~5 years stale; `init --cmd j` is not dependable there |
| `eza`, `git-delta`, `starship`, `gh`, `jj` | not packaged in bookworm at all |

Versions resolve through the `releases/latest` *redirect* rather than the GitHub
REST API, which is rate-limited to 60 requests/hour per IP — a pool of beams
shares egress and would hit that.

## Teleport tooling: opt-in

Building `gravitational/core` or `gravitational/access-graph` needs Go, Rust,
Node and friends — roughly **1.5GB and several minutes**. Most beams are used to
read logs or restructure a PR stack and need none of it, so it is never
installed by default. `devbox/teleport-tools.sh` is always symlinked onto PATH
as `teleport-tools`, and runs only when asked:

```sh
teleport-tools               # full (default)
teleport-tools backend       # Go, golangci-lint, buf, protoc, Rust
teleport-tools frontend      # Node, pnpm, Rust + wasm32, wasm-opt
teleport-tools --dry-run     # print resolved versions, install nothing
```

`install.sh --full` implies `--teleport=full`; `--teleport[=PROFILE]` gets the
toolchain without the nvim stack.

| profile | contents |
|---|---|
| `backend` | Go, golangci-lint, buf, protoc, Rust + clippy/rustfmt, `libpcsclite-dev` |
| `frontend` | Node, pnpm via corepack, Rust + `wasm32-unknown-unknown`, wasm-opt |
| `full` | both, plus helm and the helm-unittest plugin |

`build-essential` (i.e. **make** and gcc), `pkg-config`, `shellcheck` and
`xz-utils` are installed for every profile — a stock beam has none of them, and
every Teleport target starts with `make`.

### Versions are resolved, not hardcoded

These pins move every few weeks, and a stale Go minor is exactly the kind of
thing that burns an hour mid-debug. So the in-script pins are only an offline
fallback; the real source is resolved per run:

1. `--from-repo DIR` — a local `core` checkout
2. **`gravitational/core` via `gh`** — needs `ghlogin`, and is the only
   authoritative remote source
3. `gravitational/teleport` (public) — shares `build.assets` but **trails
   core**: at the time of writing core was on Go 1.27.3 / golangci-lint 2.14.0
   while public master was still on 1.26.7 / 2.12.2. Used only as a fallback,
   and the summary says so when it is
4. the built-in pins

Any single version can be forced with `TP_GO_VERSION`, `TP_NODE_VERSION`,
`TP_RUST_VERSION`, etc. — see `teleport-tools --help`.

**helm is pinned, not tracked**, and that one is load-bearing: the buildbox CI
runs chart tests in installs **helm v3.12.2** (`build.assets/Dockerfile`), while
`helm/helm`'s latest release is now **4.x**. Helm 4 is a different major with
breaking template changes, so installing "latest" renders the charts differently
from CI and turns `make test-helm` into a pile of spurious snapshot diffs. The
version is parsed back out of that Dockerfile.

`buf` is the one tool tracked at latest, because neither repo pins a CLI version
for external use.

### What is deliberately not installed

- **buf, gotestsum, gci, goda, benchstat** for core — its `common.mk` resolves
  these through `go tool -n` from `build.assets/tools/`, so a correct Go is all
  they need. The `buf` installed here is for **access-graph**, whose Makefile
  calls `buf generate` directly.
- **wasm-bindgen-cli** — core reads its version out of `Cargo.lock` and installs
  it itself in `ensure-wasm-deps`, which needs the checkout in hand.
- **Cross-compilation targets.** `rust-toolchain.toml` also lists
  `x86_64-pc-windows-gnu`; only the wasm target is installed, since the Windows
  one exists to cross-build a release `tsh` rather than to build/lint/test.
- **Antithesis, FIPS/BoringSSL, libfido2, BPF/clang** — niche, and absent only
  turns off the corresponding build tag.
- **Cloud tooling** (`qdeploy`, `ecr-tags`, `labctl`) — not used from beams.

Rust is in *both* profiles on purpose: the backend needs it for `rdp-client` and
`fdpass-teleport`, and `make lint-rust` / `make test-rust` silently become
no-ops when cargo is missing — a green run that tested nothing. The frontend
needs it for the ironrdp WASM module.

### Known limitation

**docker is not available on a beam**, so access-graph's `make postgres-start`
and the docker-compose dev stack cannot run here. Go and pnpm builds, lint and
unit tests all work.

## nvim: lean by default

The full plugin set is a poor trade on a throwaway box: mason downloads four
language servers and six CLI tools, treesitter compiles parsers, and
`telescope-fzf-native` and LuaSnip both need a C toolchain.

Lean mode keeps everything that holds the muscle memory — `set.lua`,
`remap.lua`, `autocmds.lua`, gruvbox, telescope, oil, harpoon, fugitive,
undotree, trouble, conform, cloak, zen-mode, autopairs — and drops only the
specs needing a compiler or a server download.

It keys off `BEAM_ID`, which beams export and macOS does not, so it
self-activates on a dev box and is inert on the Mac. See
`nvim/lua/bornguts/devbox.lua`. To opt in to everything:

```sh
NVIM_FULL=1 nvim          # one session
... | bash -s -- --full   # permanently, installs build-essential too
```

## GitHub access

The Teleport GitHub proxy is **not** provisioned for this identity — `tsh git ls`
returns no orgs and `tsh status` shows no `GitHub username:` — so `tsh git clone`
cannot reach private repos regardless of what the beam docs suggest. Use gh's own
credentials instead, once per beam:

```sh
ghlogin     # gh auth login --git-protocol https --web, then gh auth setup-git
```

`gh auth setup-git` registers gh as a git credential helper, so plain
`git clone https://github.com/org/private-repo` works afterwards.

## tmux

This links `tmux/tmux.server.conf` to `~/.tmux.conf` — the **inner** config.
`tmux/tmux.conf` is the local/outer one and holds the F12 toggle that puts the
outer server to sleep so your keys reach the box's tmux. Press **F12** locally,
then drive this tmux with your normal prefix.

## Claude Code files

Handled three different ways on purpose, because a beam ships its own versions:

- **`CLAUDE.md`** — composed, not replaced. The beam's file documents the
  environment (API env vars, teleport resources, publishing); the personal one
  is coding guidelines with no overlap. The beam file is kept and an `@import`
  of the personal file is appended, so it stays live with the repo.
- **`settings.json`** — merged with jq, personal settings as the base. The
  existing `env` keys (e.g. `CLAUDE_CODE_SKIP_BROWSER`, which matters on a
  headless box) and `availableModels`/`fallbackModel` win, since a straight link
  can leave a `model` pin the box cannot satisfy.
- **`keybindings.json`** — plain symlink; pure UX, no environment coupling.

## Not linked

`profile/profile` is **fish** syntax. The root `install.sh` links it to
`~/.profile`, which is correct on macOS and would break every bash login shell
here. `devbox/bashrc` is the bash port instead; it also drops `brew shellenv`,
the macOS `LDFLAGS`/`PKG_CONFIG_PATH` pair, and the auto-attach-to-`home` tmux
launcher (which misbehaves in a nested tmux and in tool-spawned shells).
