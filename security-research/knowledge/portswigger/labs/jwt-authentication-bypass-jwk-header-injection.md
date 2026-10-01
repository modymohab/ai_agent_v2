# PortSwigger Lab

## Lab

JWT authentication bypass via jwk header injection

URL: https://0a7100680399609082a2bacd007000fd.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — server verifies HS256 with an attacker-embedded symmetric `jwk` → self-signed administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + RS256 JWT (`kid` UUID), payload `{"iss":"portswigger","exp":1789608768,"sub":"wiener"}`.

## Hypotheses

- H1: absent verification (claim-only). H2: `alg:none`. H3: embedded-`jwk` confusion (generate own oct key, `alg:HS256`, self-sign).

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 (claim-only) → **401**. H2 (`alg:none`) → **401**. Both cleanly falsified.
3. H3a (header `kid:attacker-key` + `alg:HS256` + bare `jwk:{kty,k}`, no kid inside) → **401**. Shape rejected.
4. H3b (original `kid` + `jwk` without kid) → **401**. Still rejected.
5. H3c/V2 (`kid:attacker-key` in header AND inside `jwk:{kty,kid,k}`) → **200 full admin panel** (Users, roster, Delete links). SUPPORTED. Sibling V3 (no `kid` anywhere) also rendered admin — strict shape (kid agreement) is the reliable variant; V2 used for the solve.
6. `GET /admin/delete?username=carlos` (V2 token) → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED (~12 requests total).

## What Failed

- H1/H2 401s (verification present, alg locked) — 2 cheap falsifications.
- Two loose-shape H3 variants (kid mismatch / kidless jwk) — the server validates JWK shape/agreement, not just presence; recorded as the shape constraint.

## What Worked

Strict-shape embedded JWK (`kid` agreement header↔jwk, `kty:oct`, fresh 256-bit key, HS256 self-sign) + `sub=administrator` → admin → delete → solved.

## Burp Observations

- Baseline CSRF/login via Burp MCP. Forged-token probes via CLI (crypto advantage); every admin verdict body-checked (roster/links), never status-only.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `os.urandom` + `hmac`/`hashlib` + base64url for JWK generation and HS256 signing; variant matrix (4 shapes) tested one axis at a time.

## Root Cause

The verifier builds its HS256 key from the UNVERIFIED `jwk` header parameter instead of server-side key material: any client supplying a well-formed symmetric JWK (with agreeing `kid`) becomes its own key authority. Self-signed administrator tokens verify cleanly.

## Verification

- H1/H2/H3a/H3b 401s vs V2 200-admin-panel isolate shape agreement exactly.
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any low-priv account self-mints administrator sessions offline: roster disclosure + arbitrary deletion (carlos deleted), zero online footprint beyond normal requests.

## Why The Successful Approach Worked

- Cost ordering (claim → none → jwk) + shape matrix (one axis per probe) instead of jumping to RSA confusion or key hunting.
- Body-content verdicts distinguished 200-denial from 200-admin (V2/V3) — status-only matching would have conflated them.

## Generalization

- For embedded-`jwk` confusion: random oct key per attempt (never reuse across variants — isolates shape from key); test kid agreement (header↔jwk), kidless, and mismatched shapes separately; HS256 downgrade is assumed, verify by acceptance.
- Loose-shape rejection is INFORMATION about server-side JWK validation — record the constraint, don't discard the vector.

## Lessons Learned

- Fourth JWT family lab; methodology/jwt.md step 4 (`kid`/key confusion) was future work until now — this lab evidences the `jwk` sub-variant with shape constraints.
- Fresh random key per variant prevents cross-variant contamination in oracle reading.

## Related Methodology

- methodology/jwt.md (embedded-JWK confusion sequence — genuinely new; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-jwk-header-injection (objective only; solution not consulted — H1→H2→shape-matrix from methodology + first principles)
- Prior related (sequence sources): jwt-authentication-bypass-unverified-signature.md, jwt-authentication-bypass-flawed-signature-verification.md, jwt-authentication-bypass-weak-signing-key.md
- Solved instance: https://0a7100680399609082a2bacd007000fd.web-security-academy.net/ with self-signed HS256/`jwk` (kid agreement) `sub=administrator` JWT
