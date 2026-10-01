# JWT Methodology

## Core Concept

JWT authentication fails when the server trusts token claims without verifying the signature, honors attacker-chosen algorithms/keys, or resolves verification keys from attacker-controlled inputs. The token's three segments (header.payload.signature) are attacker-readable (base64url) and, when verification is absent, attacker-writable.

## Security Boundary

Intended: only the server's signing key can mint/alter trusted identity claims.
Violated when: modified claims (e.g. `sub` → administrator) are accepted with a non-matching, empty, or attacker-computed signature.

## Recognition Patterns

- Session cookie with three dot-separated base64url segments.
- Header contains `alg` (e.g. RS256) and often `kid`.
- Payload contains identity claims (`sub`, sometimes `iss`/`exp`).
- Login forms in JWT families may REQUIRE csrf binding (token + cookie from the same response, resubmitted as a pair) — unlike earlier auth labs.

## Common Locations

- `session` cookie (JWT as the whole session token).
- `POST /login` (CSRF-bound in this family).
- `/admin` + `/admin/delete?username=<victim>` (privilege proof surface).
- `/my-account?id=<user>` (identity render proof surface).

## Indicators

- Claim-only forgery (`sub` changed, signature untouched) → 200 admin content = signature never verified.
- `alg:none` + empty signature segment → 200 = algorithm confusion accepted.
- User roster + delete links + admin nav in response = vertical escalation proof.

## Testing Methodology

1. Baseline: CSRF-bound login (token + cookie pair) → capture JWT → decode header/payload (no verification needed for reading).
2. Cheapest test first: single-variable claim forgery — change ONLY `sub` to a privileged identity, keep header and signature byte-identical → request the admin surface. A 200 with admin content proves absent verification; stop (no alg/kid machinery needed).
3. If (2) fails: test `alg:none` (header `{"alg":"none"}`, empty signature segment, `sub` forged).
4. If (3) fails and `alg` is symmetric (HS256): test secret strength offline — quick HMAC check over a small candidate list first, then `hashcat -m 16500` (JWT) with a quality wordlist (repo `wordlists/passwords/rockyou.txt`); re-sign forged claims with the cracked secret. Fully offline phase: throttling irrelevant.
5. If (4) is inapplicable (asymmetric RS256 verified, alg locked): test embedded-`jwk` confusion — generate a FRESH random oct key per variant (never reuse across probes), downgrade to `alg:HS256`, embed `jwk:{kty:oct,kid,k}`, self-sign. Test shape variants one axis at a time: kid agreement (header↔jwk) first, then kidless, then mismatched. Loose-shape 401s are information about server-side JWK validation — record the constraint. Verify verdicts by body content (roster/links), never status alone.
6. If `kid` looks like a key filename/UUID with HS256: test path traversal to `/dev/null` with EMPTY-key HS256 signing at increasing depths (`../` ×1–7, `sub` forged). The 401→200 boundary reveals keydir depth (here: `../` 401 vs `../../../` 200). Null-byte/encoded variants (`%00`, `%2e%2e`) stay in reserve until plain traversal is exhausted.
7. If RS256 is verified with `kid` and alg is locked: test `jku` key-source injection — generate own RSA keypair, host the public JWKS on an attacker-reachable HTTPS URL (serve-verify before forging), forge header (`kid` agreement header↔JWKS, `alg:RS256`, `jku:<url>`), RS256 self-sign `sub=administrator`. Remaining: `x5u` variant (same shape by analogy — future work).
8. If RS256 is verified and the RSA PUBLIC key is exposed (`/jwks.json`, page source, well-known paths — sweep cheap endpoints first): test RS256→HS256 algorithm confusion — HMAC-sign forged claims using the public key as the secret, PEM encoding first, DER second (one axis per probe). A 200-admin-panel on either isolates the encoding; claim-only/`alg:none` 401s beforehand prove keyed verification exists.
9. If NO key is exposed anywhere: recover the modulus offline via GCD — collect TWO tokens with distinct signatures (fresh logins, differing `exp`), reconstruct PKCS#1-v1.5 EM blocks (SHA256 DigestInfo prefix + `SHA256(header_b64.payload_b64)`), compute `n = gcd(s1^e − EM1, s2^e − EM2)` with gmpy2-class arithmetic (pure-Python big-int `pow` at this scale is infeasible — install first), SELF-VALIDATE (`pow(s,e,n)==EM` on both tokens proves n and e=65537), rebuild key envelopes (PEM-string first, then DER/PKCS1/base64), and run the step-8 confusion matrix with the derived key. Remaining: `x5u` variant (same shape by analogy — future work).
5. Preserve `iss`/`exp` during forgery (single-variable discipline); use compact JSON + base64url without padding.
6. Prove impact via victim state change: delete the victim user, re-read the panel (`User deleted successfully!` + victim absent + `is-solved`).

## Verification

- Admin access must render privileged function (roster/delete links), not just 200 status.
- Solved marker plus victim-row absence confirms effect; check both account and admin surfaces.
- Reproduce the forgery end-to-end; 7-request solves are achievable — keep request counts minimal.

