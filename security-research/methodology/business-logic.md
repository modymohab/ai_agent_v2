# Business Logic Methodology

## Core Concept

Business-logic flaws abuse legitimate workflows with attacker-chosen values the server fails to re-validate — e.g. a shop that accepts the unit price from the client's add-to-cart form instead of looking it up server-side. No injection, no auth bypass: the workflow itself is mispriced.

A second variant assumes an immutable cart across a multi-step purchase: checkout-POST validates funds for the current cart, but the confirmation-GET finalizes WHATEVER is in the cart then — mutate between the steps and the expensive order completes at no (additional) charge.

A third variant enforces a rule on one writer but not its parallel: registration verifies mailbox proof (token link) before an address and its domain role take effect, while profile email-change applies a privileged-domain address AND role immediately with no verification.

A fourth variant under-validates a dual-use endpoint: a password change that serves self-service and arbitrary targets checks `current-password` only when the field is PRESENT — omitting it resets anyone's password (weak isolation between “change own” and “reset another's”).

A fifth variant validates only the ORDER TOTAL's sign while trusting line-item quantities: negative quantities are stored and priced, so a mixed cart (target item + N negative lines) engineers a small affordable positive total that a negative-total-only guard permits.

A sixth variant enforces coupon duplicate-use by adjacent comparison only: submitting the same code twice in a row is rejected, but ALTERNATING two codes (A,B,A,B…) re-applies every discount each cycle, stacking without bound down to the order floor.

A seventh variant holds the cart total in a 32-bit signed integer (cents) with per-request quantity caps but no cumulative cap: repeated max-quantity adds overflow past 2,147,483,647 → wrap to large negative → climb back and fine-tune with a cheap item into ($0, credit].

An eighth variant parses registration emails with discrepant libraries: validation rejects exotic encodings it recognizes (iso-8859-1/utf-8 Q-encoding) but misses UTF-7 encoded-words, while delivery decodes them — `=?utf-7?q?attacker&AEA-<attacker-host>&ACA-?=@<privileged-domain>` passes the domain gate via its trailing suffix yet routes to the attacker, yielding a privileged account from an unauthorized mailbox.

A ninth variant truncates overlong input inconsistently across layers: validation and mail delivery operate on the FULL address while storage cuts at 255 chars — crafting `<238-char prefix>@<privileged-domain>.<routable-suffix>` with the privileged suffix ending EXACTLY at char 255 yields delivery to the attacker plus a stored privileged identity (verify cut arithmetic programmatically before sending).

A tenth variant defaults staged-login roles to administrator and only downgrades on visiting the role step: DROPPING the intermediate request (never fetching it — clients auto-follow redirects, so suppression/drop is mandatory) preserves the privileged default with zero exploit payload.

An eleventh variant composes two sound mechanisms unsoundly: per-order coupon discounts apply to gift-card purchases while redemption credits full face value — each discounted buy-redeem cycle nets positive (30%-off $10 card → +$3), compounding with bulk quantities (~+40%/cycle) to arbitrary balances.

## Security Boundary

Intended: money-moving values (price, quantity, total, discount) are server-determined.
Violated when: client-submitted `price` (or equivalent) flows into cart totals and charged orders unchecked.

## Recognition Patterns

- Purchase forms carrying `price`/`total`/`discount` hidden fields (often in minor units, e.g. `price=133700` cents).
- Displayed balances/credits that frame affordability (`Store credit: $100.00` vs item `$1337.00`).
- Checkout guarded by correct controls (CSRF, login) while PRICING is not — verify each control independently.
- Stepwise purchase (cart → checkout-POST → confirmation-GET) where each step trusts prior-step state: checkout validates funds for cart-at-that-moment, confirmation finalizes cart-at-replay-time.
- Privileged-domain hints (`use your @… address`): role-implying attributes writable by MULTIPLE endpoints (register vs profile-update) with different verification.
- Account forms with EDITABLE identity fields (`username` pre-filled but not hidden/fixed): dual-use tell — the endpoint may act on any named target.
- Quantity fields with client-side-only bounds (`min=0`, no max): negative/mixed-quantity tell — test negative lines AND mixed-sign compositions against total-sign guards.

