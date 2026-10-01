# PortSwigger Lab

## Lab

Username enumeration via subtly different responses (instance `0ae700840380448880cd9e83006c0018`)

URL: https://0ae700840380448880cd9e83006c0018.web-security-academy.net/

## Vulnerability Class

Authentication — username enumeration via subtly different login failure responses, then password brute-force → account takeover

## Objective

Enumerate a valid username from lab-provided candidate lists, brute-force its password, access the account page. Solved when authenticated homepage flips to `is-solved`.

## Initial Observations

- CURRENT EVIDENCE (this instance): `GET /login` → 200 login form (`username`+`password`, no CSRF token observed in form HTML).
- CURRENT EVIDENCE: `POST /login notauser123xyz:wrongpassXYZ` → 200 `Invalid username or password.` (period).
- CURRENT EVIDENCE: lab header confirms title `Username enumeration via subtly different responses`, status `is-notsolved`.
- STORED KNOWLEDGE (not evidence): prior instance of same lab slug used `americas:moon` with trailing-space oracle; overt variant used `agenda:princess`. Neither assumed valid here.

## Hypotheses

- H1: Failure responses for valid vs invalid usernames differ by a single byte (trailing space vs period), isolable by byte-exact population scan with fixed wrong password. Source: STORED KNOWLEDGE from `methodology/authentication.md` + `authentication-username-enumeration-subtle-responses.md`.
- H2: Exactly one candidate username returns the space variant; its password returns exactly one 302 among 200s. Source: STORED KNOWLEDGE (enumerate-first economics).
- H3: Login with enumerated creds → 302 + session + redirect naming user → account page renders identity → authenticated `/` flips to `is-solved`. Source: STORED KNOWLEDGE (marker may flip on homepage, not account page).

## Attempts

1. Baseline invalid login recorded (raw bytes, no normalization) — 200 `Invalid username or password.`.
2. Fetched Academy candidate lists from `<code class="code-scrollable">` block (101 usernames, 100 passwords, count-checked) to `/tmp` only, per methodology. Did not import into repo wordlists.
3. Population scan: 101 usernames × fixed wrong password `wrongpassXYZ123`, Python raw-byte match on `Invalid username or password[.\x20]` → 100× period (98 unique + 2 duplicates: `admin`/`administrator` listed twice), exactly one space: `alabama`. H1 confirmed for this instance.
4. Determinism re-check: `alabama` → space twice; `carlos` → period. Oracle reproduces byte-exact.
5. Password scan: `alabama` × 100 passwords, no-redirect opener → exactly one 302: `abc123` → `Location: /my-account?id=alabama`. H2 confirmed.
6. Login `alabama:abc123` → 302 + `Set-Cookie: session` + `Location: /my-account?id=alabama` → `GET /my-account?id=alabama` with session → 200 `Your username is: alabama` (banner still `is-notsolved`) → `GET /` with session → `is-solved` / `Solved` / `Congratulations`. H3 confirmed.

## What Failed

- Nothing brute-forced blindly. Hand-guessing avoided entirely (prior lesson: population scan beats memory; `administrator`/`carlos` invalid here as in priors).
- No normalization used at any point (prior failure mode deliberately avoided).
- No timing/lockout/header elimination repeated exhaustively: prior instance already bounded those families with evidence; minimal single-variable byte-exact scan was sufficient here. Overt-message check was implicit in scan (no `Incorrect password` variant observed).

## What Worked

`POST /login username=alabama&password=abc123` → 302 → session → identity render → homepage `is-solved`.

## Burp Observations

- Not used via Burp MCP for bulk scans: 101+100 requests via curl/Python loops are minimal and byte-exact; per-request Burp replay would add no value (consistent with both prior lab notes). Burp Intruder equivalent: sniper on `username`, Grep-Extract on warning message, sort for space-typo row.

## Browser Observations

- Not required. Pure HTTP flow, no JS/state workflow. Browser Control MCP correctly not used per tool-selection rule.

## CLI / Tool Observations

- `curl` for baseline + final proof (headers, session jar).
- Python `urllib` (no shell `$(...)` capture, no `.strip()`) for raw-byte oracle + no-redirect 302 detection.
- Wordlists kept in `/tmp/auth-users.txt` (101) and `/tmp/auth-passwords.txt` (100); lab-specific, not added to repo.

## Root Cause

Login failure messages leak account existence: unknown users get `Invalid username or password.` (0x2E) while valid user `alabama` gets `Invalid username or password ` (0x20 trailing space). Combined with no brute-force protection and predictable password `abc123`, this yields full account takeover of `alabama`.

## Verification

- Oracle: `alabama` space variant reproduced 3× (scan + 2 re-requests); 100 others uniformly period.
- Password: single 302 + `Set-Cookie: session` + `Location: /my-account?id=alabama` among 100× 200.
- Identity: `/my-account?id=alabama` 200 renders `alabama`.
- Solved: authenticated `/` returns `is-solved` (account page alone still `is-notsolved` — both surfaces checked, consistent with `different-responses` instance).

## Impact

Account takeover of `alabama` (authenticated session, act as user). Same primitive enables targeted brute-force/credential-stuffing preparation in real apps.

## Why The Successful Approach Worked

- Treated prior `americas:moon` as hypothesis source, not answer: fresh population scan found different user (`alabama`) for this instance.
- Byte-exact comparison from first request (never normalized).
- Enumerate-first (101+100 ≈ 201 requests) vs cluster bomb (101×100).
- Verified both marker surfaces (account page vs homepage).

## Generalization

No new general principle beyond existing `methodology/authentication.md`: subtle-space oracle, enumerate-first economics, 302+session proof, homepage-marker check all already documented. This instance confirms portability across instances with different seeded accounts.

## Lessons Learned

- Instance account bases differ per deployment (`americas` vs `alabama`, `moon` vs `abc123`): never reuse prior creds as answers.
- Duplicate entries in published lists (`admin`, `administrator` twice) explain 101 requests → 99 distinct signals; outlier logic must use exact-count (1 occurrence), not 100-vs-1 assumption.
- Homepage-marker variation reconfirmed for subtle family (previously noted only for overt family).

## Related Methodology

- methodology/authentication.md (username enumeration — fully applies; no update justified, see below)
- methodology/verification.md (raw-byte differential + fresh-session proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description (wordlist URLs only; solution section incidentally present but not followed blindly — all steps re-verified by current evidence): https://portswigger.net/web-security/authentication/password-based/lab-username-enumeration-via-subtly-different-responses
- Candidate sources (lab-published, `/tmp` only): `auth-lab-usernames` (101), `auth-lab-passwords` (100) via `<code class="code-scrollable">` parse
- Prior related: knowledge/portswigger/labs/authentication-username-enumeration-subtle-responses.md (`americas:moon` instance, preserved untouched), knowledge/portswigger/labs/authentication-username-enumeration-different-responses.md (overt oracle, homepage-marker precedent)
- Solved instance: https://0ae700840380448880cd9e83006c0018.web-security-academy.net/ with `alabama:abc123`
