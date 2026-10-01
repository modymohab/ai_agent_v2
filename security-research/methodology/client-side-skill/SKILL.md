# Client-Side Skill

> Dedicated capability built from existing project knowledge. Source template `../client-side.md` is a header-only stub; this skill is organized from the client-side knowledge that already exists in this repository (XSS class knowledge, hunting references, and related class skills). See `# Source / Derivation`.

## Purpose

Organize and drive client-side security research: attacks that execute inside a victim's **browser** and depend on browser-side processing of attacker-influenced data — DOM-based behavior, client-side sources and sinks, browser security controls (CSP, `SameSite`), open redirect (navigation sinks), and browser-trust boundaries that let attacker input become active content or a credential-bearing navigational side effect.

This is a capability layer. It points to the class skills that hold the tested methodology (`../xss-skill/SKILL.md`, `../csrf-skill/SKILL.md`, `../oauth-sso-skill/SKILL.md`, `../authentication-skill/SKILL.md`, `../access-control-skill/SKILL.md`, `../business-logic-skill/SKILL.md`) and to the rich client-side class knowledge under `../../knowledge/portswigger/xss/`. It must never be treated as a replacement for those skills.

## Scope

In scope (where the knowledge base documents them):

- DOM XSS / client-side sink execution — sources, transformations, sinks, execution gating.
- Browser security controls that are attacker-bypassable: CSP (policy injection), `SameSite`/`HttpOnly` cookie flags.
- Open redirect via client-side navigation sinks, and redirect-based trust chains (SSRF filter bypass).
- Client-side trust of data that influences later security decisions (stored content rendered to privileged viewers; client-supplied values that become part of later flows).
- CSRF/forced-linking delivery machinery that runs in the victim's browser (auto-submit, auto-navigation).

Out of scope (owned by other skills):

- Server-rendered, server-encoded reflection mechanics — see `../xss-skill/SKILL.md` and `../injection-skill/SKILL.md`.
- Server-side request handling of any kind — see `../server-side-skill/SKILL.md`.
- Authorization decision logic on the server — see `../access-control-skill/SKILL.md`.

## Inputs

- Attack-surface model entries for **client-side functionality** (from `../reconnaissance-skill/SKILL.md`, e.g. `../../../skills/security-recon/references/javascript-recon.md` sends client-side signals to the hunter).
- Client-side sources observed in page JS: URL components (`location.search`, `location.hash`, `document.URL`, `document.referrer`), `window.name`, storage (`localStorage`/`sessionStorage`/cookies), `postMessage` handlers.
- Candidate sinks: DOM write/HTML insertion/URL navigation/JS-execution functions.
- Response bytes (headers incl. CSP, cookies incl. `SameSite`/`HttpOnly`, HTML/JS) from recon and baseline requests.
- Existing XSS class knowledge: `../../knowledge/portswigger/xss/class-dom-xss.md`, `../../knowledge/portswigger/xss/class-csp-bypass.md`, `../../knowledge/portswigger/xss/class-reflected-xss.md`, `../../knowledge/portswigger/xss/class-stored-xss.md`.

## Workflow

1. **Map client-side surface.** From JS recon (`../../../skills/security-recon/references/javascript-recon.md`), record routing, redirect/navigation logic, message handlers, storage reads, and dangerous client-side sinks. Do not treat client-side references as proof of server-side behavior.
2. **Enumerate client-side sources and sinks.** For each page/SPA module, list sources present and the sink functions they can reach, following the source→transformation→sink model in `../xss-skill/SKILL.md` and `../../knowledge/portswigger/xss/class-dom-xss.md`.
3. **Characterize the sink, not just the payload family.** Sink semantics dictate the payload (`innerHTML` neuters `<script>`; navigation sinks take URIs not markup; `$()` selectors flip select→create on smuggled markup). Record the execution gate: parse-time vs click-gated vs `hashchange`/`popstate`/`message`-event gated.
4. **Classify the trust boundary.** Determine whether data crosses into active content (HTML/JS), into a navigation target, or into a later processing step. Crossed boundary → hypothesis: XSS (script execution), open redirect, CSP bypass, or trusted-data confusion.
5. **Hypothesis → controlled test.** Smallest test that answers the question. For DOM sinks this requires **browser execution proof**, not response inspection — DOM sinks are invisible in the HTTP response.
6. **Prove with side-effect payloads.** Prefer numeric, non-blocking side effects (`document.title=N`); `alert()` freezes headless DOM dumps (a hang is a symptom, not an assertion).
7. **Verify** per `../verification-skill/SKILL.md` (separate SSR vs DOM reflection; fresh-session re-fetch; CDP + settle for focus events; assert on decoded values, never raw source grep).
8. **Document evidence and pass a candidate** to `../verification-skill/SKILL.md` (or hand the signal to `../impact-analysis-skill/SKILL.md` once verified).

