# Root Cause — first-occurrence sanitizer on a stored-to-DOM path

## The vulnerability
Stored comment fields are rendered client-side through `escapeHTML()`, which calls
`String.replace()` with STRING (not regex) patterns — replacing only the FIRST `<`
and FIRST `>`. Attacker text containing two or more angle brackets keeps a complete,
executable HTML tag after "sanitization," which `innerHTML` then parses in every
viewer's browser. Persistence (server JSON) × execution (client sink) = stored DOM XSS.

## Root cause (framing, three layers)
1. **Broken sanitizer primitive**: `"...".replace('<', …)` replaces one occurrence —
   JavaScript's most notorious sanitization footgun (the global-flag `/</g` or
   `replaceAll` is the correct form). A sanitizer that transforms input
   non-idempotently/non-totally isn't a sanitizer for the characters it misses.
   The filename itself advertises it (`…WithVulnerableEscapeHtml.js`) — in real code,
   grep for `replace('<'` / `replace(">"` with string literals as a high-signal smell.
2. **Stored data treated as safe by the client**: the JSON array is same-origin
   application data, so the client applies only the (broken) cosmetic escape and no
   structural defense (no `textContent`, no DOMPurify, no Trusted Types). Trust in
   "our own database" fails the moment any write path accepts attacker text.
3. **Two trust boundaries, two chances to stop it** (both missed): server store-time
   (no sanitization/validation of body — correct ONLY if render-time is safe) and
   client render-time (broken escaper). Either sound layer would have held.

## Trust boundary model
```
Attacker POST ──► stored VERBATIM in comment JSON (data at rest)
                                                │
              [BOUNDARY 1: store-time — unguarded]
                                                ▼
              viewer XHRs JSON ──► escapeHTML (first-match only) ──► innerHTML
                                                │
              [BOUNDARY 2/TRUST BOUNDARY: string(data) → parsed fragment(code)]
                                                ▼
                              img-onerror execution (viewer origin, load-time)
```
Contrast the `website` field, where the SERVER holds its boundary (scheme allowlist,
400s): same app, sound layering on one field, absent on another — coverage gaps again.

## Why the obvious vector died (and why that matters)
`website`→`href` with NO client escaping looks like the intended hole — until the
server 400s every non-http(s) scheme (case-insensitive). Lesson encoded: verify EVERY
layer's ACTUAL behavior (the client code promises exploitability; the server vetoes
it). The kill-chain moved to the weaker layer (client escaper), which is the general
rule for multi-layer apps: enumerate defenses per layer, attack the thinnest.

## Enabling conditions (checklist)
1. Attacker text persisted and later fed to a client markup sink (`innerHTML`,
   `outerHTML`, `insertAdjacentHTML`, jQuery `.html()`, `document.write`).
2. Sanitizer with first-occurrence semantics (`replace` string patterns, single-pass
   regexes without `/g`, strip-once loops) — test with DOUBLED metacharacters.
3. No structural render defense (`textContent`, sanitizer library, Trusted Types).
4. No CSP blocking inline handlers (none here).