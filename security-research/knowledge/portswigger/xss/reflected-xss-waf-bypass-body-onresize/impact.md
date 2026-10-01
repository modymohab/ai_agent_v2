# Impact — WAF-bypassed reflected XSS with victim delivery

## Applicability reasoning
The input (`search`) is echoed verbatim into page text; the WAF rejects listed
tags/handlers (400) but passes the unlisted `body`+`onresize` pair, which merges onto
the real body as a live window handler fired by programmatic iframe resize. Relevant
categories: **client-side, WAF-gated, victim-delivered, interaction-free**. No
storage, no state change, no non-HTML consumer.

## CONFIRMED
- **Interaction-free victim code execution at the application origin** (`print()` in
  the victim bot; access-log visit + `is-solved`). The chain needs no clicks, hovers,
  or scrolling — delivery itself manufactures the trigger event.
- **WAF bypass is complete for this primitive**: the filter's two gap classes (tag
  allow-by-omission, handler allow-by-omission) compose into execution; the defense
  adds friction (oracle-mapping effort) but no barrier.
- **Delivery mechanics proven cross-origin**: exploit-server page drives lab-origin
  execution via framing + style resize (no X-Frame-Options present to stop it).

## PLAUSIBLE (same primitive/chain, not separately demonstrated)
- **Arbitrary JS instead of `print()`** (alert/exfil/ATO payloads ride the identical
  chain — `print()` is merely the platform's detection signal).
- **Session theft / account takeover** of human victims following the lure link.
- **The 10 dormant allowed handlers** as alternates if `onresize` were ever listed
  (each needs its own trigger design; some may combine with page features).
- **Wider filter-gap reuse** on real apps sharing this WAF's list philosophy
  (unlisted tag × unlisted handler × merge/behavioral composer).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Listed tags/handlers as vectors | NOT APPLICABLE (disproven ~85 probes) | 400 matrix incl. case/separator evasions |
| Self-browser `print()` as solve | NOT APPLICABLE (platform rule) | objective explicitly requires the victim signal |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo; lure must be (re)visited |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |
| Click/hover-gated execution | NOT APPLICABLE (better) | resize trigger is programmatic |

## NOT TESTED
- Full handler-list boundary (only ~40 of ~100+ `on*` tested; the 10 found suffice).
- Full tag-list boundary (~45 tested; custom-tag space is unbounded by design).
- Other params/endpoints under the same WAF (only `search` mapped).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Authenticated app + inbox/share features** (support tickets, DMs, shared reports
  carrying the lure link) → organic victim flow to the attacker page.
- **Weaker framing controls** (already absent here) — with `frame-ancestors` set,
  fall back to link-delivery + a non-frame resize/scroll trigger design.
- **Verbose WAF errors** (the 400-vs-200 oracle IS the mapping accelerator — silent
  strip-filters are slower to map but equally bypassable).
- **Blocklist-only defense culture** (one gap anywhere in tag×handler×composer space
  suffices; allow-list rendering + CSP would be structural).
- **Human victims over bots**: bots don't click — the zero-interaction property is
  what makes this chain human-viable too.

## Lab-scoped confirmed impact
Victim `print()` via delivered iframe-resize exploit — platform accepted.