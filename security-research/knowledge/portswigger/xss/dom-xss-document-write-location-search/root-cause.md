# Root Cause — document.write sink sourced from location.search

## The vulnerability
The client-side script reads `location.search` (via `URLSearchParams`) and concatenates
the decoded value directly into an HTML string that is written to the document through
`document.write()`. The value lands **inside a double-quoted attribute** of an `<img>`
tag, and because `document.write`'s output is parsed as HTML, an attacker who controls the
query string controls the parsed markup.

## Root cause (framing)
- **Insecure sink API**: `document.write` takes an arbitrary HTML string and hands it to
  the parser. Any user-influence on that string is equivalent to owning the page markup.
  (Same class: `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `DOMParser().parseFromString`,
  `Range.createContextualFragment`.)
- **Dangerous source read**: `location.search` / `location.hash` / `location.href` are
  attacker-controllable at any time; reading them into a sink creates DOM XSS *without any
  server involvement*.
- **Where encoding should have been**: the query is meant to be *data* (a tracking pixel
  parameter). Defenses that would prevent the bug:
  (a) never build sink strings from URL data — write the tracking pixel with a fixed
      attribute and set `?searchTerms=` via a data-only API (e.g. `new Image().src`),
  (b) if string-building is required, context-aware escape the value for a quoted attribute
      (`&quot;` etc.) — though an API-level fix is strictly better for document.write.
- The critical flaw assumption: *"browser string data inserted into the DOM stays data."*
  The HTML parser re-interprets it as code. This is the **data → code** boundary, and it
  lives **entirely on the client** — the server never sees or sanitizes the payload.

## Trust boundary model
```
Attacker URL ──► location.search ──► URLSearchParams.get ──► JS string (data)
                                                                  │
               [TRUST BOUNDARY: data(value) → parsed markup(code)]
                                                                  ▼
                          document.write → HTML parser → DOM insertion
                                                                  │
                                                                  ▼
                                                 script/scriptless execution (victim origin)
```
- The server's encoding of its own `<h1>` reflection does NOT protect this path — the
  sink executes in the browser, downstream of any server-side mitigation. This is why
  DOM XSS requires **client-side code review**, not response inspection alone.

## Why the two physical contexts matter
- The value is concatenated after `...searchTerms=` inside `src="..."`. The breakout
  primitive is therefore **attribute termination**: `"` (end value) and `>` (end tag).
- Contrast with a text-node sink (`<p>` + value): there the primitive is `<`.
- Contrast with a script-context sink (`var x = '...'`): there the primitive is `'` + `</script>`.
  In this lab `</script>` is NOT needed/usable — the payload is written as *markup*, not
  injected into the JS string (see verification).

## Enabling conditions (checklist)
1. Sink `document.write(...)` (or sibling sink) reached with URL-derived data.
2. No output sanitization before insertion.
3. No CSP (`Content-Security-Policy` header absent here) → inline `<script>` allowed.
4. No `trusted-types` policy enforcing a sanitizer on document.write.