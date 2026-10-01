# PortSwigger Lab

## Lab

JWT authentication bypass via weak signing key

URL: https://0a55001704fb722e815fc097004600e9.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — HS256 signed with a brute-forceable secret (`secret1`) → forged administrator claims → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE: `GET /login` → 200 CSRF-bound form (JWT family pattern holds).
- CURRENT EVIDENCE: bound `POST wiener:peter` → 302 + JWT session; decoded header `{"kid":"cc0a20cc-...","alg":"HS256"}`, payload `{"iss":"portswigger","exp":1789608615,"sub":"wiener"}` — symmetric algorithm, key attack surface.

## Hypotheses

- H1: absent verification (claim-only). H2: `alg:none`. H3: weak HS256 secret, crackable offline.

## Attempts

1. CSRF-bound baseline login → JWT (3 reqs).
2. H1 (claim-only `sub`→administrator) → `GET /admin` → **401**. Rejected (one request recorded on the old lab URL by scripting slip + one on the correct host — conclusion rests on the correct-host 401).
3. H2 (`alg:none` + empty sig) → **401**. Rejected.
4. H3: quick Python HMAC check over Academy 100 + 13 commons → no hit (113 candidates).
5. `hashcat -m 16500` (JWT) + repo `rockyou.txt` → **secret `secret1`** in seconds (offline, zero target requests).
6. Forged `sub=administrator`, re-signed HS256/`secret1` → `GET /admin` → 200 full panel (Users, roster, Delete links). SUPPORTED.
7. `GET /admin/delete?username=carlos` → 302 → re-read: `is-solved` + `User deleted successfully!`, carlos gone. SOLVED.

## What Failed

- H1/H2 clean 401s — correct cheap falsifications (verification present, alg locked); 2 requests well spent.
- Quick-list crack miss (113 candidates) — bounded the search before GPU work, justified hashcat escalation.

## What Worked

Offline hashcat crack (`secret1`) → validly-signed admin forgery → delete → solved. No throttling, no lockout, fully offline crypto phase.

## Burp Observations

- Baseline CSRF/login via Burp MCP; forged-token verification via CLI (encoding advantage). H1's correct-host 401 + H2's 401 both body-checked as real denials.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `hmac`/`hashlib` for quick-list elimination; `hashcat -m 16500` + repo rockyou for the crack; Python for HMAC re-signing. First hashcat usage in this KB — tool justified by H1/H2 falsification (keyed verification proven present).

## Root Cause

HS256 symmetric signing with a dictionary-crackable secret (`secret1`): anyone holding one valid token (structure oracle) recovers the key offline and mints arbitrary claims with VALID signatures. Symmetric JWT + weak secret = server-wide forgery.

## Verification

- H1/H2 401s vs H3 200-admin-panel isolate the key axis exactly.
- Delete → 302 → re-read: success message + victim absent + `is-solved`. Victim state change on both readings.
- Forgery determinism: independently re-signed token accepted repeatedly (panel + delete + proof).

## Impact

Any low-priv account becomes administrator offline (zero online attack footprint beyond normal logins): roster disclosure + arbitrary deletion (carlos deleted).

## Why The Successful Approach Worked

- Cost ordering held: 2 one-request falsifications before GPU escalation (never lead with cracking).
- Quick-list elimination (113) before rockyou bounded the escalation rationally.
- Crack ran fully offline — throttling/lockout irrelevant by construction.

## Generalization

- HS256 in the header → secret-strength test belongs in the JWT sequence after alg:none fails: quick-list → hashcat/John + quality wordlist (repo rockyou registered).
- 401/401 on H1/H2 with HS256 present = keyed verification with weak-key hypothesis, not a dead end.

## Lessons Learned

- Third JWT family lab; methodology/jwt.md had no key-cracking step — this lab adds it (first hashcat usage recorded with mode + wordlist).
- Scripting-slip request to a stale host (old lab URL) recorded honestly and excluded from conclusions.

## Related Methodology

- methodology/jwt.md (weak-secret crack sequence — genuinely new step; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-weak-signing-key (objective only; solution not consulted — H1→H2→crack order from methodology)
- Prior related (sequence sources): jwt-authentication-bypass-unverified-signature.md, jwt-authentication-bypass-flawed-signature-verification.md
- Solved instance: https://0a55001704fb722e815fc097004600e9.web-security-academy.net/ with HS256/`secret1`-signed `sub=administrator` JWT
