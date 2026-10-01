# PortSwigger Lab

## Lab

Insufficient workflow validation

URL: https://0a4700560438d669806bc793007f0021.web-security-academy.net

## Vulnerability Class

Business logic — purchase-workflow sequencing flaw (order confirmation finalizes attacker-mutated cart without funds re-validation or charge)

## Objective

Buy the $1337.00 “l33t” Leather Jacket on ~$98 store credit. Official solution consulted AFTER elimination (stuck provision); instance wording (`order-confirmed=true`) used from evidence, not the writeup's (`order-confirmation=true`).

## Initial Observations

- Same shop family as price lab, but product form has NO `price` field (only `productId`/`quantity`/`redir`) — price-trust inapplicable (verified by reading, not assumed).
- Cart: coupon box (csrf), quantity ±/Remove, `POST /cart/checkout` (csrf) → 303 `/cart/order-confirmation?order-confirmed=true`.
- Credit $98.20–$100; jacket $1337 → EXPECTED unaffordable; cheap item $1.80 affordable.

## Hypotheses

- H1: Prices/quantities/products server-validated here (spot-check, don't assume price-lab flaw).
- H2: Checkout is stepwise (cart → checkout-POST → confirmation-GET) and the confirmation finalizes CURRENT cart state — mutating the cart between a legitimate cheap checkout and a confirmation replay yields the expensive item at no charge.
- H3: Replay completes the jacket order with no deduction → solved.

## Attempts

1. Quantity matrix (0 → empty; 99 → ok; 100/1000 → rejected-empty; 99+99 → 198 accumulated — cap bypass noted but gain-upward, parked).
2. productId matrix (`0,-1,9999,abc,1.0,01,' 1',null…`) → only exact `01` resolves (jacket, correctly priced); no fail-open.
3. `POST /cart/checkout` unaffordable cart → 303 `/cart?err=INSUFFICIENT_FUNDS`; failed checkouts leave credit untouched (validate-then-charge, correct).
4. Coupon guessing (~20 codes), coupon SQLi/flags, confirm-flags (`confirmed=true` etc.) → all `Invalid coupon`; zero coupon mentions across account + 20 product pages. Abandoned as rabbit hole.
5. Failed-checkout credit check (coupon param on checkout) → balance unchanged. Correct.
6. Cheap order E2E: add $1.80 → checkout-POST (303) → visit confirmation → `Your order is on its way!`, Total `$1.80`, credit `$98.20→$96.40`. Maps charge point to CONFIRMATION visit (correcting my earlier POST-charges assumption) — H2 supported.
7. Add jacket ($1337) → replay `GET /cart/order-confirmation?order-confirmed=true` → `Your order is on its way!`, jacket ×1, Total `$1337.00`, credit UNCHANGED `$96.40`, cart emptied; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Price-lab payload reuse (no price field exists here — confirmed by inspection before any test).
- Coupon discovery (~25 attempts + content sweep) — no valid code exists in reachable content; correctly abandoned.
- Quantity/productId/funds-check attacks — all validated server-side; each recorded as scope evidence.
- Assuming charge-at-POST (from shared-account credit observation) — corrected by step-6 evidence (charge at confirmation visit).

## What Worked

- Legitimate cheap purchase → mutate cart (add jacket) → replay confirmation GET → $1337 order at $0 marginal charge → solved.

## Burp Observations

- Not used via Burp MCP; curl + Repeater-equivalent GET replay sufficed.

## Browser Observations

- Not required. Pure HTTP sequence.

## CLI / Tool Observations

- curl session jar across login→cart→checkout→confirm; cart HTML as credit/total oracle; shell-script files (`/tmp/kflow.sh`, `/tmp/kreplay.sh`) after inline quoting broke — note: keep inline commands quote-simple or use script files.

## Root Cause

The purchase workflow assumes an immutable cart between checkout-POST and confirmation-GET but never re-validates: the confirmation endpoint finalizes and clears WHATEVER is currently in the cart, deducting only (or nothing beyond) the original cheap charge. Attacker checks out cheap, swaps in the expensive item, replays confirmation — order completes with no additional deduction (credit stayed $96.40 for a $1337 item).

## Verification

- Cheap-order baseline (charge $1.80, credit delta) vs replay (charge $0.00 for $1337, no delta) — same endpoint, mutated cart only.
- End-state: confirmation names jacket + Total `$1337.00` + `Your order is on its way!` + cart emptied + `/` `is-solved`. Deterministic server-side effect.
- Instance param `order-confirmed=true` taken from the live 303 Location, not the writeup's variant.

## Impact

Arbitrary-value orders at zero marginal charge (demonstrated $1337 item free) — revenue loss per replay; workflow replayable for any catalog item.

## Why The Successful Approach Worked

- Stopped forcing price-lab and coupon families after evidence (no field; no source) instead of deepening them.
- Mapped the TRUE charge point (confirmation visit) with a cheap baseline before attacking — the replay target followed from evidence.
- One mutation (cart contents) between two legitimate steps; solved state attributable solely to missing re-validation.

## Generalization

- For multi-step purchases, chart every step's inputs AND what it re-validates: checkout-POST (funds ✓) vs confirmation-GET (funds ✗, contents = current cart) — the gap is the flaw.
- Baseline-cheap-then-mutate-then-replay is the test shape; prove with charged-vs-uncharged balance delta + solved marker.
- Writeup param names may differ per instance (`order-confirmation` vs `order-confirmed`) — always take redirect targets from live responses.

## Lessons Learned

- Same-shop ≠ same-flaw: read forms fresh (price field present vs absent decided the whole approach in request one).
- Abandonment discipline (coupons after content sweep + 25 negatives) funded the pivot that solved it.
- Shared-account credit observations across sessions mislead charge-point attribution — per-session baselines only.

## Related Methodology

- methodology/business-logic.md (workflow sequencing — to be extended)

## References

- Lab: https://portswigger.net/web-security/logic-flaws/examples/lab-logic-flaws-insufficient-workflow-validation (solution consulted AFTER elimination; instance wording verified from live 303)
- Solved instance: https://0a4700560438d669806bc793007f0021.web-security-academy.net/