## Common Locations

- `POST /cart` (add/update: `productId`, `quantity`, `price`, `redir`).
- `GET /cart` (cart state oracle: line price, total, credit).
- `POST /cart/checkout` (+ csrf) and order-confirmation pages (charged-total oracle).

## Indicators

- Same-session cart delta: submitted `price=133700`→`100` renders line `$1.00` / Total `$1.00` — server stored attacker value.
- Charged total on confirmation (`Total: $1.00`) plus balance decrement (`$100→$99`) — financial effect, not UI echo.
- `is-solved` after manipulated purchase.

## Testing Methodology

1. Map the money flow: product page → add-to-cart params → cart state → checkout params → confirmation.
2. Read every form for money-moving fields; change exactly ONE (`price` only), round small value for clean oracle.
3. Verify trust via cart STATE before touching auth/checkout complexity.
4. Complete the workflow legitimately otherwise (preserve csrf+session binding; log in if required) so the solved state is attributable solely to the value trust.
5. Document EXPECTED STATE → TEST ACTION → ACTUAL STATE with amounts.
6. Sequencing extension: baseline-cheap E2E first (record WHERE the charge lands — POST vs confirmation visit — via balance delta), then mutate cart (add expensive item), then replay the finalizing GET. Charge-point mapping precedes the attack.
7. Parallel-writer extension: for every validated write path (register/update/reset/invite), submit identical hostile input (privileged domain, role flag) to EACH writer. Verified-vs-applied divergence = the flaw; exploit the weaker writer; confirm via role UI + solved marker.
8. Dual-use extension: where one endpoint serves self + others (editable `username` target), matrix the guard field three ways — correct value, wrong value, ABSENT. Absent-skips-check (`incorrect` vs `successfully!`) = the flaw; prove on low-value victim, then apply to highest-value target (administrator), verifying each login (302 + identity page).
9. Mixed-sign extension: where quantities lack server-side lower bounds, test negative lines first (cart-state proof), then negative-only checkout (maps the guard: `NEGATIVE_TOTAL`-style blocks), then engineer a mixed cart (target + N negatives) to a small positive total by arithmetic BEFORE acting. Guard-rejection messages specify the rule being enforced — design around the stated semantics.
10. Coupon-alternation extension: where same-code-twice is rejected, test A,B,A,B cycling with two distinct codes (second code often comes from a newsletter/signup surface — map it, never guess). Log the total per application: monotonic descent proves stacking; plateau proves enforcement. Stack to the floor, then complete the order.
11. Integer-overflow extension: where per-request quantities are capped (e.g. 99) but cumulative totals are not, add max-quantity repeatedly single-threaded with milestone total reads — a sudden large-negative flip past ~$21.47M proves 32-bit wrap. Then compute the top-up on paper (cheap-item units to land in ($0, credit]) instead of trial-and-error; persist sessions to files for timeout-proof multi-batch runs.
12. Encoded-word extension: where registration enforces a privileged domain, first map BOTH gates (format messages vs domain messages) with plain probes (multi-`@`, sub/affix/case variants). Then climb the encoding ladder: iso-8859-1 Q → utf-8 Q (expect rejections that confirm detection) → UTF-7 (`&AEA-`=@, `&ACA-`=space) exploit `=?utf-7?q?attacker&AEA-<host>&ACA-?=@<domain>`. Email arrival with a token proves the delivery-side parse; activation + role proves the validation-side parse.
13. Truncation-split extension: where overlong input is accepted, sweep lengths (120→300+) with inbox observation (not just accept/reject). If overlong privileged-domain addresses vanish into the void, test the split: `<prefix>@<privileged-domain>.<routable-suffix>` with the privileged suffix ending EXACTLY at the truncation boundary (verify char arithmetic in code first). Token arrival proves full-length delivery; privileged role proves truncated storage.
14. Step-omission extension: in staged logins, test DROPPING each intermediate request entirely (redirect-following DISABLED — default clients/browsers silently execute the "skipped" step and falsify true theories; use NoRedirect/drop). Compare pre-step vs post-step defaults: admin-by-default machines grant privilege precisely when the downgrade step never runs. Falsify values (`administrator` → homepage) and skips (→login) first so omission is adjudicated, not assumed.
15. Gift-arbitrage extension: where store-credit instruments (gift cards) coexist with discounts, test the full loop — buy discounted, redeem at face, measure NET per cycle. If positive, scale with bulk quantities sized from current balance (coupon fresh per order; harvest codes via inbox diffs) until the target is affordable. Single-use enforcement on each half does not imply compositional soundness.

