# Attack & Impact Class Coverage Matrix

PortSwigger-knowledge-driven coverage for the standard input-processing and
server-side classes. Use this matrix during the ATTACK phase (hypothesis
generation) and the IMPACT phase (impact Hypothesis Matrix / Coverage Check).

Each class row identifies, from solved PortSwigger labs:

- the lab references (index entries + lab notes)
- the primitive
- plausible sources/sinks (to check for reachability FIRST)
- exploitation patterns
- impact hypotheses (what an attacker gains)
- verification techniques (minimal safe)
- second-order / missed paths

Rule: a lab pattern creates a HYPOTHESIS, never proof for the current target.
Prove the data reaches the sink before expending effort on a class.

---

## SQL Injection

**Labs:** index lines 8–58 (`sql-injection-*` — WHERE-clause boolean, login
bypass/comment, UNION column-count/schema/credential extraction, blind boolean,
blind conditional-error, error-based) — notes in `knowledge/portswigger/labs/`.

- **Primitive:** user data concatenated into an SQL statement's string, value,
  numeric, or ORDER BY context without parameterization.
- **Sources:** query params, JSON body fields, headers, cookies, filename filters,
  sort/limit/filter params in APIs (candidates: raqnhub `variants:search`,
  dev-aip search/prospects, scrm, eshop OCC product search, Drupal7 `?q=`).
- **Sinks:** SELECT WHERE, auth/login queries, search, list/filter, ORDER BY/LIMIT,
  UPDATE/DELETE (persistence), insert portions, export/generated reports.
- **Exploitation:** tautology/comment bypass; UNION column counting; schema
  enumeration; blind boolean (diff responses); blind conditional-error
  (substring()/CASE in errors); OOB (DNS/log) only when necessary.
- **Impact hypotheses:** auth bypass; credential/PII exfiltration; mass data
  read; higher-priv data via stored procedures; multi-query corruption (reject
  unless demonstrated); second-order stored injection executed in later flows.
- **Verification:** minimal — single boolean/error oracle or UNION count only;
  avoid timed payloads and destructive statements; use `;` queries only to prove
  stacking and never to modify data.
- **Second-order / missed paths:** payloads stored (profile fields, names, notes)
  executed in later admin/report queries; injection in export features.

---

## XXE (XML External Entity)

**Labs:** index lines 298–334 (`xxe-*` — file retrieval, SSRF, blind OOB,
OOB via external DTD, parameter entities, XInclude in-value, local DTD
repurposing, SVG avatar).

- **Primitive:** XML parser processing external entities / DTDs unsafely.
- **Sources:** any XML body (product/stock checks, SOAP, file upload content,
  SVG avatars, document import/conversion services). Confirm XML exists FIRST —
  JSON-only apps (Spartacus, most JS SPAs) make XXE inapplicable.
- **Sinks:** server-side XML parsers (DOM/SAX/StAX default configs, libxml,
  php: wrapper coherence).
- **Exploitation:** `<!ENTITY xxe SYSTEM "file:///...">`; parameter entities for
  blind; external DTD URL; XInclude for in-value; local DTD grafting.
- **Impact hypotheses:** arbitrary file read (configs, source, env); SSRF via
  HTTP entity; on some stacks RCE via PHP `php://filter`/`except`, protocol
  handlers — assess the stack, do not assume.
- **Verification:** read a low-sensitivity file (e.g. `/etc/hostname`) or
  exploit the entity resolution visibly; error-based or OOB only when the app
  reflects errors. Do not exfiltrate real secrets.
- **Second-order / missed paths:** uploaded SVG/XML parsed later by another
  service; document-conversion and PDF-report endpoints.

---

## XSS (Reflected / Stored / DOM)

**Labs:** stored XSS in session-cookie username (index line 406);
`xss-scanning-non-standard-data-structures.md`; MCP Burp active-editor scanning.

