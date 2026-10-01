# PortSwigger Lab

## Lab

Inconsistent handling of exceptional input

URL: https://0ace00b50390a43f866a5df100430013.web-security-academy.net/

## Vulnerability Class

Business logic — overlong registration email truncated to 255 chars for storage/role while delivered in full: privileged-domain prefix + routable suffix yields an admin account from an unauthorized mailbox

## Objective

Register an account, obtain admin, delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: `/register` (username/email/password + csrf) + `@dontwannacry.com` employee hint; `/admin` anon → 401 local/DontWannaCry-only; no seeded accounts (wiener/administrator/carlos all invalid); no forgot/change endpoints.
- CURRENT EVIDENCE: multi-`@` → 400 `Invalid email` (format gate); non-matching domains (sub/affix) → domain rejection (exact-match gate); unverified accounts can't log in (verification genuinely gates).

## Hypotheses

- H1: validators disagree on exotic shapes (encoded-words, separators, duplicates) — probe each family.
- H2 (after stuck research): length truncation at 255 chars splits validation/delivery/storage identities — craft the cut point exactly.

## Attempts

1. Seeded logins (3 reqs, all invalid) → registration path.
2. Multi-`@`/subdomain/affix/case probes (6 reqs) → format vs exact-domain gates mapped.
3. Newline header-injection shapes → 400 (format handles newlines).
4. Encoded-words (UTF-7, Q-iso, Q-utf8, B-utf8) → accepted silently, ZERO mail delivered.
5. Duplicate-param probes: `[dontwannacry, exploit]` → accepted + token arrives (validation=ANY, storage=delivery=LAST=exploit — non-privileged dead end); reversed → accepted, void delivery. Separator variants (comma/semicolon/space) → 400.
6. Stuck provision: external research for this exact slug → 255-char truncation mechanism as hypothesis source.
7. Crafted `a×238 + @dontwannacry.com + .<exploit-suffix>` (len 315, char-255 = `m`, verified programmatically) → NO warning + verification token arrives. H2 CONFIRMED (full-length routes to inbox; stored prefix is privileged).
8. Token visit → login `trunc1` → Admin link present → `/admin` roster → `GET /admin/delete?username=carlos` → re-read: `is-solved` ×2, carlos gone. SOLVED.

## What Failed

- Encoded-word delivery (4 shapes accepted, 0 mail) — mailer here doesn't decode; dead family on this stack (vs prior lab where it worked — per-instance verification mattered).
- Separator/duplication tricks for privilege (all resolve to LAST-wins storage=delivery — provably insufficient, mapped not guessed).
- Header injection (400s).

## What Worked

Exact-cutoff truncation address → token → privileged account → delete → solved (~20 requests total).

## Burp Observations

- Structure probes via Burp-equivalent flows; multi-step jar chains via CLI (register→verify→login→admin→delete continuity).

## Browser Observations

- Not required. Pure HTTP + email-client reads via HTTP. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python length arithmetic (238 + 17 = 255, char-index verified before sending); inbox token polling; `http.cookiejar` chains.

## Root Cause

Length-handling inconsistency across layers: validation + mail delivery operate on the FULL 315-char address (privileged suffix visible; routable suffix delivers), while storage truncates to 255 chars — landing exactly on `@dontwannacry.com`. The role check then reads the truncated privileged form.

## Verification

- Token arrival proves full-length delivery identity; privileged Admin link + roster proves truncated storage identity — the split itself is the evidence.
- Delete → re-read: `is-solved` + victim absent. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any unauthenticated visitor mints a privileged-domain administrator (roster + arbitrary deletion, carlos deleted) with one crafted registration.

## Why The Successful Approach Worked

- Gate-mapping (format vs domain vs verification vs sink) BEFORE exotic shapes — so each exotic result (accept/no-mail) was adjudicated against known gates.
- Cut-point arithmetic verified programmatically (char 255 = `m`) before sending — no off-by-one retries needed.

## Generalization

- NEW reusable variant for methodology/business-logic.md: overlong-input truncation split (craft privileged-prefix + routable-suffix with the cut exactly on the privileged boundary; verify by delivery arrival + stored-form role).

## Lessons Learned

- Length is a parsing dimension like encoding: sweep it (120→300+) with inbox observation, not just accept/reject reading.
- Silent acceptance + zero mail is a distinct outcome class (mailer choked) vs void delivery — both recorded separately.

## Related Methodology

- methodology/business-logic.md (truncation-split variant — genuinely new; update justified, applied separately)
- methodology/verification.md (split-identity proof: delivery token + stored role)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description + external writeups for this exact slug (hypothesis sources after stuck checkpoint: 255-char cut, subdomain-routing suffix shape; cut arithmetic and suffix choice re-derived for this instance)
- Solved instance: https://0ace00b50390a43f866a5df100430013.web-security-academy.net/ with 238+17@cut address → delete carlos
