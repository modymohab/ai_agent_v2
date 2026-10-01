# PortSwigger Lab

## Lab

Blind SQL injection with conditional errors

URL: https://0a5600150395614080e5083300cd00ff.web-security-academy.net

## Vulnerability Class

Blind SQL injection — conditional-error oracle (TrackingId cookie; TRUE→500, FALSE→200 via UNION CASE)

## Objective

Extract the administrator's password using error-vs-normal responses as the only signal, then log in.

## Relevant Application Behavior

- Same e-commerce family; sets `TrackingId` + `session` cookies.
- NO "Welcome back!" message (unlike the conditional-responses lab) — the message oracle is absent.
- Errors → HTTP 500 "Internal Server Error" page (~2330 bytes); valid queries → 200 normal page.
- Backend requires FROM in SELECTs (Oracle-like; `||` concat rejected — not PostgreSQL-style here); harmless UNION with FROM works.

## Initial Observations

- Plain TrackingId → 200; `TID'` → 500 (interpolation confirmed).
- `AND 1=1--` / `AND 1=2--` → both 200: boolean conditions alone don't alter the response — no message/size signal exists.

## Hypotheses

- H1: TrackingId cookie injection, appended quote (payloads need `--` or quote balancing) — carried from the conditional-responses lab family.
- H2: The signal must be deliberately manufactured: `CASE WHEN (cond) THEN <error> ELSE 'ok' END` converts any condition into error/no-error.
- H3: Same extraction machinery (length bracket → SUBSTR/ASCII binary search) applies once the oracle exists.

## Attempts

1. Cookie mapping: fresh visit sets cookies; no greeting message.
2. Quote → 500; tautologies → 200. Boolean conditions don't change responses.
3. **Stuck phase:** `CASE WHEN ... THEN 1/0 ELSE 'a' END` variants (parenthesized, with/without comments) → ALL 500, both TRUE and FALSE. Also `(SELECT 'x')='x'` → 500, `||` concat → 500, `CAST(NULL AS int)=1` → 500.
4. Systematic isolation: bare `(1=1)` parens → 200; `UNION SELECT 'a' FROM users--` → 200. **Diagnosis:** every FROM-less SELECT/subquery 500s — the backend mandates a FROM clause (Oracle-family grammar). All prior CASE failures were syntax errors from missing FROM, not condition evaluation.
5. Working oracle: `' UNION SELECT CASE WHEN (<cond>) THEN TO_CHAR(1/0) ELSE 'a' END FROM users--` — TRUE→500, FALSE→200. TO_CHAR keeps both CASE branches text-typed.
6. Administrator row confirmed (error triggered on username='administrator').
7. Length bracketed: >19 TRUE (500), >20 FALSE (200), >21 FALSE → length = 20.
8. Per-character ASCII binary search (automated, ~6 req/char) → `86ax5m83jkafl2goa9zq`.
9. Login as administrator → 302 → "Your username is: administrator".

## What Failed

- FROM-less CASE/subquery payloads: `(SELECT CASE WHEN (1=1) THEN 1/0 ELSE 'a' END)='a`, `(SELECT 'x')='x'`, `CAST(NULL AS int)=1`, `||` concatenation — all 500. Root cause: backend grammar requires FROM for SELECT/subquery expressions. ~12 wasted requests before the systematic bare-parens/UNION isolation identified it.
- Assuming the lab-11 oracle shape (AND-attached subquery, `||` concat available) transferred: the message oracle was absent AND the grammar differed — both had to be re-derived from current evidence.

## What Worked

Oracle: `TrackingId=TID' UNION SELECT CASE WHEN (<condition>) THEN TO_CHAR(1/0) ELSE 'a' END FROM users--`

Extraction: `ASCII(SUBSTR(password,N,1))>M` binary search; login: `administrator` / `86ax5m83jkafl2goa9zq`.

## Root Cause

The TrackingId cookie is concatenated into a query. No data renders and no message signal exists, but errors ARE observable. Because attacker SQL can deliberately trigger a division-by-zero inside a CASE branch, any arbitrary condition becomes a 500-vs-200 bit — a manufactured boolean channel. Plaintext passwords in `users` complete the impact chain.

## Verification

- Oracle polarity deterministic: 1=1→500, 1=2→200 (reproducible).
- Length bracketed exactly (>19 true, >20 false → 20) — no artifact characters (lesson from the previous lab applied).
- All 20 extracted chars converged within 32–126; password accepted at login → DB-verified.
- Login → 302 → `/my-account?id=administrator` → "Your username is: administrator"; lab status `is-solved`.

## Impact

Full blind credential extraction (~1 bit/request) via manufactured conditional errors, followed by administrator account takeover. Demonstrates that even without message oracles or rendered output, observable errors alone suffice to exfiltrate data.

## Why The Successful Approach Worked

- When no natural signal exists, one can be created: CASE + deliberately-erroring branch converts arbitrary conditions into the only observable difference the app exposes (500).
- UNION bypassed the original WHERE entirely (the injected row replaces evaluation of the tracking condition), making CASE the sole row source.
- TO_CHAR(1/0) kept CASE branches type-consistent; FROM users satisfied the grammar.

## Generalization

- Blind-SQLi signal hierarchy: rendered data > message oracle > size delta > status/error > timing. When none exist naturally, manufacture one with `CASE WHEN cond THEN <error> ELSE <ok> END` — errors are the most universally observable signal.
- Before assuming a payload grammar, probe it cheaply: bare `(1=1)` parens, FROM-less subquery, simple UNION — classify the backend's grammar requirements (Oracle-family mandates FROM).
- Type consistency in CASE matters on strict engines: both branches must share a type (TO_CHAR(1/0) vs 'a'); on lenient engines 1/0 vs 'a' may also fail — integer variants (`THEN 1/0 ELSE 1`) are the fallback.
- The exact-length-bracketing rule (>N-1 true, >N false) from the conditional-responses lab prevented the artifact-character failure mode here.

## Lessons Learned

- The stuck phase (~12 requests) came from transferring lab-11's payload grammar to a different backend. Stored methodology generates hypotheses; current evidence decides — the systematic probe matrix (bare parens / FROM-less subquery / UNION) is what isolated the grammar variable.
- A failed "impossible" payload class (valid SQL erroring) is a grammar fingerprint, not a dead end: FROM-less failures → Oracle-family backend.
- Manufacturing the oracle (CASE + 1/0) is the general move when no signal exists: it converts ANY boolean question into the app's observable error channel.

## Related Methodology

- methodology/injection.md (blind-SQLi oracle workflow; conditional-error variant; grammar probing)

## References

- Lab: https://portswigger.net/web-security/sql-injection/blind/lab-conditional-errors
- Solved instance: https://0a5600150395614080e5083300cd00ff.web-security-academy.net