- **Primitive:** unescaped attacker data reaching an HTML, JS, or DOM sink.
- **Sources:** reflected params, stored profile/social data, JSONP/JSON
  `getContextOfExpression`-style dynamic code paths, error messages.
- **Sinks:** innerHTML/document.write/eval-ish DOM sinks; template attribute
  injection; unsanitized rendered user content.
- **Exploitation:** classic reflected `<script>`; stored XSS in content other
  users render; DOM-based via URL fragment/location.
- **Impact hypotheses:** session theft (only if HttpOnly absent), ATO chaining
  with CSRF, admin-context stored XSS → mass user compromise, victim-scope data
  theft, keylogging. Program relevance: "XSS without demonstrated business
  impact" is not accepted → the impact must be demonstrated.
- **Verification:** minimal benign confirmations (DOM marker, observable state
  change, console evidence); do NOT campaign destructive payloads against real
  users; never run payloads that modify production data for other users.
- **Second-order / missed paths:** stored payload rendered in admin/report
  views; uploads served from a different origin with XSS content-type; HTMLi →
  phishing chaining (program excludes HTMLi alone).

---

## CSRF (Cross-Site Request Forgery)

**Labs:** `csrf-no-defenses.md`, index line 458 (tokenless email change +
SameSite=None auto-submit exploit chain).

- **Primitive:** state-changing request authenticated by cookies/session with no
  CSRF token / origin checks, or token bypass (no SameSite enforcement).
- **Sources:** cookie-authenticated state-changing endpoints (profile/password
  change, role ops, order/fulfillment actions, settings).
- **Sinks:** any state-changing endpoint accepting cross-site submission.
- **Exploitation:** auto-submitting forms (`<form>` GET/POST), token fixation,
  base URL manipulation, login CSRF.
- **Impact hypotheses:** forced account modification (email/password), forced
  order/workflow action, role/privilege toggle, chained with stored XSS. Program
  excludes CSRF without business impact → target high-value actions only.
- **Verification:** prove cross-origin submit is accepted with no token/origin
  check, on YOUR OWN account; revert the changed value after proof.
- **Second-order / missed paths:** CSRF on tokenless JSON endpoints (CORS-gated),
  OAuth state redirect CSRF, logout CSRF (low impact, generally not reportable).

---

## SSRF (Server-Side Request Forgery)

**Labs:** index lines 142–162 (`ssrf-*` — loopback fetch to internal admin,
/24 sweep, blacklist bypass via 127.1, whitelist via %2523 userinfo, open-redirect
chain, blind OOB) — notes in `knowledge/portswigger/labs/`.

- **Primitive:** server-side service fetches a URL/host supplied by user data.
- **Sources:** URL/host fields (stockApi-style, webhook callbacks, image fetcher,
  PDF generator, RSS/import), proxy params, redirect-following.
- **Sinks:** HTTP clients (Axios/requests/curl in backend), image loaders, PDF
  renderers, document importers.
- **Exploitation:** loopback/pod/native-IP fetches; DNS-pinning/double-encode
  whitelist bypass; redirect chaining; cloud metadata ONLY with caution (may be a
  program hazard — prefer loopback + internal host visibility as proof).
- **Impact hypotheses:** internal service access (admin consoles, internal APIs),
  short-lived credential exposure via cloud metadata (verify stack supports it),
  port/service fingerprinting of internal range (bounded), blind OOB only when a
  safe listener exists.
- **Verification:** loopback response differences / internal hostname resolution;
  minimal bounded port checks. Program excludes "blind SSRF without impact" —
  demonstrate internal response content or an actionable effect.
- **Second-order / missed paths:** open redirect used as SSRF whitelist bypass;
  SSRF to reach otherwise-401 internal APIs that return data; PDF/thumbnail
  generation reading internal resources.

---

## Path Traversal / Arbitrary File Access

**Labs:** index lines 210–226 (`traversal-*` — simple case, absolute-path
bypass, non-recursive strip bypass via `....//`, prefix allowlist escape,
extension allowlist + null byte); `file-upload-path-traversal.md`; JWT
`kid`-header traversal.

