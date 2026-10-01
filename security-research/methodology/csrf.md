# CSRF Methodology

## Core Concept

CSRF succeeds when a state-changing action is authorized by ambient credentials alone (session cookie, or a token/header the browser or a crafted page can attach without the victim's informed consent), and the server cannot independently verify the REQUEST — not just the SESSION — came from an intentional, same-origin user action. Every technique in this skill defeats a DIFFERENT layer of a defense-in-depth stack:

| Layer defeated | Shape |
|---|---|
| No defense at all | 1 |
| `SameSite` cookie attribute | 2 |
| Token-presence validation without session binding | 3 |
| Content-Type / CORS-preflight assumption | 4 |
| Token value/format validation logic | 5 |
| HTTP method/verb enforcement | 6 |
| Referer/Origin header validation | 7 |
| CORS configuration (reflected origin + credentials) | 8 |
| Single-request assumption (multi-step flows) | 9 |
| Auth-state assumption (pre-login actions) | 10 |
| Delivery-vector assumption (payload stored ON the target) | 11 |
| Protocol assumption (WebSocket handshake CSRF) | 12 |

A real target's defenses are rarely a single layer — test in the order above (cheapest/most-diagnostic first) and record which layers are present vs absent; a "protected" verdict requires every applicable layer to hold, not just the one you happened to test first.

## Security Boundary

Intended: state changes require verifiable user intent, from a request the server can prove originated same-site/same-origin, at every layer the application claims to enforce.
Violated when: a cross-origin page (or a stored payload, or a crafted WebSocket handshake) triggers the action and it's accepted — through any single missing or misconfigured layer above.

## Recognition Patterns

### Shape 1 — No defenses (original, lab-verified)
- Update forms with no csrf/token input (email-only change forms are the classic tell).
- Session cookies flagged `Secure; HttpOnly; SameSite=None` — cross-site sends allowed by design.
- Tokenless POST accepted (302 + state change on re-read); empty-csrf logins succeeding nearby (scope note, not target).

### Shape 2 — SameSite=Lax bypass via GET
- Session cookie `SameSite=Lax` (or unset, on a Lax-default browser) — Lax still attaches cookies on top-level cross-site **navigation** (`<a>` click, `window.location`, meta-refresh), just not on sub-resource loads (`fetch`/`XHR`/`<iframe>`/`<img>`).
- A state-changing action reachable via **GET** — this is the recognition trigger; Lax gives no leverage over POST-only actions.
- An endpoint accepting both GET and POST for the same mutation is the common root cause.
- Framework method-override input fields (e.g. a hidden `_method=POST` field honored by frameworks like Symfony/Laravel on a technically-GET or technically-any-method form submission) can turn an apparently-POST-only action into something a simple top-level GET-style delivery can still trigger — check for override fields before concluding "POST-only, Lax-safe."

### Shape 3 — Double-submit / self-supplied token bypass
- A CSRF token field in the form AND a matching value set as a separate cookie (the double-submit pattern).
- Recognition tell: logging in as a SECOND account and reusing the first account's (token, cookie) pair still succeeds — the check is "do these two match each other," not "is this token bound to THIS session."
- Header-based double-submit variants (token sent via both a cookie and a custom request header, e.g. `X-CSRF-Token`) may be vulnerable to CRLF injection into the header-construction logic on some server/proxy stacks, letting an attacker smuggle a second header value or split the response — a narrower, stack-specific variant of the same non-binding root cause.

### Shape 4 — Content-Type / CORS-preflight bypass
- A JSON state-changing endpoint defended only by the assumption that browsers can't cross-site POST JSON — no explicit token, no server-side Origin/Referer check.
- The server accepts `Content-Type: text/plain` (or `application/x-www-form-urlencoded`, or in some stacks `multipart/form-data` / `text/xml`) bodies that still parse as the expected structured format — any of these content-types can be emitted by a plain HTML form without triggering a CORS preflight (only "simple requests" skip preflight; a crafted form stays simple while its body coincidentally parses as JSON/XML server-side).

### Shape 5 — Token validation-logic bypass
- The token exists and IS checked, but the validation logic itself has an exploitable gap, independent of session-binding (contrast Shape 3, which is about binding):
  - Token removed entirely (parameter or value blanked) — some implementations fail open when the parameter is simply absent rather than wrong.
  - Token replaced with one of identical length/format but attacker-generated — reveals whether the check is format-only.
  - Token length varied by one character — probes off-by-one validation bugs.
  - Type-juggling / loose-comparison bugs in the validation code (e.g. PHP `==` treating certain differently-typed values as equal) — a stack-specific but recurring class of token-check bypass.
  - Attacker injects THEIR OWN valid CSRF token into the victim's session first (via a separate vulnerability, or via a shared/predictable token-generation flaw), then uses that known token in the forged cross-site request.
  - Predictable/weak token generation — collect multiple tokens across requests/sessions and check for static substrings, low entropy, or a derivable pattern (timestamp-seeded, sequential, or session-ID-derived) rather than assuming cryptographic randomness.

### Shape 6 — HTTP method/verb tampering
- The token or origin check is enforced on one HTTP method but not another the endpoint also accepts.
- Recognition tells: changing POST→GET and simply dropping the token; changing PUT/DELETE→POST (many REST-ish endpoints only gate the "primary" verb); presence of a custom method-override header (`X-HTTP-Method-Override`) or hidden form field the framework honors, letting a request LOOK like GET at the HTTP layer while being processed as POST/PUT/DELETE server-side (or vice versa) — the CSRF check and the actual processing logic may consult different signals for "what method is this."

### Shape 7 — Referer/Origin header validation bypass
- The server validates `Referer` and/or `Origin` instead of (or in addition to) a token.
- Recognition tells: the check can often be defeated by simply STRIPPING the header (some validation logic fails open on absence — many browsers/proxies/redirect chains can produce a request with no Referer at all, e.g. via a `<meta name="referrer" content="no-referrer">` delivery page, or an HTTPS→HTTP downgrade in the referrer chain); loose substring/regex matching on the Referer value accepting an attacker-controlled domain that merely CONTAINS the target's domain as a substring (e.g. `target.com` matched inside `target.com.attacker.com` or `attacker.com/target.com`) rather than validating it as the actual origin.

### Shape 8 — CORS misconfiguration + credentials
- A JSON/XHR API reachable cross-origin because the server reflects the requesting `Origin` header back in `Access-Control-Allow-Origin` (instead of an allowlist) AND sets `Access-Control-Allow-Credentials: true` — this combination lets a cross-site page read the AUTHENTICATED response, not just fire the state-changing request blind, which is a strictly worse outcome than classic CSRF (data exfiltration, not just forced action).
- Recognition tell: send a request with an arbitrary/attacker `Origin` header and check whether it's reflected verbatim in `Access-Control-Allow-Origin` alongside `Access-Control-Allow-Credentials: true`.

### Shape 9 — Multi-step / chained CSRF
- Each individual step of a multi-step workflow (e.g. a "start change" confirmation followed by a separate "confirm change" step) is, in isolation, adequately protected or low-risk — but the CHAIN as a whole can be driven end-to-end by an attacker page that fires each step in sequence (e.g. an `<iframe>` triggering step 1 via `onload`, then a script firing step 2).
- Recognition tell: any workflow with more than one state-changing request where a later step trusts that an earlier step already happened, without re-validating actor intent at each step independently.

### Shape 10 — Login CSRF
- The LOGIN endpoint itself has no CSRF protection (a common oversight, since "you're not authenticated yet, what's there to protect" is a frequent but flawed assumption).
- Attacker forges a login request using THEIR OWN credentials into the victim's browser — the victim is now authenticated as the attacker's account, and anything the victim subsequently enters (search history, saved payment info, uploaded documents) lands in an account the attacker controls and can later log into and read.

### Shape 11 — Stored CSRF
- The forged request/payload is stored ON the vulnerable application itself (e.g. an `<img>` or `<iframe>` tag saved into a comment/profile field that accepts HTML, whether via a separate HTML-injection bug or a permissive rich-text feature) rather than delivered from an external attacker-controlled page.
- Higher severity than off-site delivery: the victim is already authenticated to the target site when they view the page carrying the stored payload (no cross-domain trust/click needed), and they're statistically more likely to view a page on the site they use regularly than an external phishing link.

### Shape 12 — WebSocket handshake CSRF
- A WebSocket endpoint accepts a connection/subscription without first requiring an established, validated session — i.e. the WebSocket handshake itself isn't gated the way the equivalent HTTP endpoint would be.
- Recognition tell: an anonymous/cross-origin page can open a WebSocket connection to the target and successfully send messages/subscribe to channels that should require prior authentication, because the CSRF-equivalent check (session validation before allowing the handshake to do anything privileged) was never applied to the WS upgrade path.

## Prerequisites (test before attempting exploitation)

Recognition alone does not mean a shape is exploitable — several shapes are **conditional hypotheses** gated on a specific, testable precondition. A failed precondition is a valid negative result, not an inconclusive one — do not retry the shape with variations once the precondition itself is disproven.

- **Shape 2:** delivery must be a genuine top-level browser navigation. `fetch`/`XHR`/`<iframe>`/`<img>` never carry `SameSite=Lax` cookies.
- **Shape 3:** the attacker must actually be able to get a self-minted cookie into the victim's cross-site request — depends on the token cookie's own `SameSite`/`Secure`/`HttpOnly`/`Domain`/`Path` scoping. If it's itself `SameSite=Strict`/`Lax` and not attacker-writable cross-site, this shape does not apply. Confirm cookie scoping FIRST.
- **Shape 4:** the server's body parser must actually accept the alternate Content-Type as the expected structure — confirm on your OWN session (send a known-good body with the alternate Content-Type) before building any cross-site delivery.
- **Shape 5:** requires access to observe multiple token issuances (own account, or a second test account) to test predictability/format claims — a single-token observation can't establish a pattern.
- **Shape 8:** requires the target to actually reflect Origin AND set `Allow-Credentials: true` together — reflecting Origin alone (without credentials) is a much lower-severity finding (public-data CORS relaxation), not a CSRF-adjacent credential-exposure bug; do not conflate the two in reporting.
- **Shape 12:** requires the application to use WebSockets for privileged/state-changing operations at all — recon (`reconnaissance-skill/SKILL.md`) should confirm a `wss://`/`ws://` upgrade exists and carries authenticated traffic before this shape is even a candidate.

## Hypothesis

For each recognized shape whose prerequisite holds: the server will accept a forged or chained request carrying only attacker-controlled material (no victim secret, no victim token) — or a request whose defensive layer was misconfigured/absent for the specific method/content-type/protocol tested — and apply the state change (or credential-bearing response) as if the victim intended it.

## Testing Methodology

1. **Baseline (all shapes):** reproduce the target action as an authenticated legitimate request on YOUR OWN session first; record the exact method, headers, body shape, and cookie flags before touching anything cross-site.
2. **Shape 1 (full original procedure — restore this exact operational sequence, do not compress it):**
   a. Confirm tokenless success on your own session: strip the token entirely from the legitimate request, resubmit, and confirm 302 + state change on re-read.
   b. Read the session cookie flags explicitly (`SameSite=None` is the enabling condition for this shape).
   c. Build the MINIMAL auto-submit delivery page: a bare HTML `<form>` targeting the exact action URL with the exact field names, plus a `<script>` that calls `.submit()` on load — no extraneous markup.
   d. Store the delivery page on the exploit server (or equivalent hosting), then explicitly VERIFY the bytes are live and correct by fetching the stored page back yourself before delivering it.
   e. DELIVER the page to the victim — critically, ensure the delivered version carries the REAL, correct field values, not placeholders; deliver re-stores whatever is currently in the page, so a placeholder left in during testing will silently ship as the "exploit" and fail.
   f. Poll the exploit server's access log (`/log` or equivalent) for the victim's user-agent string; a hit with no corresponding solved-marker flip means the exploit fired but misfired (recheck field names/values), while no hit at all means the victim simply hasn't visited yet.
   g. Allow generous wait time (15+ minutes is a reasonable floor observed across multiple lab instances) before concluding a verified-correct setup has failed and reworking it — victim polling cycles are frequently slower than the instinct to "fix" a working exploit.
3. **Shape 2:** enumerate state-changing endpoints for GET-acceptance (`curl -X GET` the same URL a POST form targets). If GET-reachable, build a genuine top-level-navigation delivery (`<a>` auto-click, meta-refresh, or `window.location`); verify via DevTools `Sec-Fetch-Mode: navigate` (not `cors`/`no-cors`) before concluding Lax was bypassed.
4. **Shape 3:** mint your OWN token/cookie pair via your own session (never touch a captured victim token — that's session/token theft, a different and more severe bug). Confirm the cookie-scoping prerequisite, then replay the self-minted pair into a cross-site forged request.
5. **Shape 4:** confirm parser leniency on your own session (send the alternate Content-Type with a known-good body first). Only then build the cross-site `enctype="text/plain"` (or equivalent) form and verify no preflight fires in the network log.
6. **Shape 5:** matrix the token-manipulation variants (removal, length shift, type-juggling-prone comparison, reused/predicted token) ONE AXIS AT A TIME against the live validation; a single variant succeeding is enough to confirm the class, but record which variants failed too (useful for the report's precision).
7. **Shape 6:** matrix HTTP methods and override-header/field combinations against the same endpoint; a 200/302 + state change on a method or override combination that should have been rejected is the signal.
8. **Shape 7:** test Referer/Origin stripping (deliver via a `no-referrer` meta tag or an HTTPS→HTTP hop) and substring-style spoofing (attacker domain containing the target's domain as a substring) as independent variants; a validation regex that passes the substring case is a distinct, reportable logic bug from one that merely fails on missing headers.
9. **Shape 8:** send a probe request with an arbitrary `Origin` header; check the response for reflected `Access-Control-Allow-Origin` + `Access-Control-Allow-Credentials: true` together; if both hold, build a cross-site `fetch(..., {credentials:'include'})` PoC that reads back authenticated response data, not just fires the request blind — this is the higher-severity variant and should be demonstrated as such.
10. **Shape 9:** map the full multi-step flow first (recon discipline — read every step before touching any), then build a single delivery page that fires each step in sequence (e.g. chained `<iframe>` `onload` handlers), verifying end state only after the full chain completes.
11. **Shape 10:** forge a login request using attacker-owned credentials; verify the victim's browser session is now authenticated AS THE ATTACKER'S ACCOUNT (check the rendered identity post-delivery, not just a 302); note what victim-entered data would subsequently land in the attacker-controlled account for the impact write-up.
12. **Shape 11:** identify a stored-content surface that accepts raw HTML or an auto-triggering tag (`<img src="action-url">` for GET-based mutations, or a scripted auto-submit form for POST-based ones if script injection is also available); store it; verify it fires when viewed by a second (or privileged) account, per the cross-viewer proof standard shared with `xss-skill/SKILL.md` Shape 3.
13. **Shape 12:** attempt a WebSocket handshake from an unauthenticated/cross-origin context to the target's WS endpoint; if the handshake succeeds and privileged messages/subscriptions are accepted without an established session, this is confirmed; verify the specific message types affected (read vs state-changing) since impact differs substantially between the two.

## Verification

- Self-proof (own session state change) then victim-proof (victim UA + marker flip) for delivery-based shapes; the marker arbitrates, not exploit elegance.
- Shape 2: confirm genuine top-level navigation via DevTools `Sec-Fetch-Mode`; an iframe/img "success" is a false positive from cookie leakage elsewhere.
- Shape 3: confirm the forged pair was self-minted and never touched the victim's real session — reusing a captured victim token is a different bug (theft), not this design flaw.
- Shape 4: confirm via state re-read, not the 200 status of the forged submission alone.
- Shape 5: record which specific validation-logic variant succeeded (removal vs juggling vs prediction) — these are distinct root causes needing distinct remediation, even though they share a recognition pattern.
- Shape 8: confirm the reflected-Origin + credentials combination explicitly in the raw response headers, not inferred from a successful fetch alone — some browsers/tooling mask the distinction in convenience wrappers.
- Shape 12: confirm impact by the actual message/subscription content received or action taken over the WebSocket, not merely that the handshake succeeded (a successful handshake to an endpoint that then re-validates on every message is not, by itself, a bypass).

## Common Failure Modes

- Rewriting a working Shape 1 exploit during a slow victim polling cycle instead of waiting the full window.
- Delivering placeholder bodies (deliver re-stores — always send real content).
- Assuming `SameSite` defaults instead of reading the actual `Set-Cookie` flags.
- Testing Lax-bypass via `fetch`/`XHR`/`<iframe>`/`<img>` instead of true top-level navigation (Shape 2).
- Treating Shapes 3/4 as universally exploitable without confirming their gating prerequisite first — both fail often, and a failed prerequisite is a valid negative, not grounds for retrying variations.
- Testing only ONE HTTP method/Content-Type/header combination and concluding "protected" — Shapes 5–7 specifically exist because a single passed check doesn't mean every equivalent check passed.
- Conflating Shape 8 (reflected-origin + credentials, a data-exposure bug) with plain permissive CORS (no credentials, much lower severity) in reporting.
- Missing multi-step chains (Shape 9) by testing each step in isolation and declaring each one individually "low risk" without testing the chain end-to-end.
- Assuming login endpoints are out of scope for CSRF because "there's no session to protect yet" (Shape 10's whole premise is that this assumption is wrong).
- Treating WebSocket endpoints as outside CSRF scope entirely because they're "not HTTP forms" (Shape 12).

## Impact Considerations

- Shape 1: any undefended state-changing action is forgeable.
- Shape 2: GET-reachable mutations are forgeable via a single clicked link — no JS required.
- Shape 3/5: false sense of security — a visible token misleads reviewers; report explicitly which specific validation gap made it exploitable.
- Shape 4: expands CSRF risk to "API-only, so CSRF-safe" assumptions.
- Shape 6: reveals that defense applied to one verb doesn't transfer to another the same endpoint accepts.
- Shape 7: Referer/Origin-only defenses are inherently weaker than token-based ones; report this as a design-level finding even where the specific bypass fails, if no token exists as a second layer.
- Shape 8: strictly worse than classic CSRF — cross-site JS can READ authenticated response data, not just trigger actions; treat as a data-exposure finding, escalate severity accordingly.
- Shape 9: chain impact can exceed any single step's individual risk rating — assess the CHAIN'S end state, not each step separately.
- Shape 10: victim ends up transacting inside an attacker-controlled account — anything they subsequently enter (search terms, saved cards, uploaded files, browsing history tied to that account) is attacker-visible; this can be a severe confidentiality impact disguised as a low-looking "just a login" bug.
- Shape 11: removes the cross-domain/phishing-click requirement entirely — the payload fires simply by the victim using the site normally, which typically increases both likelihood and effective severity versus off-site delivery.
- Shape 12: WebSocket CSRF against an unauthenticated handshake can let anonymous actors reach business logic that assumed a session was always established first — the CVE-2025-41254 case study below is the concrete real-world shape of this.

## Lessons Learned

- From PortSwigger "CSRF vulnerability with no defenses": tokenless email POST proven on self → minimal auto-submit → store/verify/deliver → victim at ~15 min → `is-solved`. SameSite=None read first; real-body delivery; patience over rewrites. (Shape 1 — lab-verified.)
- (Additive, not lab-sourced) Shapes 2–12 are documented, sourced bypass classes from current public research and disclosed CVEs (see Sources below), recorded as hypotheses gated on explicit prerequisites where applicable. Each requires independent verification per `verification-skill/SKILL.md`, and each has a well-defined "does not apply here" outcome that must be recorded rather than retried indefinitely.

## CVE Case Studies (real-world, not lab-sourced — hypothesis-generation material only)

> These are cited to ground Shapes above in real, disclosed vulnerabilities — not to be treated as proof for any current target. Use them the same way a PortSwigger lab note is used: as a pattern to test for, never as evidence a target shares the same flaw. Sourced current as of this skill's last research pass (September 2026); re-search before relying on this list as "latest" in a future session, since new CVEs publish continuously.

### 2026 (current-year, most relevant to present-day recon)

- **CVE-2026-44613** (Apache Zeppelin, fixed in 0.12.1): Zeppelin's default CORS configuration allowed cross-origin, CREDENTIALED, state-changing requests, and additionally accepted `text/plain` request bodies for what should have been JSON-only endpoints — letting a remote attacker reach both Zeppelin's REST API and its WebSocket endpoints via a lured victim. This is a single real-world finding that spans THREE shapes in this skill at once: Shape 8 (CORS + credentials), Shape 4 (`text/plain` content-type bypass), and Shape 12 (WebSocket endpoints affected too) — a strong illustration that these shapes are not mutually exclusive and a real target's root cause is often "the same misconfiguration defeats several layers simultaneously," not one isolated bug per layer.
- **CVE-2026-93456** (django-page-cms, through 2.0.13, CVSS 8.2 High): five admin mutation views were explicitly CSRF-exempted in the application's own view code, letting forged requests from a signed-in editor's browser modify page content. A concrete real-world instance of Shape 6/Shape 1 territory — the framework's CSRF protection existed and worked elsewhere in the app, but specific endpoints opted out, which is a distinct and very findable root cause (grep the codebase/behavior for exemption decorators or inconsistent per-endpoint enforcement, not just "does the framework have CSRF protection at all").
- **CVE-2026-84084** (IBM Guardium Data Protection 12.2, CVSS 8.8 High): a CSRF vulnerability allowing a remote attacker to bypass security restrictions, disclosed September 18, 2026 — reinforces that CSRF in privileged administrative/security-tooling products remains a currently and actively disclosed class, not a legacy concern.
- **CVE-2026-78280** (Hash Form, CVSS 4.3 Medium): unauthenticated CSRF, disclosed August 2026 — a lower-severity but illustrative example of Shape 1 continuing to surface in actively maintained plugins.
- **CVE-2026-1169** (Birkir Prime CMS, up to 0.4.0.beta.0): a disclosed-but-unpatched CSRF at time of writing, publicly reported via a GitHub issue with no maintainer response yet — a reminder that "disclosed" and "fixed" are different states worth distinguishing when a real-world case study is used to argue urgency in a report.
- **Jenkins Pipeline: Groovy Plugin** (disclosed 2026-06-24): CSRF in the Pipeline Snippet Generator allowing attackers to instantiate types beyond intended Pipeline steps via job/system configuration — illustrates CSRF chaining into a CONFIGURATION/code-execution-adjacent primitive in CI/CD tooling, worth noting when a target embeds Jenkins-family components.

### 2024–2025 (prior-year, retained for pattern diversity)

- **CVE-2025-41254** (Spring Framework, `spring-websocket`): a WebSocket CSRF vulnerability allowing payloads to reach STOMP controllers without an established session first, letting anonymous users execute business logic that assumed a session had already been created. Directly informs Shape 12, and is the same underlying pattern CVE-2026-44613 above shows independently in a different product.
- **CVE-2025-29722** (Commercify v1.0, open-source e-commerce): missing CSRF protection on a settings-update endpoint (`/update_settings`). Directly informs Shape 1's continued real-world relevance.
- **CVE-2025-26206** (Sell Done Storefront v1.0): critical-rated CSRF from a complete absence of anti-CSRF tokens, enabling privilege escalation.
- **WordPress "Sign-up Sheets" plugin** (pre-2.4.0): a CSRF nonce present but not properly VALIDATED on the sign-up-deletion action — a real-world instance of Shape 5's "token exists but the validation logic has a gap" pattern.
- **GHSA-9qpj-gvc6-34rv** (idccms v1.35): a straightforward admin-panel CSRF (`admin/vpsCompany_deal.php`), reinforcing that admin-context CSRF remains commonly found and high-impact when the victim is a privileged account.

## Related Concepts

- methodology/verification.md (self-then-victim proof, marker arbitration)
- methodology/authentication.md (session mechanics, cookie flags, login-flow specifics relevant to Shape 10)
- `xss-skill/SKILL.md` (Shape 11's stored-delivery mechanism overlaps with stored-XSS cross-viewer proof discipline; a stored CSRF payload delivered via an HTML-injection bug may itself BE a stored-XSS finding — do not double-report the same root cause as two separate vulnerabilities without distinguishing the injection point from the CSRF consequence)
- `client-side-skill/SKILL.md` (auto-submit/auto-navigation delivery machinery — Shape 2's top-level-navigation requirement is a specific case of that skill's general model; do not re-derive delivery mechanics here beyond what's specific to CSRF)
- `api-security-skill/SKILL.md` (Shape 8's CORS-misconfiguration overlap; Shape 12's WebSocket-as-undocumented-API-surface overlap)
- OAuth/SSO forced-linking (`oauth-sso-skill/SKILL.md`) — same deliver/poll machinery as Shape 1, different trust flaw being defeated; useful contrast for understanding what CSRF's ambient-credential model does and doesn't share with token-based identity flaws.

## Sources

- PortSwigger lab: CSRF vulnerability with no defenses (knowledge/portswigger/labs/csrf-no-defenses.md) — Shape 1, lab-verified.
- Shapes 2–11 bypass technique synthesis, current public research (accessed 2025): "CSRF Bypass Techniques" (token manipulation, method/header tampering, content-type bypasses, double-submit exploits) — x86ciPher, Feb 2025; "Breaking SameSite: Advanced CSRF Bypass Techniques" — Agarwaldaksh, Apr 2025; "Bypassing CSRF Protections: A Deep Dive" (double-submit-cookie binding tests, text/plain JSON smuggling) — Itamar Yochpaz, May 2025; "CSRF Bypass Techniques (Deep Dive)" (Referer/CORS/multi-step/login-CSRF matrix) — Ikajakam, Oct 2025; OWASP Foundation "Cross Site Request Forgery (CSRF)" reference page (stored-CSRF concept, Shape 11).
- Shape 12 case study: CVE-2025-41254 (Spring Framework `spring-websocket` CSRF), HeroDevs Vulnerability Directory, Oct 2025; CVE-2026-44613 (Apache Zeppelin), OX Security disclosure, Aug 2026.
- CVE Case Studies section (2026): CVE-2026-44613 (Apache Zeppelin — OX Security), CVE-2026-93456 (django-page-cms), CVE-2026-84084 (IBM Guardium Data Protection — TheHackerWire), CVE-2026-78280 (Hash Form — TheHackerWire), CVE-2026-1169 (Birkir Prime — SentinelOne Vulnerability Database), Jenkins Pipeline: Groovy Plugin CSRF (CVEdetails.com, disclosed 2026-06-24).
- CVE Case Studies section (2024–2025, retained): CVE-2025-29722 (Commercify), CVE-2025-26206 (Sell Done Storefront), WordPress "Sign-up Sheets" plugin CSRF-nonce-validation advisory (Tenable CVE feed), GHSA-9qpj-gvc6-34rv (idccms v1.35).
- All CVEs cited as real-world grounding, not lab-verified evidence for any specific target.
- Flagged for lab-backed validation when encountered on a live mission, per the "hypothesis, not proof" rule in `impact-analysis-skill/SKILL.md`.
