# Root Cause — incomplete WAF blocklists + body-merge + resizable framing

## The vulnerability
A reflected search echo with NO output encoding is fronted by a reject-style WAF
whose tag blocklist omits `body` and whose event blocklist omits `onresize`. The
unlisted pair composes into interaction-free execution: injected `<body onresize>`
merges onto the real body element (parser behavior for duplicate body tokens),
arming `window.onresize`, and a framing page resizes the victim viewport
programmatically to fire it.

## Root cause (framing, three layers)
1. **Blocklist incompleteness (the WAF half)**: finite deny-lists for an infinite
   language. The filter enumerates dangerous KNOWN tags and COMMON handlers but misses
   (a) the semantically special `<body>` (pure omission — nothing legitimate needs an
   injectable body tag),
   (b) `onresize` among dozens of window events. Deny-listing event handlers is
  proven-unwinnable in practice: ~10 obscure-but-valid handlers passed the same filter.
2. **Body-merge semantics (the parser half)**: a second `<body>` start tag is not
   dropped — its novel attributes are COPIED onto `document.body`, where `on*`
   content attributes reflect to window handlers. An "impossible" injection point
   (inside `<h1>` text, no breakout needed) becomes a window-handler plant.
3. **Framing-permitted resize trigger (the delivery half)**: lab responses carry NO
   `X-Frame-Options` (verified: home-page headers show content-type/set-cookie/
   content-length only), so the exploit-server iframe embeds the lab page
   cross-origin without resistance. The resize trigger itself (`onload` → style
   width change) needs no privileges at all — any framing page can drive it.

## Trust boundary model
```
Attacker lure (exploit origin) ──► victim iframe navigation (LAB origin)
                                                      │  echo passes WAF gaps
                                                      ▼
                              reflected <body onresize> ──► body-merge (parser)
                                                      │
              [TRUST BOUNDARY: reflected text(data) → window handler(code)]
                                                      ▼
                        iframe onload resizes viewport ──► resize event
                                                      │
                                                      ▼
                                          print() (LAB origin, victim ctx)
```

## The general rule this lab exists to teach
WAF bypass is SET DIFFERENCE computed empirically: {what the browser executes} −
{what the filter blocks} = your payload space. Browsers execute: any tag (known or
custom) × any `on*` handler × body-merge × window events. The filter blocked most of
each set but left `body` × `onresize` — and ONE surviving pair with a programmatic
trigger is sufficient. Never conclude "blocked" from the common cases; enumerate to
the edges (custom tags, obscure handlers, merge semantics, trigger design).

## Enabling conditions (checklist)
1. Reflected echo without encoding (or with bypassable encoding) + reject-style
   filter (400/403 oracle makes mapping fast; silent-strip filters need diffing).
2. At least one unlisted tag AND one unlisted window-event handler whose combination
   parses (body-merge is the classic composer).
3. Framability (or link-delivery + a non-frame trigger) for the resize/event step.
4. Victim-visit channel (exploit server, inbox, shared link) when the objective
   requires victim-side signals (`print()` here).