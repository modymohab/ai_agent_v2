# PortSwigger Lab

## Lab

Brute-forcing a stay-logged-in cookie

URL: https://0a4800da044288e2837aeb7100240042.web-security-academy.net/

## Vulnerability Class

Authentication — predictable `stay-logged-in` cookie (`base64(username:md5(password))`) forgeable offline → account takeover (carlos)

## Objective

Forge a valid `stay-logged-in` cookie for `carlos` and access his account page. Solved when the account page renders with `is-solved`.

## Initial Observations

- CURRENT EVIDENCE (Burp): `GET /login` → 200 form with `username` + `password` + `stay-logged-in` checkbox, no CSRF.
- CURRENT EVIDENCE (Burp): `POST wiener:peter&stay-logged-in=on` → 302 `/my-account?id=wiener` + `stay-logged-in=d2llbmVyOjUxZGMzMGRkYzQ3M2Q0M2E2MDExZTllYmJhNmNhNzcw` (Expires year 3000) + session.
- CURRENT EVIDENCE: base64 decode → `wiener:51dc30ddc473d43a6011e9ebba6ca770`; CLI `md5("peter")` = `51dc30ddc473d43a6011e9ebba6ca770` — exact match. Cookie structure fully determined from 2 requests.

## Hypotheses

- H1 (confirmed): cookie = `base64(username + ":" + md5(password))`.
- H2: server validates by recomputing MD5 with no server-side binding → forged cookie authenticates.
- H3: carlos's password is in the Academy 100-list; exactly one forged cookie renders his account.

## Attempts

1. Burp baseline (2 reqs): form shape, wiener login, cookie capture.
2. Offline structure analysis: decode + MD5 match (0 target requests).
3. Forge scan (CLI Python): MD5 each of 100 Academy passwords → `GET /my-account?id=carlos` with forged cookie, match `Your username is: carlos` → **`george`** hit (`Y2FybG9zOjliMzA2YWIwNGVmNWUyNWY5ZmI4OWM5OThhNmFlZGFi`), ~100 GETs, no lockout surface touched.
4. Burp verification: forged cookie → 200 + `is-solved` + `Solved` + `Congratulations, you solved the lab!` + `Your username is: carlos` + authenticated nav (My account/Log out) + fresh session. SOLVED on the proof request itself.

## What Failed

- Nothing: first forged hit was the password. No brute-force protection encountered (cookie validation is not rate-limited).

## What Worked

`GET /my-account?id=carlos` with `stay-logged-in=base64("carlos:"+md5("george"))` → full carlos session + solved marker.

## Burp Observations

- Login flow, cookie capture, and final proof all via Burp MCP (`burp_send_http1_request`) with full request/response evidence. `burp_base64_decode` for structure analysis.
- Bulk forge testing via CLI (hashing + loop), the smaller appropriate toolset; Burp-per-request would add nothing.

## Browser Observations

- Not required. Pure HTTP flow, no JS/state workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `hashlib.md5` + `base64` for offline forge generation; `GET`-only scan (read-only, no state change, no throttle risk).

## Root Cause

The persistent-login cookie is an unsigned, deterministic function of public values: `base64(username:md5(password))` with a 3000-year expiry. No HMAC, no server-side token store, fast unsalted MD5. Anyone who guesses the password offline (100-list) forges a valid eternal session cookie for any user.

## Verification

- Structure: decode + independent MD5 recomputation match on known account (wiener:peter).
- Hit uniqueness: single identity render among 100 forged cookies.
- Proof: forged-cookie request returns `is-solved` banner + `Solved` + congratulations + `Your username is: carlos` + authenticated navigation + fresh `session` cookie. Deterministic end-to-end.

## Impact

Full persistent account takeover of `carlos` (eternal cookie, year-3000 expiry) with zero failed-login footprint — invisible to brute-force monitoring.

## Why The Successful Approach Worked

- Solved the cookie structure from ONE known sample before touching the victim (decode → hash-identify → recompute-confirm), turning online brute-force into offline hashing + 100 clean GETs.
- GET-only scan: no failed logins, no counters, no lockout risk by construction.

## Generalization

- For persistent-login cookies: decode first (base64/hex), identify hash (length/charset), recompute against a known credential to confirm the construction, then forge offline and test — never brute-force the login form when the cookie is self-validating.
- Deterministic unsigned auth tokens are eternal forgery primitives; expiry dates (here year 3000) extend the impact.

## Lessons Learned

- First stay-logged-in family lab in the KB (grep confirmed no prior coverage); methodology had cookie/session mentions but no token-structure recipe.
- Two requests (login + decode) fully determined the construction; the remaining 100 were mechanical verification.

## Related Methodology

- methodology/authentication.md (persistent-login token analysis — new reusable pattern; update justified, applied separately)
- methodology/verification.md (independent recomputation + identity render + solved marker)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/authentication/other-mechanisms/lab-brute-forcing-a-stay-logged-in-cookie (objective only; solution not consulted — structure derived from own cookie)
- Candidate source (lab-published, `/tmp` only): `auth-lab-passwords` (100)
- Solved instance: https://0a4800da044288e2837aeb7100240042.web-security-academy.net/ with forged `carlos:george` cookie
