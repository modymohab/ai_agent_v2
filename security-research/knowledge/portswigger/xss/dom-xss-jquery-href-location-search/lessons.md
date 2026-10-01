# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a script copies URL data into a navigation-capable attribute or property
> (`href`, `src`, `action`, `location`, `window.open()`), test a `javascript:` URI —
> and remember execution is CLICK-gated (or navigation-gated), never load-gated. The
> payload is a URI, not markup: no breakout characters, single-encode only
> URI-significant characters. The same sink with an `https:` value is an open redirect.**

Coupled rules:
1. **Sink family decides payload shape AND trigger**: markup sinks take HTML and fire
   on parse/error; navigation sinks take URIs and fire on follow. Firing HTML at an
   `href` sink (or `javascript:` at `innerHTML`) is a category error, not a filter bypass.
2. **Whole-attribute assignment needs no breakout** — `.attr("href", value)` has no
   surrounding syntax to escape, exactly like whole-element `innerHTML` assignment.
3. **One sink, two impacts**: unsanitized link targets are simultaneously XSS (script
   scheme) and open redirect (http scheme). Report both; fix once (scheme/path validation).

## Recon indicators (how to find this class again)
- `returnUrl` / `returnPath` / `next` / `continue` / `redirect` / `callback` parameters,
  especially on login, logout, feedback, error, and "cancel/back" flows.
- JS grep: `\.attr\(['"](href|src|action)['"]|location\s*=|\.href\s*=|window\.open\(`
  near `location\.|URLSearchParams|hash|referrer`.
- Links whose href is EMPTY in static HTML (`<a id="backLink">Back</a>`) but populated
  at runtime — the value comes from somewhere; find the assignment.
- jQuery-era codebases (`.attr()` on anchors) and SPA routers that set `href` from
  route/query state are the highest-yield hunting grounds.

## Verification techniques (reusable)
1. **Attribute proof first** (`--dump-dom` + grep the anchor): cheap, proves
   attacker-controlled value reaches the sink verbatim — do this before any clicking.
2. **SSR-absence proof** (unique marker + response grep): scopes the finding to the
   client and pre-empts "server filter" debates.
3. **CDP programmatic-click proof** for click-gated sinks: local headless Chromium +
   `--remote-debugging-port` + `--remote-allow-origins=*` + `Page.navigate` +
   `Runtime.evaluate(el.click())`; assert on a `void()`-wrapped side effect
   (`javascript:void(document.title='MARK')`) so the page survives for assertion.
   (Operational notes learned: never `pkill -f` with a pattern present in your own
   command line; quote `--remote-allow-origins=*` under zsh.)
4. **Bare-`javascript:` behavior check**: a non-`void` expression returning a string
   REPLACES the document — useful as a noisy execution signal, but use `void()` for
   clean assertions.
5. **Dual-scheme test**: fire `javascript:` AND `https://evil` values — one sink, two
   confirmed impacts (XSS + open redirect) from two cheap requests.

## Common mistakes that miss this
- **Firing markup payloads at a URI sink** (`<script>`, `<img onerror>`) → inert href
  string → false "not vulnerable" verdict. Payload must match sink family.
- **Expecting load-time execution**: page loads clean; without a click nothing happens.
  Test harnesses that only load-and-dump will miss click-gated XSS entirely.
- **Response-only testing**: zero reflection in HTTP — curl+grep reports clean.
- **Stopping at XSS and missing the redirect** (or vice versa): the sink yields both;
  the redirect half often survives even partial fixes (e.g. blocking `javascript:` but
  allowing arbitrary `https:`).
- **Over-encoding the URI** (`%253A` etc.) — relies on browser normalization luck;
  single-encode reserved chars and verify per browser.
- **Assuming CSP `script-src` fixes it**: `javascript:`-URI navigation is governed by
  navigation directives, not `script-src`, in several browsers — scheme validation at
  the sink is the durable fix. (Do not over-claim CSP behavior per-browser; verify.)

## Cross-cutting
- With the two sibling labs, the DOM-XSS execution-moment matrix is now complete:
  | Sink | Fires when | Payload family | Interaction |
  |---|---|---|---|
  | `document.write` | parse | HTML (`<script>` OK) | none |
  | `innerHTML` | resource error / auto event | event-handler element | none |
  | jQuery/anchor `href` | navigation follow | `javascript:` URI | **click required** |
- The method chain is unchanged across all three (source/sink audit → context map →
  family-correct payload → side-effect assertion → negative control); only the payload
  family and the trigger differ. Memorizing the matrix beats memorizing payloads.