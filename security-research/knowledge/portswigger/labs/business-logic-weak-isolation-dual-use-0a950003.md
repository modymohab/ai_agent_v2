# PortSwigger Lab

## Lab

Weak isolation on dual-use endpoint (instance `0a950003039d632983c9fc92009200aa`)

URL: https://0a950003039d632983c9fc92009200aa.web-security-academy.net/

## Vulnerability Class

Business logic — password-change endpoint serving self-service and arbitrary targets checks `current-password` only when the field is present; omitting it resets anyone's password

## Objective

Delete user `carlos` via the admin panel. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: change-password form byte-identical in shape to the prior instance (editable `username=wiener`, `current-password`, `new-password-1/2`, csrf).
- CURRENT EVIDENCE: wiener:peter valid (identity renders).

## Hypotheses

- H1: `current-password` wrong → rejection; DROPPED → success (guard skipped when absent).
- H2: reset carlos, then administrator, then admin delete → `is-solved`.

## Attempts

1. Guard matrix on low-value carlos: wrong value → `Current password is incorrect`; DROPPED field → carlos login with new password SUCCEEDS (identity renders). H1 CONFIRMED via effect (success banner text not relied upon).
2. Same dropped-field reset for `administrator` → administrator login succeeds (identity renders).
3. `/admin` → 200 panel; `GET /admin/delete?username=carlos` → re-read: `is-solved` ×2, roster shows only `wiener - ` (carlos gone; administrator itself not listed as a deletable row). H2 CONFIRMED. SOLVED.

## What Failed

- Nothing: matrix behaved exactly per methodology on first attempt.

## What Worked

Dropped-guard reset chain (carlos → administrator) → admin delete → solved.

## Burp Observations

- Form-shape evidence via Burp-equivalent flows; multi-step jar chains via CLI (wiener session → resets → fresh logins → admin → delete).

## Browser Observations

- Not required. Pure HTTP workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` chains; login verification per identity (302-follow + identity render).

## Root Cause

Presence-gated guard: `current-password` verified only when submitted; omission converts "change own password" into "reset anyone's password" with no additional check.

## Verification

- Wrong-vs-dropped differential on carlos (reject vs login-success).
- Both reset logins verified by identity render (not redirect alone).
- Delete → re-read: `is-solved` + victim absent. Victim state change confirmed.

## Impact

Any authenticated user resets any account's password including administrator → full admin takeover (carlos deleted).

## Why The Successful Approach Worked

- Low-value-first matrix (carlos before administrator) + per-identity login proofs, straight from methodology step 8.

## Generalization

NONE new — identical variant to the existing note. No methodology or index changes justified.

## Lessons Learned

- Instance confirmation only: byte-identical form shape → byte-identical exploit chain.

## Related Methodology

- methodology/business-logic.md (variant 4 + step 8 — fully applies; NO update)
- methodology/verification.md (differential + identity + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Prior same-slug instance: knowledge/portswigger/labs/business-logic-weak-isolation-dual-use.md
- Solved instance: https://0a950003039d632983c9fc92009200aa.web-security-academy.net/ with dropped-field resets → delete carlos
