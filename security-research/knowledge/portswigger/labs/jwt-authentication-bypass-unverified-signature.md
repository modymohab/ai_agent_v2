# PortSwigger Lab

## Lab

JWT authentication bypass via unverified signature

URL: https://0af5007003eff72e83d30593006b0017.web-security-academy.net/

## Vulnerability Class

JWT authentication bypass — server accepts modified claims without verifying the signature → vertical privilege escalation (administrator) → user deletion

## Objective

Delete user `carlos` via the admin panel. Solved when the admin panel flips to `is-solved` with `User deleted successfully!`.

## Initial Observations

- CURRENT EVIDENCE (Burp): `GET /login` → 200 form with `csrf` hidden field (this lab family REQUIRES csrf; earlier auth labs did not).
- CURRENT EVIDENCE: `POST wiener:peter` without csrf → 400 `Missing parameter 'csrf'`.
- CURRENT EVIDENCE: token+cookie pair from same response → `POST` → 302 `/my-account?id=wiener` + session JWT (RS256, `kid` UUID).
- CURRENT EVIDENCE: decoded JWT header `{"kid":"17b5ec73-...","alg":"RS256"}`, payload `{"iss":"portswigger","exp":1789608347,"sub":"wiener"}`.

## Hypotheses

- H1: signature never verified → `sub=administrator` + original signature yields admin. (Cheapest single-variable test: only `sub` changes.)
- H2 (untested, unneeded): `alg:none` + empty signature.
- H3 (untested, unneeded): `kid`-keyed verification flaw.

## Attempts

1. CSRF-bound login (token + cookie from same `GET /login`, resubmitted as pair) → 302 + JWT session. Baseline established.
2. Forged `sub=administrator`, original header + original signature → `GET /admin` → 200 admin panel (user list wiener/carlos + delete links + Admin/My-account nav). H1 SUPPORTED on first forgery — 3 requests total to admin access.
3. `GET /admin/delete?username=carlos` with forged cookie → 302 `/admin`.
4. Re-read `/admin` → `is-solved` + `Solved` + `Congratulations, you solved the lab!` + `User deleted successfully!` + carlos gone (only wiener remains). SOLVED.

## What Failed

- One CSRF-less login (400) — form-shape probe that confirmed this family requires csrf binding; immediately corrected, not repeated.
- H2/H3 never tested (H1 sufficed — correctly not pursued).

## What Worked

Single-claim forgery (`sub` → `administrator`, signature untouched) → admin panel → delete carlos → solved marker.

## Burp Observations

- Entire lab via Burp MCP (`burp_send_http1_request`): baseline, CSRF probe, bound login, forged admin access, delete, solved proof — full request/response evidence, 7 requests total.
- CLI only for base64url forging (ordering/encoding advantage).

## Browser Observations

- Not required. Pure HTTP flow, no JS/state workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `base64.urlsafe_b64encode` + compact JSON for exact segment forging; original `exp`/`iss` preserved (single-variable change).

## Root Cause

The server decodes the JWT and trusts the `sub` claim for authorization WITHOUT verifying the RS256 signature — a structurally valid header/payload pair with any signature (here the original, now covering different claims) is accepted as administrator. Signature verification is absent, not merely weak.

## Verification

- Forged-token `/admin` → 200 + user list + delete links + admin nav (vs low-priv baseline expectations).
- Delete → 302 → re-read shows `User deleted successfully!` + carlos absent + `is-solved`/`Solved`/congratulations banner. Victim state change (not status alone) per access-control reference discipline.
- Deterministic end-to-end in 7 requests.

## Impact

Unauthenticated-equivalent administrator access from any low-priv account: read user roster, delete arbitrary users (carlos deleted), full admin-function compromise.

## Why The Successful Approach Worked

- Single-variable forgery first (`sub` only): distinguishes "no verification" from "weak verification" in one request — alg/kid attacks would have been wasted effort.
- CSRF binding respected from the first retry (token+cookie pair discipline from prior SQLi-login lesson).

## Generalization

- For JWT sessions: decode header/payload first; test claim-only forgery (`sub` → privileged identity, signature untouched) before any alg/kid machinery — a hit proves absent verification, the cheapest primitive.
- CSRF presence varies per lab family — probe once, then bind token+cookie as a pair.

## Lessons Learned

- First JWT family lab in the KB (methodology/jwt.md was an empty stub; zero prior JWT notes — grep-verified).
- 7-request solve: baseline (3) + forgery (1) + delete (1) + proof (2). Minimal-request discipline pays on unthrottled endpoints too.

## Related Methodology

- methodology/jwt.md (first content — unverified-signature test sequence; genuinely new family knowledge, applied separately)
- methodology/access-control.md (vertical escalation verified via victim state change)
- methodology/verification.md (302+render proof, dual-surface marker)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/jwt/lab-jwt-authentication-bypass-via-unverified-signature (objective only; solution not consulted — H1 tested first by cost ordering)
- Solved instance: https://0af5007003eff72e83d30593006b0017.web-security-academy.net/ with forged `sub=administrator` JWT