## Common Failure Modes

- Omitting CSRF binding on login (400) — bind token+cookie as a pair in JWT families.
- Starting with alg/kid attacks before the one-request claim-only test.
- Changing multiple claims at once (breaks single-variable adjudication).
- Reporting 200 status without privileged-content proof.

## Impact Considerations

- Full vertical escalation: any low-priv holder becomes administrator (user enumeration via roster, arbitrary deletion).
- Forged tokens are stateless — no brute-force footprint, no throttling interaction.

## Lessons Learned

- From PortSwigger “JWT authentication bypass via unverified signature”: claim-only `sub`→administrator forgery hit on the FIRST attempt (7 requests total: baseline 3 + forgery 1 + delete 1 + proof 2). Absent verification beats weak verification as the opening hypothesis by cost ordering.
- From PortSwigger “JWT authentication bypass via flawed signature verification”: claim-only forgery → clean 401 (verification PRESENT — title said "flawed"); `alg:none` + empty signature → 200 full admin panel → delete carlos → `is-solved` (~9 requests). The H1/H2 differential fingerprints verification presence without key material; `kid` machinery correctly never needed.
- From PortSwigger “JWT authentication bypass via weak signing key”: claim-only → 401, `alg:none` → 401 (both rejected, HS256 present) → quick-list HMAC miss (113) → `hashcat -m 16500` + rockyou → `secret1` → validly-signed `sub=administrator` → delete carlos → `is-solved`. Cost order: falsify (2 reqs) → quick-list → GPU; crack phase fully offline.
- From PortSwigger “JWT authentication bypass via jwk header injection”: claim-only → 401, `alg:none` → 401, loose-shape JWK (kid mismatch / kidless jwk) → 401 — strict-shape embedded JWK (kid agreement header↔jwk, fresh oct key, HS256 self-sign) → 200 admin panel → delete carlos → `is-solved` (~12 requests). Fresh key per variant; body-content verdicts.
- From PortSwigger “JWT authentication bypass via kid header path traversal”: claim-only → 401, `alg:none` → 401 — `kid:../../../dev/null` + empty-key HS256 self-sign → 200 admin panel → delete carlos → `is-solved` (~9 requests). Depth matrix (`../` 401 vs `../../../`+ 200) reveals keydir depth; null-byte variants never needed.
- From PortSwigger “JWT authentication bypass via jku header injection”: claim-only → 401, `alg:none` → 401 — own RSA keypair + hosted JWKS (serve-verified) + `jku` with `kid` agreement + RS256 self-sign → 200 admin panel → delete carlos → `is-solved` (~10 requests + keygen/hosting). Attacker infrastructure prepared before forging.
- From PortSwigger “JWT authentication bypass via algorithm confusion”: claim-only → 401, `alg:none` → 401 — `/jwks.json` exposed RSA public key (matching `kid`) → HS256 HMAC with PEM bytes → 200 admin panel (DER variant 401) → delete carlos → `is-solved` (~13 requests). 401/401/200/401 is a two-axis (algorithm × encoding) oracle.
- From PortSwigger “JWT authentication bypass via algorithm confusion with no exposed key”: 8 clean falsifications (claim-only, alg:none, empty-sig, TLS key, traversal×2, kid-key, secret1, JWK-embed) → GCD recovery from 2 signatures (gmpy2 install; dual-token EM self-validation proves n and e) → PEM-envelope HS256 confusion → admin → delete carlos → `is-solved`. External writeups consulted only after stuck checkpoint; transferred claims re-derived locally.

## Related Concepts

- methodology/access-control.md (vertical escalation proof via victim state change)
- methodology/verification.md (302+render proof, dual-surface marker)
- methodology/authentication.md (CSRF+session binding, 302+session proof standard)

## Sources

- PortSwigger lab: JWT authentication bypass via unverified signature (knowledge/portswigger/labs/jwt-authentication-bypass-unverified-signature.md)
- PortSwigger lab: JWT authentication bypass via flawed signature verification (knowledge/portswigger/labs/jwt-authentication-bypass-flawed-signature-verification.md)
- PortSwigger lab: JWT authentication bypass via weak signing key (knowledge/portswigger/labs/jwt-authentication-bypass-weak-signing-key.md)
- PortSwigger lab: JWT authentication bypass via jwk header injection (knowledge/portswigger/labs/jwt-authentication-bypass-jwk-header-injection.md)
- PortSwigger lab: JWT authentication bypass via kid header path traversal (knowledge/portswigger/labs/jwt-authentication-bypass-kid-header-path-traversal.md)
- PortSwigger lab: JWT authentication bypass via jku header injection (knowledge/portswigger/labs/jwt-authentication-bypass-jku-header-injection.md)
- PortSwigger lab: JWT authentication bypass via algorithm confusion (knowledge/portswigger/labs/jwt-authentication-bypass-algorithm-confusion.md)
- PortSwigger lab: JWT authentication bypass via algorithm confusion with no exposed key (knowledge/portswigger/labs/jwt-authentication-bypass-algorithm-confusion-no-exposed-key.md)
