# PortSwigger Lab

## Lab

SQL injection UNION attack, retrieving data from other tables

URL: https://0af6009304e9cdf2813f572200690070.web-security-academy.net

## Vulnerability Class

SQL injection — UNION attack, cross-table data extraction (credential disclosure)

## Objective

Retrieve the administrator's username and password from a `users` table (via UNION) and log in as administrator.

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2485 bytes); valid queries → 200.
- Comment style: `--` works; `#` → 500 (verified fresh, per methodology).
- 2 result columns (UNION 2 NULLs → 200; 1 and 3 → 500).
- Login at `POST /login` (csrf/username/password; token+cookie pairing).

## Initial Observations

- Baseline `category=Accessories` → 200, 8067 bytes.
- `category=Accessories'` → 500 (interpolation confirmed).
- `UNION SELECT NULL,NULL--` → 200 (+81 bytes).

## Hypotheses

- H1: Filter injection, `--` comment, 2 columns, at least one rendered text position.
- H2: This variant uses the classic unrandomized `users(username, password)` table (unlike the contents labs where identifiers were randomized) — direct extraction may work without enumeration.
- H3: `|| '~' ||` concatenation surfaces credential pairs in the rendered position.

## Attempts

1. Baseline / quote / comment checks → injection + `--` confirmed.
2. NULL increments → 2 columns bracketed (500 at 1 and 3).
3. Direct extraction: `' UNION SELECT username || '~' || password,NULL FROM users--` → 200, rendered `administrator~u51cot0ox2ybrq2qlvl0`, carlos, wiener. (No enumeration needed — H2 correct.)
4. Login with administrator credentials (CSRF+cookie paired) → 302 → `/my-account?id=administrator` → "Your username is: administrator".

## What Failed

- Nothing: the direct-extraction hypothesis worked on the first payload. Instance verification (comment style, column count) still preceded it — those are never skippable.

## What Worked

`GET /filter?category=Accessories' UNION SELECT username || '~' || password,NULL FROM users--`

then login with `administrator` / `u51cot0ox2ybrq2qlvl0`.

## Root Cause

Unparameterized `category` input in a 2-column SELECT. Because UNION can reference ANY table accessible to the query's database connection (not just the FROM of the original query), the product listing becomes an arbitrary-query interface: the `users` table is extracted through the product-listing UI. Storing credentials in plaintext makes the extracted data immediately weaponizable.

## Verification

- Column count bracketed deterministically (500 at 1/3, 200 at 2).
- Credential rows rendered with unambiguous `~` separator: `administrator~u51cot0ox2ybrq2qlvl0`.
- Login → 302 to `/my-account?id=administrator`; page rendered "Your username is: administrator" + "Log out"; lab status `is-solved`.

## Impact

Complete credential disclosure for all users (administrator, carlos, wiener) from a separate table via the filter injection point, followed by administrator account takeover. Demonstrates that a single injection point compromises every table the DB account can read — not merely the queried table.

## Why The Successful Approach Worked

- UNION replaces the original row set entirely: the injected SELECT's FROM clause is attacker-controlled, so cross-table extraction requires no second vulnerability.
- The recipe's structural steps (comment, count) were verified fresh in 6 requests; with the context known, a single direct-extraction payload finished the lab — the table names in this variant are unrandomized, so enumeration (labs 5–7) was unnecessary.
- Separator concatenation packed two fields into the single rendered position.

## Generalization

- UNION injection is an arbitrary-read primitive scoped only by the DB account's privileges: any table, not just the one in the original query, is extractable.
- Guessing standard table/column names (`users`, `username`, `password`) is worth exactly one cheap request when enumeration exists as fallback — the 200-vs-500 response adjudicates instantly. In real targets, randomization (labs 5–7 pattern) is the case where enumeration is mandatory.
- The full recipe now spans: context verification → count → rendered position → extraction (direct or via enumeration) → credential login. Each step is small, verifiable, and composable.

## Lessons Learned

- Hypothesis ordering matters for efficiency: test the cheap standard-name guess first, keep enumeration as the fallback — never the reverse (enumeration-first costs 2+ requests when 1 suffices).
- The difference between this lab and the contents labs is purely identifier randomization; the attack surface and recipe are identical. Recognizing variant families saves the entire enumeration phase.
- Plaintext credential storage converts data disclosure directly into account takeover — extraction and login-bypass are one combined impact chain.

## Related Methodology

- methodology/injection.md (UNION recipe; cross-table extraction; standard-name-first heuristic)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-union-retrieving-data-from-other-tables
- Solved instance: https://0af6009304e9cdf2813f572200690070.web-security-academy.net
