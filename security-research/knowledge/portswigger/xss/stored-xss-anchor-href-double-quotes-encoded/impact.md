# Impact — Stored XSS into href (scheme unvalidated)

## Applicability reasoning
The input (`website`) is persisted and rendered as an anchor `href` accepting arbitrary
schemes: `javascript:` targets execute in the viewer's browser on the application
origin after one click on native UI. Relevant categories are **client-side,
stored-delivered**. No other server consumer exists; the comment POST itself is
CSRF-token protected.

## CONFIRMED
- **Stored click-gated code execution for every future viewer**: one `javascript:`
  store → poisoned author link served to all visitors indefinitely (CDP click proof +
  real `alert(1)` + acceptance). No per-victim link, no off-site lure — victims arrive
  organically and click trusted page chrome.
- **Arbitrary-URL acceptance (open-redirect mechanism)**: the same sink stored
  `https://WSMARK.example.com/…` verbatim — author links can equally point off-site
  (mechanism proven; redirect ride not separately fired).

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Mass session theft / account takeover**: every reader is one reflexive click from
  execution; stolen contexts usable for authenticated actions.
- **Admin/moderator compromise**: comment-review flows that render the author link
  turn routine moderation into privileged execution.
- **Phishing at scale**: off-site author URLs or same-origin injected login overlays,
  delivered to the whole readership.
- **Self-propagation (stored-XSS worm)**: payload that submits further comments via
  the victim's session + page CSRF tokens — the classic stored-XSS escalation, viable
  wherever write + token-reuse coincide (not attempted here).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| `"`-breakout / tag injection from this field | NOT APPLICABLE (disproven + structural) | `&quot;` blocks termination; raw `<>` inside a value can't open tags |
| `comment`/`name` injection on this build | NOT APPLICABLE (disproven) | fully encoded (contrast first stored lab) |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | value reaches only the HTML template |
| CSRF against comment POST via THIS primitive | NOT APPLICABLE | endpoint requires per-session token; attacker uses own session |
| Load-time execution | NOT APPLICABLE | href needs the click (no autofocus equivalent for anchors) |

## NOT TESTED
- Scheme-filter bypasses (`JaVaScRiPt:`, whitespace/control-char padding,
  `&colon;` entities) — server accepted plain `javascript:`, so no bypass needed.
- Admin-view rendering chains; other posts as injection hosts.
- Cookie flags interplay (session is HttpOnly+SameSite=None — noted, not decisive here).

## What would increase impact in a real application
- **High-traffic content + trusted author chrome** (bylines, avatars, "verified"
  badges as links) — maximizes click-through on the poisoned element.
- **Authenticated readership** (intranet, courses, support portals) → clicks become ATO.
- **Moderation dashboards rendering the same link** → instant privilege escalation.
- **No link-confirmation interstitial** for off-site author URLs (none here).
- **Comment-write reachable from the XSS context** (CSRF token present in page) →
  wormability.

## Lab-scoped confirmed impact
`alert()` via stored author-link click — accepted on first poll.