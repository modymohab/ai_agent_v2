# PortSwigger Lab

## Lab

Authentication bypass via information disclosure

URL: https://0a2e0086043d08d28017bcaf00ae00ee.web-security-academy.net/

## Vulnerability Class

Authentication bypass — `TRACE` discloses the trusted `X-Custom-IP-Authorization` header name + client IP; forged `127.0.0.1` value passes the localhost authorization check → admin panel → user deletion

## Objective

Access the admin panel and delete `carlos`. Solved when the panel flips to `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound login form; debug-path sweep (7 paths) all 404 — no phpinfo/backup exposure here.
- CURRENT EVIDENCE: `GET /admin` anon → 401 `Admin interface only available to local users` (IP-based authorization stated in the denial itself).
- CURRENT EVIDENCE: seeded `wiener:peter` REJECTED (jar-correct, twice) — no seeded account; login path abandoned immediately.

## Hypotheses

- H1 (explored): valid-user enumeration via message-less 200 (`wiener` differs from invalid users) + password brute-force.
- H2 (after stuck checkpoint + description research): `TRACE /admin` discloses the trusted header; spoofing `127.0.0.1` passes the local-IP check.

## Attempts

1. Debug sweep + CSRF-bound login probes (seeded creds falsified — stopped after evidence).
2. Username enumeration (4 hand probes): only `wiener` returned message-less 200 vs `Invalid username or password.` for others.
3. Full 101-username scan → ALL identical (contradicted H1's hand probe — first anomaly).
4. Token-reuse isolation test: same-token reuse AND fresh-token first use both returned message-less 200 for wiener → rate-dependent oracle identified (rapid scans normalize responses; slow probes preserve them).
5. Slow 100-password brute-force (1.5s spacing, fresh CSRF each) → zero 302s. H1 DEAD (password not in Academy list at any rate).
6. Quote probe on login → normal 200 (no verbose errors — info-disclosure is elsewhere).
7. Stuck provision: description research → TRACE/header mechanism (hypothesis source, every step below re-verified).
8. `GET /admin` → 401 local-users-only (denial states the rule).
9. `TRACE /admin` → 200 `message/http` echo containing server-appended `X-Custom-IP-Authorization: <my-IP>`. DISCLOSURE CONFIRMED.
10. `GET /admin` + `X-Custom-IP-Authorization: 127.0.0.1` → 200 full admin panel (roster + delete links). BYPASS CONFIRMED.
11. `GET /admin/delete?username=carlos` → 302 → re-read: `is-solved` + `Solved` + congratulations + `User deleted successfully!`, carlos gone. SOLVED.

## What Failed

- Password brute-force at two rates (fast 200-req + slow 1.5s-spacing 100-pw) — wrong vulnerability theory, correctly killed by zero-302 evidence rather than extended.
- Full population scan that contradicted hand probes — resolved into the rate-dependence finding instead of being discarded (scan artifact documented, not hidden).
- Seeded-credential anchoring (2 attempts) — stopped on evidence.

## What Worked

TRACE disclosure → localhost header spoof → admin → delete → solved (~10 requests for the real chain).

## Burp Observations

- Login/CSRF probes, admin denial, TRACE disclosure, spoofed admin access, delete, and solved proof — ALL via Burp MCP (`burp_send_http1_request`) with full request/response evidence. TRACE method sent directly (no special tooling needed).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl sweeps (debug paths) + Python loops (enumeration/brute-force with fresh-CSRF discipline). Rate finding came from comparing fast vs slow runs.

## Root Cause

Two compounding flaws: (1) `TRACE` enabled with request echo discloses internal trust metadata — the exact header name the authorization layer reads plus the client's own IP, teaching the bypass shape; (2) the admin authorization trusts the CLIENT-SUPPLIED `X-Custom-IP-Authorization` value instead of the connection source, so `127.0.0.1` forges locality.

## Verification

- 401-without-header vs 200-admin-panel-with-header on the same endpoint isolates the header axis exactly.
- Delete → 302 → re-read: success message + victim absent + `is-solved`/`Solved`/congratulations. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Unauthenticated administrator access (roster + arbitrary deletion, carlos deleted) via two unauthenticated requests (TRACE + spoofed GET). TRACE echo additionally leaks request internals to any caller.

## Why The Successful Approach Worked

- Killed the brute-force theory with evidence (zero 302s at two rates) instead of escalating to rockyou.
- Turned the scan contradiction into a finding (rate-dependence) rather than ignoring it.
- Used the stuck provision at the right time (after genuine exhaustion) and re-verified every transferred claim (denial text, TRACE echo, spoof acceptance).

## Generalization

- NEW reusable variant: TRACE-disclosed trusted headers — probe `TRACE` on auth-gated endpoints; if the echo names an IP/role header, spoof loopback. Extends the client-controlled-marker family (Referer/X-Original-URL precedents).
- Rate-dependent oracles: when population scans contradict hand probes, test fast-vs-slow before concluding.

## Lessons Learned

- First infoleak-auth lab in the KB; methodology/access-control.md gains the TRACE-header variant (8th client-marker bypass).
- Description research is legitimate after stuck-checkpoint discipline (6+ bounded falsifications here), with per-step re-verification mandatory.

## Related Methodology

- methodology/access-control.md (TRACE-disclosed IP-marker bypass — genuinely new variant; update justified, applied separately)
- methodology/verification.md (same-endpoint differentials + victim-state proof)
- methodology/injection.md does NOT apply (quote correctly diagnosed as non-SQLi). Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/information-disclosure/exploiting/lab-infoleak-authentication-bypass (objective + TRACE/header mechanism as hypothesis source after stuck checkpoint; all steps re-verified by current evidence)
- Prior related (technique cousins): access-control Referer-gate and X-Original-URL labs (client-controlled markers); timing-lab block-polling lesson (don't poll)
- Solved instance: https://0a2e0086043d08d28017bcaf00ae00ee.web-security-academy.net/ with `X-Custom-IP-Authorization: 127.0.0.1` → delete carlos
