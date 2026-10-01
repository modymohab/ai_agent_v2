# PortSwigger Lab

## Lab

SQL injection UNION attack, determining the number of columns returned by the query

URL: https://0af400310406857780ce21eb0013009c.web-security-academy.net

## Vulnerability Class

SQL injection — UNION attack, column-count discovery (NULL-increment method)

## Objective

Determine the number of columns returned by the query by appending an additional row containing NULL via UNION SELECT.

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2525 bytes); valid queries → 200 listing.
- Comment style: `--` works; `#` → 500 (comment style is instance-specific — verified fresh, per methodology).

## Initial Observations

- Baseline `category=Accessories` → 200, 5064 bytes.
- `category=Accessories'` → 500 (interpolation confirmed).
- Empty-comment diagnostics: `Accessories' --` → 200; `Accessories'#` → 500 → `--` is the valid terminator on this instance.

## Hypotheses

- H1: NULL-increment UNION probing (1, 2, 3, ...) until 200 identifies the column count (methodology step 2).
- H2: `--` comment works (instance-dependent; verified via empty-comment test before probing).
- H3: The count is ≥3 (fresh instance, unknown a priori).

## Attempts

1. Baseline → 200 (reference).
2. `Accessories'` → 500 (injection confirmed).
3. Empty-comment checks → `--` valid, `#` invalid on this instance.
4. `UNION SELECT NULL--` → 500; `NULL,NULL--` → 500; `NULL,NULL,NULL--` → **200** (+86 bytes, one extra row).
5. Repeated with 4/5/6 NULLs → 500 (confirms exactly 3 columns; over-count fails differently — size 5548 vs. 2525 suggests partial render/error variant).

## What Failed

- Nothing significant: 1 and 2 NULLs → 500 as expected (too few columns); 4+ NULLs → 500 (too many). The bracketing 500s at N-1 and N+1 confirmed the count without ambiguity.

## What Worked

`GET /filter?category=Accessories' UNION SELECT NULL,NULL,NULL--`

(URL-encoded: `category=Accessories%27+UNION+SELECT+NULL%2CNULL%2CNULL--`)

Result: 200 with an additional NULL row rendered in the listing; lab status changed to `is-solved`.

## Root Cause

The `category` parameter is concatenated into a SELECT with **3** result columns. UNION requires the injected SELECT to match the original column count exactly; the NULL-increment probe identifies it. The application renders the injected row, which the lab counts as success.

## Verification

- Deterministic: 500 at 1–2 NULLs, 200 at 3, 500 at 4–6 — the count is bracketed and unambiguous.
- The 200 response was +86 bytes vs. baseline — exactly one additional rendered row.
- Lab status header: `is-solved` (checked both the filter response and homepage).

## Impact

Column-count discovery is the structural prerequisite for all further UNION attacks (rendered-column identification, data extraction, schema enumeration). By itself it discloses query structure; it enables the full extraction chain demonstrated in labs 3–6.

## Why The Successful Approach Worked

- The NULL-increment method matches the original query's arity automatically — no guessing.
- Bracketing 500s at N±1 removed off-by-one ambiguity.
- Verifying the comment style first (2 cheap requests) avoided misattributing comment failures to column-count failures — the exact failure mode lab 4 documented.

## Generalization

- Column-count = the first structural fact to establish in any UNION attack; everything else (rendered-position tests, payload placement) depends on it.
- A 200 with size delta ≈ one row proves the UNION row rendered — a stronger success signal than 200 alone.
- Comment-style verification (empty `x'--` vs `x'#`) costs 2 requests and prevents the most common UNION-probing misdiagnosis.

## Lessons Learned

- This lab is the isolated, minimal case of methodology step 2 — the NULL-increment probe works identically across instances (2 columns in labs 3–5 contexts, 3 here), so no per-instance assumptions should be carried over; probe fresh every time.
- Over-count probes (N+1, N+2) also return 500 but sometimes with different error bodies (5548 vs. 2525 bytes) — not all 500s are equal; size deltas can hint at *which* mismatch occurred.

## Related Methodology

- methodology/injection.md (UNION recipe step 2 — column-count discovery)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-determining-number-of-columns
- Solved instance: https://0af400310406857780ce21eb0013009c.web-security-academy.net
