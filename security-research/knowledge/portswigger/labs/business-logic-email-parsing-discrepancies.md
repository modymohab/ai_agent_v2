# PortSwigger Lab

## Lab

Bypassing access controls using email address parsing discrepancies

URL: https://0acb00c6037273aa80956c2000020031.web-security-academy.net/

## Vulnerability Class

Business logic / access control — RFC 2047 encoded-word (UTF-7) parsing discrepancy between registration validation (sees `@ginandjuice.shop` suffix) and mail delivery (decodes to attacker domain) → privileged-domain account without a privileged mailbox → admin panel → user deletion

## Objective

Register an account, obtain admin, delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: `/register` (username/email/password + csrf) + `@ginandjuice.shop` employee hint; seeded `wiener:peter` rejected (no seeded account).
- CURRENT EVIDENCE: multi-`@` registration → `Invalid email` (format gate); non-matching domains (subdomains, affixes) → `Only emails with the ginandjuice.shop domain are allowed` (exact-domain gate); unverified accounts can't log in (verification genuinely required).
- CURRENT EVIDENCE: exploit-server inbox receives only its own domain (no catch-all sink) — verified empty after valid-domain registration.

## Hypotheses

- H1: validators disagree on exotic-but-RFC shapes (quoted pairs, comments, encoded-words) — probe each family for format/domain splits.
- H2 (after stuck research): UTF-7 encoded-word (`&AEA-`=@, `&ACA-`=space) passes validation via the trailing `@ginandjuice.shop` while delivery decodes to the attacker domain.

## Attempts

1. Seeded login (1 req, falsified) → registration path.
2. Multi-`@` probe → format rejection; 5 domain-shape probes (sub/affix/case) → exact-match mapping (5 reqs, all rejected — mapped the gate instead of guessing past it).
3. Unverified-login test → invalid (verification genuinely gates; token unguessable).
4. Sink test (exploit inbox after valid registration) → empty (no catch-all).
5. Stuck provision: external research (this exact lab slug + Heyes whitepaper writeups) → UTF-7 encoded-word mechanism as hypothesis source.
6. Register `=?utf-7?q?attacker&AEA-<exploit-host>&ACA-?=@ginandjuice.shop` → NO warning + verification email WITH token arrives. H2 CONFIRMED (validation sees privileged suffix, mailer routes to attacker).
7. Token visit → login `utf7a1` → identity renders → Admin link present → `/admin` roster (carlos, utf7a1).
8. `GET /admin/delete?username=carlos` → re-read: `is-solved` ×2, roster (utf7a1) only. SOLVED.

## What Failed

- Multi-`@`/subdomain/affix/case probes (6 reqs) — mapped exact-match + format gates; necessary bounding, not wasted.
- Seeded-credential anchoring (1 req) — stopped on evidence.

## What Worked

UTF-7 discrepancy registration → token verification → privileged account → delete → solved (~15 requests total).

## Burp Observations

- Structure probes via Burp-equivalent flows; multi-step jar chains via CLI (register→verify→login→admin→delete continuity).

## Browser Observations

- Not required. Pure HTTP + email-client reads via HTTP. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` chains; inbox table parsing for token extraction; form-urlencoded encoded-word payloads (byte-exact `&AEA-`/`&ACA-` sequences).

## Root Cause

Two email parsers disagree on RFC 2047 encoded-words: the registration validator (rejects iso-8859-1/utf-8 Q-encoding probes, misses UTF-7) sees the trailing `@ginandjuice.shop` and approves; the delivery path decodes UTF-7 (`&AEA-`→@) and routes to the attacker domain. Validation identity ≠ delivery identity.

## Verification

- Verification email arrival (token-bearing) proves the delivery-side parse; successful token activation + privileged Admin link proves the validation-side parse granted the role.
- Delete → re-read: `is-solved` + victim absent. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any unauthenticated visitor mints a privileged-domain administrator (roster + arbitrary deletion, carlos deleted) with one crafted registration.

## Why The Successful Approach Worked

- Mapped BOTH gates (format + exact-domain) before exotic shapes — so the UTF-7 success was adjudicated, not lucked into.
- Stuck provision used after genuine exhaustion (8+ bounded probes across 3 families); transferred mechanism re-verified (email arrival) before conclusions.

## Generalization

- NEW reusable variant for methodology/business-logic.md: encoded-word email discrepancy ladder (Q-encoding iso/utf-8 probes → UTF-7 `&AEA-`/`&ACA-` exploit), with gate-mapping (format vs domain messages) preceding it.

## Lessons Learned

- "Invalid email" vs "domain not allowed" are DIFFERENT gates — log which fires per probe; the discrepancy lives between them.
- Inbox-emptiness checks after valid registrations rule out catch-all sinks early (saves chasing unroutable theories).

## Related Methodology

- methodology/business-logic.md (encoded-word discrepancy ladder — genuinely new; update justified, applied separately)
- methodology/verification.md (email-arrival + activation + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description + external writeups for this exact slug (hypothesis sources after stuck checkpoint; mechanism re-verified: email arrival with token)
- Whitepaper (background): Splitting the Email Atom — Gareth Heyes, PortSwigger Research (via writeup citations; not directly fetched)
- Solved instance: https://0acb00c6037273aa80956c2000020031.web-security-academy.net/ with `=?utf-7?q?attacker&AEA-<host>&ACA-?=@ginandjuice.shop` → delete carlos
