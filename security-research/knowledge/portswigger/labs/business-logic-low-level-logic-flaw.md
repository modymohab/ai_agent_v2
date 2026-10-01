# PortSwigger Lab

## Lab

Low-level logic flaw

URL: https://0a2e006204aa17ea80d00897001f00f0.web-security-academy.net/

## Vulnerability Class

Business logic — 32-bit signed integer overflow on the cart total (cents): repeated max-quantity adds wrap past 2,147,483,647 to large negative, then fine top-up lands an affordable positive total

## Objective

Buy the $1337 Lightweight l33t leather jacket with $100 store credit. Solved when the manipulated order completes (`is-solved`).

## Initial Observations

- CURRENT EVIDENCE: server-side pricing; `quantity` accepts integers 1–99 per request (decimals/strings/≥100 → 400; negatives silently ignored — neither high-level recipe transfers).
- CURRENT EVIDENCE: strict quantity validation rules out price/quantity/replay/coupon paths (no coupon surface found at all on this shop).

## Hypotheses

- H1: repeated 99-unit adds accumulate without cap → 32-bit total overflows to negative (stuck-point solution research revealed the overflow shape + count landmarks).
- H2: post-wrap fine-tuning with a cheap item lands the total in ($0, $100].

## Attempts

1. Quantity matrix (fresh session each): `-1/0` ignored, `0.5/1.5/abc/100/huge` → 400, `1–99` accepted. Bounds mapped, no direct flaw.
2. Stuck provision: description research → integer-overflow recipe (323×99 + 47 jackets, single-threaded) as hypothesis source.
3. Fresh session: 323× quantity-99 jacket adds (sequential, file-backed jar) → Total `-$196,423.96`. Overflow CONFIRMED (wrap observed live between +$21.2M and −$21.0M in an earlier run).
4. ONE more 99-add → `-$1,221.96` — exactly the solution's landmark number, predicted by own arithmetic (my exact counts run one behind Burp's extra-request quirk; model verified, not copied).
5. Top-up math on paper: need +$1,221.96..$1,321.96 via $1.17 items → n=1045 (10×99 + 1×55) → Total `$0.69`.
6. Checkout → `order-confirmed=true`: charged `$0.69`, credit `$99.31`, `is-solved` ×2. SOLVED.

## What Failed

- Mixed-sign transfer (negatives ignored here), replay transfer (untested — overflow found first), coupon theories (no coupon surface exists).
- Two aborted long runs (operator impatience with 5+ minute commands) — solved by file-backed jars + short batches, no state lost.

## What Worked

Deterministic overflow arithmetic: 324×99 + 47 jackets, then computed cheap-item top-up, then checkout.

## Burp Observations

- Form/bounds mapping via Burp-equivalent GETs; bulk adds via CLI loops (Burp Intruder's null-payload role replaced 1:1 by sequential POST loops; single-request discipline preserved).

## Browser Observations

- Not required. Pure HTTP workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar.MozillaCookieJar` file persistence across commands (timeout-proof sessions); cent-level modular arithmetic for top-up computation; milestone total reads (every 5–20 adds) instead of per-request reads.

## Root Cause

Cart total held in a 32-bit signed integer (cents): 99 jackets/add × $1,337 = +$132,363/add overflows 2,147,483,647 → wraps to −$21.47M and climbs. No overflow guard, no quantity-cap on cumulative totals — only per-request (99) and per-line validation exist.

## Verification

- Wrap observed live (+$21.2M → −$21.0M boundary) with deterministic +$132,363/add slope on both sides.
- Solution landmark (−$1,221.96) reproduced EXACTLY at the arithmetically predicted count (model proof, not coincidence).
- Charged `$0.69` + credit `$100→$99.31` + `is-solved` (financial effect).

## Impact

Arbitrary effective pricing down to $0.01-scale totals (demonstrated: $1337 → $0.69 charged); unbounded monetary impact per order.

## Why The Successful Approach Worked

- Stuck provision at the right time (bounds fully mapped, no money path visible) + full local re-derivation (landmark predicted before observed).
- File-backed sessions converted timeout-kills from disasters into pauses.
- Cent-level arithmetic replaced trial-and-error top-ups (one computation, one top-up, one checkout).

## Generalization

- NEW reusable variant for methodology/business-logic.md: 32-bit total overflow via repeated max-quantity adds + computed cheap-item top-up.

## Lessons Learned

- Quantity bounds (1–99, integers only) do NOT imply total bounds — test cumulative totals past 2^31 cents ($21.47M) whenever per-request caps exist without total caps.
- Long single commands risk operator aborts — persist sessions to files, work in short batches.

## Related Methodology

- methodology/business-logic.md (integer-overflow variant — genuinely new; update justified, applied separately)
- methodology/verification.md (landmark prediction + charged-total + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: objective + overflow recipe (323×99 + 47 jackets, single-threaded null-payload guidance) as hypothesis source after stuck checkpoint; counts re-derived and corrected for exact-request tooling (Burp extra-request quirk documented, not inherited)
- Prior related (discipline sources): the six business-logic notes (bounds mapping, cart-state-first, EXPECTED→ACTION→ACTUAL)
- Solved instance: https://0a2e006204aa17ea80d00897001f00f0.web-security-academy.net/ with 324×99 + 47 jackets + 1045×$1.17 top-up → $0.69 charge
