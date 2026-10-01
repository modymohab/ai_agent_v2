# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **If a page reads URL state (`location.search`, `location.hash`) into a DOM-string
> sink (`document.write`, `innerHTML`, `outerHTML`, `insertAdjacentHTML`,
> `DOMParser.parseFromString`, `jQuery.html/.append`, anchor `href`), then attacker control
> of the URL = attacker control of parsed markup. Determine the exact context the value
> lands in (attribute / text / script), derive the minimal breakout primitive, and encode
> delivery accordingly.**

Rule of thumb for context→primitive:
- double-quoted attribute inside dynamically written HTML → breakout with `"` (+ `>` for
  tag-close/script route; or `" evt=… x="` for same-element scriptless).
- text node → breakout with `<`.
- JS/JSON string (`var x='…'`) → breakout with `'` and/or `</script>`.
Test the context empirically with distinct markers before choosing a payload.

## Recon indicators (how to find this class again)
- Search/filter/page-state features that visibly reflect the term in attributes/images
  (tracking pixels, "results for", query persistence).
- Read **inline + external JS** on every interesting page; grep for the sink
  family (`document.write|innerHTML|outerHTML|insertAdjacentHTML|setAttribute\(['\"]on|eval|href=`) 
  and the source family (`location\.(search|hash|href)|URLSearchParams|document.referrer|document.URL`).
- A sink+source couple in the same function is a candidate; DOM XSS is invisible in the
  HTTP response, so **static JS review is mandatory** — response inspection alone is not enough.
- Note: DOM XSS is not only from the URL — `document.referrer`, `window.name`, `postMessage`
  events, `localStorage/sessionStorage`, and cookie values can also be source-S.
- Check for CSP / Trusted Types headers: their absence is an enabler.

## Verification techniques (reusable)
1. **Non-blocking execution probe**: `document.title='MARK'` (or create a DOM marker) so a
   headless dump or automation can assert execution without a dialog blocking the render.
   `alert()` freezes headless render/dump — the hang is a symptom, not an assertion.
2. **Dump the sink output**: `--dump-dom` shows the elements/document.write actually
   produced — confirm the breakout shape (e.g., `<img ... searchTerms=">`).
3. **Prove BOTH vector families when the sink is attribute-context**: tag-close+script AND
   event-handler-on-same-tag; this maps the primitive to multiple payloads for real targets
   with CSP.
4. **Isolate SSR vs DOM**: test the same parameter against server reflections separately
   (marker + encoding observation). Only the DOM path was exploitable here — knowing why
   (server encoding) prevents over/under-reporting.
5. **Encoding discipline**: deliver payloads single-encoded (%22 %3E %3C …) and verify in
   the browser; be aware browsers will percent-collapse sequences like %25→% and %2F→/.
   `URLSearchParams.get` decodes once.

## Common mistakes that miss this
- **Response-only testing** (curl + grep): the vuln is invisible in the response; you must
  execute the JS. (curl "verifies" nothing about a DOM sink.)
- **Assuming the SSR reflection is the sink** (or the only sink): the `<h1>` is encoded
  (safe); the real bug is in an unrelated inline script.
- **Wrong breakout primitive**: trying `</script>` closure on a *markup* sink, or trying
  `<script>` without `"`/`>` when the value is inside an attribute — both stay inert.
- **Not reading the actual JS**: sim-search payload fuzzing without reviewing the sink code.
- **Failing to re-fetch / dump**: not confirming the written-then-parsed output; reporting
  based on intent not on observed DOM.
- **Over-encoding or under-encoding** the delivered URL (double-encoding relies on browser
  normalization; triple-encoding would break). One correct encoding, validated per browser.
- **Confusing DOM XSS with reflected XSS**: here server provides identical response for all
  queries; only client execution differs. Distinguishing matters for remediation
  (client-side fix vs server-side filter).

## Cross-cutting
- Same app pattern (blog + search) recurs across PortSwigger DOM labs; the reusable
  method (source/sink audit → context map → minimal breakout → browser-confirmed proof)
  applies to `innerHTML`, jQuery, and hashchange variants.
- When a sink is reached via multiple sources, prioritize sources an attacker controls
  without interaction (location.search trumps document.referrer for luring).