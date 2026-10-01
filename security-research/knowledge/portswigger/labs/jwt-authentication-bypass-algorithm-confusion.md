# PortSwigger Lab

## Lab

JWT authentication bypass via algorithm confusion

URL: https://0a4500d9034026ce81b407a1006e000c.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — RS256→HS256 algorithm confusion using the exposed RSA public key as the HMAC secret → forged administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + RS256 JWT (`kid` UUID), payload `{"iss":"portswigger","exp":1789609164,"sub":"wiener"}`.
- CURRENT EVIDENCE (recon): `/jwks.json` → 200 (455 bytes) with the RSA public key (`kty:RSA`, matching `kid`, `e:AQAB`); `/robots.txt` + `/.well-known/jwks.json` → 404. Public key deliberately exposed.

## Hypotheses

- H1: absent verification (claim-only). H2: `alg:none`. H3: RS256→HS256 confusion with the exposed public key as HMAC secret (PEM vs DER encoding unknown — test both).

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 → **401**. H2 → **401**. Both cleanly falsified.
3. Recon: key-endpoint sweep (6 GETs) → `/jwks.json` hit with matching `kid`.
4. H3a (HMAC key = PEM-encoded public key, `kid` preserved, `alg:HS256`) → `GET /admin` → **200 full admin panel** (Users, roster, Delete links). SUPPORTED.
5. H3b (DER bytes as key) → 401 page — encoding matters, PEM confirmed (single spare probe, recorded).
6. `GET /admin/delete?username=carlos` → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED (~13 requests total).

## What Failed

- H1/H2 401s (2 cheap falsifications).
- DER-as-key variant (401) — encoding constraint information, not wasted.

## What Worked

PEM-public-key-as-HMAC-secret + `alg:HS256` + `sub=administrator` → admin → delete → solved.

## Burp Observations

- Baseline CSRF/login via Burp MCP. Forged-token verdicts via CLI (crypto advantage); admin verdicts body-checked (roster/links).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `cryptography` (JWK→RSA→PEM/DER reconstruction), `hmac`/`hashlib` for HS256 signing; endpoint sweep for key discovery.

## Root Cause

The verifier switches on the attacker-supplied `alg`: for HS256 it uses a key derived from the PUBLIC RSA key material (PEM form) instead of rejecting the algorithm mismatch or using a dedicated symmetric secret. Public keys are public — the "secret" is downloadable from `/jwks.json` — so anyone mints valid administrator tokens.

## Verification

- H1/H2/PEM/DER matrix (401/401/200/401) isolates both the algorithm axis and the key-encoding axis exactly.
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any low-priv account becomes administrator with public information only: roster disclosure + arbitrary deletion (carlos deleted). No secret to steal, no brute-force.

## Why The Successful Approach Worked

- Cost ordering (claim → none → confusion) + key discovery BEFORE crypto (endpoint sweep precedes forging).
- PEM-vs-DER tested as separate one-axis variants instead of assuming an encoding.

## Generalization

- For RS256 + `kid` with verification present: hunt the public key first (`/jwks.json`, page source, well-known paths); then RS256→HS256 confusion with PEM encoding first, DER second.
- Exposed public key + `alg` agility = confusion primitive; record which encoding the verifier uses.

## Lessons Learned

- Seventh JWT family lab; methodology/jwt.md had no algorithm-confusion step — this lab adds it (first RSA-public-as-HMAC-secret recipe). Only `x5u` remains future work.
- 401/401/200/401 across claim/none/PEM/DER is a complete two-axis oracle in 4 requests.

## Related Methodology

- methodology/jwt.md (algorithm-confusion sequence — genuinely new; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-algorithm-confusion (objective only; solution not consulted — H1→H2→key-hunt→confusion from methodology)
- Prior related (sequence sources): the five earlier JWT notes
- Solved instance: https://0a4500d9034026ce81b407a1006e000c.web-security-academy.net/ with HS256/PEM-public-key-signed `sub=administrator` JWT
