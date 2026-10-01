# Race Conditions Methodology

## Core Concept

Race conditions fail when a counted benefit or limit is enforced check-then-set without atomicity or session locking: concurrent requests interleave inside the window between the check ("already applied?") and the set (DB update), so N parallel requests each observe the unused state and each applies. Demonstrated shape: single-use 20% coupon (sequential re-application idempotent) stacked ~16× under a multiplexed burst, compounding 0.8^n ($1337 → $37.62).

## Security Boundary

Intended: limited benefits apply at most their stated count regardless of request concurrency.
Violated when: N simultaneous applications each pass the limit check before any commits, overrunning the limit (discounts, credits, votes, stock).

## Recognition Patterns
- Sequential duplicate use rejected with an explicit message (`Coupon already applied`) while totals/prices suggest a counted benefit worth stacking.
- Cart/coupon/balance flows with separate check and commit endpoints/steps (`/cart/coupon` apply vs DB update).
- Session-keyed server-side cart state (empty cart without session cookie) — per-session windows, no cross-user interference needed.
- Totals with closed forms (e.g. compounding 0.8^n) that turn noisy oracles into exact win-counters.
- Login rate limiting with per-username scope: 3 failures → timed lock message with live countdown (`try again in N seconds`), while other usernames still get normal `Invalid` — counter keyed on identity, incremented after the check.
- Single request/response checkout with live-cart snapshot: affordable cart validates, but a concurrent cart mutation lands in the confirmed order (no second funds check — overdraft confirmation). Gift-card buy/redeem loops fund probing at net zero.
- Single endpoint with split-phase side effects: message-send task addressed from request input while the template renders from a later DB re-read of single-slot state (email change) — a parallel swap mid-window misdirects the token (To: attacker, body: victim).

## Common Locations

- Coupon/discount application (`POST /cart/coupon`), removal (`/cart/coupon/remove` for pristine-reset per round).
- Checkout + confirmation pairs (`POST /cart/checkout` → 303 → `GET .../order-confirmation?...` finalizes — the GET is part of the transaction).
- Any redeem/apply/vote endpoint paired with a balance/usage display.

## Indicators

- Naive threaded bursts move the needle slightly but plateau (here: 2–3 stacks over 6 rounds) — window proven, throughput insufficient.
- HTTP/1.1 thread bursts cap wins; HTTP/2 multiplexed bursts on one connection multiply them (~16/40) — transport shape is a first-class variable.
- Totals matching integer stack counts (e.g. $684.54 = 1337×0.8³) prove real wins vs noise.

## Testing Methodology

1. Map the benefit and its stated limit; establish baselines: no-benefit total, single-benefit total, duplicate-use rejection message.
2. Reset to pristine (remove benefit, empty cart) — bursts from applied state add nothing (check fails fast).
3. Escalate concurrency shape stepwise: sequential (expect idempotent) → threaded bursts (expect small wins) → barrier-fired raw sockets → HTTP/2 multiplexed streams on one connection. Read the total after each shape.
4. Compute required wins from the closed form (e.g. 0.8^n × price < credit) and compare observed totals to integer win counts.
5. Remove-and-repeat rounds per the lab's guidance when wins plateau below target; re-read csrf per round (forms rotate tokens).
6. Spend the stacked state promptly (checkout + confirmation GET); verify via marker + balance delta, not redirect status.
7. Rate-limit-gate extension: map the limit first (strike count, lock message, countdown = timer-based reset), prove per-username scoping with a cross-identity probe, then single-packet the ENTIRE candidate space on one HTTP/2 connection (atomic stream-ID allocation under the send lock; shared session csrf suffices). Adjudicate by status only (exactly one 302); expect the burst to trip the lock afterward — wait it out fully, then login cleanly with the found credential.
8. Multi-endpoint extension: where validation and effect live on different endpoints sharing mutable state (cart vs checkout), eliminate single-endpoint racing first (multiplexed burst proving atomicity), then fire mutation + commit as one multiplexed pair on a single h2 connection — commit stream first, mutation stream immediately after. Read the COMMIT response body (not status) for mutated content; sustain probe funds via stored-value buy/redeem loops; reset cart via delta ops (`quantity=-N`, never absolute 0).
9. Single-endpoint split-phase extension: where one endpoint both triggers a message and renders it from re-read single-slot state, pair self-address + victim-value concurrently behind a barrier (2 threads suffice); adjudicate on recipient/body mismatch in the attacker-visible channel (inbox); click the mismatched token promptly.

## Verification

- Arithmetic proof (observed total == closed-form prediction for integer n) plus state proof (charge amount, balance delta, order line, solved marker).
- No-benefit and single-benefit controls must bracket the raced result.
- 302/303 alone is never proof — the confirmation/finalization request and re-read decide.

## Common Failure Modes

- Testing only from applied state (bursts add nothing — always reset per round).
- HTTP/1.1-only concurrency (TLS/handshake jitter caps wins; multiplex instead).
- Stale csrf across rounds (rotate per round; remove/apply forms differ).
- Treating redirect-after-checkout as completion (confirmation GET finalizes).
- Harness deadlocks (barriers placed after fallible sends — synchronize dispatch, not completion).

## Impact Considerations

- Arbitrary-price purchases for pennies of credit (demonstrated $1337 → $37.62); generalizes to any count-limited benefit (credits, votes, stock reservations).

## Lessons Learned

- From PortSwigger “Limit overrun race conditions”: pristine-reset + h2-multiplexed 40× coupon burst → ~16 stacks → $37.62 → checkout → confirmation → `is-solved`, credit $50→$12.38. Sequential/threaded capped at 2–3 stacks over 6 rounds; closed-form totals as win-counter.
- From PortSwigger “Multi-endpoint race conditions”: redeem×redeem proven atomic (single 302 under h2-20) → paired h2 firing [checkout + add-jacket] from $10-card cart → validation saw $10, snapshot took jacket+card → $1347 order confirmed → `is-solved`, credit $100→-$1247.00 (overdraft). Commit-body proof; delta-quantity cart ops; gift buy/redeem sustains probes.
- From PortSwigger “Single-endpoint race conditions”: barrier-paired email changes [own + carlos@ginandjuice.shop] → inbox email To: own with body naming victim + live token → click → victim address + admin link → delete carlos → `is-solved`. Two threads suffice; recipient/body mismatch is the oracle.
- From PortSwigger “Bypassing rate limits via race conditions”: per-username 3-strike/60s lock (live countdown) → h2 single-packet burst over 30 candidate passwords → exactly one 302 (`qwerty`) → wait out lock → normal login → `carlos` identity → `/admin` → delete carlos → `is-solved`. Stream IDs atomic under send lock; header keys arrive as bytes; shared csrf suffices for the gate.

## Related Concepts

- methodology/business-logic.md (coupon/state/quantity reasoning)
- methodology/verification.md (arithmetic + state re-read proof)
- methodology/file-security.md step 11 (TOCTOU file race — sibling race shape, millisecond windows, parallelism mandatory)

## Sources

- PortSwigger lab: Limit overrun race conditions (knowledge/portswigger/labs/race-conditions-limit-overrun.md)
- PortSwigger lab: Bypassing rate limits via race conditions (knowledge/portswigger/labs/race-conditions-bypassing-rate-limits.md)
- PortSwigger lab: Multi-endpoint race conditions (knowledge/portswigger/labs/race-conditions-multi-endpoint.md)
- PortSwigger lab: Single-endpoint race conditions (knowledge/portswigger/labs/race-conditions-single-endpoint.md)
