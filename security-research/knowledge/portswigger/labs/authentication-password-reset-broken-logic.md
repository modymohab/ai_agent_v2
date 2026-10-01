# PortSwigger Lab

## Lab

Password reset broken logic

URL: https://0a2800af04760524869a78d5002a005b.web-security-academy.net/

## Vulnerability Class

Authentication – password-reset broken logic: reset token validated independently of the `username` POST parameter, so a token minted for the attacker's account resets the VICTIM's password

## Objective

Take over Carlos's account by resetting his password with attacker's own token, then log in (solved marker flips on authenticated homepage visit). Established by `is-solved` after `carlos:pwned123` login + `/` visit. Official description not fetched; flow mapped from forms + email evidence.

## Initial Observations

- Blog + `/my-account`; login form has `Forgot password?` link (no csrf on login).
- `wiener:peter` works (302) – own baseline account available.
- `/forgot-password` form: single `username` field → `Please check your email` (token emailed, unobservable except via own inbox).
- Own reset for `wiener` → email with link `/forgot-password?temp-forgot-password-token=<32c>` → reset form contains THREE security-relevant fields: hidden `temp-forgot-password-token` + hidden `username=wiener` + `new-password-1/2` – token and identity travel SEPARATELY (current evidence shaping H1).
- Stored `methodology/authentication.md` (enumeration overt/subtle, 2FA logic/skip; no password-reset section). No prior reset labs.

## Hypotheses

- H1: Token validates session/validity but NOT username binding – `username` from POST body decides whose password changes. Evidence needed: own token + `username=carlos` → 302 (vs error) → carlos login with new password works.
- H2: Fresh login as carlos + identity render + homepage marker = proof chain (marker-location lesson reused).

## Attempts

1. Baseline `GET /login` + `POST wiener:peter` (302) + `GET /forgot-password` (form mapped) – flow recon in 3 requests.
2. `POST /forgot-password username=wiener` → check-email page → email client → token link → reset form fields captured (token + separate username – H1's precondition observed, not assumed).
3. `POST /forgot-password?token=<own-token>` with `username=carlos&new-password-1/2=pwned123` → 302 to `/` – accepted (no binding error).
4. `POST /login carlos:pwned123` → 302 to `/my-account?id=carlos` + session – H1 confirmed (victim password changed by attacker token).
5. `GET /my-account?id=carlos` → 200 renders `carlos`/`carlos@carlos-montoya.net` (identity proof; banner still `is-notsolved`) → `GET /` → `is-solved`/`Solved`/`Congratulations` – H2 confirmed (marker-location lesson reused verbatim).

## What Failed

- Nothing on target. No dead ends; 7 functional requests.

## What Worked

- Own-token mint → cross-user reset POST → victim login → identity render → homepage marker.

## Burp Observations

- Baseline, login (302), reset request, token-link fetch (form fields), cross-user reset (302), victim login (302 + session + redirect target), identity render, proof (`200 is-solved`) – all via Burp MCP.

## Browser Observations

- Not required. Email client read via Burp (token extraction); no JS/state workflow.

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No scanner/crawler/fuzzer.

## Root Cause

Reset handler validates the token's EXISTENCE/validity but takes the target account from the client-controlled `username` form field instead of the token's bound identity. Attacker's legitimately-minted token + victim's username = victim password overwrite. Token–identity binding missing – the classic broken-reset-logic shape.

## Verification

- 302 on cross-user reset (accepted, not rejected) → victim login 302 + session + redirect naming carlos (password actually changed – not assumed from 302 alone).
- Identity render (`carlos` + victim email) → global marker on `/` (account page alone still `is-notsolved` – both surfaces checked per prior lesson).

## Impact

Full victim account takeover (password overwrite + authenticated session + PII email render) using only attacker's own legitimate reset token. Same primitive compromises any account (including admins) without brute force or email access.

## Why The Successful Approach Worked

- Read the reset form's field split (token + username traveling separately) as the binding hypothesis BEFORE submitting – the form structure advertised the flaw.
- Minted own token legitimately (no token theft needed) – the flaw is binding, not secrecy.
- Verified password change by LOGGING IN as victim (302 + session + redirect), not by trusting the reset 302.

## Generalization

- For reset flows with separate token + identity fields: mint own token → read reset form (token field vs identity field) → submit own token + VICTIM identity + attacker password → verify by victim login (302 + session + redirect target) → identity render → homepage marker (not just account page).
- Token validity ≠ token binding – always test cross-user submission; 302 on reset proves acceptance, login proves effect.

## Lessons Learned

- Hidden form fields (`username=wiener`) are attacker-controlled inputs, not server state – re-read them as hypotheses, especially alongside tokens.
- Reset 302 proves acceptance only; victim-login 302 proves effect – two different 302s, both required.
- Marker-location lesson repeats (homepage flip) – now routine to check both surfaces.

## Related Methodology

- Extends `methodology/authentication.md` (no password-reset section – update justified below; 5th auth lab, new sub-technique: token–identity binding).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: all auth notes (302+session proof, identity render, marker-both-surfaces reused); 2FA-skip (given-flow mapping discipline).

## References

- Solved instance: https://0a2800af04760524869a78d5002a005b.web-security-academy.net/
- Lab: https://portswigger.net/web-security/authentication/other-mechanisms/lab-password-reset-broken-logic
- Flow evidence: reset form fields (`temp-forgot-password-token` + `username` separate), own token `cifaqxo4i8acb1t7f3x2583kp3xorvgi` (instance-bound), victim creds set: carlos / pwned123 (instance-bound)
- Deliberately did NOT fetch official solution; binding flaw read from form structure, verified by victim login.
