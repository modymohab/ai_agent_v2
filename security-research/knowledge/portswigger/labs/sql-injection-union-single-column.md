# PortSwigger Lab

## Lab

SQL injection UNION attack, retrieving multiple values in a single column

URL: https://0aa300a7036de9128428c2c700050097.web-security-academy.net

## Vulnerability Class

SQL injection — UNION attack, multi-value extraction in a single rendered column (separator concatenation)

## Objective

Retrieve the administrator's username and password from the `users` table when only ONE of the query's columns is rendered, and log in as administrator.

## Relevant Application Behavior

- Same e-commerce family; injection point `GET /filter?category=<value>`.
- Errors → HTTP 500 (~2519 bytes); valid queries → 200.
- Comment style: `--` works; `#` → 500 (verified fresh).
- 2 result columns (UNION 2 NULLs → 200; 1 and 3 → 500).
- Only position 2 renders text (position 1: literal probe not displayed).

## Initial Observations

- Baseline `category=Lifestyle` → 200, 4858 bytes.
- `category=Lifestyle'` → 500 (interpolation confirmed).
- `UNION SELECT NULL,NULL--` → 200 (+81 bytes).

## Hypotheses

- H1: Filter injection, `--` comment, 2 columns.
- H2: Exactly one rendered position — the "single column" constraint named in the title — requiring `username || '~' || password` concatenation into that position.
- H3: Classic unrandomized `users(username, password)` table (standard-name-first heuristic from lab 9).

## Attempts

1. Baseline / quote / comment checks → injection + `--` confirmed.
2. NULL increments → 2 columns bracketed.
3. Literal probe per position: pos 1 → not rendered; pos 2 → rendered (single rendered column identified).
4. `' UNION SELECT NULL,username || '~' || password FROM users--` → `administrator~ock15150ypjn139dymcs`, carlos, wiener.
5. Login with administrator credentials (CSRF+cookie paired) → 302 → `/my-account?id=administrator` → "Your username is: administrator".

## What Failed

- Nothing: the separator-concatenation technique from methodology applied directly; no enumeration needed (unrandomized identifiers).

## What Worked

`GET /filter?category=Lifestyle' UNION SELECT NULL,username || '~' || password FROM users--`

then login with `administrator` / `ock15150ypjn139dymcs`.

## Root Cause

Unparameterized `category` input in a 2-column SELECT where the application renders only the second column. Multiple values (username, password) must be merged into the single rendered position via string concatenation. The `users` table is readable by the query's DB account, and plaintext credentials convert disclosure into account takeover.

## Verification

- Column count bracketed (500 at 1/3; 200 at 2).
- Rendered position identified by literal probe (pos 1 undisplayed; pos 2 displayed).
- Credential rows rendered with unambiguous `~` separator; login → 302 → "Your username is: administrator"; lab status `is-solved`.

## Impact

Full credential disclosure for all users via a single rendered column; administrator account takeover. Demonstrates that a reduced rendering surface (1 of 2 columns displayed) does NOT reduce extractability — concatenation restores full multi-field extraction.

## Why The Successful Approach Worked

- The literal-placement probe (2 requests) identified which of the two positions renders, directing the concatenated payload into position 2 with NULL padding position 1.
- `||` concatenation with `~` separator packs both credential fields into the one rendered slot and keeps parsing unambiguous.
- Standard-name-first (`users`) worked immediately — no enumeration required.

## Generalization

- Reduced rendering (N columns queried, fewer displayed) is a presentation-layer restriction, not a security control: any text-tolerant rendered position can carry arbitrarily many concatenated fields.
- The recipe for single-column extraction: count → find rendered position(s) → concatenate all wanted fields with a distinctive separator into a rendered position.
- This completes the UNION lab family: the same recipe solved count (7), rendered-position (8), direct cross-table (9), and single-column (this) variants — only the final payload differs.

## Lessons Learned

- The separator-concatenation technique, promoted from the contents labs, directly solved the single-column constraint without adaptation — methodology reuse paid off with zero failed payloads.
- Literal-probe cost stays at one request per position regardless of column count — cheap insurance against payload placement in a dead position.

## Related Methodology

- methodology/injection.md (UNION recipe; single-column extraction via separator concatenation)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-union-single-column
- Solved instance: https://0aa300a7036de9128428c2c700050097.web-security-academy.net
