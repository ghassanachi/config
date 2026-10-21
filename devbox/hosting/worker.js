/**
 * Cloudflare Worker serving the devbox installer at dev.ghassanachi.com.
 *
 *   curl -fsSL dev.ghassanachi.com | sh
 *
 * The Worker is a thin shim over raw.githubusercontent.com, which cannot be
 * CNAME'd directly (it requires its own Host header and SNI). Serving it here
 * also means the bare root path works, which GitHub Pages cannot do without
 * naming the script index.html.
 *
 * Browsers asking for text/html get readable docs; curl and wget get the
 * script.
 */

// Pin REF to a tag rather than a branch when you want installs to be
// reproducible: whatever this points at executes on every box you bootstrap.
const REPO = "ghassanachi/config";
const REF = "master";
const SCRIPT_PATH = "devbox/install.sh";

const UPSTREAM = `https://raw.githubusercontent.com/${REPO}/${REF}/${SCRIPT_PATH}`;
const CACHE_SECONDS = 300;

const SCRIPT_HEADERS = {
  "content-type": "text/x-shellscript; charset=utf-8",
  "cache-control": `public, max-age=${CACHE_SECONDS}`,
  "x-content-type-options": "nosniff",
};

/**
 * Failures must themselves be valid shell. The body of a non-2xx response
 * still reaches the interpreter when someone pipes a bare `curl` (no -f), so
 * returning prose would have the shell try to execute an error message.
 */
function shellError(message) {
  const safe = String(message).replace(/'/g, "'\\''");
  return new Response(
    `#!/bin/sh\nprintf 'devbox: %s\\n' '${safe}' >&2\nexit 1\n`,
    { status: 502, headers: SCRIPT_HEADERS },
  );
}

const DOCS = `<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>devbox</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  :root { color-scheme: light dark; }
  body { max-width: 46rem; margin: 4rem auto; padding: 0 1.5rem;
         font: 16px/1.6 ui-sans-serif, system-ui, sans-serif; }
  pre  { padding: .9rem 1.1rem; border-radius: .5rem; overflow-x: auto;
         background: light-dark(#f4f4f5, #1c1c1f); }
  code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
  h1   { font-size: 1.5rem; }
  td, th { text-align: left; padding: .2rem 1.5rem .2rem 0; vertical-align: top; }
  a    { color: inherit; }
</style>
<h1>devbox</h1>
<p>Bootstrap an ephemeral Linux dev box: tmux, nvim, git/gh, and shell setup.</p>
<pre><code>curl -fsSL dev.ghassanachi.com | sh</code></pre>
<p>Options:</p>
<table>
  <tr><th><code>--full</code></th><td>complete nvim stack (LSP, treesitter) + build-essential</td></tr>
  <tr><th><code>--no-tools</code></th><td>link configs only</td></tr>
  <tr><th><code>--no-link</code></th><td>install tools only</td></tr>
  <tr><th><code>--ref &lt;ref&gt;</code></th><td>install from a branch or tag</td></tr>
</table>
<pre><code>curl -fsSL dev.ghassanachi.com | sh -s -- --full</code></pre>
<p>Source: <a href="https://github.com/${REPO}/blob/${REF}/${SCRIPT_PATH}">${SCRIPT_PATH}</a>
   &middot; <a href="https://github.com/${REPO}/tree/${REF}/devbox">docs</a></p>
`;

export default {
  async fetch(request) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("method not allowed\n", {
        status: 405,
        headers: { allow: "GET, HEAD" },
      });
    }

    // Only a real browser navigation gets HTML. curl sends Accept: */* and
    // wget sends nothing, so neither is misrouted into the docs page.
    const accept = request.headers.get("accept") || "";
    if (accept.includes("text/html")) {
      return new Response(DOCS, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": `public, max-age=${CACHE_SECONDS}`,
        },
      });
    }

    let upstream;
    try {
      upstream = await fetch(UPSTREAM, {
        cf: { cacheTtl: CACHE_SECONDS, cacheEverything: true },
      });
    } catch (err) {
      return shellError(`could not reach GitHub: ${err.message}`);
    }

    if (!upstream.ok) {
      return shellError(
        `installer unavailable (GitHub returned ${upstream.status} for ${REF})`,
      );
    }

    return new Response(upstream.body, { headers: SCRIPT_HEADERS });
  },
};
