# PortSwigger Lab

## Lab

Limit overrun race conditions — https://0a9d00c4031daf6f804f95a200aa0074.web-security-academy.net/ (PortSwigger Web Security Academy, Race conditions). Creds wiener:peter, credit $50.00, coupon PROMO20 (20% off).

## Vulnerability Class

Race condition: non-atomic limit enforcement (check-then-set on coupon application). NOT injection.

## Objective

Purchase the Lightweight L33t Leather Jacket ($1337) with $50 credit.

## Initial Observations

- Account: credit $50.00, banner coupon PROMO20. No gift/voucher/top-up mechanics; endpoints: `/cart`, `/cart/checkout`, `/cart/coupon`, `/cart/coupon/remove`, `/my-account/change-email`.
- Cart: jacket $1337 + PROMO20 → -$267.40 → $1069.60. Checkout → 303 `/cart?err=INSUFFICIENT_FUNDS`.
- Sequential coupon re-application: 302 each, total frozen at $1069.60 (single-use enforced). `quantity=-1` → 400.
- No stock display, no /post, no extra JS. `methodology/race-conditions.md` is an empty stub; no prior limit-overrun lab in KB.

## Hypotheses

- H1: single coupon application is check-then-set without atomicity — N parallel applies from pristine state stack N discounts (compounding 0.8^n). Needs n≥15 ($1337×0.8^15≈$47 < $50).
- H2: once applied, further bursts add nothing (check fails fast) — must remove-all and repeat per round.
- H3: HTTP/1.1 thread bursts underperform (TLS/handshake jitter); HTTP/2 multiplexing on one connection lands far more requests inside the window.

## Attempts

1. Baseline single apply + 3 sequential re-applies → idempotent $1069.60 (limit confirmed).
2. Naive 12-thread burst (shared csrf, separate connections) → $1069.60 (1 effective).
3. Barrier 40-thread burst from PRISTINE (remove-all first) → $684.54 (exactly 3 stacks: 1337×0.8³) — window proven, throughput insufficient. Repeat rounds → $684.54/$855.68 (2–3 stacks), never more.
4. Second burst WITHOUT remove → unchanged $684.54 (H2 confirmed: must reset per round).
5. HTTP/2 multiplexed burst (40 streams, one connection, back-to-back HEADERS+DATA under lock): harness hung on drain (barrier-after-send deadlock when one stream errored) — BUT sends had landed: total **$37.62** (≈16 stacks: 1337×0.8^16).
6. Checkout at $37.62 → 303 `/cart/order-confirmation?order-confirmed=true` → GET confirmation → `Congratulations, you solved the lab!` + `is-solved`, charged $37.62, credit $50→$12.38.

## What Failed

- Sequential + naive-threaded coupon bursts (atomicity holds at low concurrency; 2–3 stack ceiling over 6 remove/repeat rounds).
- H2 harness v1 drain deadlock (barrier placed after fallible sends; fixed conceptually by removing the barrier — h2 single-connection sends are already back-to-back under one lock).

## What Worked

Warmed… (no warming needed for h2): fresh csrf → 40 multiplexed POSTs → ~16× stacking → $37.62 → checkout → confirmation visit → solved. Total: ~10 requests mapping + bursts + checkout/confirm.

## Burp Observations

Not used (Burp MCP flaky on adjacent hosts; raw sockets + curl + python-h2 sufficed). Burp Repeater parallel groups / Turbo Intruder are the GUI equivalents of the h2 burst.

## Browser Observations

Homepage/account mapping only.

## CLI / Tool Observations

- curl + cookie jars per phase; manual redirect handling; csrf re-read per round (remove/apply forms carry distinct tokens).
- Python threads + raw TLS for HTTP/1.1 bursts; python-h2 (available locally) for the multiplexed burst.

## Root Cause

Coupon application performs check ("already applied?") then set (append discount + DB update) without atomicity or session locking. Concurrent requests interleave inside the window: each sees unused, each appends. Discounts compound multiplicatively per win (0.8^n), so ~15 wins take $1337 → <$50. HTTP/2 multiplexing collapses arrival spread so ~16/40 land inside.

## Verification

- Arithmetic proof: $684.54 = 1337×0.8³ and $37.62 ≈ 1337×0.8^16 — totals match integer stack counts, not noise.
- State proof: charged $37.62, credit delta $50→$12.38, order line (jacket ×1), `is-solved` marker on re-read homepage + confirmation page. No-coupon control ($1337) and single-coupon control ($1069.60) bracket the raced result.

## Impact

Purchase arbitrary-priced items for pennies of credit (demonstrated: $1337 → $37.62); same primitive overruns any count-limited benefit.

## Why The Successful Approach Worked

Removed the two scarcities separately: (1) logical — reset to pristine each round so the check passes; (2) physical — multiplexed transport so enough requests share the window. Either alone capped at 2–3 stacks.

## Generalization

Where a counted benefit (coupon uses, credits, votes, stock) is check-then-set per session: pristine-reset per round; escalate concurrency shape (threads → barrier → h2 multiplex) until stack count moves; use the resulting total's closed-form (here 0.8^n) to compute required wins and confirm wins from evidence, not vibes.

## Lessons Learned

- Sequential idempotence proves nothing about concurrency — the race window only exists under parallel load; test it loaded.
- H1-thread bursts have a throughput ceiling (here 3/40); h2 multiplexing on one connection broke it (~16/40). Match transport concurrency to the suspected window.
- Totals with closed forms (0.8^n) turn a noisy oracle into an exact win-counter.
- Checkout is two-step here (303 → confirmation GET finalizes); 302/303 alone is never proof — re-read marker + credit delta.

## Related Methodology

- methodology/race-conditions.md (FIRST real content from this lab — stub filled below)
- methodology/business-logic.md (coupon/state reasoning precedents)
- methodology/verification.md (arithmetic + state re-read proof)
- methodology/injection.md — compared, NOT applicable (no interpreter, no data/logic-boundary break; no touch)

## References

- Lab description: https://portswigger.net/web-security/race-conditions/lab-race-conditions-limit-overrun