## Detection / Hypothesis Areas

Only the following areas are documented by the knowledge base. Everything else is a coverage boundary (see `# Coverage Boundaries`).

### DOM XSS — client-side sources and sinks (detailed, supported)

Class knowledge in `../../knowledge/portswigger/xss/class-dom-xss.md` documents the source→sink model (DOM XSS: client-side script reads an attacker-controllable source and passes it unsanitized to a sink):

- **Sources:** `location.search`, `location.hash`, `document.URL`, `document.documentURI`, `document.referrer`, `window.name`, `postMessage`, `localStorage`/`sessionStorage`/cookies, redirect `returnPath`/`next` parameters.
- **Sinks:** HTML injection (`innerHTML`/`outerHTML`/`insertAdjacentHTML`), `document.write`/`writeln`, `eval`/`Function`/`setTimeout(string)`, anchor/`href`/`src`/`srcdoc` (navigation/URL sinks), jQuery `.html()` and `$()` selector sinks, `location=` / `window.open` (redirect sinks).
- **Execution-moment matrix:** `document.write` fires at parse time; event-handler and element-based payloads fire at event dispatch; navigation sinks fire only on click or on programmatic navigation; `hashchange`/`popstate`/`message`-gated sinks fire only when the event is manufactured.
- **Browser-vs-server distinction:** DOM sinks are invisible in the HTTP response — execution proof is mandatory; never confuse DOM reflection with (possibly encoded) server-side reflection.

### Open redirect via navigation sinks (supported, narrow)

Navigation sinks that take URIs (`href=.attr`, `location=`, `window.open`) accept `javascript:` and external/http(s) targets interchangeably; test both schemes (see `../../knowledge/portswigger/xss/class-dom-xss.md` jQuery `.attr(href)` sink). Open redirect is also a component of server-side chains here: `../../knowledge/portswigger/labs/ssrf-open-redirect-chain.md` documents SSRF filter bypass via an open redirect.

### Browser security controls — CSP and cookie flags (detailed, supported)

- **CSP policy injection** is documented in `../../knowledge/portswigger/xss/class-csp-bypass.md`: attacker bytes in a policy (e.g. reflected nonce/report-uri), raw `;`/`,` delimiters smuggling live directives, `script-src-elem` overriding `script-src` in Chromium, multiple `script-src` directives intersecting, first `report-uri` winning. Recognition: attacker-controlled bytes end up inside the CSP value; diff the policy across parameter values; candidate delimiters `;` `,` whitespace.
- **Cookie flags** (`SameSite`, `HttpOnly`) determine cross-site attach and exfiltration cost — see `../csrf-skill/SKILL.md` (read the actual `Set-Cookie` flags; never assume defaults) and `../xss-skill/SKILL.md` (HttpOnly raises exfil cost but never prevents impact).

### Client-side trust of content rendered to other viewers (supported)

Stored, user-influenced data rendered later — especially to privileged viewers — is a client-side trust boundary even when storage validation rejects inputs. See `../xss-skill/SKILL.md` (storage and render are separate trust decisions; victim-side action without exfiltration receiver) and `../../knowledge/portswigger/xss/class-stored-xss.md` (`stored-xss-onclick-entity-decode`: encode `&` first; assert on **decoded** values).

### CSRF / forced-linking delivery machinery (supported, cross-referenced)

Victim-browser auto-submit and auto-navigation are the delivery machinery for CSRF and forced OAuth profile linking — see `../csrf-skill/SKILL.md` and `../oauth-sso-skill/SKILL.md` (linking endpoint with no `state`, plant/deliver/poll machine). Same storage/delivery/polling discipline.

## Verification