## Verification

- Prove with charged total + balance delta + solved marker — never form echo alone.
- Confirm surrounding controls (CSRF, login) enforced, to isolate the flaw to value trust.
- Reproduce the cart delta on a fresh session before checkout where feasible.

## Common Failure Modes

- Testing price AND quantity AND coupon at once — cannot attribute the total change.
- Breaking csrf/session binding across cart→login→checkout — false checkout failures blamed on pricing.
- Claiming impact from cart display without completing checkout (no financial effect, no solved marker).

## Impact Considerations

- Arbitrary price setting → revenue loss at scale; extends to quantity/coupon/currency/shipping parameters.
- Impact is demonstrated only via completed order with charged total outside the affordability boundary.

## Lessons Learned

- From PortSwigger “Excessive trust in client-side controls”: `POST /cart` stored `price=100` for the $1337 jacket; checkout charged Total `$1.00` (credit `$100→$99`) → `is-solved`. CSRF + login correctly enforced around the flaw.
- From PortSwigger “Insufficient workflow validation”: no price field (server-side pricing), quantities capped, funds checked — but confirmation-GET finalizes current cart: cheap baseline (charge $1.80 at confirmation visit) → add jacket → replay confirmation → $1337 order, $0 additional charge, `is-solved`. Take redirect targets from live responses (instance `order-confirmed=true` differed from writeup text).
- From PortSwigger “Inconsistent security controls”: registration requires mailbox token before address/role effect (unverified address → login fails), but `POST /my-account/change-email` to `@dontwannacry.com` applies immediately with no verification AND grants Admin panel → delete carlos → `is-solved`. Prove with paired same-input/different-endpoint evidence.
- From PortSwigger “Weak isolation on dual-use endpoint”: change-password with editable `username`; `current-password` wrong → `incorrect`, DROPPED → `Password changed successfully!` for `carlos` then `administrator` → logins (302 + identity) → `/admin` 200 → delete carlos → `is-solved`. Matrix guard presence, not just values.
- From PortSwigger “High-level logic vulnerability”: no price field (server pricing), negative `quantity=-1` stored (`-$63.27` line), negative-only checkout blocked (`NEGATIVE_TOTAL`), no coupon anywhere reachable — mixed cart (jacket ×1 + product2 ×−21, computed on paper) → Total `$8.33` → legitimate checkout → charged `$8.33`, credit `$100→$91.67`, `is-solved`. Rejected guards design the bypass; arithmetic precedes action.
- From PortSwigger “Flawed enforcement of business rules”: `NEWCUST5` (-$5, single-use holds on re-apply), negatives silently ignored, replay 400, funds verified, coupon moves no credit — newsletter signup yields `SIGNUP30`; alternating the two stacks discounts (`$1332→$930.90→…→$0.00`) → free jacket order, credit untouched, `is-solved`. Same-code-twice rejection proves adjacent comparison; per-application total logging proves stacking.
- From PortSwigger “Low-level logic flaw”: quantities 1–99 only (decimals/strings/100+ → 400, negatives ignored) — repeated 99-jacket adds overflow 32-bit cents at ~$21.47M → wrap to −$21M → 324×99 + 47 jackets + computed 1045×$1.17 top-up → `$0.69` charge, credit `$100→$99.31`, `is-solved`. Landmark (−$1,221.96) predicted by own arithmetic before observing; file-backed sessions survive aborts.
- From PortSwigger “Bypassing access controls using email address parsing discrepancies”: exact-domain + format gates mapped (multi-`@`/sub/affix rejected, unverified login blocked, no catch-all sink) — UTF-7 `=?utf-7?q?attacker&AEA-<host>&ACA-?=@ginandjuice.shop` → verification email arrives → activate → privileged Admin link → delete carlos → `is-solved`. Gate-mapping precedes the ladder; email arrival proves delivery parse.
- From PortSwigger “Inconsistent handling of exceptional input”: separators/duplicates/encodings mapped (duplicates deliver iff LAST=routable but store non-privileged; encoded forms accepted with zero mail) — 238+17@cut truncation address → token arrives → privileged account → delete carlos → `is-solved`. Cut arithmetic verified programmatically; split identity proven by delivery + role.
- From PortSwigger “Authentication bypass via flawed state machine”: unlisted role → homepage (values enforced), skip/anon → login-bounce/400 — but DROPPING `GET /role-selector` (redirects disabled; auto-follow caused one false negative) → default administrator → delete carlos → `is-solved`. Omission is a third axis beyond values and order.
- From PortSwigger “Infinite money logic flaw”: redemption repeat/race/case all correctly enforced — but 30%-off gift-card purchase ($7) + full-face redemption (+$10) nets +$3/cycle; bulk scaling ($103→$1438 in 8 cycles, ~+40%/cycle) → jacket purchase → `is-solved`. Test cross-mechanism composition, not just each half.

