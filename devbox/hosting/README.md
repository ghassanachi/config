# Hosting `dev.ghassanachi.com`

A Cloudflare Worker that serves `devbox/install.sh`, so the installer reads as:

```sh
curl -fsSL dev.ghassanachi.com | sh
curl -fsSL dev.ghassanachi.com | sh -s -- --full
```

## Why a Worker and not just DNS

`raw.githubusercontent.com` cannot be CNAME'd — it requires its own `Host`
header and TLS SNI, so a DNS-only alias fails the handshake. Something has to
terminate the request and re-issue it.

GitHub Pages would work but answers the **bare root path** only with a file
named `index.html`, which means committing the shell script under an `.html`
name. The Worker avoids that, sets a real `text/x-shellscript` content type,
and can tell a browser from curl.

## Deploy

One-time, from this directory:

```sh
npm install -g wrangler     # or: npx wrangler
wrangler login
wrangler deploy
```

`custom_domain = true` in `wrangler.toml` makes Cloudflare create the DNS
record itself, so there is no separate record to add by hand. The zone must
already be on Cloudflare (it is).

Verify:

```sh
curl -fsSL dev.ghassanachi.com | head -5          # the script
curl -fsSL -H 'Accept: text/html' dev.ghassanachi.com | head -5   # the docs
```

## Behaviour

| Request | Response |
|---|---|
| `curl` / `wget` (`Accept: */*` or none) | the script, `text/x-shellscript` |
| browser (`Accept: text/html`) | a small docs page |
| GitHub unreachable or non-200 | **still valid shell**, printing an error to stderr and exiting 1 |

That last row is deliberate. The body of a failed response still reaches the
interpreter when someone pipes a bare `curl` without `-f`, so an error page
would otherwise be handed to `sh` to execute. Returning a tiny script that
exits non-zero fails safely instead.

## Pinning

`REF` in `worker.js` points at `master`. Whatever it names executes on every
box you bootstrap, so point it at a tag when you want installs reproducible and
immune to an accidental push:

```js
const REF = "devbox-v1";
```

Note that this URL is a code-execution path onto your machines: whoever controls
the domain or the branch controls what runs. A tag plus branch protection is the
cheap mitigation.
