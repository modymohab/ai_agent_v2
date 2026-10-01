# PortSwigger Lab

## Lab

JWT authentication bypass via jku header injection

URL: https://0a1e002b03e7686a80ca0dda00ab00ef.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — server fetches the RS256 verification key set from an attacker-controlled `jku` URL → self-signed administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + RS256 JWT (`kid` UUID), payload `{"iss":"portswigger","exp":1789609020,"sub":"wiener"}`.

## Hypotheses

- H1: absent verification (claim-only). H2: `alg:none`. H3: `jku` key-set injection (own RSA keypair + hosted JWKS + RS256 self-sign).

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 → **401**. H2 → **401**. Both cleanly falsified.
3. H3: RSA-2048 keypair generated (`cryptography`); JWKS (`kty:RSA,kid:attacker-kid,use:sig,n,e`) hosted on the lab exploit server (`/keys.json`, STORE action, verified served); forged header (`kid:attacker-kid,alg:RS256,jku:<keys.json>`) + `sub=administrator`, RS256-signed → `GET /admin` → **200 full admin panel** (Users, roster, Delete links). SUPPORTED.
4. `GET /admin/delete?username=carlos` → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED (~10 requests + keygen/hosting).

## What Failed

- H1/H2 401s (2 cheap falsifications — verification present, alg locked, keyed RS256 confirmed real).

## What Worked

Attacker-hosted JWKS + `jku` + matching `kid` + RS256 self-sign → admin → delete → solved.

## Burp Observations

- Baseline CSRF/login via Burp MCP. Forged-token verdicts via CLI (crypto advantage), body-checked (roster/links).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `cryptography` (RSA keygen, PKCS1v15/SHA256 sign); exploit-server STORE form (responseFile/responseHead/responseBody) for JWKS hosting with serve-verification before forging.

## Root Cause

The verifier resolves its RS256 trust anchor from the UNVALIDATED `jku` header URL instead of server-side key material: any client hosting a JWKS becomes its own certificate authority. `kid` agreement (header↔JWKS) is the only linkage, fully attacker-controlled.

## Verification

- H1/H2 401s vs H3 200-admin-panel isolate the key-source axis exactly.
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any low-priv account becomes administrator with one keypair + one hosted file: roster disclosure + arbitrary deletion (carlos deleted). No crypto barrier (no cracking, no brute-force).

## Why The Successful Approach Worked

- Cost ordering (claim → none → jku) meant the two 401s selected key-source attacks over blind key hunting.
- JWKS serve-verified BEFORE forging (no wasted signatures against a dead URL); `kid` agreement header↔JWKS from the start (JWK-shape lesson transferred).

## Generalization

- For RS256 + `kid` with verification present and alg locked: test `jku` (and `x5u`) key-source injection — own RSA keypair, host JWKS on an attacker-controlled HTTPS URL the target can reach, `kid` agreement, self-sign. Serve-verify the JWKS first.
- `jku` completed the `kid`-variant ladder (traversal done previously); remaining: `x5u` (same shape, certificate chain — by analogy, untested).

## Lessons Learned

- Sixth JWT family lab; methodology/jwt.md step 6 (`jku`/`x5u`) was future work until now — `jku` evidenced, `x5u` still future by explicit analogy (not claimed).
- Attacker infrastructure (keypair + hosted JWKS) is part of the minimal plan for key-source vectors — prepare before forging.

## Related Methodology

- methodology/jwt.md (jku-injection sequence — genuinely new; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-jku-header-injection (objective only; solution not consulted — H1→H2→H3 from methodology cost ranking)
- Prior related (sequence sources): the four earlier JWT notes
- Solved instance: https://0a1e002b03e7686a80ca0dda00ab00ef.web-security-academy.net/ with `jku`-hosted-RSA self-signed `sub=administrator` JWT