## Related Concepts

- Client-side control trust (price/total/discount parameters)
- Workflow sequencing (immutable-cart assumption, charge-point mapping, replay of finalizing steps)
- Inconsistent parallel validation (register vs update, create vs edit — same rule, different enforcement)
- Dual-use endpoints (self vs other targets; present-vs-absent guard validation)
- methodology/verification.md (EXPECTED→ACTION→ACTUAL + state proof)

## Sources

- PortSwigger lab: Excessive trust in client-side controls (knowledge/portswigger/labs/business-logic-excessive-trust-client-side-controls.md)
- PortSwigger lab: Insufficient workflow validation (knowledge/portswigger/labs/business-logic-insufficient-workflow-validation.md)
- PortSwigger lab: Inconsistent security controls (knowledge/portswigger/labs/business-logic-inconsistent-security-controls.md)
- PortSwigger lab: Weak isolation on dual-use endpoint (knowledge/portswigger/labs/business-logic-weak-isolation-dual-use.md)
- PortSwigger lab: High-level logic vulnerability (knowledge/portswigger/labs/business-logic-high-level-logic-vulnerability.md)
- PortSwigger lab: Flawed enforcement of business rules (knowledge/portswigger/labs/business-logic-flawed-enforcement-of-business-rules.md)
- PortSwigger lab: Low-level logic flaw (knowledge/portswigger/labs/business-logic-low-level-logic-flaw.md)
- PortSwigger lab: Bypassing access controls using email address parsing discrepancies (knowledge/portswigger/labs/business-logic-email-parsing-discrepancies.md)
- PortSwigger lab: Inconsistent handling of exceptional input (knowledge/portswigger/labs/business-logic-inconsistent-handling-exceptional-input.md)
- PortSwigger lab: Authentication bypass via flawed state machine (knowledge/portswigger/labs/business-logic-auth-bypass-flawed-state-machine.md)
- PortSwigger lab: Infinite money logic flaw (knowledge/portswigger/labs/business-logic-infinite-money-logic-flaw.md)
