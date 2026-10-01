# Impact — DOM XSS in jQuery selector sink (hashchange, victim-delivered)

## Applicability reasoning
The input (`location.hash`) reaches jQuery `$()` HTML construction → detached-element
event execution in the victim's browser on the application origin. Relevant categories
are therefore **client-side, victim-delivered**. The fragment never reaches the server
(fragments are client-only), so server-side categories are excluded. Delivery needs a
lure page + a fragment change, and framing is permitted (no `X-Frame-Options` observed).

## CONFIRMED
- **Victim-browser code execution at the application origin**: planted `print()`
  executed in the victim's Chrome (access-log visit + `is-solved`); the primitive is
  arbitrary JS (CDP proof ran `document.title=` assignment through the same path).
- **Full delivery chain works cross-origin**: attacker page on `exploit-server.net`
  drives code in `web-security-academy.net` origin via framed fragment mutation — no
  cookies/credentials of the attacker needed; victim context is used.
- **Event-gating confirmed as the delivery constraint**: cold link to `/#payload` is
  inert; only a post-load fragment change reaches the sink.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover**: arbitrary JS in victim origin — steal cookies
  (non-HttpOnly), tokens, DOM secrets; perform authenticated actions as the victim.
- **Multi-step victim workflows**: keylogging, transaction forgery, admin-action abuse
  if the victim is privileged.
- **Alternative change triggers** (same sink, untested variants): `location.hash=`
  assignment from another framed context, back/forward fragment navigation, links that
  alter the fragment post-load — any post-load fragment change suffices.
- **Other auto-firing constructed elements** through the same sniff: `<svg onload>`,
  `<details ontoggle>` (needs toggle), `<iframe srcdoc/onload>`, `<video><source
  onerror>` — any element whose construction alone fires a handler.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | fragment never leaves the browser; zero server reflection possible |
| Load-time execution (cold crafted link) | NOT APPLICABLE (disproven) | fresh-target test: handler never runs without a change event |
| Markup-parser payloads (`document.write`-style `<script>`) | NOT APPLICABLE | sink is `$()`, not an HTML parser; `<script>` construction without insertion does not run here |
| Stored/persistent delivery | NOT APPLICABLE | dies with the victim page view; fresh lure per victim |
| CSRF / state-change abuse via THIS primitive | NOT APPLICABLE | no state-changing endpoint in the chain |
| Open redirect | NOT APPLICABLE | no navigation sink involved |

## NOT TESTED
- Exact jQuery-version boundary (1.8.2 confirmed; 3.x behavior reasoned from the
  tightened sniff regex, not executed).
- Whether `jqueryMigrate` alters the path (it only logged its version; no evidence of
  interference).
- Other pseudo-selectors / Sizzle paths with untrusted input on this build.
- Victim browsers other than the lab's Chrome 151 bot.

## What would increase impact in a real application
- **Authenticated app**: victim session = account takeover; reflected DOM XSS becomes
  a one-click ATO when the lure is plausible.
- **Framable sensitive pages** (no `X-Frame-Options` / CSP `frame-ancestors`): enables
  the silent iframe-mutation delivery used here; proper framing controls would force
  noisier link-based delivery.
- **Hash-driven features everywhere** (tabs, modals, scroll-spy, filters reading
  `location.hash` into `$()`): one audit finding class, many pages.
- **Privileged victims** (admins opening "look at this" links) → privilege escalation.
- **Exploit-kit reuse**: the iframe-mutator is a generic wrapper — any hashchange-gated
  DOM sink on any framable page falls to the same delivery template.

## Lab-scoped confirmed impact
`print()` in the victim's browser via delivered iframe exploit — platform accepted.