# PortSwigger Lab

## Lab

SQL injection attack, querying the database type and version on MySQL and Microsoft

URL: https://0a050034048cd3ac835c8c21002d0066.web-security-academy.net

## Vulnerability Class

SQL injection — UNION-based extraction, database version enumeration (MySQL)

## Objective

Make the database retrieve and display its version string (target: `8.0.42-0ubuntu0.20.04.1`).

## Relevant Application Behavior

- Same e-commerce product-listing family; injection point `GET /filter?category=<value>`.
- Errors render as HTTP 500 (~2658 bytes); valid queries return 200 with the listing.
- This instance is MySQL-backed (unlike the Oracle lab in the same series).

## Initial Observations

- Baseline `category=Gifts` → 200, 8747 bytes.
- `category=Gifts'` → 500 (interpolation confirmed).

## Hypotheses

- H1: Same filter injection point and UNION approach as the Oracle version lab; 2 columns (app-template assumption).
- H2: Backend is MySQL → `@@version`, no `FROM dual`.
- H3: `--` comment works as in prior labs. (This proved WRONG — the key lesson of this lab.)

## Attempts

1. Baseline → 200; `Gifts'` → 500 (injection confirmed).
2. `' UNION SELECT NULL[,NULL...]--` for 1–8 columns → all 500 (stuck point).
3. Tautology checks: `' OR 1=1--` → 500; `Gifts'--` → 500 → the `--` comment itself was the failure, not the payload structure.
4. `' UNION SELECT NULL,NULL#` → 200 (+80 bytes) — `#` (MySQL comment) works.
5. NULL increments with `#`: 1 col → 500, 2 cols → 200, 3+ → 500 (2 columns confirmed).
6. `' UNION SELECT @@version,NULL#` → 200, version string rendered.

## What Failed

- **`--` comment syntax**: every `--`-terminated payload returned 500, including the empty `Gifts'--` and the previously-successful `' OR 1=1--`. Root cause of the stuck phase: carried-over assumption from MySQL/Oracle-style labs. On this MySQL backend `--` requires a trailing space/control character to register as a comment; `#` is the reliable terminator. (The failure of an empty-comment test `x'--` while `x'#` succeeds is a clean diagnostic that the comment — not the injection — is the problem.)
- Initial UNION probing wasted 8 requests because it combined two unknowns (comment syntax + column count) instead of isolating them.

## What Worked

`GET /filter?category=Gifts' UNION SELECT @@version,NULL#`

(URL-encoded: `category=Gifts%27+UNION+SELECT+%40%40version%2CNULL%23`)

## Root Cause

The `category` parameter is concatenated into a two-column SELECT. MySQL accepts `@@version` without a FROM clause, and `#` comments out the trailing `' AND released = 1`-style remainder. The application renders the injected row, disclosing the database version.

## Verification

- `#`-terminated NULL probing deterministically bracketed the column count (500 at 1 and 3; 200 at 2).
- Final payload rendered `8.0.42-0ubuntu0.20.04.1` in the listing — matches the lab's target string.
- Lab status changed to "Solved" (is-solved).

## Impact

Database version disclosure via in-band UNION extraction on MySQL — reconnaissance for CVE/exploit selection and further schema/data extraction. Same technique chain continues to `information_schema` enumeration.

## Why The Successful Approach Worked

- Isolating the comment variable (empty-comment tests) distinguished "payload wrong" from "terminator wrong".
- `#` is a first-class MySQL comment with no trailing-character requirement, so the query terminated cleanly.
- `@@version` needs no FROM on MySQL, and position 1 was the rendered column.

## Generalization

- Comment syntax is backend-specific and a common failure variable when transferring payloads across databases: MySQL/MSSQL `-- ` (with space) or `#` (MySQL only); Oracle/Postgres `--`.
- When a payload that "should work" fails, isolate variables one at a time: injection (quote test) → terminator (empty-comment test `x'--` vs `x'#`) → structure (NULL increments).
- An empty comment test (`value'--` vs `value'#`) is a cheap, decisive diagnostic for comment-syntax problems.
- MySQL fingerprint: `#` accepted, `@@version` accepted, `FROM dual` unnecessary.

## Lessons Learned

- The carried-over `--` assumption caused the only stuck phase; stored methodology works only as a hypothesis, and the differential empty-comment test resolved it in two requests.
- Change one variable at a time between failed payloads — combining unknowns (comment + column count) multiplies wasted requests.
- The UNION recipe from the Oracle lab transferred fully once the terminator was corrected; only the DB-specific bits differed (`#` vs `--`, `@@version` vs `v$version`, no FROM vs `dual`).

## Related Methodology

- methodology/injection.md (UNION-based extraction, DB-specific comment/version syntax)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-mysql-list
- Solved instance: https://0a050034048cd3ac835c8c21002d0066.web-security-academy.net