- DOM sink findings require browser execution proof (CDP / headless with side-effect assertions), never response-text inspection.
- Separate stored vs reflected (fresh-session re-fetch) and SSR vs DOM reflection independently.
- Prove persistence before impact claims; assert on decoded values for entity-smuggling paths.
- Focus-event / attribute vectors: CDP + settle (assert `activeElement` too); `--dump-dom` races autofocus and produces false negatives.
- Marker/solved-state discipline per `../verification-skill/SKILL.md`: verify by victim-side effect with clean causality, no intervening attacker action.

## Evidence

Per `../verification-skill/SKILL.md`, preserve: source (attacker-controllable read point), sink, execution context, an observable security consequence (side-effect value, state marker, victim UA from forced navigation), and the full reconstructed request/response pair plus the decoded sink operand. For CSP: record policy-before and policy-after (the injection proof). Record failed candidates (encoded fields, encoded SSR, wrong breakout) — how the app defends is actionable.

## Handoff

- Confirmed XSS/redirect/CSP candidates pass to `../verification-skill/SKILL.md`; verified impact reasoning to `../impact-analysis-skill/SKILL.md`.
- Open redirect reaching server routes feeds `../ssrf-skill/SKILL.md` (redirect-chain filter bypass) and `../server-side-skill/SKILL.md`.
- Client-side CSRF and forced-linking ship to `../csrf-skill/SKILL.md` / `../oauth-sso-skill/SKILL.md` for the delivery machine.
- Generalized patterns feed back into `../../knowledge/portswigger/xss/` class files per AGENTS.md knowledge-feedback rules.

## Related Skills

- `../xss-skill/SKILL.md` — the primary class skill for script-execution-based impact (reflected/stored/DOM); this capability routes into it.
- `../csrf-skill/SKILL.md` and `../oauth-sso-skill/SKILL.md` — cross-origin auto-submit/auto-navigation delivery; cookie-flag semantics.
- `../authentication-skill/SKILL.md` — cookie/session mechanics, `SameSite`/`HttpOnly` reading, 302+session proof standards.
- `../access-control-skill/SKILL.md` — server-side authorization boundaries (the counterpart of browser trust).
- `../business-logic-skill/SKILL.md` — client-supplied-value trust for later financial/role decisions.
- `../verification-skill/SKILL.md` — execution proof, dual-surface markers, differential testing.
- `../server-side-skill/SKILL.md` — the complementary capability for server-processed input.
- `../../../skills/security-hunter/references/client-side.md` — the hunting-layer client-side signal reference this skill is organized around.

## Source / Derivation

- **Directly derived:** DOM XSS source→sink model and CSP-policy-injection mechanics from `../../knowledge/portswigger/xss/class-dom-xss.md` and `../../knowledge/portswigger/xss/class-csp-bypass.md`; client-side hunting signals and source→transformation→sink method from `../../../skills/security-hunter/references/client-side.md`; stored-content trust and victim-side action from `../xss-skill/SKILL.md` and `../../knowledge/portswigger/xss/class-stored-xss.md`.
- **Cross-referenced (not re-derived here):** CSRF/forced-linking machinery (`../csrf-skill/SKILL.md`, `../oauth-sso-skill/SKILL.md`), cookie-flag semantics (`../authentication-skill/SKILL.md`), open redirect as a chain component for SSRF (`../../knowledge/portswigger/labs/ssrf-open-redirect-chain.md`).
- **Source template:** `../../methodology/client-side.md` was an empty header-only stub; no verbatim body existed to migrate.

## Coverage Boundaries

The current knowledge base does not yet contain a dedicated methodology for:

- **Clickjacking / UI redress** (frame-busting, transparent overlays, `frame-gating` on navigations). Closest existing skill: `../csrf-skill/SKILL.md` (cross-origin interaction machinery) — treat clickjacking hypotheses as unverified until researched.
- **`postMessage` messaging abuse as a dedicated class** (postMessage-only sinks, origin validation of incoming messages). Only listed as a *source* in `../../knowledge/portswigger/xss/class-dom-xss.md`; no message-handler methodology exists.
- **Prototype pollution leading to client-side sinks** (only noted as "where applicable" in orchestration; no methodology in the repository).
- **Client-side caching / service-worker / PWA trust** (only a host-header web-cache-poisoning lab note exists, server-side).
- **Client-side SSRF / browser-driven server requests beyond redirect chains.**

Within the *documented* areas above, this skill provides organization and dispatch; the class skills and XSS class knowledge are the detailed methodology.