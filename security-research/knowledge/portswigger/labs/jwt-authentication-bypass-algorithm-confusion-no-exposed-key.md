# PortSwigger Lab

## Lab

JWT authentication bypass via algorithm confusion with no exposed key

URL: https://0a3600f304bc240f80d3171500300008.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — RS256→HS256 algorithm confusion with the RSA public key recovered offline via GCD modulus derivation from two signatures (no key exposure) → forged administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + RS256 JWT (`kid` UUID), payload `{"iss":"portswigger","exp":1789609295,"sub":"wiener"}`.

## Hypotheses

- H1: absent verification. H2: `alg:none`. H3: confusion with key from non-obvious exposure. H4 (after external research, genuinely stuck): RSA modulus recoverable via GCD of two signatures → confusion with derived key.

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 → 401. H2 (alg:none) → 401. Empty-sig RS256 → 401.
3. Key recon: `/jwks.json`, well-known, robots, static dirs, page sources, headers → all 404/empty. TLS-cert public key as HMAC secret → 401 (wrong key, recorded).
4. Traversal+HS256 (`../dev/null` ×2 depths, empty key) → 401s. kid-as-key → 401. `secret1` reuse → 401. Embedded-JWK transfer → 401.
5. Stuck checkpoint: verification present, alg locked, no key anywhere reachable, no exploit server on this lab. External research consulted (writeups on this exact lab slug) — revealed GCD modulus recovery; used as hypothesis source, every step re-derived locally.
6. Second distinct JWT via fresh login (exp differs → signature differs).
7. Pure-Python big-int `s^e` infeasible (300s timeout, zero output) → installed `gmpy2` (via `python3 -m pip`, after discovering bare `pip` was Python 2.7's) → `n = gcd(s1^e − EM1, s2^e − EM2)` with PKCS#1-v1.5 EM reconstruction → 2048-bit n, SELF-VALIDATED (`pow(s,e,n)==EM` for BOTH tokens, proving e=65537 and n correct).
8. Encoding matrix with derived key: DER → 401; base64(DER) → 401; PKCS1 → 401; **PEM string bytes → 200 full admin panel** (Users, roster, Delete links).
9. `GET /admin/delete?username=carlos` → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED.

## What Failed

- H1/H2/empty-sig (401s), TLS key, traversal×2, kid-key, secret1, JWK-embed (401s) — each a clean falsification bounding the space; ~15 requests total before research.
- Pure-Python big-int arithmetic (infeasible scale: 2048-bit^65537 ≈ 134M-bit intermediates) — solved with gmpy2.
- No-exploit-server on this lab (jku-to-attacker-host impossible — correctly never attempted).

## What Worked

GCD modulus recovery (2 signatures) → PEM-envelope HMAC confusion → admin → delete → solved.

## Burp Observations

- Baseline CSRF/login via Burp MCP. Forged-token verdicts via CLI (crypto advantage); admin verdicts body-checked (roster/links), never status-only.

## Browser Observations

- Not required. Pure HTTP + offline crypto. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `hashlib` (EM reconstruction with SHA256 DigestInfo prefix), `gmpy2` (`pow`/`gcd` on 134M-bit intermediates — seconds vs infeasible), `cryptography` (SPKI/PEM/PKCS1 envelopes), `openssl s_client` (TLS-key elimination), `hashcat` NOT applicable (asymmetric — correctly never attempted).

## Root Cause

Two compounding properties: (1) the verifier infers the algorithm from the token header instead of pinning RS256, so HS256 with the public key bytes as HMAC secret verifies; (2) RSA signatures leak the modulus — `s^e − EM` is a multiple of `n`, so two signatures yield `n` via GCD, and the key envelope (PEM string) is then reconstructible offline. No key exposure needed; the signatures ARE the exposure.

## Verification

- H1/H2/TLS/traversal/kid-key/secret1/JWK 401s vs PEM-confusion 200-admin-panel isolate algorithm × key-source × envelope exactly.
- Modulus self-validation on both tokens BEFORE forging (wrong n/e cannot exhibit PKCS#1 structure with correct digests twice).
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change confirmed.

## Impact

Any low-priv account becomes administrator with two logins + offline math: roster disclosure + arbitrary deletion (carlos deleted). No secret to steal, no brute-force, no throttling interaction.

## Why The Successful Approach Worked

- Cost ordering held through 8 falsifications before external research (never read the solution first).
- Self-validating recovery (dual-token EM check) distinguished correct n from cofactor noise without any server interaction.
- Encoding matrix (DER/b64DER/PKCS1/PEM) instead of assuming one envelope — the writeups' "X.509" hint alone was ambiguous.

## Generalization

- For RS256 + no key exposure: collect TWO tokens (distinct exp) → GCD recovery (`n = gcd(s1^e − EM1, s2^e − EM2)`, PKCS#1-v1.5 EM with SHA256 DigestInfo) → validate on both → envelope matrix (PEM-string first per this evidence, then DER/PKCS1/b64) → HS256 confusion.
- Big-int scale demands gmpy2-class arithmetic; pure-Python `pow` without modulus is infeasible at 2048-bit^65537 — install first, compute second.
- External writeups are hypothesis sources for stuck positions only; every transferred claim (GCD shape, PEM envelope) re-verified locally before conclusions.

## Lessons Learned

- Eighth JWT family lab; methodology/jwt.md had no key-recovery step — this lab adds GCD recovery (largest single methodology addition this session). Only `x5u` remains future work.
- Falsification count (8) is proportional to certainty: each 401 eliminated exactly one axis.

## Related Methodology

- methodology/jwt.md (GCD modulus-recovery sequence — genuinely new; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-algorithm-confusion-with-no-exposed-key (objective only; solution not consulted)
- External writeups consulted AFTER stuck checkpoint (hypothesis sources, all claims re-derived): Kh4n Security JWT08 (GCD shape + sig2n reference), siunam JWT-8 (mint/scan mechanics + tampered-JWT testing), AdityaBhatt3010 (attack chain), OffSec Notes (endpoint shape)
- Prior related (sequence sources): the six earlier JWT notes
- Solved instance: https://0a3600f304bc240f80d3171500300008.web-security-academy.net/ with HS256/PEM-recovered-key-signed `sub=administrator` JWT
