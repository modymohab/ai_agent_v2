# PortSwigger Lab

## Lab

Blind SQL injection with conditional responses

URL: https://0a2e00d303e0b2cd8281013e008800fd.web-security-academy.net

## Vulnerability Class

Blind SQL injection — boolean oracle via conditional response ("Welcome back!" message), Cookie header injection point

## Objective

Extract the administrator's password from the `users` table using only a true/false response signal, then log in as administrator.

## Relevant Application Behavior

- The application sets two cookies on first visit: `TrackingId` and `session`.
- On subsequent visits with valid cookies, the home page displays "Welcome back!".
- The `TrackingId` cookie value is interpolated into a SQL query: a TRUE condition keeps the row matched → "Welcome back!" rendered; a FALSE condition or SQL error → message absent.
- No error output, no result rendering — the ONLY signal is message-present vs. message-absent.

## Initial Observations

- First request (no cookies) → no "Welcome back!"; sets TrackingId + session.
- Second request (same cookies) → "Welcome back!" (1 occurrence).
- Message presence is a binary oracle independent of HTTP status (always 200).

## Hypotheses

- H1: TrackingId is injected into a query whose row-match drives the "Welcome back!" message — conditional payloads (`AND '1'='1'` vs `'1'='2'`) would flip the message.
- H2: The password can be extracted character-by-character via `SUBSTR`/`ASCII` binary search, using the message as the boolean channel.
- H3: Numeric-comparison payloads need correct quote balancing (a stuck-phase discovery — see below).

## Attempts

1. Cookie behavior mapped: fresh visit → no message; repeat with TrackingId+session → message.
2. Oracle confirmed: `' AND '1'='1` → message; `' AND '1'='2` → no message.
3. Administrator row confirmed: `AND (SELECT 'a' FROM users WHERE username='administrator')='a` → message.
4. **Stuck phase:** every numeric comparison (`COUNT(*)>1`, `LENGTH>10`, `ASCII>64`) returned "false" — including conditions that must be true. Diagnosis: the application appends a closing quote after the injected value; payloads ending in a number leave a dangling quote → syntax error → no row → indistinguishable from FALSE. Earlier successes had ended in `'a` (quote-balanced).
5. Fix confirmed: `' AND 1=1--` → message; `' AND 1=2--` → none. The `--` comment terminates the trailing quote.
6. Password length via binary search: >15 true, >20 false, >21 false → concluded 21 (see What Failed).
7. Character extraction: automated ASCII binary search (32–126, ~6 requests/char) → `2qclxqqdp7ibjreto82z ` (21 chars incl. trailing "space").
8. Login: exact 21-char string failed (200 rejection); 20-char trimmed string → 302 → administrator session.

## What Failed

- **Quote-unbalanced payloads (stuck phase):** numeric-comparison payloads without `--` all returned "no message" — syntax errors masquerading as FALSE. In a boolean oracle, error and false are indistinguishable by signal alone; only systematic hypothesis testing revealed the difference.
- **Length determination error:** `>20` false was misread as length 21 without testing `>19`/`=20`. Actual length is 20. The extracted "character 21" (ASCII 32) was an artifact: `SUBSTR` beyond length returns empty string, `ASCII('')` is NULL, and `NULL > x` is always false → binary search converges to its floor (32 = space). The trailing "space" was the tell that the length was wrong.
- **First login attempt with the artifact string** (21 chars) rejected; trimmed 20-char password succeeded.

## What Worked

- Oracle: `' AND <condition>--` in the TrackingId cookie; "Welcome back!" presence = TRUE.
- Extraction: `AND (SELECT ASCII(SUBSTR(password,N,1)) FROM users WHERE username='administrator')>M--` binary search per position.
- Login: `administrator` / `2qclxqqdp7ibjreto82z` (20 chars).

## Root Cause

The TrackingId cookie is concatenated into a SQL query whose result controls the "Welcome back!" greeting. Because attacker-controlled SQL can turn the query's row-match on/off, the message becomes a boolean side channel — data can be extracted one bit per request even though nothing is ever rendered. The password is stored in plaintext and the DB account can read the `users` table.

## Verification

- Oracle deterministic: 1=1 → message, 1=2 → none (reproducible across requests).
- Each extracted character confirmed by binary search convergence within 32–126.
- Cross-check: the artifact trailing-space at position 21 contradicted login failure; trimming to 20 chars produced a successful login — the DB itself verified the password.
- Login → 302 → `/my-account?id=administrator` → "Your username is: administrator"; lab status `is-solved`.

## Impact

Full blind credential extraction (administrator's 20-char password) at ~1 bit/request, followed by account takeover. Demonstrates that absence of output rendering is not a defense: any observable boolean difference (message, size, timing, status) suffices to exfiltrate arbitrary readable data.

## Why The Successful Approach Worked

- The greeting message is query-dependent state, so it leaks one bit of query truth per request.
- `SUBSTR` + `ASCII` binary search converts an arbitrary string into ~6 boolean queries per character.
- The `--` terminator neutralized the application's appended closing quote — the key structural insight from the stuck phase.

## Generalization

- Blind SQLi workflow: (1) find a stable boolean signal (message presence/absence, response size, timing); (2) confirm controllability with tautology/contradiction; (3) verify target data exists; (4) extract via per-character binary search.
- In boolean oracles, ERROR and FALSE are indistinguishable — when "impossible false" results appear, suspect quote-balancing/syntax errors, not data values. Test `' AND 1=1--` vs `' AND 1=1` to expose the appended-quote structure.
- Out-of-range SUBSTR returns empty string; ASCII(NULL-ish) makes comparisons always-false, so binary search converges to 32 (space). A trailing-space artifact at position N+1 is a strong indicator the true length is N — verify length exactly (`>N-1` vs `>N`) before extraction.
- Cookie headers are first-class injection points: TrackingId/session values are user-controlled input even though they're not form fields.

## Lessons Learned

- The stuck phase cost ~15 requests because error-vs-false were conflated; the systematic re-test (tautology, users-exists, then the failing numeric class) isolated the payload-shape variable. Change one payload property at a time.
- Length verification must bracket exactly (`>N-1` true AND `>N` false → length N) — an unverified length leaks an artifact character and costs a failed login attempt.
- Automating the extraction (Python + curl subprocess) turned ~120 requests into one script run — appropriate tool choice once the oracle was fully understood, and zero requests before that point.

## Related Methodology

- methodology/injection.md (blind SQLi — boolean oracle workflow; appended-quote payload balancing; SUBSTR/ASCII binary search)

## References

- Lab: https://portswigger.net/web-security/sql-injection/blind
- Solved instance: https://0a2e00d303e0b2cd8281013e008800fd.web-security-academy.net
