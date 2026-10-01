# Impact — DOM XSS in innerHTML(location.search)

## Applicability reasoning
The input (`search` query param) reaches `element.innerHTML` — a browser-executable
context (fragment parser → live elements → event handlers) in the victim's browser on
the application origin. Relevant categories are therefore **client-side**. The payload
never reaches any server-side consumer (zero reflection in responses), so server-side
categories are structurally excluded.

## CONFIRMED
- **Client-side code execution at the application origin** via event-handler injection
  (`<img src=x onerror=…>` proven; title-mutation + real-browser `alert(1)` + lab
  acceptance).
- Execution requires **one victim page load of a crafted URL**; the `onerror` vector
  needs no further interaction (image error fires on parse).

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session/data theft and account takeover** in any authenticated context the vulnerable
  page is reachable in (cookies, CSRF tokens, page secrets exfiltrated; actions performed
  as the victim).
- **Admin compromise** if a privileged user opens the crafted search URL.
- **Same-origin phishing overlays** (inject a fake login form into the page DOM).
- **Keylogging / form capture** via injected handlers on existing or injected inputs.
- **Alternative live vectors through the same sink** (not fired, same primitive):
  `<svg onload=…>`, `<details ontoggle=…>`, `<iframe srcdoc=… onload=…>`,
  `<img src=x onerror=…>` variants — any event-handler-carrying element.

## NOT APPLICABLE (structurally excluded or directly disproven)
| Category | Verdict | Basis |
|---|---|---|
| `<script>`-tag execution via this sink | NOT APPLICABLE (disproven) | spec neuter; negative test shows inert insertion |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | input never leaves the browser; zero server reflection |
| Stored/persistent delivery | NOT APPLICABLE | attack dies with the page load; fresh crafted link per victim |
| State-changing / CSRF / authz impact of THIS primitive | NOT APPLICABLE | search is a side-effect-free GET; no state-changing endpoint in the chain |
| document.write page-replacement quirk | NOT APPLICABLE | different sink; innerHTML cannot tear down the document |

## What would increase impact in a real application
- **Authenticated page** carrying the same sink → one click = account takeover.
- **Admin-facing search** (support consoles, log viewers rendering query into innerHTML)
  → privilege escalation to admin.
- **Stored link**: if the crafted search URL gets persisted anywhere rendered as a link
  (recent searches, shared reports, admin audit views) → chains link-based DOM XSS into
  stored delivery.
- **Absence of CSP** (true here) keeps `on*` handlers viable; a strict
  `script-src`/`trusted-types` policy would force narrower vectors or kill the sink.
- **Richer page**: more secrets in DOM / more same-origin iframes reachable → larger
  theft surface for the same one-click primitive.

## Lab-scoped confirmed impact
Trigger `alert()` through the search page — delivered via `<img onerror>`.