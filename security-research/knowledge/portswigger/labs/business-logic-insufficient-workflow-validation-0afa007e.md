# PortSwigger Lab

## Lab

Insufficient workflow validation (instance `0afa007e039d1ee086158a66000a0017`)

URL: https://0afa007e039d1ee086158a66000a0017.web-security-academy.net/

## Vulnerability Class

Business logic — order confirmation finalizes the CURRENT cart rather than the checked-out cart: cheap baseline order, mutate, replay confirmation

## Objective

Obtain the $1337 jacket without sufficient credit ($100). Solved when the replayed order completes (`is-solved`).

## Initial Observations

- CURRENT EVIDENCE: wiener login → `$100.00`; cheap item product 2 = `$40.50`.

## Hypotheses

- H1: charge lands at confirmation-visit (map with cheap E2E first).
- H2: post-charge mutation + confirmation replay finalizes the mutated cart.

## Attempts

1. Cheap E2E: product2 ×1 → checkout → `order-confirmation?order-confirmed=true`, charged `$40.50`, credit `$59.50`. H1 CONFIRMED (charge point = confirmation visit; live URL recorded from response).
2. Added jacket ×1 to cart → replayed confirmation GET → amounts `$1337.00` + `$19.00`, `is-solved` ×2. H2 CONFIRMED (mutated cart finalized; $0 additional jacket charge beyond the cheap baseline). SOLVED.

## What Failed

- Nothing: baseline-then-replay worked first try per methodology.

## What Worked

Cheap baseline ($40.50) → jacket mutation → confirmation replay → solved.

## Burp Observations

- Flow mapped via Burp-equivalent requests; jar-preserved multi-step chain via CLI.

## Browser Observations

- Not required. Pure HTTP workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` single-session chains; live redirect targets from responses (never assumed).

## Root Cause

Missing cart-immutability between checkout and confirmation: the confirmation step prices whatever the cart holds at replay time, not what was validated at checkout.

## Verification

- Baseline charge proof ($40.50, $59.50 left) before mutation.
- Replay shows jacket amount + `is-solved` with no additional jacket charge. Solved marker + mutated-cart finalization confirmed.

## Impact

$1337 goods for the price of the cheapest item (demonstrated: $40.50 baseline + replay).

## Why The Successful Approach Worked

- Charge-point mapping first (methodology step 6): knowing the charge lands at confirmation-visit selected replay over coupon/quantity theories with zero wasted probes.

## Generalization

NONE new — identical variant to the existing note. No methodology or index changes justified.

## Lessons Learned

- Instance confirmation only: same flow, same proof shape.

## Related Methodology

- methodology/business-logic.md (variant 2 + step 6 — fully applies; NO update)
- methodology/verification.md (baseline-then-effect proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Prior same-slug instance: knowledge/portswigger/labs/business-logic-insufficient-workflow-validation.md
- Solved instance: https://0afa007e039d1ee086158a66000a0017.web-security-academy.net/ with $40.50 baseline + jacket replay
