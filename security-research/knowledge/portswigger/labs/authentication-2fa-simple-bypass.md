# PortSwigger Lab

## Lab

2FA simple bypass

URL: https://0a2e000a0432d3da8407f5fe00b60008.web-security-academy.net/

## Vulnerability Class

Authentication – 2FA stage-skipping: stage-1 session grants account pages directly without completing the 4-digit code step

## Objective

Access Carlos's account page (victim creds `carlos:montoya` given by description; 2FA code unobtainable). Established by `is-solved` after stage-1 session visits `/my-account?id=carlos`. Official description consulted for victim creds/objective only after verify-confusion probes + brute-force elimination.

## Initial Observations

- Blog + `/my-account`; login form has NO csrf. `POST /login wiener:peter` → 302 to `/login2` + stage-1 session; `/login2` asks 4-digit `mfa-code` (POST, no visible verify param/cookie).
- Email client (exploit server) shows wiener's codes (0824, 1155 – only 2 emails despite 4+ logins; code-emailing is not per-login).
- `verify=carlos` as cookie/query/body on stage-2: cookie ignored (wiener session on valid code), query ignored (wiener session), body → 500 `No user logged in` (session binding breaks – recorded, not retried).
- `carlos` + 100-list passwords → 100× 200, zero 302 (no throttle evidence; password outside list or unnecessary – correctly deprioritized, not extended).
- Stored `methodology/authentication.md` (READ: 2FA-logic extension covers verify-mint + brute-force; no stage-skip pattern). Prior: subtle-enumeration + overt-enumeration + 2FA-broken-logic labs.

## Hypotheses

- H1: Stage-1 session already authorizes account pages (2FA unenforced on `/my-account`). Evidence needed: `GET /my-account?id=wiener` 200 with fresh stage-1 session.
- H2: Ownership still enforced (`?id=carlos` with wiener session → 302) – so victim stage-1 needed, not IDOR.
- H3: Victim creds obtainable from description (given-credential lab family). Evidence needed: description text.

## Attempts

1. Baseline `GET /login` + `POST wiener:peter` → 302 + stage-1 session; `GET /login2` → code form mapped.
2. verify-confusion matrix (cookie/query/body × valid code 1155): cookie→wiener 302, query→wiener 302, body→500 session-break – verify vector absent here; correctly abandoned (3 requests, not repeated).
3. Stage-skip test: fresh wiener stage-1 session → `GET /my-account?id=wiener` → 200 full account page (`wiener`, email, forms) – H1 confirmed (2FA skippable for own account).
4. Same session → `GET /my-account?id=carlos` → 302 `/login` – H2 confirmed (ownership enforced; need carlos stage-1).
5. 100-password brute-force on carlos → all 200 – correctly ruled out (not extended into lockout risk).
6. Description read → victim creds `carlos:montoya` (given, not cracked) → `POST /login carlos:montoya` → 302 + stage-1 session → `GET /my-account?id=carlos` → 200 `Your username is: carlos` – H3 confirmed.
7. `GET /` with carlos session → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- verify-parameter confusion (all positions) – no such vector in this lab; 3 requests, abandoned per evidence (query/cookie ignored, body destructive).
- Password brute-force on carlos (100× 200) – wrong approach for given-credential lab; stopped before lockout territory.
- Assuming wiener-stage-1 `/` visit would solve (still `is-notsolved`) – objective is victim-specific; corrected to carlos session.

## What Worked

- Stage-1 → direct `/my-account?id=<own-stage-1-user>` (2FA skip) + description-provided victim creds → victim page → homepage marker. 8 functional requests + scans.

## Burp Observations

- Baseline, stage-1 logins (302s + sessions), stage-2 form mapping, brute-force negative (via curl loop), victim login + page + proof (`200 is-solved`) via Burp MCP.
- Email client read via Burp (wiener codes observed, used once for baseline validity).

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `curl` loops for 100-password scan (302-outlier filter); email-code cross-check. No scanner/crawler/fuzzer.

## Root Cause

Second-factor step is advisory only: stage-1 session authorizes `/my-account` directly; no server-side gate requires completed 2FA before serving account content. Combined with provided victim password, attacker walks past `/login2` by navigating around it. Ownership check exists (`?id=` enforced → 302) but stage check does not.

## Verification

- Stage-skip proof: fresh stage-1 session (never touched `/login2`) → 200 account page (wiener, then carlos with own stage-1).
- Ownership proof: cross-account access → 302 (no IDOR conflation).
- Identity proof: victim page renders `carlos` + email; marker proof: `is-solved` on `/` with victim session (account page alone showed `is-notsolved` – both surfaces checked, as per prior lesson).

## Impact

Full 2FA bypass for any account whose password is known (demonstrated victim account takeover + PII email render). Reduces MFA deployment to single-factor strength.

## Why The Successful Approach Worked

- Tested the skip FIRST on own account (cheap, safe) before needing victim creds – separated the vulnerability (missing stage gate) from the objective (victim access).
- Read verify-confusion negatives as eliminations (not failures): cookie/query ignored + body destructive = no such vector, move to skip hypothesis.
- Consulted description for creds only after brute-force elimination (100× 200) – given-credential family recognized, not assumed upfront.

## Generalization

- For 2FA labs: after stage-1, immediately test direct gated-page access (`/my-account?id=<stage-1-user>`) BEFORE code games – skip flaws are one request to rule in/out.
- verify-vector matrix (cookie/query/body × valid code) eliminates confusion flaws in 3 requests; body-500s mean binding breakage, not bypass.
- Given-credential labs state victim passwords in the description – brute-force only after ruling this out (or when description silent); 100-list miss = stop, read objective source.

## Lessons Learned

- Stage gates must be tested independently of identity confusion: skip (missing gate) vs swap (wrong binding) are different flaws needing different probes.
- Marker location repeats: homepage flip, account page static – prior lesson reused verbatim (checked both again).
- Email-code inventory (2 emails vs 4 logins) hinted codes aren't per-session-bound the naive way – noted, unused further once skip proven.

## Related Methodology

- Extends `methodology/authentication.md` (verify-mint + brute-force 2FA; no stage-skip pattern – update justified below; 4th auth lab).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: 2FA-broken-logic (stage mapping + single-header discipline reused), overt-enumeration (marker-both-surfaces lesson reused).

## References

- Solved instance: https://0a2e000a0432d3da8407f5fe00b60008.web-security-academy.net/
- Lab: https://portswigger.net/web-security/authentication/multi-factor/lab-2fa-simple-bypass
- Victim creds (description-given): carlos / montoya; own: wiener / peter
- Email evidence: wiener codes 0824 + 1155 (only 2 emails for 4+ logins – generation not per-login)
- Deliberately shaped probes from auth methodology; official solution consulted for victim creds/objective after brute-force elimination.
