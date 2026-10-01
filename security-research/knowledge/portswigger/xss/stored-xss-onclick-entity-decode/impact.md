# Impact — Entity-smuggled breakout in stored onclick

## Applicability reasoning
The input (`website`) is persisted with `&` unencoded and rendered into an `onclick`
handler string; the victim parser decodes `&apos;` to a string terminator, and the
injected `-alert(1)-` runs when any viewer clicks the author name (native blog UI).
Relevant categories: **client-side, stored-delivered, click-gated, decode-enabled**.
No non-HTML consumer; comment POST is CSRF-protected (attacker's own session).

## CONFIRMED
- **Stored click-gated code execution for every future viewer** (entity breakout at
  DOM level + sync-click execution proof + real `alert(1)` + acceptance). One store,
  indefinite.organic reach via trusted page chrome.
- **Escaper bypass without touching defended chars**: `'"<>\` all handled — the
  attack uses ONLY the unhandled `&` plus inert alphanumerics. Defenses fall to
  unlisted characters, not to filtered ones.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Mass session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as each clicking victim).
- **Admin/moderator compromise** via comment-review views (same JSON, same decode).
- **Self-propagation (stored-XSS worm)** (write primitive + in-page CSRF tokens;
  click-gating slows but doesn't stop worm spread on high-traffic posts).
- **Other entity smuggles** through the same hole (`&#x27;`, `&quot;` into
  double-quoted JS/attrs, `&colon;`/`&Tab;` into `javascript:` scheme positions —
  same `&`-raw root, untested variants).
- **Phishing overlays / keylogging / credential capture** at readership scale.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Direct quote/backslash/tag breakout | NOT APPLICABLE (disproven) | `\'`, `&quot;`, `&lt;`, `\\` — all contained |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | JSON store only |
| CSRF against comment POST via THIS primitive | NOT APPLICABLE | per-session token; own session used |
| Load-time execution | NOT APPLICABLE | handler needs the click (no autofocus on anchors) |

## NOT TESTED
- Alternate entity spellings (`&#39;`, `&#x27;`, `&quot;`-in-double-quotes).
- Other posts as hosts; admin-view chains; CSP variants (none here).
- `href`-twin weaponization (inert URL navigation — no decode-to-code path).

## What would increase impact in a real application
- **High-traffic user content with linkified fields** (author URLs, social links,
  "source" citations rendered into handlers/analytics calls).
- **Authenticated readership** (intranet, courses, support portals) → clicks = ATO.
- **Moderation dashboards** rendering the same stored values → privilege escalation.
- **Tracker/analytics-in-markup patterns** (`onclick="track('USER')"` is an industry
  commonplace — every instance with raw `&` is this lab).
- **Missing HttpOnly** → trivial cookie read in handler.

## Lab-scoped confirmed impact
`alert()` via stored author-link click — accepted.