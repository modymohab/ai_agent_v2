# PortSwigger Lab

## Lab

Authentication bypass via encryption oracle

URL: https://0ac400ac043562dc83636e6e00e00072.web-security-academy.net/

## Vulnerability Class

Authentication bypass — comment error path exposes a symmetric encrypt/decrypt oracle pair (`notification` cookie): chosen plaintext in, ECB block surgery out → forged administrator `stay-logged-in` cookie

## Objective

Log in as administrator, access the admin panel, delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound login; `stay-logged-in` cookie = 32-byte base64 blob; block 1 byte-identical across logins (ECB/fixed-IV), block 2 random per login.
- CURRENT EVIDENCE: case-variant login (`WIENER`) authenticates as wiener with a DIFFERENT cookie — auth case-insensitive, cookie case-preserving (oracle-adjacent finding, not the path).
- CURRENT EVIDENCE: change-email works but never alters cookie size (email not in cookie); no register/forgot endpoints; `/admin` 401 anon.

## Hypotheses

- H1: comment error path encrypts attacker email into `notification` cookie and decrypts it for display (oracle pair) — from external research after ECB mapping stalled.
- H2: cookie format is `username:timestamp`; ECB block excision forges administrator.

## Attempts

1. ECB/case/length probing (cookie determinism, case oracle, email-length invariance) — mapped the cipher shape, found no direct input channel.
2. Stuck provision: external research for this exact slug → comment/notification oracle mechanics as hypothesis source.
3. Invalid-email comment (NoRedirect capture!) → `Set-Cookie: notification=<ct>` — redirect-following had silently eaten this cookie in the first attempt (same NoRedirect discipline as the state-skip lab).
4. `GET /post` with notification → renders `Invalid email address: oracleprobe1` + clears cookie. DECRYPT CONFIRMED.
5. Swapped stay-logged-in into notification → renders `wiener:1789616724839`. FORMAT + TIMESTAMP CONFIRMED.
6. Encrypted `xxxxxxxxxadministrator:<ts>` (9-pad → 23+9=32, two full prefix blocks) → dropped first 32 bytes → decrypt-verify → exactly `administrator:<ts>`. FORGERY CONFIRMED.
7. `stay-logged-in=<forged>` with NO session cookie → `Your username is: administrator` → `/admin` roster → delete carlos → `is-solved` ×2, carlos gone. SOLVED.

## What Failed

- Direct cookie tampering (all → login redirect; no padding oracle differentiator).
- Case-oracle path (real finding, wrong primitive — case variants can't spell administrator).
- Email-length influence tests (email provably outside the cookie).
- First oracle capture lost to redirect-following (fixed with NoRedirect before concluding anything).

## What Worked

Encrypt oracle → decrypt oracle → format learn → padded ECB excision → sessionless admin login → delete → solved.

## Burp Observations

- Login/cookie analysis via Burp-equivalent flows; oracle encrypt/decrypt/verify/forgery chain via CLI (binary/base64 advantage, NoRedirect control).

## Browser Observations

- Not required. Pure HTTP + crypto flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python base64/url-codec + 16-byte block surgery; NoRedirect opener for Set-Cookie capture; decrypt-oracle as its own proof harness (every forgery verified by decryption BEFORE use).

## Root Cause

Two compounding flaws: (1) the comment error path encrypts attacker-controlled email into a cookie AND decrypts arbitrary cookie values into error display — a full chosen-plaintext + decryption oracle pair sharing the session cipher; (2) the session cookie is ECB (deterministic blocks), so prefix-block excision forges arbitrary `username:timestamp` values with no key.

## Verification

- Oracle proofs: encrypt(oracleprobe1)→ct→decrypt→verbatim message; decrypt(session-cookie)→`wiener:<ts>`.
- Forgery proof: decrypt(forged)→`administrator:<ts>` exactly (no prefix), THEN used for login (never untested).
- Login proof: identity render as administrator with session cookie REMOVED (stay-logged-in alone suffices).
- Delete → re-read: `is-solved` + victim absent. Victim state change confirmed.

## Impact

Any low-priv user forges any identity including administrator (roster + arbitrary deletion, carlos deleted) with ~10 requests and no crypto knowledge beyond block surgery.

## Why The Successful Approach Worked

- Stuck provision at the right time (cipher shape fully mapped, no input channel found) + every transferred claim re-verified (encrypt→decrypt round-trip before forgery; forgery→decrypt before login).
- NoRedirect discipline (same lesson as state-skip lab, new context).
- Padding math on paper (23+9=32) before encrypting — one oracle call, not a padding search.

## Generalization

- NEW reusable pattern for methodology/authentication.md: symmetric-cookie oracle chains (encrypt endpoint + decrypt endpoint sharing the session cipher → format learn → padded ECB excision → sessionless use).

## Lessons Learned

- Error-display cookies that round-trip attacker input are decrypt oracles until proven otherwise — test by swapping in a known ciphertext (own session cookie).
- Redirect-following silently eats Set-Cookie oracles — NoRedirect capture is mandatory for encrypt-oracle work.

## Related Methodology

- methodology/authentication.md (crypto-oracle extension — genuinely new; update justified, applied separately)
- methodology/verification.md (oracle round-trips + decrypt-before-use + victim-state proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description + external writeups for this exact slug (hypothesis sources after stuck checkpoint: comment/notification oracle pair, 23+9 padding, sessionless use; all re-verified locally)
- Solved instance: https://0ac400ac043562dc83636e6e00e00072.web-security-academy.net/ with ECB-excised `administrator:<ts>` stay-logged-in cookie → delete carlos
