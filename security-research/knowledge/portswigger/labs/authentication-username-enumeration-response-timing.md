# PortSwigger Lab

## Lab

Username enumeration via response timing

URL: https://0a01007e047db32580615db60091009d.web-security-academy.net/

## Vulnerability Class

Authentication — username enumeration via response-timing oracle (password-hash delay only for valid users), then password brute-force → account takeover (apache)

## Objective

Enumerate a valid username via timing differences, brute-force its password from lab-provided candidate lists, access the account page. Solved when authenticated homepage flips to `is-solved`.

## Initial Observations

- CURRENT EVIDENCE: `GET /` + `GET /login` → 200, form `username`+`password`, no CSRF observed; header confirms title `Username enumeration via response timing`, `is-notsolved`.
- CURRENT EVIDENCE (pre-lockout): invalid user timing ~0.30s for both short and 130-char passwords — no length effect for invalid (hashing skipped).
- CURRENT EVIDENCE: after a rapid 101-request population scan, ALL `POST /login` returned `You have made too many incorrect login attempts. Please try again in 30 minute(s).` — self-inflicted IP block (see What Failed). Block persisted across turns; each status re-probe risked extending the window.

## Hypotheses

- H1: Valid usernames incur extra delay with LONG passwords (server hashes the supplied password only if the user exists); invalid usernames return fast regardless of length.
- H2: The IP block keys on the effective client IP and honors `X-Forwarded-For` when present, so a fresh XFF value partitions the counter (single-probe test, not assumed).
- H3: Exactly one candidate shows deterministic elevated median delay; its password returns a single 302.
- H4: Login → identity render → `is-solved` (check account page and `/`).

## Attempts

1. Rapid 101-username byte-exact scan (fixed wrong password, no XFF, no throttle) → triggered 30-minute IP block before any timing work. Taught the lockout cost (see What Failed).
2. Waited across turns; single status probes (curl, then Burp) still showed the block — each probe plausibly extends the sliding window, so probing stopped.
3. XFF hypothesis test (ONE Burp request): `POST test:test123` + `X-Forwarded-For: 10.99.0.1` → 200 `Invalid username or password.` (normal message, no block). Same request without XFF → block message. H2 confirmed with 2 requests.
4. Timing pass 1 (CLI Python, 128-char password, median-of-3 per user, unique XFF per request, 0.3s spacing, ~303 reqs, zero blocks): 100 users 0.276–0.366s, exactly one outlier — **`apache` 0.918s**. H1 confirmed.
5. Confirmation (6 samples each): apache median 0.877s (6/6 elevated 0.851–0.973s) vs carlos 0.288s vs atlas 0.286s. Deterministic oracle. H3 (user half) confirmed.
6. Password scan (`apache` × 100 passwords, unique XFF each, 0.25s spacing): exactly one 302 — **`dragon`** → `Location: /my-account?id=apache`. H3 confirmed.
7. Verification logins: Burp `POST apache:dragon` (+XFF) → 302 + session + apache Location; curl login → session → `GET /my-account?id=apache` → 200 `Your username is: apache` (banner `is-notsolved`) → `GET /` → `is-solved`/`Solved`/`Congratulations`. H4 confirmed.

## What Failed

- The opening rapid population scan (my carryover habit from message-oracle labs) tripped the IP block and cost the whole early session: byte-exact message scan was the wrong FIRST move on a timing lab whose defense is rate-based. Correct order here would have been throttled timing from the start.
- Repeated single status probes while blocked: each likely extended the window. Lesson: after a block, go silent or switch identity key (XFF), don't poll.
- Regex miss on first message scan (`NO-MATCH` for 99 responses) — warning markup differed from assumed pattern; raw-context inspection caught it, but the scan rate had already done the damage.

## What Worked

XFF-partitioned, long-password, median-ranked timing scan → `apache` → single-302 password `dragon` → session → identity render → homepage `is-solved`.

## Burp Observations

