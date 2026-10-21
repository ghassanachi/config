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
# full nvim stack (LSP/mason, treesitter, neotest, cmp) + build-essential
curl -fsSL .../devbox/install.sh | bash -s -- --full

# link configs without installing tools, or vice versa
... | bash -s -- --no-tools
... | bash -s -- --no-link

# install from a branch, or clone somewhere else
... | bash -s -- --ref my-branch --dir ~/src/config
```

Environment overrides: `DEVBOX_REPO`, `DEVBOX_REF`, `CONFIG_DIR`, `NVIM_FULL`,
`BIN_DIR`.

## What it does

1. **Preflight** — requires Debian/Ubuntu, x86_64, a non-root user, and curl.
2. **Clone** `~/.config/dotfiles`, shallow + blobless + sparse. Only the paths a
   dev box needs are checked out: **640KB cloned instead of a full clone**.
3. **Tools** — see the table below. Everything that is not an apt package lands
   in `~/.local/bin`, so only the apt step needs sudo.
4. **Link** — symlinks into `$HOME`, appends a marker block to `~/.bashrc`, and
   creates `~/.vim/undodir` (which `set.lua` requires for `undofile`).

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
| `eza`, `git-delta`, `starship`, `gh` | not packaged in bookworm at all |

Versions resolve through the `releases/latest` *redirect* rather than the GitHub
REST API, which is rate-limited to 60 requests/hour per IP — a pool of beams
shares egress and would hit that.

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
