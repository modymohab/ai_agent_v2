# Root Cause — complete JS-layer escaping with raw brackets (parser-layer hole)

## The vulnerability
The search term is echoed into a single-quoted JavaScript string with quotes AND
backslashes escaped — a SOUND JS-layer defense — but angle brackets pass through
raw, so `</script>` terminates the script ELEMENT at the HTML-tokenizer layer (which
precedes JS parsing) and a fresh attacker `<script>` block executes.

## Root cause (framing)
- **Right defense, wrong layer coverage**: the escaper closes every JS-layer
  breakout (quote termination, backslash shifting, line-continuation) while leaving
  the HTML-parser layer — which also interprets the same bytes, FIRST — fully open.
  Any echo into `<script>` must neutralize BOTH layers: JS metachars (`'"\` +
  newlines) AND the element terminator (`</script>`, typically via `<`→`\x3c` or
  equivalent). This is the general form: **every embedding context has a stack of
  parsers; the escaper must cover the union of their metachars, and testing must
  attack each layer independently**.
- Failed assumption: *"escaped quotes make script echoes safe."* True within JS
  source semantics; false once the tokenizer (which doesn't understand strings)
  reaches `</script>` first.
- Contrast the trilogy siblings: quotes-raw (break AT JS layer), quotes-escaped
  +`\`-raw (break VIA encoding-shift at JS layer), quotes+backslash-escaped
  (break ABOVE JS layer, at HTML). Escaper strength doesn't remove the hole — it
  RELOCATES it up the parse stack.

## Trust boundary model
```
Attacker URL ──► GET param ──► server template into <script> (data?)
                                                                     │
              [TRUST BOUNDARY 1 (JS layer): HELD — quotes/backslash escaped]
                                                                     │
              [TRUST BOUNDARY 2 (HTML layer): OPEN — </script> raw] ◄── crossed here
                                                                     ▼
                        tokenizer ends element → fresh script block (page origin)
```

## Enabling conditions (checklist)
1. Request data echoed inside a `<script>` block (search echoes, config vars,
   analytics assignments, JSON-in-HTML string fields).
2. Escaper covering JS metachars but NOT `<` (or not `</script>` specifically) —
   test the bracket pair explicitly even when quotes are handled.
3. Fresh-block payload avoiding server-mangled chars (no `'` here — use `"`/quoteless).
4. No CSP blocking inline scripts (none here; `script-src` without `'unsafe-inline'`
   would neuter BOTH the original and injected blocks — depth that actually works).