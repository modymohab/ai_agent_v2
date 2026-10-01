# Impact — DOM XSS in document.write(location.search)

## Applicability reasoning
The input (`search` query param) reaches **`document.write`** — a browser-executable
context (HTML parser → DOM → script/event execution) in the victim's browser on the
application origin. Therefore the relevant impact categories are **client-side**.
Server-side categories are structurally not applicable because the payload never reaches
a server sink (the server response is fixed for any query).

## CONFIRMED
- **Client-side code execution at the application origin**:
  - stored-as-script vector: written `<script>` executes (title-mutation proof).
  - scriptless vector: `autofocus onfocus` event handler on the injected `img` executes.
  - real-browser `alert(1)` firing accepted by the lab.
- Execution requires **one victim page load of a crafted URL** (`?search=…`) — a
  link-based attack; no additional interaction for Vector 1 (script runs on parse).

## PLAUSIBLE (same primitive, not separately demonstrated here)
- **Theft of any data the page/JS can reach** — session cookies, CSRF tokens, in-page
  secrets, DOM of same-origin iframes — and exfiltration to attacker domain.
  Credentials theft, authenticated-action abuse as the victim.
- **Page-replace / phishing via document.write quirk**: after load, `document.write`
  destroys the document — attacker can fully replace the page with a look-alike login
  form on the same origin (bypasses origin-based phishing heuristics).
- **Keylogging / credential capture** via injected handlers on any future forms.

## NOT APPLICABLE (structurally excluded)
| Category | Verdict | Basis |
|---|---|---|
| Server-side code/command execution | NOT APPLICABLE | payload never leaves the browser; no server sink |
| Server-side request behavior / SSRF / XML / filesystem / SQL | NOT APPLICABLE | no input reaches SQL/OS/URL/XML/file consumers |
| Unauthenticated state changes | NOT APPLICABLE | no state-changing endpoint involved; vulnerability is a pure client-side read of a GET param |
| Stored/mass-delivery persistence | NOT APPLICABLE | attack dies with the page load; re-delivery requires a new crafted link per victim |
| SSR XSS (same param, `<h1>` context) | NOT APPLICABLE | server HTML-encodes reflection (verified) |

## What would increase impact in a real application
- **Authenticated context**: if the vulnerable page is behind auth and contains
  sensitive data/tokens, one click → full account takeover.
- **Privileged viewers**: if admin reaches the same search page → admin-level takeover.
- **Absence of CSP** (true here) maximizes payload choice; a strict CSP would force
  scriptless vectors (svg/image event handlers, style-based), which are still viable.
- **Absence of `X-Content-Type-Options`/trusted-types**; presence of `trusted-types`
  would break `document.write` entirely (its API rejects untrusted strings).
- **Secondary sinks**: the same search value might later be consumed by another JS sink
  (e.g., stored recent-searches rendered with innerHTML) → chains into stored DOM XSS.
- **Delivery mechanics**: combine with phishing, URL shorteners, or an earlier stored link
  injection to increase click rate.
- This lab's cookie is `HttpOnly`+`SameSite=None` — HttpOnly does not impede DOM XSS
  (page code itself is what we run); `SameSite=None` is moot for a same-page DOM bug.

## Lab-scoped confirmed impact
Trigger `alert()` through the search page — delivered via both `<script>` and event-handler
payloads.