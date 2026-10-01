# PortSwigger Lab

## Lab

SQL injection vulnerability in WHERE clause allowing retrieval of hidden data

URL: https://0a660052043c29a4807c715b00810009.web-security-academy.net

## Vulnerability Class

SQL injection (WHERE clause / boolean manipulation / hidden data disclosure)

## Objective

The lab contains a SQL injection vulnerability in the product category filter. The goal is to display details of all products, including unreleased/hidden ones.

## Initial Observations

- The application is an e-commerce product listing with category filters.
- The filter issues `GET /filter?category=<value>`.
- Baseline `category=Gifts` returns HTTP 200 with 3 products.
- The lab title explicitly indicates the vulnerability class (WHERE clause injection for hidden data retrieval).

## Hypotheses

- H1: The `category` parameter is interpolated directly into a SQL string literal in a WHERE clause, so a single quote would break the query (observable as 500 or error).
- H2: A boolean-altering payload (`' OR 1=1 --`) would make the WHERE clause always true and disclose hidden products.
- H3: A trailing condition (e.g., `AND released = 1`) likely follows the injection point, requiring a comment (`--`) to neutralize it.

## Attempts

1. Baseline request `category=Gifts` → 200, 3 products (reference point).
2. `category=Gifts'` → HTTP 500 (quote breaks SQL syntax).
3. `category=Gifts' OR 1=1` (no comment) → HTTP 500 (trailing condition still breaks the query).
4. `category=' OR 1=1 --` → HTTP 200, 20 products (all products disclosed).

## What Failed

- `' OR 1=1` without a comment suffix → 500. Taught that the injected string is followed by additional SQL (`AND released = 1`), not just a closing quote.

## What Worked

`GET /filter?category=' OR 1=1 --` (URL-encoded: `category=%27+OR+1%3D1+--`)

Result: 200 OK, 20 products rendered vs. 3 in the normal Gifts category.

## Burp Observations

- Proxy history confirmed the filter requests and baseline response (200, 8198 bytes).
- All injected requests were replayed and compared through the proxy.

## Browser Observations

- The lab homepage and filter UI confirmed the category parameter and product listing behavior (used only for reconnaissance; permission for direct browser-content access was not granted, so HTTP-level testing via curl/Burp was used instead).

## CLI / Tool Observations

- curl used for baseline, single-quote, and final payload requests.
- Product counts compared with grep; product names compared with sort/diff:
  - baseline Gifts: 3 products
  - injected `' OR 1=1 --`: 20 products (17 additional hidden items across all categories, e.g., unreleased products like "Laser Tag", "The Bucket of Doom")

## Root Cause

The application builds the product query by concatenating the `category` parameter directly into a SQL statement resembling:

`SELECT ... FROM products WHERE category = '<category>' AND released = 1`

The injected `' OR 1=1 --` closes the string literal, makes the predicate always true (1=1), and comments out the `released = 1` restriction, so all products (released and unreleased) are returned.

## Verification

- Payload behavior is deterministic and was reproduced over plain HTTP (independent of browser state).
- Baseline vs. injected product sets were compared (3 vs. 20 products) — the additional 17 items are the intended hidden data.
- Lab status header changed from "Not solved" to "Solved" (confirmed via response HTML: `is-solved` / "Solved").

## Impact

Unauthorized disclosure of hidden/unreleased product data. The same injection class in a real application typically allows retrieval of arbitrary table data (via UNION, etc.), bypassing intended visibility constraints.

## Why The Successful Approach Worked

- The single-quote 500 confirmed string-literal interpolation (injection point exists).
- The 500 on `' OR 1=1` (no comment) revealed a trailing condition — evidence for using `--`.
- The comment neutralized the remainder of the query, converting a syntactically broken query into an always-true predicate.

## Generalization

- Error-based differential testing (baseline vs. quote vs. quote+comment) systematically maps the injection context before attempting data retrieval.
- A 500 on `x'` but 200 on `x' -- <always-true>` is a strong signature of WHERE-clause string interpolation with trailing conditions.
- In e-commerce/listing applications, visibility flags (released, hidden, published, deleted) are common WHERE-clause companions; injected tautologies bypass them.

## Lessons Learned

- Test incrementally: baseline → syntax-break → boolean tautology → comment. Each step's result informs the next payload.
- The difference between a 500 (payload without comment) and 200 (payload with comment) identifies trailing SQL structure.
- Counting result rows (3 vs. 20) is a simple, reliable impact measurement for data disclosure.

## Related Methodology

- methodology/injection.md (SQL injection: WHERE clause, boolean-based manipulation)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-retrieve-hidden-data
- Solved instance: https://0a660052043c29a4807c715b00810009.web-security-academy.net
