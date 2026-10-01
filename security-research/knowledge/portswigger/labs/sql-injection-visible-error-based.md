# PortSwigger Lab

## Lab

Visible error-based SQL injection

URL: https://0adc00dc04c28ab3808fee6b00920001.web-security-academy.net

## Vulnerability Class

Blind/visible error-based SQL injection — data leakage through DB error message text (TrackingId cookie, PostgreSQL)

## Objective

Extract the administrator's password (leaked via visible error output) and log in as administrator.

## Relevant Application Behavior

- Same e-commerce family; sets `TrackingId` + `session` cookies.
- Errors → HTTP 500 with a rich error page containing the PostgreSQL error message (`<h4>` element); some errors → bare "Internal Server Error" (21 bytes) instead.
- Injected query (leaked by the error itself): `SELECT * FROM tracking WHERE id = '<TrackingId>'` — PostgreSQL backend.
- The TrackingId cookie value is TRUNCATED by the application (~62 chars of cookie value; total query position cap ~97).

## Initial Observations

- `TID'` → 500 with "Unterminated string literal started at position 52 in SQL SELECT * FROM tracking WHERE id = '...'". The error leaks the full query text — a reconnaissance goldmine.
- Boolean tautologies via TrackingId don't change normal responses (no message oracle).

## Hypotheses

- H1: The query text leak in errors enables direct payload-shape confirmation.
- H2: PostgreSQL cast errors (`::int`, `CAST(x AS int)`) include the offending VALUE in the error message → converting the password to int leaks it in one request.
- H3: A length limit on the cookie constrains payload size — must be budgeted (short TID, minimal SQL).

## Attempts

1. Mapped the injection: `TID'` → unterminated-string error leaking `SELECT * FROM tracking WHERE id = 'TID'`.
2. Verified appends-quote structure: payloads must be quote-balanced or `--`-commented (carried from labs 11/12).
3. Explored the error surface: long payloads → truncation at position ~95/97 → "syntax error at end of input" (generic, leaks nothing).
4. **Stuck phase:** `CAST(password AS int)` / `password::int` with `WHERE username='administrator'` payloads → always truncation errors; payload too long (TID 16 chars + WHERE clause ≈ 85+ chars).
5. Measured the truncation budget empirically (padding probes of 30/40/44/48 chars): under ~62 cookie chars survives; over → generic syntax error.
6. Fix: SHORT TrackingId (`x`) + `'||(SELECT password::int FROM users LIMIT 1)||'` → **`ERROR: invalid input syntax for type integer: "csoghfdmpx3m198ossiz"`** — the password leaked in the error text.
7. Login: `administrator` / `csoghfdmpx3m198ossiz` → 302 → administrator session.

## What Failed

- **Long payloads (stuck phase):** `WHERE username='administrator'` variants exceeded the cookie truncation budget → generic "syntax error at end of input / Position: 97" errors that leak nothing. Multiple attempts wasted before the padding-probe measurements identified the exact budget.
- **`LIKE 'adm%'` variant (67 chars):** over budget → bare 500 without the rich error page — not all error paths render the leak page.
- Assuming the first leaked row was carlos/wiener (in other labs administrator was a separate row) — here LIMIT 1 returned administrator's row; verified by successful login rather than assumption.

## What Worked

`Cookie: TrackingId=x'||(SELECT password::int FROM users LIMIT 1)||'; session=...`

→ PostgreSQL cast error: `invalid input syntax for type integer: "csoghfdmpx3m198ossiz"` → login as administrator.

## Root Cause

The TrackingId cookie is concatenated into `SELECT * FROM tracking WHERE id = '<value>'` on PostgreSQL. The application surfaces raw database error text to the user. PostgreSQL's type-cast errors embed the offending value, so casting the password to int turns the error channel into a data channel: one request leaks the full value (no per-character binary search needed). Plaintext password storage completes the chain.

## Verification

- The leaked value `csoghfdmpx3m198ossiz` was validated by the application itself: login as administrator succeeded (302 → "Your username is: administrator").
- The cast-error mechanism was reproducible (deterministic across requests).
- Lab status changed to `is-solved`.

## Impact

Direct credential disclosure in a single request via error-message leakage — vastly more efficient than blind binary search (1 request vs ~120). Administrator account takeover. The leaked query text also disclosed the tracking table structure for free.

## Why The Successful Approach Worked

- The unterminated-string error leaked the query shape, enabling payload construction without guessing.
- PostgreSQL's `::int` cast error embeds the VALUE: `invalid input syntax for type integer: "<value>"` — value-reflection in errors is a data channel.
- Shortening the TrackingId from 16 chars to 1 freed ~15 chars of payload budget — the decisive move after measuring the truncation limit.

## Generalization

- Error-message data channels (strongest first): value-reflecting cast/conversion errors (`::int`, `CAST`, XML/JSON parse errors) > query-text-echo errors (unterminated strings leak the SQL) > generic syntax errors (leak nothing).
- Truncation budgets are a hidden payload constraint: measure them empirically with padding probes BEFORE crafting data-leaking payloads; every character of fixed overhead (original value, TID, table/column names) eats the budget.
- When a WHERE clause won't fit the budget, drop it: `LIMIT 1` (possibly with ORDER BY) may return the needed row — verify the row's identity by using the leaked value (login) rather than assuming.
- Value-reflecting errors extract the WHOLE value in one request — prefer them over per-character oracles whenever the backend surfaces error text.

## Lessons Learned

- The padding-probe measurement (fixed-length 'B'*N payloads) pinpointed the truncation budget in ~6 requests and converted an intractable stuck phase into a budget-fitting exercise.
- The leaked query text ("SELECT * FROM tracking WHERE id = '...'") was free reconnaissance: grammar, table, and injection shape in one response.
- A "500 without details" vs "500 with rich error page" distinction mattered: only specific error classes render the leak page — classify the error surface before building an extractor.

## Related Methodology

- methodology/injection.md (error-based extraction; value-reflecting cast errors; truncation budgets)

## References

- Lab: https://portswigger.net/web-security/sql-injection/blind/lab-sql-injection-visible-error-based
- Solved instance: https://0adc00dc04c28ab3808fee6b00920001.web-security-academy.net
