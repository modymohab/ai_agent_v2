# PortSwigger Lab

## Lab

Username enumeration via subtly different responses

URL: https://0a310034038721bf80ca80c9006000f9.web-security-academy.net

## Vulnerability Class

Authentication — username enumeration via subtly different login failure responses, then password brute-force → account takeover

## Objective

Enumerate a valid username, brute-force its password (wordlists provided by lab), access the account page. Solved when account page accessed (`is-solved` on `/`).

## Initial Observations

- Blog app; only auth surface is `POST /login` (`username`+`password`, no CSRF token — differs from SQLi-lab login forms); `/my-account` → 302 when anon; `/forgot-password`, `/register`, `/admin` → 404.
- Invalid login → 200 `Invalid username or password.` — identical across candidates at first glance.

## Hypotheses

- H1: Failure responses for valid vs invalid usernames differ in a subtle channel (byte-level message text, headers, timing, lockout state).
- H2: Once a valid username is isolated, its password is brute-forceable from the provided password wordlist (302 = success).
- H3: Login as enumerated user → `GET /my-account` 200 with that identity → solved.

## Attempts

1. Body/word comparison across 7 candidates (nonexistent/administrator/admin/carlos/wiener/root/test) with text normalization → all `Invalid username or password.`, normalized diff ZERO. Taught nothing yet — normalization was the mistake (see Root Cause).
2. Header comparison (`Set-Cookie`, lengths) → identical. Ruled out.
3. Timing: 6-sample then 20-sample statistical comparison (`zzznooneinvalid` vs `administrator`, trimmed means 0.3367 vs 0.3361) → identical. Ruled out timing oracle.
4. Lockout: 8 then 15 rapid failures on `administrator` → all responses identical. Ruled out lockout oracle.
5. Empty/missing password → 400 `Missing parameter` for both valid-candidate and invalid → identical. Ruled out.
6. Seeded creds (`wiener:peter`, `carlos:montoya`, `administrator:administrator`, `admin:admin`) → all rejected. This lab uses different accounts; also meant no known-valid reference existed for differential testing.
7. Backend-variant split (`<!-- -->` intermittent markup proved ≥2 backends): partitioned responses WITH vs WITHOUT the comment, diffed valid-candidate vs invalid within each → still zero. Ruled out version-skew oracle.
8. Genuinely stuck on oracle → consulted official lab description (permitted). Learned: typo oracle (trailing space vs period) + wordlist URLs. All subsequent steps re-verified by current evidence, not taken on faith.
9. Byte-EXACT scan (Python, no normalization) over extracted 101-username wordlist with fixed wrong password → 100× `password.<`, exactly one `password <`: **`americas`**. H1 confirmed.
10. Extracted 100-password wordlist; scanned `americas` + each → exactly one 302: **`moon`**. H2 confirmed.
11. `POST /login americas:moon` → 302 `/my-account?id=americas` + fresh session → `GET /my-account` → 200 `Your username is: americas`; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- All normalized comparisons (whitespace-collapsed, stripped) — destroyed the single-byte oracle. The `$(...)` shell capture also strips trailing whitespace: my early `len=29` loop was blind by construction.
- Timing/lockout/header/endpoint-discovery families — correctly eliminated, each with recorded evidence; not wasted (they bounded the search).
- Chasing the intermittent `<!-- -->` markup (rates 5–9/12 across names) — infrastructure noise (two backends), proven uniform, abandoned.

## What Worked

- Byte-exact message comparison over the provided username wordlist → `americas` (`Invalid username or password ` + space).
- Password scan for that user → `moon` (302).
- Login → account page → solved.

## Burp Observations

- Not used via Burp MCP; official path uses Intruder + Grep-Extract, but curl loops with byte-exact matching were minimal and sufficient. Intruder equivalent: sniper on `username`, Grep-Extract on the message, sort to surface the space-typo row.

## Browser Observations

- Not required. Pure HTTP flow.

## CLI / Tool Observations

- curl + Python (no shell string capture for oracle bytes); `difflib` on normalized text for elimination, raw substring test (`password.<` vs `password <`) for the hunt.
- Wordlist extraction: page HTML → strip tags → single-token lines (`carlos`… 101 names; `123456`… 100 passwords), saved only to /tmp (lab-specific, NOT added to repo wordlists).

## Root Cause

Login failure messages differ by account existence: nonexistent users get `Invalid username or password.` (period) while the valid user gets `Invalid username or password ` (trailing space). The one-byte difference enables username enumeration; combined with no brute-force protection and a predictable password (`moon`), it yields full account takeover of `americas`.

## Verification

- Oracle isolation: 101 usernames × same wrong password → exactly one SPACE variant (`americas`); re-requested to confirm determinism.
- Password isolation: 100 passwords × `americas` → exactly one 302 (`moon`); others 200.
- Auth proof: 302 → `/my-account?id=americas` + session cookie; account page 200 renders `americas`; `/` marker `is-notsolved` → `is-solved`. Deterministic end-to-end.

## Impact

Account takeover of `americas` (read/update account data, act as that user). Same primitive in real apps enables credential-stuffing preparation and targeted brute-force.

## Why The Successful Approach Worked

- Recognized the missing known-valid reference made “compare valid vs invalid” impossible — switched to population scan (entire wordlist) for the odd-one-out.
- Dropped all normalizing comparisons after the solution hint; byte-exact matching surfaced the one-byte signal immediately.
- Enumerate-first (101 reqs) then brute-force-one-user (100 reqs) = ~200 requests vs 101×100 cluster bomb.

## Generalization

- NEVER normalize when hunting subtle oracles: compare raw bytes (trailing spaces, punctuation, NBSP, `\r\n` vs `\n`); shell `$(...)` and text `.strip()` destroy evidence — use Python/xxd on raw bodies.
- Elimination order for login oracles: exact bytes → headers → timing (statistics, n≥20) → lockout (≥15) → param edge cases → backend-version split → then consult writeup (stuck provision).
- Enumerate-then-brute-force beats cluster bomb; 302 (+ session + redirect target naming the user) is the password oracle; account-page identity render is the proof.

## Lessons Learned

- My 7-candidate “identical” conclusion was an artifact of normalization, not evidence — methodology now mandates raw-byte comparison first.
- Intermittent markup across responses signals multi-backend noise; partition before concluding, then abandon if uniform.
- Seeded creds from other labs (`wiener:peter`) failing is itself information: different account base, don't anchor.

## Related Methodology

- methodology/authentication.md (username enumeration — to be created from stub)
- methodology/verification.md (raw-byte differential + fresh-session proof)

## References

- Lab: https://portswigger.net/web-security/authentication/password-based/lab-username-enumeration-via-subtly-different-responses (description + solution consulted AFTER systematic elimination; all findings re-verified by current evidence)
- Wordlists: auth-lab-usernames / auth-lab-passwords (lab-specific; used from /tmp, not added to repo)
- Solved instance: https://0a310034038721bf80ca80c9006000f9.web-security-academy.net/
