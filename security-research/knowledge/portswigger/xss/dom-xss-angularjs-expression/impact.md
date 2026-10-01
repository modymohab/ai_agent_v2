# Impact — AngularJS expression injection

## Applicability reasoning
The input (`search`) reaches the AngularJS template compiler, which evaluates it as
an expression that escalates (via the constructor chain) to ARBITRARY GLOBAL JS in
the victim's browser on the application origin, on crafted-URL load, with no
interaction and no markup. Relevant categories are **client-side, link-delivered,
full-JS** (the strongest client primitive in this KB: no tag/handler/scheme/CSP-shape
limits beyond the expression grammar). No storage, no state change, no non-JS
consumer.

## CONFIRMED
- **Load-time arbitrary global JS at the application origin** on crafted-URL visit
  (title-mutation proof through the full chain + real `alert(1)` + acceptance).
  The inner function body is unconstrained JS — strictly more expressive than any
  markup/handler/URI vector.
- **Zero interaction, zero markup, zero breakout**: no clicks, no `<>`, no attribute
  termination — only `{{}}` + `"` survive-and-suffice.
- **Per-request delivery, no account/storage needed**.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, in-page secrets;
  authenticated actions as the victim).
- **Admin compromise** via crafted search link (tickets, shared links, dashboards).
- **Keylogging / credential capture / phishing overlays / CSRF-token theft**.
- **Multi-statement inner payloads** (`Function("s1;s2;…")`) — only URL length
  constrains; flag the exfil-rich variant as the real-world shape.
- **Other reflection points in the same ng-app** (any echo into compiled DOM —
  error pages, usernames, notification text) fall to the IDENTICAL payload.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Markup payloads | NOT APPLICABLE | sink compiles expressions; `&lt;&gt;` inert AND unnecessary |
| Single-quote strings | NOT APPLICABLE (this build) | `&apos;` — `"` mandatory (build-specific; other builds may invert) |
| Direct global references in-expression | NOT APPLICABLE (disproven) | scope restriction (the fromCharCode lesson) — globals live ONLY in the generated body |
| Sandbox escapes | NOT APPLICABLE (this version) | no sandbox in 1.6+ (WOULD be required on 1.0–1.5) |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | input reaches only the echo template |
| Stored/persistent delivery | NOT APPLICABLE | per-request reflection |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET search |

## NOT TESTED
- Angular versions other than the served 1.7.7 (sandbox-era shapes not exercised).
- CSP-hardened Angular deployments (no CSP here).
- Other `ng-` sinks on the same app (`ng-include`, `ng-bind-html`, directive attrs).

## What would increase impact in a real application
- **Authenticated SPA with AngularJS**: crafted route/query links → ATO; SPAs keep
  tokens in JS-reachable storage — ideal theft surface for a global-JS primitive.
- **User content rendered inside ng-app** (comments, names, bios compiled by
  Angular) → converts link-delivery into STORED CSTI (the most severe Angular shape).
- **Admin panels built in Angular 1.x** (very common historically) → privilege
  escalation via shared links/tickets.
- **Long inputs allowed** (multi-statement exfil needs URL room; POST-echo variants
  remove even that limit).
- **Any template caching of the payload** (recent searches, history) → persistence.

## Lab-scoped confirmed impact
`alert()` via search-term expression injection — accepted first poll.