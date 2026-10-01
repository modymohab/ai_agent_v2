# PortSwigger Lab

## Lab

SQL injection UNION attack, finding a column containing text

URL: https://0a7e00ca03f3e2578221e28a001e00b4.web-security-academy.net

## Vulnerability Class

SQL injection — UNION attack, rendered text-column discovery (literal placement)

## Objective

Make the database retrieve the string `Uqtq28` (i.e., identify a UNION position that both renders and accepts text).

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2572 bytes); valid queries → 200 listing.
- Comment style: `--` works; `#` → 500 (instance-specific, verified fresh).
- 3 result columns (UNION 3 NULLs → 200; 2 and 4 → 500).

## Initial Observations

- Baseline `category=Food & Drink` → 200, 5139 bytes.
- `category=...& Drink'` → 500 (interpolation confirmed).
- `UNION SELECT NULL,NULL,NULL--` → 200 (+86 bytes, one injected row).

## Hypotheses

- H1: Filter injection with `--` comment (empty-comment test: `--` → 200, `#` → 500).
- H2: Column count is 3 (NULL-increment bracketing).
- H3: Exactly one (or more) of the three positions renders text; placing the literal `Uqtq28` there fulfills the objective.

## Attempts

1. Baseline / quote / empty-comment checks → injection + `--` confirmed.
2. NULL increments: 1 → 500, 2 → 500, 3 → 200, 4 → 500 (3 columns, bracketed).
3. Literal placement of `Uqtq28` at each position:
   - position 1 → renders (1 occurrence)
   - position 2 → renders (3 occurrences)
   - position 3 → does not render
4. Position-2 payload → 200; lab status `is-solved`.

## What Failed

- Position 3 did not render the literal — expected behavior for non-displayed columns; not a failure of the method. No wasted requests: each placement test was a single request.

## What Worked

`GET /filter?category=Food & Drink' UNION SELECT NULL,'Uqtq28',NULL--`

(URL-encoded: `category=Food+%26+Drink%27+UNION+SELECT+NULL%2C%27Uqtq28%27%2CNULL--`)

Result: 200 with `Uqtq28` rendered in the product listing; lab solved.

## Root Cause

The `category` parameter is concatenated into a 3-column SELECT. The application renders columns 1 and 2 (title/description contexts) but not column 3. Text-tolerant rendered positions are discoverable via literal placement — the query accepts a string literal only in text-typed columns, and rendering depends on the application's display logic.

## Verification

- Column count bracketed deterministically (500 at 2 and 4; 200 at 3).
- Literal rendered: position-2 response contained `Uqtq28` (grep count 3 — multiple render contexts).
- Lab status header changed to `is-solved`.

## Impact

Rendered-column identification completes the structural reconnaissance needed for data extraction: with a text-tolerant rendered position known, arbitrary query results (credentials, schema data) can be surfaced through the listing UI — the exact technique used in the version and contents labs.

## Why The Successful Approach Worked

- The lab's target string doubles as the literal-placement test: one payload per position, three requests total, no separate `'a'` probe needed when the objective is itself a literal.
- A text literal in a numeric-typed column would 500 (type mismatch), so a 200 at a position proves both text tolerance and render.

## Generalization

- Rendered-position discovery: place the target literal at each NULL position; a position that returns 200 AND displays the string is extraction-ready. Positions that 500 are non-text; positions that return 200 but don't display are text but unrendered (distinguishable only by checking the body).
- Multiple positions can render (here 1 and 2); any rendered text position is usable for extraction — prefer the one with the most predictable rendering context.
- The literal-placement step subsumes the separate `'a'` probe when the payload is already a known string.

## Lessons Learned

- Steps 2 (count) and 3 (rendered position) of the UNION recipe compose directly: NULLs first, then substitute the literal one position at a time — never both unknowns simultaneously.
- Per-instance verification remains essential: this instance used `--` with 3 columns where a sibling instance (column-count lab) also used `--` but a MySQL instance used `#` — always re-test comment style and count fresh.

## Related Methodology

- methodology/injection.md (UNION recipe step 3 — rendered/text column identification)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-find-column-containing-text
- Solved instance: https://0a7e00ca03f3e2578221e28a001e00b4.web-security-academy.net
