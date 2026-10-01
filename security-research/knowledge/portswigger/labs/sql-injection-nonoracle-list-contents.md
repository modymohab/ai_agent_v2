# PortSwigger Lab

## Lab

SQL injection attack, listing the database contents on non-Oracle databases

URL: https://0a1f002e03157966812efd3700d90070.web-security-academy.net

## Vulnerability Class

SQL injection — UNION-based schema enumeration + credential extraction (PostgreSQL, `information_schema`)

## Objective

Find the users table, determine its columns, extract the administrator's credentials, and log in as administrator.

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2527 bytes); valid queries → 200 listing.
- Comment style: `--` works; `#` → 500 (opposite of the MySQL lab instance — verified fresh).
- Backend identified as **PostgreSQL** via system-table leakage (`pg_partitioned_table`, `pg_statio_all_tables`, `foreign_tables`, etc. in `information_schema.tables` output).
- Login at `POST /login` (csrf/username/password; token+cookie pairing).

## Initial Observations

(re-verified fresh on resumption; this instance was first probed in an interrupted session — no stored results were trusted)

- Baseline `category=Accessories` → 200, 8131 bytes.
- `category=Accessories'` → 500 (interpolation confirmed).
- `UNION SELECT NULL,NULL--` → 200 (+81 bytes) → 2 columns.
- Tables enumerated: `users_wbhcjp` among many `pg_*` system tables.

## Hypotheses

- H1: Standard UNION recipe applies: 2 columns, `--` terminator, `information_schema` for metadata (non-Oracle).
- H2: `information_schema.columns WHERE table_name='users_wbhcjp'` reveals credential columns with randomized suffixes.
- H3: `|| '~' ||` concatenation (valid in both PostgreSQL and Oracle) extracts username+password in the single rendered column.

## Attempts

1. Baseline / quote / empty-comment / UNION2 → injection context confirmed (fresh).
2. `UNION SELECT table_name,NULL FROM information_schema.tables--` → found `users_wbhcjp` (PostgreSQL system tables confirmed backend).
3. `UNION SELECT column_name,NULL FROM information_schema.columns WHERE table_name='users_wbhcjp'--` → `username_vttdpo`, `password_yzzzkv`, `email`.
4. `UNION SELECT username_vttdpo || '~' || password_yzzzkv,NULL FROM users_wbhcjp--` → `administrator~lb6hvjf4fdwf847gpvy3`, carlos, wiener.
5. Login with administrator credentials → 302 → `/my-account?id=administrator` → "Your username is: administrator".

## What Failed

- Nothing significant in this session. (Historical note: the first session on this instance interleaved-rows parsing issue was resolved then by full-text parsing — same lesson as the Oracle contents lab.)

## What Worked

- Enumeration chain: `information_schema.tables` → `information_schema.columns` → data extraction with `||` concatenation → credential login.
- Full-text response parsing (stripping tags, filtering) instead of positional grep — injected rows interleave with product tiles.

## Root Cause

Unparameterized `category` input in a 2-column SELECT on PostgreSQL. The information schema is UNION-queryable through the product listing UI; the users table (randomized name) is fully extractable, yielding plaintext credentials for all users.

## Verification

- Each enumeration step: 200 with size deltas matching added rows.
- Credential row rendered `administrator~lb6hvjf4fdwf847gpvy3` — separator disambiguates username/password.
- Login → 302 to `/my-account?id=administrator`; page rendered "Your username is: administrator" + "Log out"; lab status `is-solved`.

## Impact

Full database content disclosure on PostgreSQL: schema enumeration, column discovery, and extraction of all users' plaintext credentials. Administrator account takeover. Equivalent confidentiality compromise as the Oracle contents lab — the only differences are the metadata dictionary (`information_schema` vs. `all_*`) and backend fingerprint.

## Why The Successful Approach Worked

- Backend identification early (via `pg_*` tables in the table enumeration) selected the right metadata dictionary before column enumeration — no wasted Oracle-syntax attempts.
- `||` concatenation works on PostgreSQL just as on Oracle — the rendered-single-column workaround is portable across both.
- Randomized identifiers handled by enumeration, never guessing.

## Generalization

- Non-Oracle enumeration chain: `information_schema.tables` → `information_schema.columns WHERE table_name='<T>'` → `FROM <T>`. (Oracle: `all_tables` → `all_tab_columns`.)
- `information_schema` is standard across MySQL/PostgreSQL/MSSQL — one dictionary serves all non-Oracle backends.
- Backend fingerprinting via leaked system-table names (`pg_*` → PostgreSQL) is free reconnaissance from the table-enumeration step itself.
- Comment syntax and column count vary per instance, not per backend family — always re-verify (`--` here, `#` on the MySQL lab, both on 2-column apps).

## Lessons Learned

- The UNION extraction chain is now validated on three backends (Oracle, MySQL, PostgreSQL): identical recipe, only dictionary views and string-concat idioms differ (`||` vs `CONCAT`).
- Re-verifying an interrupted session's observations cost ~5 requests and eliminated any risk of acting on stale/misremembered state — stored observations are hypotheses, not facts.
- System-table leakage during enumeration doubles as backend fingerprinting — read the full table list, not just the users-like row.

## Related Methodology

- methodology/injection.md (UNION-based extraction sequence; non-Oracle dictionary chain)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-listing-database-contents-non-oracle
- Solved instance: https://0a1f002e03157966812efd3700d90070.web-security-academy.net
