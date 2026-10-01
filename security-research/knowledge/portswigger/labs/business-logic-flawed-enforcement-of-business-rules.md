# PortSwigger Lab

## Lab

Flawed enforcement of business rules

URL: https://0a6b00ce03530c9c8174529200750019.web-security-academy.net/

## Vulnerability Class

Business logic — coupon duplicate-use check compares only against the immediately previous code, so alternating two coupons stacks discounts without limit → free order

## Objective

Buy the $1337 Lightweight l33t leather jacket with $100 store credit. Solved when the manipulated order completes (`is-solved`).

## Initial Observations

- CURRENT EVIDENCE: server-side pricing (no `price` field); `quantity min=0 max=99`; $100 credit; jacket $1337.
- CURRENT EVIDENCE: coupon form (`POST /cart/coupon` + csrf); no coupon code anywhere on reachable surfaces (homepage, blog-less shop, register-404, anon cart).
- CURRENT EVIDENCE: negative `quantity=-1` silently ignored (redirect, no cart change) — mixed-sign recipe from the high-level lab does NOT transfer; recorded and abandoned after 2 probes.
- CURRENT EVIDENCE: confirmation replay → HTTP 400 — replay recipe does not transfer either.
- CURRENT EVIDENCE: funds verified (`INSUFFICIENT_FUNDS` on $1332 vs $96.96); coupon does not move credit ($96.96 before/after/around).

## Hypotheses

- H1: a second coupon exists outside reachable surfaces (stuck point — description research revealed newsletter signup).
- H2: duplicate-use enforcement is order-local (same-code-twice rejected) but bypassable by alternation.

## Attempts

1. Shop/coupon-surface mapping; negative-qty, replay, funds, credit-movement probes (all above — bounded falsifications, each 1–3 requests).
2. Stuck provision: description research → newsletter signup path + alternation hint (hypothesis source, NOT blindly copied — every claim below re-verified).
3. Newsletter `POST /sign-up` → alert `Use coupon SIGNUP30 at checkout!` (evidence, not assumption).
4. Jacket cart + `NEWCUST5` → -$5.00 ($1332); re-apply → unchanged (same-code-twice correctly rejected — matches description).
5. Alternation `NEWCUST5,SIGNUP30 ×8`: totals `$1332 → $930.90 → $925.90 → $524.80 → $519.80 → $118.70 → $113.70 → $0.00` (floor). Each alternation re-applies BOTH discounts — duplicate check only compares adjacent codes. H2 CONFIRMED.
6. Checkout at `$0.00` → `order-confirmed=true`, credit untouched `$96.96`, `is-solved` ×2. SOLVED.

## What Failed

- Negative quantities (silently ignored here, unlike the high-level lab) — family recipes do not transfer without per-instance verification.
- Confirmation replay (400) — same lesson.
- Blind coupon guessing (refused — correctly, as the code came from the newsletter surface, then description).

## What Worked

Two-coupon alternation to the $0.00 floor → free jacket order.

## Burp Observations

- Form/endpoint mapping via Burp-equivalent GETs; multi-step jar flows via CLI (login→cart→coupon×N→checkout continuity).

## Browser Observations

- Not required. Pure HTTP workflow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` single-session chains; per-application total logging (the descending sequence IS the evidence of stacking).

## Root Cause

Coupon duplicate-use enforcement compares the submitted code only against the most recently applied code (adjacent comparison): same-code-twice rejected, but A,B,A,B alternation re-applies every discount each cycle. Discounts stack without bound down to the $0.00 floor, and $0 orders complete.

## Verification

- Descending total sequence per application proves stacking (not a one-off rendering quirk).
- $0.00 checkout completes with credit untouched + `is-solved` (financial effect: $1337 goods, $0 charged).
- Same-code-twice rejection observed directly (control proving the adjacent-comparison mechanism).

## Impact

Arbitrary discount stacking → free orders (demonstrated: $1337 → $0.00); revenue loss at scale on any coupon pair.

## Why The Successful Approach Worked

- Stuck provision used correctly: after 6+ bounded falsifications across 4 recipe families, description research supplied exactly the two missing facts (newsletter code, alternation shape), each re-verified before conclusions.
- Per-application total logging made the stacking mechanism self-evident (monotonic descent vs single-use plateau).

## Generalization

- NEW reusable variant for methodology/business-logic.md: adjacent-comparison duplicate checks are bypassed by alternation; always test A,B,A,B cycling wherever same-code-twice is rejected.

## Lessons Learned

- Family-recipe non-transfer is data: negative-qty and replay failures here (vs success one lab prior) prove per-instance verification beats recipe reuse — recorded, not regretted.
- Coupon discovery belongs to surface mapping (newsletter form at page bottom); guessing is never the first move.

## Related Methodology

- methodology/business-logic.md (coupon-alternation variant — genuinely new; update justified, applied separately)
- methodology/verification.md (descending-sequence proof + $0 charge + marker)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: objective (buy jacket) + newsletter/SIGNUP30/alternation solution (hypothesis source after stuck checkpoint; every step re-verified by current evidence)
- Prior related (discipline sources): the five business-logic notes, especially high-level (mixed-sign) and excessive-trust (coupon-surface) instances
- Solved instance: https://0a6b00ce03530c9c8174529200750019.web-security-academy.net/ with NEWCUST5/SIGNUP30 ×8 → $0.00 order
