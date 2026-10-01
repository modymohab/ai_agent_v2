# Impact — Reflected XSS into attribute (`<>` encoded)

## Applicability reasoning
The input (`search` query param) is server-rendered into a double-quoted HTML attribute
with quotes unencoded, yielding event-handler execution in the victim's browser on the
application origin upon crafted-URL visit (autofocus: no click needed). Relevant
categories are therefore **client-side, link-delivered**. No storage, no state change,
no non-HTML server consumers exist in this chain.

## CONFIRMED
- **Zero-click client-side code execution at the application origin** on crafted-URL
  visit: `autofocus` focuses on load → `onfocus` fires (title-mutation + focus-state
  proof; real-browser `alert(1)` + lab acceptance).
- **Per-request delivery, no persistence needed**: each view of the crafted URL
  re-fires; the attacker needs no account, no stored content, no prior interaction.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** in any authenticated context (cookie exfil,
  token theft, authenticated actions as the victim).
- **Admin compromise** via a crafted link opened by a privileged user.
- **Same-origin phishing overlays / credential capture / keylogging** injected into
  the page DOM.
- **`<script>`-free filter-evasion variants** through the same hole (any handler:
  `onfocus`, `onmouseover`, `onchange`+`autofocus`, etc.) — same sink, interchangeable
  triggers.
- **Wider template exposure**: the `<>`-only encoding habit, if shared by other
  templates/params on a real app, multiplies reflection points (each needs its own map).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Tag injection (`<script>`, `<img>`, `<svg>`) | NOT APPLICABLE (disproven) | `<>` entity-encoded in both reflections |
| `'`-quote breakout | NOT APPLICABLE (structural) | attribute is double-quoted; `'` is inert data |
| Stored/persistent delivery | NOT APPLICABLE | reflection exists only in the crafted response; no storage path observed |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | input reaches only the HTML template; no other consumer |
| State-change / CSRF / authz impact of THIS primitive | NOT APPLICABLE | search is a side-effect-free GET |
| Click-gated execution | NOT APPLICABLE (better than that) | autofocus removes the interaction requirement entirely |

## NOT TESTED
- Other parameters/endpoints sharing the template (only `search` on `/` mapped).
- CSP-hardened variants (no CSP here to bypass).
- `X-Frame-Options: SAMEORIGIN` relevance — present but immaterial to this self-URL
  vector (matters only for framing-based delivery, which this attack doesn't need).

## What would increase impact in a real application
- **Authenticated app**: one link preview/click = ATO; reflected XSS is the classic
  session-theft primitive.
- **High-trust lure context**: password-reset, support, or notification flows
  echoing parameters into attributes — users click without suspicion.
- **Missing `HttpOnly`** on session cookies → trivial `document.cookie` theft (here
  cookies ARE HttpOnly, so theft must go through in-context actions — still fully
  viable, just less trivial).
- **Long-lived sessions / no re-auth for sensitive actions** → stolen context stays
  useful.
- **Widespread `<>`-only encoding** across the codebase → many exploitable reflections
  from one bad helper (audit the encoder, not just the page).

## Lab-scoped confirmed impact
Trigger `alert()` through the search page — delivered via attribute breakout +
autofocus, first poll already solved.