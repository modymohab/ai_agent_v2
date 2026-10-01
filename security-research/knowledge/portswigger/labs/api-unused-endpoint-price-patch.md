# PortSwigger Lab

## Lab

Finding and exploiting an unused API endpoint

URL: https://0add003703bf09c18360e64200170059.web-security-academy.net

## Vulnerability Class

API security — undocumented state-changing endpoint (PATCH price) without authorization, enabling global price manipulation → free purchase

## Objective

Buy the $1337.00 jacket with $0.00 store credit (inferred from economics + solved state; official description not read).

## Initial Observations

- Shop; product form has NO price field (server-side pricing per line at add time — cart lines snapshot the price).
- `wiener` credit is `$0.00` here (differs from other labs — read fresh, not assumed).
- JS `/resources/js/api/productPrice.js` calls `GET /api/products/<id>/price` → `{"price":"$1337.00","message":…}` — documented read endpoint.
- Method probe on `/api/products/1/price`: GET→200, POST/PUT/DELETE→405, **PATCH→401** (handled but auth-gated — the anomaly).

## Hypotheses

- H1: An undocumented PATCH handler mutates the product price; auth = any login (no role check).
- H2: Mutated global price flows into cart lines added afterwards → checkout affordable → solved.
- H3: Cart lines snapshot at add time (stale after re-price) — remove + re-add picks up new price.

## Attempts

1. `GET /api/products/1/price` anon → 200 JSON. Baseline read shape.
2. Method matrix (POST/PUT/PATCH/DELETE) → 405/405/401/405. PATCH singled out — H1 source.
3. Login `wiener:peter` (302, verified) → `PATCH {"price": 100}` → 200 `{"price":"$1.00"}`; `GET` confirms global `$1.00`. WORKED (auth, no privilege required).
4. Add jacket → cart `$1.00`/Total `$1.00`; checkout on $0 credit → 303 `/cart?err=INSUFFICIENT_FUNDS`. Correct control — price must go to $0 (also: a wrong-URL run against the previous lab's host failed silently; redone on the right instance before concluding anything).
5. `PATCH {"price": 0}` → `$0.00`; cart still `$1.00` (snapshot confirmed — H3). Remove + re-add → `$0.00`/Total `$0.00`.
6. Checkout (session csrf) → 303 confirmation; visit → `Your order is on its way!`, Total `$0.00`; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- $1.00 checkout on $0 credit (INSUFFICIENT_FUNDS) — funds check correctly enforced; forced the $0 step (also proved the check exists, bounding the flaw to pricing).
- One misfired run against the previous lab's hostname (no files created, caught by missing-output check) — verify host per command in multi-lab sessions.

## What Worked

- JS discovery → method matrix → authed PATCH price to $0 → remove/re-add (snapshot refresh) → legitimate checkout → solved.

## Burp Observations

- Not used via Burp MCP; curl + JSON sufficed. Repeater equivalent for PATCH.

## Browser Observations

- Not required. No JS-driven flow beyond the static price fetch.

## CLI / Tool Observations

- curl with `-X PATCH -H Content-Type: application/json`; repo wordlist `wordlists/api/api-endpoints.txt` available but unneeded (JS gave the endpoint directly — smallest tool first).
- Cart HTML as price/total/credit oracle at each step.

## Root Cause

The price API exposes an undocumented `PATCH /api/products/<id>/price` mutation guarded only by authentication (any logged-in user, no admin role). It rewrites the GLOBAL catalog price, which cart lines snapshot at add time and checkout charges without further validation. Attacker zeroes the jacket, re-adds at $0, checks out on $0 credit.

## Verification

- Method differential (405×3 vs 401) isolated PATCH pre-auth; authed PATCH 200 + GET-confirm proved mutation.
- Single-variable economics: $1337 → $1.00 (INSUFFICIENT on $0) → $0.00 (checkout 303 + confirmation + `is-solved`); cart snapshot behavior confirmed by stale-$1.00 then refreshed-$0.00.
- End-state: confirmation `Your order is on its way!` Total `$0.00` + solved marker. Deterministic.

## Impact

Any authenticated user reprices ANY product globally (demonstrated $1337→$0) and purchases at will — revenue loss + catalog integrity compromise for all users.

## Why The Successful Approach Worked

- JS-first discovery (exact endpoint + shape) beat wordlist brute-force.
- The 405-vs-401 method differential named the hidden mutation without guessing paths.
- Snapshot awareness (remove/re-add) handled the stale cart line instead of misreading it as a failed PATCH.

## Generalization

- For API-augmented shops: harvest JS (`productPrice.js`-style) for endpoint shapes, then matrix HTTP methods per endpoint — 405-vs-401/403 splits reveal hidden mutations.
- Undocumented mutations need only authentication here — always test low-priv, not just anon-vs-admin.
- Price mutations are global + cart lines snapshot: verify via GET re-read AND fresh add; stale lines require remove/re-add.
- Funds/credit checks may be correctly enforced around the flaw — measure the boundary (here $0 credit forced price→$0, not just cheap).

## Lessons Learned

- 405 “Method Not Allowed” vs 401 “Unauthorized” on the same path is a first-class discovery oracle for unused endpoints.
- Multi-lab sessions: assert the hostname per command (one misfire caught by output check, no harm).
- First API lab: api-security reference (map endpoints/methods/IDs, 200≠vuln) transfers directly; wordlists are fallback, not opener.

## Related Methodology

- methodology/api-security.md (undocumented endpoint discovery + method differential — to be created from stub)

## References

- Solved instance: https://0add003703bf09c18360e64200170059.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