- Status/block checks, XFF bypass proof (block vs normal message pair), and final carlos-style 302 proof all via Burp MCP (`burp_send_http1_request`) — full request/response evidence.
- Bulk timing/password loops via CLI Python (timing precision + per-request XFF rotation + ordering), the smaller appropriate toolset; Burp-per-request would add no value.
- Repeater tab `timing-baseline-test` pre-created (unsent) during the blocked phase; actual work used scripted requests.

## Browser Observations

- Not required and not used (tab-89 permission never granted; pure HTTP flow). Browser Control MCP correctly unused. Burp proxy history confirmed the user's own browser made only safe `GET`s (no `POST /login` via proxy), so it never extended the block.

## CLI / Tool Observations

- Python `urllib` + `time.time()` + `statistics.median`; no-redirect handler for 302 detection; `X-Forwarded-For: 10.99.x.x / 10.100.x.x / 10.101.x.x` rotation (unique per request).
- Wordlists from existing `/tmp/auth-users.txt` (101) + `/tmp/auth-passwords.txt` (100); lab-specific, not added to repo.

## Root Cause

Two compounding flaws: (a) the login flow hashes the supplied password only when the username exists, leaking account existence through response time (~0.88s vs ~0.29s with 128-char passwords); (b) the brute-force IP block derives the client identity from `X-Forwarded-For` when present, so any attacker-supplied XFF value gets a fresh counter — the rate limit is partitioned at will. Together: unlimited, unattributed timing oracle → enumeration → predictable-password (`dragon`) takeover of `apache`.

## Verification

- Oracle determinism: apache elevated 9/9 total samples across two runs (0.851–0.973s); controls flat at ~0.29s (12 samples).
- XFF bypass: paired requests (same creds, ±XFF) → block message vs normal message.
- Password: single 302 + `Set-Cookie: session` + `Location: /my-account?id=apache` among 100, reproduced in two independent sessions (Burp + curl).
- Identity: account page renders `Your username is: apache`.
- Solved: authenticated `/` returns `is-solved` (account page alone `is-notsolved` — both checked).

## Impact

Full account takeover of `apache`. Timing oracles additionally enable stealthy user harvesting; XFF-keyed counters enable unlimited guessing from a single host.

## Why The Successful Approach Worked

- Treated the block as a key-management problem (which identity does the counter key on?) instead of waiting out the timer — one paired probe answered it.
- Amplified the signal before measuring (128-char password forces hash work for valid users only), then ranked medians instead of eyeballing single samples.
- Confirmed the outlier with controls before spending the password list (6-sample + 2-control determinism check).

## Generalization

- For timing-enumeration: long-password amplification + median-of-N ranking + control confirmation is the portable recipe; short passwords show no delta.
- For counter-gated endpoints: test whether the counter honors client-controlled IP headers (`X-Forwarded-For`) with ONE paired probe; if so, rotate per request. Never poll a block to check expiry — silence or identity-switch instead.
- Scan-rate discipline is family-dependent: message-oracle speed is harmful on rate-defended logins.

## Lessons Learned

- First timing-enumeration success in the KB (prior timing mentions were only eliminations); methodology had statistics guidance but no amplification/ranking recipe.
- First evidence that this lab family's IP counters honor XFF — extends the previous turn's reset-based bypass with a header-partition bypass.
- Rapid-scan habit from overt/subtle labs does not transfer to rate-defended labs; match scan rate to the defense.

## Related Methodology

- methodology/authentication.md (timing-enumeration recipe + XFF-counter note — new reusable patterns; update justified, applied separately)
- methodology/verification.md (median determinism + dual-session 302 + dual-surface marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/authentication/password-based/lab-username-enumeration-via-response-timing (objective only; solution not consulted — XFF idea came from brute-force-protection family reasoning, verified by paired probe)
- Candidate sources (lab-published, `/tmp` only): `auth-lab-usernames` (101), `auth-lab-passwords` (100)
- Prior related (hypothesis sources, not answers): subtle-responses (`americas:moon`, `alabama:abc123` instances), different-responses (`agenda:princess`), broken-bruteforce-protection-ip-block (`carlos:ranger` — reset-based bypass; this lab adds header-partition bypass)
- Solved instance: https://0a01007e047db32580615db60091009d.web-security-academy.net/ with `apache:dragon`