- **Primitive:** user-controlled filename/path used in file read/write without
  canonicalization.
- **Sources:** download/export/view params (filename, path, file, doc), upload
  filename, JWT `kid` header, language/theme/template params.
- **Sinks:** `open()`/`readfile`/streaming writes, upload/rename targets, template
  loaders, archive extract-to-path.
- **Exploitation:** `../` sequences, absolute paths, nested/encoded encodings,
  null-byte (legacy), path normalization differences.
- **Impact hypotheses:** arbitrary file read (source code, configs, `.env`,
  backups, logs with personal data), write/overwrite in upload contexts, source
  disclosure feeding further chaining.
- **Verification:** read one low-sensitivity file and show exact bytes;
  for write/traversal-upload show a benign overwrite on test path, revert if
  possible. Do not read production PII/credentials for proof.
- **Second-order / missed paths:** traversal on archive extraction (zip-slip);
  DE font-loading; traversal into template dirs → SSTI/RCE where applicable.

---

## Also consider (same method; classes in `methodology/`)

- SSTI (`methodology/ssti.md`) — template params/email themes.
- Command injection (`methodology/injection.md`) — env/exec sinks on
  server-side tool fields.
- Deserialization — ViewState class (hunter-03 lead: henkeleconomato.es).
- Race conditions (`methodology/race-conditions.md`) — transactional flows.
- JWT / OAuth (`methodology/jwt.md`, `oauth-sso.md`) — auth headers.
- NoSQL injection — JSON filter operators on Mongo-style backends.

## Reference

- `index/portswigger.md` — full solved-lab index (by class/lab note).
- `knowledge/portswigger/labs/<lab>.md` — per-lab notes (patterns, sequences).
- `methodology/*.md` — per-class testing methodology.
- The IMPACT side of this matrix is the Impact Hypothesis Matrix in
  `methodology/impact-analysis.md` (steps 3–8) and the mandatory Impact
  Coverage Check before completing any finding.
  
  
  # Attack & Impact Class Coverage Matrix — Index

> **Deduplication note:** This file previously contained a full copy of the class-by-class impact matrix (boundary → hypotheses → escalation paths → lab refs) that also lives, near-verbatim, in `methodology/impact-analysis-skill/SKILL.md` §2b ("Impact-Class Coverage Matrix"). Maintaining two independently-editable copies risks silent drift. **`methodology/impact-analysis-skill/SKILL.md` §2b is now the single source of truth** for the class → boundary → impact-hypothesis → escalation → lab-ref matrix. This file is a lightweight INDEX/POINTER layer only.
>
> **Staleness note (fixed after review):** an earlier version of this table hedged several rows with "if present" / "if exists" / "future" language, written as if most class skills were still aspirational. Per `methodology.md`'s canonical map, the great majority of classes now HAVE a realized `*-skill/SKILL.md`. That hedging has been removed below; only genuinely unimplemented classes are marked as gaps.

## How to use this file

1. During ATTACK/hypothesis generation: find your suspected class below, jump straight to its class skill for the tested methodology (sources, sinks, exploitation patterns, testing steps).
2. During IMPACT analysis: use `../impact-analysis-skill/SKILL.md` §2b for the boundary → impact-hypothesis → escalation-path → lab-ref reasoning. Do not re-derive it here.
3. Rule (unchanged from the original matrix): a lab pattern or a class-skill pattern creates a HYPOTHESIS, never proof for the current target. Prove the data reaches the sink before expending effort on a class.

## Class → Skill → Lab-Index Pointer Table

