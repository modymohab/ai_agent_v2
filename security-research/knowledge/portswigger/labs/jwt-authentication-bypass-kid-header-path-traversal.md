# PortSwigger Lab

## Lab

JWT authentication bypass via kid header path traversal

URL: https://0ac500dc04647670827d518a0005007c.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — `kid` header used as a filesystem path to load the HMAC key; traversal to `/dev/null` yields an empty key → self-signed administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + HS256 JWT (`kid` UUID), payload `{"iss":"portswigger","exp":1789608900,"sub":"wiener"}` — symmetric algorithm with key-file semantics hinted by UUID `kid`.

## Hypotheses

- H1: absent verification (claim-only). H2: `alg:none`. H3: `kid` path traversal to a known/empty key file + empty-key HS256 signature.

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 → **401**. H2 → **401**. Both cleanly falsified (verification present, alg locked).
3. H3 depth matrix (empty-key HS256, `sub=administrator`): `../dev/null` → 401; `../../../dev/null` → **200 full admin panel**; `../../../../../../dev/null` → 200 admin content. Boundary at depth 2–3 (key dir is 2–3 levels deep); `mid` used for solve.
4. `GET /admin/delete?username=carlos` (mid token) → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED (~9 requests total).

## What Failed

- H1/H2 401s (2 cheap falsifications).
- Shallow traversal (`../dev/null`, 401) — depth boundary information, recorded as the constraint.

## What Worked

`kid:../../../dev/null` + empty-key HS256 self-sign + `sub=administrator` → admin → delete → solved.

## Burp Observations

- Baseline CSRF/login via Burp MCP. Forged-token probes via CLI (encoding advantage); admin verdicts body-checked (roster/links), never status-only.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `hmac` with `b''` empty key + base64url forging; depth matrix (3 depths) one axis at a time.

## Root Cause

The verifier loads the HS256 key from a filesystem path derived from the UNVALIDATED `kid` header (`<keydir>/<kid>`). `../../../dev/null` escapes to the empty device file, whose zero-length content becomes the HMAC key — attacker signs arbitrary claims with the empty key and the server agrees with itself.

## Verification

- H1/H2/shallow 401s vs mid/deep 200-admin-panel isolate depth exactly (boundary 2–3 levels).
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any low-priv account becomes administrator with 9 requests: roster disclosure + arbitrary deletion (carlos deleted). Traversal also leaks key-directory depth.

## Why The Successful Approach Worked

- Cost ordering (claim → none → traversal) + depth matrix (shallow→deep, one axis) instead of jumping to key hunting or null-byte variants (never needed).
- Boundary reading: shallow-401 vs mid-200 pinpoints keydir depth without source access.

## Generalization

- For UUID/`kid` + HS256: test traversal to `/dev/null` with empty-key signing at increasing depths (`../` ×1–7); the 401→200 boundary reveals keydir depth.
- Null-byte/encoded variants (`%00`, `%2e%2e`) stay in reserve until plain traversal is exhausted.

## Lessons Learned

- Fifth JWT family lab; methodology/jwt.md step 5 (`kid` variants) was future work until now — this lab evidences path-traversal-to-empty-key with depth-boundary reading. `jku`/`x5u` remain future work.
- 401/401/401/200/200 across the matrix is a complete depth oracle in 5 requests.

## Related Methodology

- methodology/jwt.md (kid-traversal sequence — genuinely new; update justified, applied separately)
- methodology/traversal.md (depth-boundary reading transfers; deliberate cross-link, no duplication)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-kid-header-path-traversal (objective only; solution not consulted — H1→H2→depth-matrix from methodology)
- Prior related (sequence sources): the three earlier JWT notes (all falsification patterns reused)
- Solved instance: https://0ac500dc04647670827d518a0005007c.web-security-academy.net/ with `kid:../../../dev/null` + empty-key HS256 `sub=administrator` JWT
