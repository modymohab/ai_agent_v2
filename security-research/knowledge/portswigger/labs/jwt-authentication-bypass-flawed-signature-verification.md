# PortSwigger Lab

## Lab

JWT authentication bypass via flawed signature verification

URL: https://0ae9008b0478b6c981a27aa60052001b.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — `alg:none` accepted with empty signature → vertical privilege escalation (administrator) → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the panel shows `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE (Burp): `GET /login` → 200 form with `csrf` (JWT family requires binding, as prior lab).
- CURRENT EVIDENCE: CSRF-less `POST wiener:peter` → 400; token+cookie pair → 302 `/my-account?id=wiener` + RS256 JWT (`kid` UUID).
- CURRENT EVIDENCE: decoded payload `{"iss":"portswigger","exp":1789608494,"sub":"wiener"}`.

## Hypotheses

- H1: absent verification (claim-only `sub`→administrator, signature untouched).
- H2: `alg:none` + empty signature accepted.
- H3 (untested): RS256→HS256 confusion (kept in reserve).

## Attempts

1. CSRF-bound baseline login → JWT session (3 reqs).
2. H1 (`sub`→administrator, original header+sig) → `GET /admin` → **401** `Admin interface only available if logged in as an administrator` (+ session cleared). H1 REJECTED — signature IS verified here (title said "flawed", not "unverified").
3. Procedural error noted: first H1 attempt accidentally sent literal `PLACEHOLDER_H1` (also 401); immediately re-ran with the real forged token → same 401. Both recorded honestly; conclusion rests on the real token.
4. H2 (`{"alg":"none"}` + forged `sub` + empty segment) → `GET /admin` → **200** + full admin panel (Users, wiener/carlos roster, Delete links, Admin nav). H2 SUPPORTED — content proof, not status alone.
5. `GET /admin/delete?username=carlos` with H2 token → 302 `/admin`.
6. Re-read `/admin` → `is-solved` + `User deleted successfully!`, carlos absent. SOLVED (~9 requests total).

## What Failed

- H1 claim-only forgery (401) — the correct negative that distinguished this lab from the prior unverified-signature instance; cost-ordering worked as designed (cheap falsification before machinery).
- One placeholder-cookie mistake (my scripting error) — caught immediately by re-reading the request, corrected, no conclusion drawn from it.

## What Worked

`alg:none` + empty signature + `sub=administrator` → admin → delete carlos → solved.

## Burp Observations

- Baseline, H1 denial, and form-shape evidence via Burp MCP (full request/response). Forged-token admin/delete/proof via CLI loops (encoding advantage). H2's 200 confirmed as admin content via body grep, not assumed from status.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `base64.urlsafe_b64encode` + compact JSON for segment forging; `iss`/`exp` preserved (single-variable + one axis at a time: claim, then alg).

## Root Cause

Signature verification honors the attacker-supplied `alg` header: `none` disables the check while the server still trusts `sub` for authorization. RS256 verification exists (H1's 401 proves it) but is bypassable by algorithm downgrade — flawed, not absent.

## Verification

- H1 401 vs H2 200-admin-panel on the same endpoint isolates the alg axis exactly.
- Delete → 302 → re-read: `User deleted successfully!` + carlos gone + `is-solved`. Victim state change, both surfaces considered.
- Deterministic, minimal-request chain.

## Impact

Any low-priv account becomes administrator: roster disclosure + arbitrary user deletion (carlos deleted), no crypto needed.

## Why The Successful Approach Worked

- Cost ordering from methodology/jwt.md: claim-only (1 req falsification) before alg:none (1 req) before kid machinery (never needed).
- H1's clean 401 was INFORMATION (verification present) that selected H2 over H3 (no key hunting required).

## Generalization

- "Flawed" vs "unverified" in the title predicts H1's fate — but test H1 anyway (1 request) since a hit ends the lab immediately.
- A 401 differential between claim-only and alg:none fingerprints verification presence without any key material.

## Lessons Learned

- Second JWT family lab; methodology/jwt.md step 3 (`alg:none`) was an untested hypothesis until now — this lab verifies it. Step 4 (`kid`) remains future work.
- Placeholder-variable mistakes are caught by re-reading the actual sent request (Burp request echo), never by reinterpreting the response.

## Related Methodology

- methodology/jwt.md (alg:none verification — step 3 now evidence-backed; update justified, applied separately)
- methodology/access-control.md (vertical escalation via victim state change)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-flawed-signature-verification (objective only; solution not consulted — H1→H2 order came from methodology cost ranking)
- Prior related (sequence source, not answer): knowledge/portswigger/labs/jwt-authentication-bypass-unverified-signature.md (H1 hit there, cleanly falsified here)
- Solved instance: https://0ae9008b0478b6c981a27aa60052001b.web-security-academy.net/ with `alg:none` + `sub=administrator` JWT
