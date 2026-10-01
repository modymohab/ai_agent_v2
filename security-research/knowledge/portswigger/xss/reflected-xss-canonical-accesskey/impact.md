# Impact — Canonical link accesskey XSS

## Applicability reasoning
The input (full query string) is URL-encoded into a single-quoted `href`; the raw
`'` breaks out and plants `accesskey` + `onclick` on a `<link>` element, whose
handler fires when the access-key combo is pressed (platform-simulated here).
Relevant categories: **client-side, keypress-gated**. No storage, no state change,
no non-HTML consumer.

## CONFIRMED
- **Keypress-driven code execution at the application origin** on crafted-URL visit
  + access-key combo (real `alert(1)` + acceptance). The handler is arbitrary JS
  (not constrained to alert).
- **URL-encoding neutralized exactly the wrong set**: tags and `"` dead, `'` live —
  filter characterization complete and minimal.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** where victims can be talked into the keypress
  (the social-engineering cost is the only discount vs load-time vectors).
- **Credential/cookie access** via handler JS once fired (same origin consequences
  as any XSS post-fire).
- **Other single-quoted URL echoes** (redirect `?next=` in attributes, canonical/
  OG tags, `<base href>`) under URL-encoding — same breakout shape transfers.
- **Other key-triggerable hosts** (any element accepting `accesskey` + handler).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Tag injection | NOT APPLICABLE (disproven) | `%3c%3e` inert |
| `"`-breakout | NOT APPLICABLE (disproven) | literal `%22` text |
| Load/error-time fire | NOT APPLICABLE | link is inert until key-activated |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |

## NOT TESTED
- Which exact key combo fires headlessly (platform simulated; CDP dispatch skipped).
- Non-Chrome engines (objective states Chrome-only — accepted, unverified).
- Other query params/paths as echo sources (only bare-query on `/` used).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Cooperative keypress contexts**: kiosks, assistive-tech users, shortcut-driven
  power users, apps that DOCUMENT their accesskeys ("press Alt+X for…") — the lure
  writes itself.
- **Login-adjacent echoes** (redirect/canonical/OG tags on auth pages) → session theft.
- **Missing HttpOnly** → direct cookie read in handler.
- **Keyboard-heavy victims** (support agents, data entry) more likely to oblige.
- **Framed/embedded delivery** where the attacker page can FOCUS + synthesize keys
  (limited; real keypresses generally needed — the platform simulation is the lab's
  threat-model gift).

## Lab-scoped confirmed impact
`alert()` via canonical-tag accesskey breakout + simulated keypress — first poll.