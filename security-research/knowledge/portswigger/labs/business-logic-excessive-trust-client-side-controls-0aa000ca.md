# PortSwigger Lab

## Lab

Excessive trust in client-side controls (instance `0aa000ca035a490780a82b87000a0006`)

URL: https://0aa000ca035a490780a82b87000a0006.web-security-academy.net/

## Vulnerability Class

Business logic — client-submitted unit price stored into cart and charged at checkout without server re-validation

## Objective

Purchase the $1337 jacket for less than the $100 store credit. Solved when the manipulated order completes (`is-solved`).

## Initial Observations

- CURRENT EVIDENCE: product form byte-identical in shape to the prior instance (`productId=1`, `redir=PRODUCT`, `quantity`, hidden `price=133700`).
- CURRENT EVIDENCE: lab header `is-notsolved`.

## Hypotheses

- H1: `POST /cart` with `price=100` renders cart Total `$1.00` (stored trust).
- H2: legitimate CSRF-bound login + checkout charges the stored Total.

## Attempts

1. `POST /cart productId=1&redir=PRODUCT&quantity=1&price=100` (price ONLY changed) → `GET /cart` → Total `$1.00`. H1 confirmed.
2. Same-session CSRF-bound `wiener:peter` login → 302→200 `/my-account?id=wiener`, identity renders, credit `$100.00` (login follows redirect; 200 is the account page, not a failure — verified by identity render, not assumed).
3. `POST /cart/checkout` (cart-page csrf, same jar) → `order-confirmation?order-confirmed=true`: charged Total `$1.00`, list `$1337.00`, credit `$99.00`, `is-solved` ×2. H2 confirmed.

## What Failed

- Nothing: first price value worked; no lockout, no CSRF issues (pair discipline held throughout).
- Momentary misread: login's 200 (post-redirect render) looked like non-redirect until identity render confirmed success — status-only reading would have misled.

## What Worked

Single-variable price drop → cart state proof → legitimate checkout → $1.00 charge on $100→$99 credit → solved.

## Burp Observations

- Form-shape evidence via Burp-equivalent GETs; flow executed via CLI cookie-jar loops (session preservation across cart→login→checkout is the whole game; scripted jar preferred over per-request Burp replay).

## Browser Observations

- Not required. Pure HTTP workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` for binding cart→login→checkout to one session; regex oracles on amounts/marker.

## Root Cause

Cart pricing trusts the client-submitted `price` field with no server-side lookup: attacker value flows into line total, cart total, and the charged order.

## Verification

- Cart state `$1.00` before auth (trust proof isolated from checkout).
- Charged total `$1.00` + balance delta `$100→$99` + `is-solved` (financial effect, not UI echo).
- CSRF + login enforced around the flaw (controls isolated to value trust).

## Impact

Arbitrary price setting on any item (demonstrated: $1337 → $1.00 charged); revenue loss at scale.

## Why The Successful Approach Worked

- Single-variable change (price only) → attribution clean.
- Cart-state proof BEFORE auth complexity (methodology step order).
- Same-jar session continuity (cart survives login).

## Generalization

NONE new — identical variant to the existing note (same amounts, same flow, same proof). Methodology variant 1 covers it completely.

## Lessons Learned

- Instance confirmation only: byte-identical form shape → byte-identical exploit; no adaptation needed. Preserved as instance evidence per the multi-instance convention.

## Related Methodology

- methodology/business-logic.md (variant 1 — fully applies; NO update justified)
- methodology/verification.md (charged-total + balance-delta + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Prior same-slug instance: knowledge/portswigger/labs/business-logic-excessive-trust-client-side-controls.md (`americas`-era amounts identical)
- Solved instance: https://0aa000ca035a490780a82b87000a0006.web-security-academy.net/ with `price=100` checkout
