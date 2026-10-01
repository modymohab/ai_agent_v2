# PortSwigger Lab

## Lab

SQL injection attack, querying the database type and version on Oracle

URL: https://0a8600b903c33478812c846700b200f5.web-security-academy.net

## Vulnerability Class

SQL injection — UNION-based extraction, database version enumeration (Oracle)

## Objective

Make the database retrieve and display its version string (e.g., via `v$version` banner on Oracle).

## Relevant Application Behavior

- Same e-commerce product-listing family as previous labs.
- Injection point: `GET /filter?category=<value>` (string-literal WHERE clause).
- Errors render as HTTP 500 (size ~2830); valid queries return 200 with product listing.

## Initial Observations

- Baseline `category=Pets` → 200, 9634 bytes.
- `category=Pets'` → 500 (interpolation confirmed — consistent with prior labs' recognition pattern).

## Hypotheses

- H1: Same WHERE-clause string-literal injection as prior filter labs.
- H2: UNION SELECT is possible; on Oracle every SELECT requires a `FROM` clause, so payloads need `FROM dual`; column count is discoverable by incrementing NULLs.
- H3: Version string is retrievable as `SELECT banner FROM v$version` (Oracle-specific dictionary view).

## Attempts

1. Baseline `Pets` → 200 (reference).
2. `Pets'` → 500 (injection confirmed).
3. `' UNION SELECT NULL FROM dual--` → 500 (wrong column count).
4. `' UNION SELECT NULL,NULL FROM dual--` → 200, size grew vs. baseline (2 columns — correct count).
5. `' UNION SELECT NULL,NULL,NULL FROM dual--` → 500 (confirmed exactly 2 columns).
6. Text-column check: `'a'` in column 1 → 200 rendered; column 2 → not rendered (column 1 is the text column).
7. `' UNION SELECT banner,NULL FROM v$version--` → 200, banner rendered in the listing.

## What Failed

- `UNION SELECT NULL FROM dual--` (1 column) → 500; three columns → 500. Only the NULL-increment method identified the true count (2).
- Test string `'a'` in the second column did not render — the app only displays the first column, so `banner` had to go in position 1.

## What Worked

`GET /filter?category=' UNION SELECT banner,NULL FROM v$version--`

(URL-encoded: `category=Pets%27+UNION+SELECT+banner%2CNULL+FROM+v%24version--`)

## Burp Observations

- All requests were plain GETs, verified at HTTP level through curl; differential (200/500, size deltas) was sufficient — no browser state needed.

## Browser Observations

- Not required: static HTML listing; HTTP-level testing sufficed.

## CLI / Tool Observations

- curl for each payload; status code + response size as the differential signal.
- NULL-increment column discovery: 1 col → 500, 2 cols → 200 (+91 bytes vs. baseline), 3 cols → 500.
- Text-column identification via `'a'` render test.
- Banner confirmed with grep: `Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production`.

## Root Cause

The `category` parameter is concatenated into a SELECT with two result columns (e.g., `SELECT name, description FROM products WHERE category='<input>'`). Because input is not parameterized, a UNION SELECT injects an attacker-chosen row set; the application renders the first column, so database metadata (`v$version.banner`) is disclosed through the same UI as product data.

## Verification

- Column-count payload deterministically distinguished 200 vs. 500 across repeated requests.
- The injected row rendered the literal test string (`'a'`) in position 1 — proving attacker-controlled output rendering.
- Final payload rendered the full Oracle banner: "Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production".
- Lab status header changed from "Not solved" to "Solved" (is-solved).

## Impact

Database version disclosure via in-band extraction. Version identification is reconnaissance for further attacks (known CVEs, exploit selection, syntax for deeper UNION extraction of table data). This is the entry point of the UNION extraction chain: same technique with `table_name`/`column_name` from dictionary views yields full schema enumeration, then data extraction.

## Why The Successful Approach Worked

- NULL-increment UNION probing found the exact column count (2) before any real payload was attempted — 500s at 1 and 3 columns bracketed the answer.
- Oracle requires a FROM clause even for literals, so `FROM dual` was mandatory (MySQL/Postgres would accept no FROM).
- `v$version` is the Oracle-specific dictionary view for the banner; other databases use equivalent functions (`@@version` on MySQL, `version()` on Postgres).
- Rendering test with a literal identified which column the application displays, so `banner` was placed in the displayed position with NULL padding the other.

## Generalization

- UNION attack sequence (generic, DB-agnostic prefix): confirm injection → find column count via NULL increments → identify a rendered/text column → substitute real subquery.
- Database-specific pivots: Oracle needs `FROM dual` and `v$version`; MySQL `@@version`; Postgres `version()`. Fingerprinting syntax acceptance itself (e.g., dual vs. bare SELECT) identifies the DB.
- 500-vs-200 + response-size deltas are reliable oracles for column-count discovery when errors are generic.

## Lessons Learned

- The generic UNION recipe (NULL increments → text-column test → payload) transfers directly from the filter-lab injection context to metadata extraction.
- On Oracle, `FROM dual` is required for literal SELECTs; its acceptance/necessity is itself an Oracle fingerprint.
- Error pages carry oracle value: a 500 at N columns but 200 at N+1 pins the column count without any data exfiltration.
- Rendering position matters: identify which columns the app displays before substituting payloads.

## Related Methodology

- methodology/injection.md (UNION-based extraction step, DB-specific version queries)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-oracle-version-query
- Solved instance: https://0a8600b903c33478812c846700b200f5.web-security-academy.net
