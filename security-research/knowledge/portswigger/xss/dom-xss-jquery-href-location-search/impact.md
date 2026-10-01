# Impact — DOM XSS in jQuery href(location.search)

## Applicability reasoning
The input (`returnPath`) reaches an anchor `href` — a navigation-execution context:
`javascript:` targets execute in the victim's browser on the application origin, but
ONLY after a click. Arbitrary non-script targets additionally redirect the victim
off-site. Relevant categories are therefore **client-side + open-redirect**. The value
has zero server reflection, so server-side categories are excluded.

## CONFIRMED
- **Click-gated client-side code execution at the application origin**:
  `javascript:` href planted from the query string; code runs in page origin on click
  (CDP click proof + real-browser `alert(1)` + lab acceptance).
- **Open redirect via the same sink**: arbitrary `https://` target accepted verbatim
  (`href="https://evil.example/phish"` proven) — clicking "Back" navigates off-site.
  Mechanism confirmed end-to-end (attribute value → browser navigation semantics).

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** in any authenticated context: planted JS runs
  with victim cookies/DOM access; exfiltration + authenticated actions as victim.
- **Admin compromise** if a privileged user follows the crafted feedback link and
  clicks "Back".
- **Phishing via the redirect**: attacker crafts `/feedback?returnPath=https://evil…`
  — the visible domain in the lure is the TRUSTED app; only post-click does the victim
  land on the look-alike. "Back"/"Cancel"/breadcrumb links are ideal because users
  click them reflexively.
- **Combined lure**: link text/URL shows the legitimate app; either the JS runs (XSS)
  or the victim lands on a credential-harvesting clone (redirect) — attacker picks per
  victim by choosing the scheme.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Load-time / error-time execution | NOT APPLICABLE | nothing executes until click; `.attr()` parses nothing |
| HTML-markup payloads (`<script>`, `<img onerror>`) | NOT APPLICABLE (disproven shape) | attribute assignment never parses markup |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | zero server reflection; no server consumer |
| Stored/persistent delivery | NOT APPLICABLE | dies with the page; fresh link per victim |
| CSRF against `/feedback/submit` via THIS primitive | NOT APPLICABLE | submit endpoint is CSRF-token protected and untouched by this chain |
| `data:`-URI origin-context theft | NOT APPLICABLE | navigates to a new document, losing app-origin context |

## NOT TESTED
- The `/feedback/submit` endpoint's own security (CSRF token observed; its validation,
  stored-feedback rendering, and admin-view chains are a separate assessment surface).
- `vbscript:`/other scheme behavior (browser-dependent, legacy; `javascript:` suffices).
- Whether other pages consume `returnPath`-style params into other sinks (only
  `/feedback` mapped).

## What would increase impact in a real application
- **Plausible link text**: "Back to dashboard", breadcrumbs, logos, OAuth "cancel"
  links — anything users click without reading the URL.
- **Authenticated app**: one click = session theft/ATO; combine with the redirect for
  credential phishing when JS is blocked.
- **Widespread parameter**: if the same `returnPath` pattern is copied across login,
  logout, error, and payment flows (common), one finding = many exploit pages.
- **Missing confirmation interstitial** on off-site navigation (none here).
- **No CSP `navigate-to`** (no CSP at all here) — `navigate-to` could blunt the
  redirect half while scheme validation remains the XSS fix.

## Lab-scoped confirmed impact
Trigger `alert()` through the feedback page — delivered via `javascript:` href + click.