# PortSwigger Lab

## Lab

Infinite money logic flaw

URL: https://0a9e008c035d516a8064b7360085003a.web-security-academy.net/

## Vulnerability Class

Business logic — gift cards purchasable with discounted funds but redeemable at full face value: 30%-off $10 card ($7) redeems +$10 credit → +$3/cycle, compounding to arbitrary balances

## Objective

Buy the $1337 Lightweight l33t leather jacket starting from $100 store credit. Solved when the jacket order completes (`is-solved`).

## Initial Observations

- CURRENT EVIDENCE: shop (20 products), wiener login → `$100.00`; my-account redeem form (`POST /gift-card` + csrf + code).
- CURRENT EVIDENCE: $10 gift card (product 2); purchase → code emailed to wiener@exploit inbox; redeem → +$10 credit; re-redeem → 400 (single-use holds); 15-thread race → single 200 (no double-spend).
- CURRENT EVIDENCE: cart coupon form; `NEWCUST5/WELCOME10/DISCOUNT` → `Invalid coupon`; `SIGNUP30` → -$401.10 on jacket (30% off) but single-use holds on re-apply; newsletter re-emits the SAME code (no second coupon).

## Hypotheses

- H1: redeem repeats (falsified: 400) or races (falsified: 1/15 wins) — single-use sound.
- H2: discounted purchase + full-value redemption nets positive per cycle → compound to jacket price.

## Attempts

1. Buy $10 card ($100→$90) → redeem (+$10 → $100): net $0 — baseline economics, no flaw alone.
2. Race (2-thread, 15-thread) and case-variant double-redeems → all rejected. Rate/case families closed.
3. Coupon probing (4 codes) → only SIGNUP30 valid (30% off, single-use per order).
4. COMBINATION: $10 card + SIGNUP30 → $7.00 charge ($100→$93) → redeem +$10 → $103. +$3/cycle CONFIRMED.
5. Scaling loop (8 cycles, bulk quantities ≤99, fresh coupon per order, inbox-diff code harvesting): `$103→$145→$205→$292→$415→$592→$844→$1141→$1438` (~+40%/cycle, coupon reusable across separate orders).
6. Jacket purchase at $1438 credit → charged `$1337`, `$101.00` left, `is-solved` ×2. SOLVED.

## What Failed

- Redemption repeat/race/case tricks (all correctly enforced — the flaw is compositional, not in redemption).
- Second-coupon hunt (only one code exists; alternation impossible here).

## What Worked

Discounted-purchase × full-redemption arbitrage, compounded over 8 bulk cycles.

## Burp Observations

- Login/cart/coupon/redeem mapping via Burp-equivalent flows; bulk loop via CLI (session continuity + inbox diffing advantage).

## Browser Observations

- Not required. Pure HTTP + email-client reads via HTTP. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python single-session chains; inbox set-difference code harvesting (seen-set vs poll); per-cycle credit logging (the compounding curve IS the evidence).

## Root Cause

Two individually-sound mechanisms compose unsoundly: per-order coupon discount (correctly single-use) applies to gift-card purchases, while redemption credits full face value. Each buy-redeem cycle mints $3 per $10 card (30% of face); bulk quantities scale it to ~+40%/cycle with no cap.

## Verification

- Per-cycle credit deltas logged ($103→$1438 monotonic compounding).
- Final jacket charge `$1337` + `$101.00` remainder + `is-solved` (financial effect).
- Deterministic end-to-end.

## Impact

Unbounded store-credit generation (demonstrated: $100→$1438 in 8 cycles) → any-priced goods for free; direct revenue loss at scale.

## Why The Successful Approach Worked

- Killed redemption-side theories with evidence (400s, 1/15 race) instead of escalating concurrency blindly.
- Noticed the COMPOSITION (discount × face-value) rather than hunting a second flaw in either half.
- Bulk quantities + fresh-coupon-per-order turned +$3/cycle into exponential growth.

## Generalization

- NEW reusable variant for methodology/business-logic.md: discounted-purchase × full-redemption arbitrage (test gift/store-credit instruments under every active discount; loop while net-positive).

## Lessons Learned

- Single-use enforcement on each half does not imply compositional soundness — always test cross-mechanism loops (buy↔redeem, discount↔credit).
- Compounding beats linear: bulk sizing per cycle from current balance minimizes cycles logarithmically.

## Related Methodology

- methodology/business-logic.md (gift-card arbitrage variant — genuinely new; update justified, applied separately)
- methodology/verification.md (per-cycle delta logging + charged-total + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Prior related (discipline sources): coupon-alternation lab (coupon mechanics: single-use per order, reusable across orders, floor behavior), low-level lab (bulk sizing)
- Solved instance: https://0a9e008c035d516a8064b7360085003a.web-security-academy.net/ with SIGNUP30 gift-card arbitrage → $1438 → jacket
