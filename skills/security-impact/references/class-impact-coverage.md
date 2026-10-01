# Class — Impact Coverage Matrix (Impact Phase)

PortSwigger-referenced impact framing. Usage: for every confirmed finding,
map the verified primitive onto the relevant rows to build the Impact
Hypothesis Matrix and to run the mandatory Impact Coverage Check.

Rule: claim impact only where DEMONSTRATED. Labs are hypotheses, not proof.

---

## SQL Injection
- Boundary: app → backend database (authentication boundary if login/session query).
- Impact hypotheses: auth bypass; sensitive/personal data read (quantity as demonstrated); modification/deletion (only if stacking proven); elevation to higher-priv data.
- Escalation: UNION schema enumeration → PII/credential tables; blind boolean/error oracles; second-order stored injection in later admin/report queries.
- Labs: sql-injection-where-clause-hidden-data; sql-injection-login-bypass; sql-injection-union-*; sql-injection-blind-conditional-responses; sql-injection-blind-conditional-errors; sql-injection-visible-error-based.

## XXE
- Boundary: app → file system; app → internal services via entity SSRF; stack protocol handlers.
- Impact hypotheses: arbitrary file read; SSRF into internal hosts; blind OOB exfiltration; RCE only if stack demonstrably supports it.
- Escalation: file read → credentials/keys → deeper access; SSRF → internal admin.
- Labs: xxe-external-entity-file-retrieval; xxe-ssrf-metadata-credentials; xxe-blind-oob-interaction; xxe-blind-oob-exfiltration-dtd; xxe-blind-oob-parameter-entities; xxe-xinclude-file-retrieval; xxe-targeted-scanning-stock-xinclude; xxe-local-dtd-repurposing; xxe-svg-avatar-file-upload.

## XSS
- Boundary: user-controlled data re-rendered in a victim browser context (reflected/stored/DOM).
- Impact hypotheses: session theft (only if HttpOnly absent); ATO via chained CSRF; stored XSS reaching other users/admin; DOM extraction. Program requires demonstrated business impact.
- Escalation: stored XSS in widely-viewed content; admin-context XSS → mass impact.
- Labs: stored XSS in session-cookie username (index line 406); xss-scanning-non-standard-data-structures.

## CSRF
- Boundary: cross-site-originated state-changing requests (missing token/origin/SameSite).
- Impact hypotheses: forced account state change (email/password/role/order/workflow); login CSRF; admin action forging. Program requires business impact.
- Escalation: chain with stored XSS; tokenless JSON endpoints; SameSite bypass.
- Labs: csrf-no-defenses; tokenless email change + SameSite=None auto-submit (index line 458).

## SSRF
- Boundary: app → internal/cloud network via backend fetch.
- Impact hypotheses: internal response disclosure; bounded internal port/service reach; cloud metadata short-lived credentials only where stack/instance supports it; blind OOB needs an effect.
- Escalation: loopback/local-host fetches to internal apps; redirect-chain/whitelist bypass; reach 401-internal APIs that return data.
- Labs: ssrf-basic-backend-system; ssrf-basic-local-server; ssrf-blacklist-filter-bypass; ssrf-whitelist-double-decode; ssrf-open-redirect-chain; ssrf-blind-oob-detection.

## Path Traversal
- Boundary: app → file system read (and write in upload/extract contexts).
- Impact hypotheses: arbitrary file read (source/config/.env/backups/logs with PII); traversal-write (zip-slip); source disclosure → chaining.
- Escalation: read secrets → authenticate deeper; write-side overwrite where demonstrated; traversal into template dirs → SSTI/RCE only if loader reachable.
- Labs: traversal-simple-case; traversal-absolute-path-bypass; traversal-sequences-stripped-nonrecursively; traversal-validate-start-of-path; traversal-extension-null-byte; file-upload-path-traversal; jwt-authentication-bypass-kid-header-path-traversal.

## Adjacent (same discipline)
SSTI, command injection, NoSQL injection, deserialization (ViewState), race
conditions, JWT/OAuth — methodology/ class files + index/attack-impact-coverage.md.

## Output tie-in
The matrix above feeds: Impact Hypothesis Matrix → applicable-path tests →
Impact Coverage Check (tested / not-applicable / unverified) → findings not
complete until coverage check present (see methodology/impact-analysis-skill/SKILL.md and
agents/impact.md §13c).