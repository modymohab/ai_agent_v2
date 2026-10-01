# PortSwigger Lab

## Lab

Multi-endpoint race conditions — https://0a1d00bd03a273fa81a09e85007b008d.web-security-academy.net/ (PortSwigger Web Security Academy, Race conditions). Creds wiener:peter, credit $100. Gift Card product 2 ($10), jacket product 1 ($1337).

## Vulnerability Class

Race condition across endpoints: cart mutation vs order validation/confirmation (multi-endpoint collision). NOT injection.

## Objective

Purchase the Lightweight L33t Leather Jacket with $100 credit.

## Initial Observations

- Account: $100 credit + gift-card redeem form (`POST /gift-card` + csrf + code). No coupons; endpoints: `/cart`, `/cart/checkout`, `/cart/coupon`(present but unused), `/gift-card`.
- Gift card $10: buy ($100→$90) → code issued → redeem → +$10 (net zero; single redeem atomic — 20-thread and h2-20 bursts both yielded exactly one 302, rest 400 `Invalid gift card`).
- Cart/checkout: single request/response checkout (200 = confirmation, no second step unlike limit-overrun lab).
- Methodology/race-conditions.md had limit-overrun + rate-limit patterns; multi-endpoint is new.

## Hypotheses

- H1: redeem×redeem is atomic (proven: exactly one 302 under h2-20) — NOT the vector.
- H2: checkout validates the cart then confirms from live cart state in one cycle — a concurrent `POST /cart` adding the jacket lands post-validation, pre-snapshot (multi-endpoint collision). Confirmed round 1 of paired firing.
- H3: confirmation tolerates overdraft (no second funds check at snapshot). Confirmed: -$1247.00.

## Attempts

1. Full gift-card economy mapping (buy→code→redeem, net-zero proof) + redeem-race elimination (threads then h2, both single-302).
2. Paired h2 firing [POST /cart/checkout + POST /cart productId=1] from $10-card cart: round 1 checkout body ALREADY contained the jacket (8144B) — hit immediately.
3. No reset loop needed; no failed collision rounds.

## What Failed

- Redeem×redeem racing (atomic single-use, twice proven) — necessary elimination that reframed to cross-endpoint.
- Early harness round without Location capture (303/302 ambiguity) — added redirect capture before the winning run.

## What Worked

One paired h2 burst (checkout stream first, add stream immediately after, one connection): validation saw $10, snapshot included jacket+$10 card → order $1347 confirmed → `is-solved`, credit $100→-$1247.00. Gift cycling (buy/redeem) sustained credit across probe rounds per the lab tip.

## Burp Observations

Not used (MCP flaky; Repeater parallel groups / Turbo Intruder are GUI equivalents).

## Browser Observations

Mapping only.

## CLI / Tool Observations

- curl jars per phase; csrf re-read per round (checkout csrf rotates).
- Cart line ops are DELTAS (`quantity=-N` removes; absolute `quantity=0` → 400) — reset via negative delta, not zero-set.
- python-h2 one-connection two-stream firing; capture status + Location + body (302s carry no body — follow Location).

## Root Cause

Order validation (funds vs current cart) and order confirmation (snapshot of live cart) are not atomic: a concurrent cart mutation between them is included in the confirmed order. No second funds check at snapshot permits overdraft confirmation.

## Verification

- Confirmation body: jacket ×1 + card ×1, Total $1347, `Your order is on its way!` + `is-solved` on re-read homepage.
- Credit delta $100→-$1247.00 corroborates snapshot-after-validation ordering.
- Pre-attack controls: gift-only checkout $10 (200, no jacket), jacket-only checkout 303 insufficient-funds path — winning order differs from both.

## Impact

Arbitrary-item purchase bypassing funds checks (demonstrated $1347 order on $100, settled negative); same primitive appends any catalog item to any affordable order.

## Why The Successful Approach Worked

Fired the mutation in the validation→snapshot gap of a single-cycle checkout: the check saw the cheap cart, the snapshot saw the mutated cart, and confirmation never re-checked funds.

## Generalization

Wherever validation and effect are split across endpoints sharing mutable state (cart/order/draft): fire state-mutation + commit as one multiplexed pair (commit first, mutation immediately after); read the COMMIT response body (not status) for the mutated content; sustain probe funds via the app's own stored-value loop.

## Lessons Learned

- Redeem-style endpoints are often atomic — eliminate single-endpoint racing with a multiplexed burst BEFORE assuming the window; the real race may be cross-endpoint.
- Cart ops may be delta-based (`quantity=-N` to remove; `0` rejected) — read the Remove button's actual fields.
- Capture Location + body on every race response; 302/303 without following is inconclusive.
- Single request/response checkouts still race — the window is INSIDE the cycle (validate→snapshot), not between user-visible steps.
- Gift-card buy/redeem loops fund experimentation at net zero when single-use holds.

## Related Methodology

- methodology/race-conditions.md (third pattern added below: multi-endpoint validation/snapshot collision)
- methodology/business-logic.md (stored-value/coupon reasoning)
- methodology/verification.md (commit-body + credit-delta proof)
- methodology/injection.md — compared, NOT applicable (no interpreter; state-ordering flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/race-conditions/lab-race-conditions-multi-endpoint
