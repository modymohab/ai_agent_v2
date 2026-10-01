# Impact — Reflected DOM XSS via eval(JSON)

## Applicability reasoning
The input (`search`) is reflected into XHR JSON that the page `eval()`s: arbitrary
attacker statements execute in the victim's browser on the application origin upon
crafted-URL visit, with the page rendering normally afterward. Relevant categories are
**client-side, link-delivered, arbitrary-statement** (stronger than markup-only XSS:
no tag/handler/CSP-shape constraints beyond the eval itself). No storage, no
state-change, no non-JS server consumer.

## CONFIRMED
- **Load-time arbitrary-JS execution at the application origin** on crafted-URL visit
  (flag-setting + title-mutation through the real XHR→eval path; real `alert(1)` +
  acceptance). Payload is a full STATEMENT (`;alert(1);`), not a markup fragment —
  any JS goes, constrained only by the breakout grammar.
- **Stealth execution**: post-eval object intact (`searchTerm` valid, results render,
  "0 search results" displayed) — victim sees a working page; no breakage signals.
- **Per-request delivery, no account/storage/interaction needed**.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookie/token exfil, localStorage, in-page
  secrets; HttpOnly bypassed via in-context authenticated actions).
- **Admin compromise** via crafted search link (support tickets, shared dashboards).
- **Cart/order/payment abuse** on shop builds of this pattern (the sink shape, not
  this blog's data, is what's reusable).
- **Keylogging / credential capture / phishing overlays**; **CSRF-token theft +
  authenticated state-changing actions** as the victim.
- **Longer multi-statement payloads** (the grammar allows `;s1;s2;…` chains before
  the `//`; only URL length constrains).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Markup-shape payloads (`<script>`, `<img onerror>`) | NOT APPLICABLE | sink consumes JS source text, not markup — angle brackets inert (passed raw, harmless) |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | input reaches only the JSON template |
| Stored/persistent delivery | NOT APPLICABLE | per-request reflection; no storage path |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | search + JSON fetch are side-effect-free GETs |
| `results[]` as injection vector | NOT APPLICABLE (reasoned) | server DB data; query only selects matches |
| Comment/execution via `displaySearchResults` consumers | NOT APPLICABLE | `innerText` + static-prefix `setAttribute` only (audited) |

## NOT TESTED
- Other endpoints feeding `eval` (only `/search-results` mapped); POST variants.
- Server error-path reflections (only 200-path characterized).
- CSP-`unsafe-eval` interplay (no CSP here; under a policy WITHOUT `unsafe-eval`,
  `eval` itself throws — a relevant hardening note, unverified on this stack).

## What would increase impact in a real application
- **Authenticated app with rich page JS** (tokens, API clients, PII in DOM) — the
  arbitrary-statement primitive subsumes every markup-XSS impact with fewer
  constraints.
- **Shared search links** (support consoles, "share these results" features) —
  converts link-delivery into organic reach.
- **Verbose error/debug JSON fields** echoing more input (wider injection surface).
- **Long-lived sessions + sensitive actions without re-auth**.
- **Absence of CSP** (true here); note a CSP WITH `unsafe-eval` would still allow
  this sink — only removing `eval` (or `JSON.parse`) fixes it.

## Lab-scoped confirmed impact
`alert()` through the search page's XHR→eval path — accepted first poll.