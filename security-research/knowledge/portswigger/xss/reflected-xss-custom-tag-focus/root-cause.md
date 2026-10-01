# Root Cause — tag blocklist blind to custom elements + fragment focus

## The vulnerability
The search echo blocks standard HTML tags (400) but passes unknown/custom elements
with arbitrary attributes including event handlers. A custom element made focusable
via `tabindex` and targeted by the URL fragment receives automatic focus on page
load, firing its `onfocus` handler in the victim's browser — interaction-free script
execution with cookie access.

## Root cause (framing, three layers)
1. **Tag blocklist vs infinite element set**: a finite deny-list
   (`script`, `img`, `svg`, …) cannot cover unknown elements (`<xss>`, `<x>`,
   anything-not-in-the-list). Browsers parse unknown elements as generic inline
   elements that FULLY support global attributes and event handlers — "unknown"
   means unstyled, never inert. The filter mistakes absence-from-list for safety.
2. **Unfiltered handlers + focusability composition**: with `on*` unblocked, ANY
   host element suffices; `tabindex` upgrades an inert custom element into a
   focus-event source. Two individually-harmless allowances (custom tags,
   tabindex) compose into execution.
3. **Fragment-driven focus (no-interaction trigger)**: `#id` navigation auto-focuses
   focusable targets on load. The trigger ships inside the delivery URL itself —
   no second action, no iframe mechanics, no victim gesture.

## Trust boundary model
```
Attacker lure (exploit origin) ──► victim navigation to LAB payload URL + #x
                                                      │  echo passes tag filter
                                                      ▼
                              <xss id=x onfocus=… tabindex=1> parsed (LAB origin)
                                                      │
              [TRUST BOUNDARY: reflected markup(data) → live element + handler(code)]
                                                      ▼
                              load-time fragment focus ──► onfocus (victim ctx)
                                                      │
                                                      ▼
                                          alert(document.cookie) — data access shown
```

## Contrast with the sibling WAF lab (same family, mirrored gaps)
| | Prior lab (most-tags+attrs blocked) | This lab (all tags except custom blocked) |
|---|---|---|
| Tag filter | known-tag list (body + custom pass) | standard-tag list (custom pass) |
| Handler filter | extensive `on*` list (10 obscure pass) | effectively OPEN (onfocus passes) |
| Winning pair | `<body>` × `onresize` | `<xss>` × `onfocus` |
| Trigger | manufactured (iframe resize) | URL-intrinsic (`#x` auto-focus) |
| Delivery | iframe embed | `location=` navigation |
| Signal | victim `print()` | victim `alert(document.cookie)` |
Same invariant: set-difference vs the filter + trigger matched to the objective.

## Enabling conditions (checklist)
1. Reflected echo with tag filtering that passes unknown elements (test `<xss>`,
   `<x>`, `<custom-tag>` immediately — two requests).
2. Event handlers unfiltered (or gapped — see prior lab) on those hosts.
3. `tabindex` (or inherently focusable host) + fragment-focusable `id` for the
   zero-interaction trigger.
4. Victim-visit channel when the signal must come from the victim's browser.