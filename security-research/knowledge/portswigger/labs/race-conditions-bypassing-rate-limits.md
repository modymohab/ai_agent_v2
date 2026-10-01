# PortSwigger Lab

## Lab

Bypassing rate limits via race conditions — https://0a9f007e031198dd84902c06009b0057.web-security-academy.net/ (PortSwigger Web Security Academy, Race conditions). Instance arrived expired (restart page); POSTed `/restart` + csrf, waited for 200 login form. Creds wiener:peter (valid). Target: carlos password from 30-candidate list → login → admin → delete carlos.

## Vulnerability Class

Race condition: per-username login-attempt counter incremented after the authentication check, so parallel guesses all execute pre-lock. NOT injection.

## Objective

Brute-force carlos's password despite a 3-strikes/60s lockout; log in; delete carlos via admin panel.

## Initial Observations

- `/login` form (csrf + username + password). 3× wrong wiener passwords → normal `Invalid`; 4th → `...incorrect login attempts. Please try again in 60 seconds.` (live countdown 60→59).
- wiener:peter → 302 `/my-account?id=wiener` (seeded-valid; also resets wiener's counter).
- carlos probe during wiener history → normal `Invalid` → counter is PER-USERNAME (not session/IP) — the scoping fact the whole attack rests on.
- Academy candidate list: 30 passwords (123123 … 000000).

## Hypotheses

- H1: counter check-then-increment per username → one h2-multiplexed burst of 30 distinct-password logins lands multiple attempts pre-lock; exactly one 302 names the password.
- H2: burst trips the lock (expected) — must wait ~60s+ then login normally; 302-in-burst is identifier only.

## Attempts

1. Mapping + scoping probes above (5 fails, 1 valid login, 1 carlos probe).
2. h2 burst v1: 30 streams, thread-index stream IDs → ALL `StreamIDTooLowError` (out-of-order send violates monotonic IDs), 0/30 responses. Fixed: atomic sid counter under send lock.
3. h2 burst v2: **0/30 counted** — responses arrived but header keys are BYTES (`b':status'`), str compare never matched. Fixed compare. (Lesson: the burst likely worked blind the first time; evidence lost to a parsing bug.)
4. h2 burst v3 (after 70s lock wait, fresh csrf): **30/30, exactly one 302 — `qwerty`**; rest 200 (invalid) + 400s (spent csrf variants — shared-token reuse is partial, harmless).
5. Waited 75s → normal login carlos:qwerty → 302 `/my-account?id=carlos` (first try 400 on stale csrf — re-read token, fixed) → identity `carlos` → `GET /admin` 200 (delete links) → `GET /admin/delete?username=carlos` → 302 → re-read `is-solved` ×2 (session 401 after, victim deleted — expected).

## What Failed

- Stream-ID ordering bug, bytes/str header bug (harness, both fixed with evidence).
- Stale-csrf 400 on first carlos login (session rotated during lock wait; re-read pattern from file-upload lessons applied).

## What Worked

Single-packet-style h2 burst (one connection, lock-serialized back-to-back HEADERS+DATA, shared session csrf) over the full candidate list in one gate; 302-oracle adjudication; wait-reset-login.

## Burp Observations

Not used (MCP flaky; Turbo Intruder single-packet shape replicated exactly by the h2 script: one connection, simultaneous dispatch).

## Browser Observations

None required (form-based login, no JS flows).

## CLI / Tool Observations

- curl + per-phase jars; manual redirect handling; csrf re-read per phase (login csrf rotated at least once).
- python-h2 available locally; ALPN h2 confirmed on lab host.

## Root Cause

Login flow checks credentials, returns session on success, and only then increments the per-username failure counter — under multiplexed concurrency all 30 checks run before any increment commits, so the 3-strike gate never engages mid-burst. The lock still trips afterward (by design), but the 302 already leaked the password.

## Verification

- Deterministic oracle: 29 non-302 vs exactly one 302 across a complete 30-candidate sweep (no partial-list ambiguity).
- Normal login with the found password → 302 + `Your username is: carlos` (identity, fresh session).
- Admin 200 + delete links → delete 302 → `is-solved` ×2 on re-read; carlos session 401 after (victim gone).

## Impact

Any rate-limited credential attack becomes unthrottled: full password-space testing in one burst per lock window; demonstrated account takeover + admin victim deletion.

## Why The Successful Approach Worked

Collapsed 30 sequential check-then-increment races into one multiplexed instant so the shared counter never got a turn; used the 302 (not timing, not message) as the single-bit oracle; respected the post-burst lock instead of fighting it.

## Generalization

Wherever a per-identity counter gates authentication/attempts: prove scoping (cross-identity probe), prove reset behavior, then single-packet the entire candidate space on one h2 connection with atomic stream IDs; adjudicate by status only; wait out the resulting lock; login cleanly.

## Lessons Learned

- h2 header keys arrive as BYTES — compare accordingly or silently count zero.
- h2 stream IDs must ascend in SEND order — allocate atomically under the send lock, never from thread index.
- Shared login csrf is partially reusable (mixed 200/400 under burst) — one token suffices for the gate; refresh for the clean login.
- Lockout messages with live countdowns confirm timer-based (not attempt-based) reset — sleep once, fully, instead of polling the block.
- First-login 400 after any wait = rotated csrf/session, not wrong password — re-read before concluding.

## Related Methodology

- methodology/race-conditions.md (second pattern added below: rate-limit gate racing)
- methodology/authentication.md (per-username scoping, 302+session proof, reset behavior)
- methodology/verification.md (complete-sweep oracle, identity + state proof)
- methodology/injection.md — compared, NOT applicable (no interpreter; counter-ordering flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/race-conditions/lab-race-conditions-bypassing-rate-limits