| Class | Class skill (tested methodology) | Impact matrix row | Primary lab index range |
|---|---|---|---|
| SQL Injection | `../injection-skill/SKILL.md` | `impact-analysis-skill §2b → SQL Injection` | index lines 8–58 |
| XXE | `../xxe-skill/SKILL.md` | `impact-analysis-skill §2b → XXE` | index lines 298–334 |
| XSS (reflected/stored/DOM) | `../xss-skill/SKILL.md` | `impact-analysis-skill §2b → XSS` | index line 406 + `xss-scanning-non-standard-data-structures.md` |
| CSRF | `../csrf-skill/SKILL.md` | `impact-analysis-skill §2b → CSRF` | `csrf-no-defenses.md`, index line 458 |
| SSRF | `../ssrf-skill/SKILL.md` | `impact-analysis-skill §2b → SSRF` | index lines 142–162 |
| Path Traversal / Arbitrary File Access | `../traversal-skill/SKILL.md`, `../file-security-skill/SKILL.md` (upload-side) | `impact-analysis-skill §2b → Path Traversal` | index lines 210–226 |
| SSTI | `../ssti-skill/SKILL.md` | adjacent-classes note in §2b | see ssti-skill Sources |
| Command Injection | `../injection-skill/SKILL.md` | adjacent-classes note in §2b | see injection-skill Sources |
| Deserialization | `../deserialization-skill/SKILL.md` | adjacent-classes note in §2b | see deserialization-skill Sources |
| Race Conditions | `../race-conditions-skill/SKILL.md` | adjacent-classes note in §2b | see race-conditions-skill Sources |
| JWT | `../jwt-skill/SKILL.md` | adjacent-classes note in §2b | see jwt-skill Sources |
| OAuth / SSO | `../oauth-sso-skill/SKILL.md` | adjacent-classes note in §2b | see oauth-sso-skill Sources |
| API Security | `../api-security-skill/SKILL.md` | — | see api-security-skill Sources |
| Access Control | `../access-control-skill/SKILL.md` | — | — |
| Privilege Escalation | `../privilege-escalation-skill/SKILL.md` (coordination layer over access-control/jwt/oauth-sso/business-logic/race-conditions) | — | — |
| Client-Side (DOM/CSP/open-redirect) | `../client-side-skill/SKILL.md` | — | see client-side-skill Sources |
| Server-Side (dispatch layer) | `../server-side-skill/SKILL.md` | — | see server-side-skill Sources |
| File Security / Upload | `../file-security-skill/SKILL.md` | — | see file-security-skill Sources |
| Business Logic | `../business-logic-skill/SKILL.md` | — | — |
| Authentication | `../authentication-skill/SKILL.md` | — | — |
| Reconnaissance | `../reconnaissance-skill/SKILL.md` | (pre-attack phase, not impact-mapped) | — |

## Genuine Gaps (no class skill exists — confirmed against `methodology.md`)

- **NoSQL injection** — no dedicated class skill; only mentioned as "Also consider" in the impact matrix. Filter-operator injection (`$where`, `$ne`, etc.) on Mongo-style backends.
- **HTTP Request Smuggling** — documented as an explicit coverage boundary in `../server-side-skill/SKILL.md`; no class skill or lab knowledge.
- **Clickjacking / UI redress** — documented as an explicit coverage boundary in `../client-side-skill/SKILL.md`.
- **CVE Research** — documented as an explicit, named implementation gap in `methodology.md` ("GAP — not yet implemented"; no `cve-research-skill/` directory exists).

These four are the only rows that should carry gap language. Every other class in the table above has a realized skill — do not re-introduce "if present"/"future" hedging for rows already backed by an existing `*-skill/SKILL.md`.

## Reference

- `../impact-analysis-skill/SKILL.md` §2b — **authoritative** class → boundary → impact-hypothesis → escalation-path → lab-ref matrix (read this, not a copy of it).
- `index/portswigger.md` — full solved-lab index (by class/lab note).
- `knowledge/portswigger/labs/<lab>.md` — per-lab notes (patterns, sequences).
- `methodology.md` — canonical map; consult it before marking any class a gap, so this file doesn't go stale again as new skills are added.
