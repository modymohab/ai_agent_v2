# Attack Chain — Template-literal interpolation over Unicode escapes

## Data flow
```
Attacker crafts URL   /?search=${alert(1)}
   │  (transport: %24%7Balert(1)%7D)
   ▼
[INPUT] GET /?search=…  →  server echoes with six classes Unicode-escaped
   │
   ▼
[PROCESSING] template:  var message = `0 search results for '${alert(1)}'`;
   │  every dangerous char neutralized EXCEPT $ { } ( ) — the interpolation
   │  syntax itself, which no string-escaper touches (it mustn't — it's not
   │  string content, it's the literal's own grammar)
   ▼
[SINK] JS engine evaluates the template literal → ${…} expression position →
alert(1) runs during variable initialization, page parse time
   │
   ▼
[TRUST BOUNDARY CROSSED] template text(data) → evaluated expression(code) —
no breakout, no terminator, no tag: the "string" was executable all along
   ▼
RESULT: alert(1) in app origin; message assigned afterwards (innerText sink inert)
```

## Why this shape (only shape)
- Terminators: backtick→`\u0060` (can't end the literal), quotes→`\u00XX` (can't
  break strings — and there IS no nested string to break out of anyway).
- Tags: `\u003c\u003e` inert (no `</script>` closure possible).
- Backslash: `\u005c` (no shift).
- The ONLY executable syntax reachable: `${EXPR}` interpolation — `$`, `{`, `}`
  must survive for the literal to function at all; the escaper cannot touch them
  without breaking legitimate use. The defense enumerates six classes and misses
  the seventh because the seventh IS the feature.
- Inner payload needs no quotes (`alert(1)`) — and single-quoted inner strings
  would arrive `\u0027`-mangled (same inner-discipline as prior labs, unneeded here).

## Expected response sequence (verified)
1. `GET /?search=${alert(1)}` → 200, interpolation bytes verbatim in the literal.
2. Browser evaluates the literal during initial script parse; expression fires.
3. `alert(1)` → `is-solved` (first poll).