# PortSwigger Lab

## Lab

Excessive trust in client-side controls

URL: https://0a9000ab04867138831f8d2800250070.web-security-academy.net

## Vulnerability Class

Business logic — price tampering via client-side-controlled unit price (cents)

## Objective

Purchase the $1337.00 “l33t” Leather Jacket with $100.00 store credit (inferred from shop economics + solved state; official description not read).

## Initial Observations

- Shop + cart (`/cart`) + checkout (`/cart/checkout`); jacket `productId=1`, $1337.00; account store credit $100.00 (visible post-login) — EXPECTED: jacket unaffordable.
- Product page form `POST /cart` carries `productId=1`, `quantity=1`, `redir=PRODUCT`, and **`price=133700` hidden field** (cents) — client-controlled pricing signal (H1 source, not proof).

## Hypotheses

- H1: Server trusts the submitted `price` instead of looking it up → cart total follows attacker value.
- H2: Checkout charges the cart total (no server-side re-price) → manipulated order completes within $100 credit.
- H3: Order confirmation + `is-solved` follow a completed manipulated purchase.

## Attempts

1. `POST /cart productId=1&quantity=1&price=100&redir=PRODUCT` (anon session) → 302; `GET /cart` → jacket `$1.00`, Total `$1.00`. H1 confirmed — server stored attacker price.
2. `POST /cart/checkout` without csrf → 400 `Missing parameter 'csrf'`; with cart-page csrf but anon → 303 `/cart?err=NOT_LOGGED_IN`. Checkout requires session+CSRF AND login — recorded, not bypassed.
3. `POST /login` with cart-page csrf (same session jar) `wiener:peter` → 302 `/my-account?id=wiener`. WORKED (standard seeded account re-verified, not assumed).
4. `POST /cart/checkout` with fresh cart csrf, authed → 303 `/cart/order-confirmation?order-confirmed=true`; confirmation page: `Your order is on its way!`, jacket `$1337.00 × 1`, **Total: $1.00**, credit `$100→$99`; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- CSRF-less checkout (400) and anon checkout (NOT_LOGGED_IN redirect) — correct controls; the flaw is pricing only, so these were scope confirmations, not bypass attempts.

## What Worked

- Single tampered add-to-cart (`price=133700` → `100`) + legitimate login + legitimate checkout → $1337 jacket for $1.00 → solved.

## Burp Observations

- Not used via Burp MCP; curl form posts + cart-state reads sufficed. Repeater equivalent for price tampering.

## Browser Observations

- Not required. No JS/cart-state logic beyond plain forms.

## CLI / Tool Observations

- curl with session jar (csrf+session binding preserved across cart→login→checkout); cart HTML as state oracle (unit price, total, credit balance).

## Root Cause

Unit price is accepted from the client: `POST /cart` stores the submitted `price` (cents) per line item, and checkout charges the resulting cart total without server-side re-pricing against the product catalog. Attacker sets any price (here $1.00 for a $1337 item) and checks out normally within store credit.

## Verification

- EXPECTED ($1337.00, unaffordable on $100) → ACTION (`price=100`) → ACTUAL (cart `$1.00`, total `$1.00`) — single-variable delta on the same session.
- End-state proof: confirmation page `Your order is on its way!` + charged Total `$1.00` + credit decrement `$100→$99` + `/` `is-solved`. Server-side financial effect, not UI text.
- Controls around the flaw (CSRF, login) verified enforced — impact isolated to pricing trust.

## Impact

Arbitrary price reduction on any purchasable item (demonstrated 1337:1); direct revenue loss, inventory depletion at attacker-chosen prices. Same class extends to quantity (negative/oversize), coupon, and total parameters.

## Why The Successful Approach Worked

- Read the form before testing it: the hidden `price` field named the exact client-controlled variable.
- Verified trust via cart STATE (not form echo) before involving checkout/login complexity.
- Kept one variable changed (`price` only); reused legitimate auth/checkout so the solved state is attributable solely to pricing trust.

## Generalization

- In shops, map every money-moving parameter (price, quantity, total, discount, coupon, currency, shipping) to client/server origin; hidden `price`/`total` fields are first-class test points.
- EXPECTED→ACTION→ACTUAL on cart totals; prove with charged total + balance delta + solved marker.
- Auth/CSRF around checkout are separate checks — verify them as enforced, then focus the hypothesis on pricing state.

## Lessons Learned

- Price in cents (`133700`) invites integer tampering (`100`); always test round small values first for clean oracle reads.
- Store credit display (`$100.00`) defines the affordability boundary — it frames the impact measurement (`$99.00` remainder).
- First business-logic lab: no authN/authZ payloads applied; workflow-sequencing discipline (cart→login→checkout order preserved) kept the test valid.

## Related Methodology

- methodology/business-logic.md (client-side price trust — to be created from stub)

## References

- Solved instance: https://0a9000ab04867138831f8d2800250070.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
