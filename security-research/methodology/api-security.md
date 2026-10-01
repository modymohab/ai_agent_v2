# API Security Methodology

## Core Concept

APIs fail when undocumented state-changing endpoints ship without authorization — e.g. a read-only price API (`GET /api/products/<id>/price`) that also honors `PATCH {"price": N}` for any authenticated user, rewriting the GLOBAL catalog price that shop carts snapshot and checkout charges.

APIs also fail when MACHINE-READABLE DOCUMENTATION is exposed and advertises sensitive operations that lack authorization — e.g. an OpenAPI document at a predictable path (`/api/openapi.json`) describing `DELETE /api/user/{username}`, callable by any authenticated session to delete arbitrary users.

## Security Boundary

Intended: price mutations (if any) require an admin role; carts charge catalog truth.
Violated when: low-priv `PATCH` rewrites global price → fresh cart lines take attacker price → checkout completes.

## Recognition Patterns

- Client JS revealing API shapes (`/resources/js/api/productPrice.js` → `/api/products/<id>/price`).
- Exposed machine-readable docs at predictable paths (`/api/openapi.json` 200/2096B vs 404/11B siblings) — contract first, no guessing.
- Server-side query assembly from user input: injected `&<name>=` splits into validated params — unknown names error (`Parameter is not supported`) while `username` duplicates pass; `#` truncates server-appended suffix (`Field not specified`); bare `{"error":...}` (no type/code) fingerprints the internal API vs typed outer errors.
- Server-side REST path assembly: `..` normalizes before route matching (`A/../B` ≡ B); error shapes separate layers (`Invalid route` JSON = API router, HTML proxy = underlying web server escaped at ≥4 `..`); single-decode only (`%2F` active, `%2e` inert, backslash literal).
- Method differential on one path: GET→200, POST/PUT/DELETE→405, but PATCH→401 — handled-but-gated = hidden mutation.
- Global effect: GET re-read shows the mutated value; per-user sessions share it.

## Common Locations

- `/api/products/<id>/price` (GET read + PATCH write), sibling `/api/*` resources.
- Predictable documentation paths (`/api/openapi.json`, `/api/docs`, `/swagger*`, `/redoc`, `/docs`, `/v2/api-docs`); `servers: ./` in the doc anchors the base to the doc's own mount — resolve relative.
- Repo fallback: `wordlists/api/api-endpoints.txt` (295 entries) — only if JS/crawl yields nothing.
- Shop flow endpoints that consume API state: `POST /cart` (snapshot), `POST /cart/checkout` (charge).

## Indicators

- 405×N vs 401/403×1 method split on one endpoint (mutation exists, auth-gated).
- Authed low-priv mutation → 200 + GET re-read confirms global change.
- Documented sensitive operation callable low-priv (DELETE → 200 `User deleted`) with victim-absent re-read (GET → 404) + solved marker.
- Fresh cart lines take the mutated price; checkout + confirmation + `is-solved`.

## Testing Methodology

1. Harvest API shapes from JS/crawling first (exact paths + JSON shapes); wordlists only as fallback.
2. Sweep documentation paths early when the theme names docs (fixed candidates; code+size oracles); read the contract (`python -m json.tool`) for paths/methods/params before any state-changing call.
3. Read page-specific JS (not just homepage) for internal endpoint/param contracts before brute-forcing values.
4. Matrix HTTP methods per endpoint (GET/POST/PUT/PATCH/DELETE); read 405-vs-401/403 splits as discovery oracles.
5. Test candidate mutations as LOW-PRIV (not just anon-vs-admin); confirm via read-back (global?) and via consuming flow (fresh cart add, not stale lines — remove/re-add on snapshot).
6. For SSPP query strings: map the parser (`&unknown=` allowlist, `#`/truncation, `field`-selector combinations), read page JS for internal param names, then request a sensitive field (`reset_token`) with truncation of the server suffix; use the disclosed value directly.
7. For SSPP REST paths: ladder `..` depth (1..6) to attribute layers; escape to the API definition (`../../../../openapi.json%23`); build versioned field paths from the definition (`../../v1/users/<victim>/field/<secret-field>%23`); confirm field names in page JS (they vary per lab).
8. Complete the consuming workflow legitimately (csrf+session, login) so impact is attributable to the API flaw; measure boundaries (funds checks may force price→$0, not merely cheap).
9. For mass assignment: diff GET vs POST JSON shapes per endpoint; add each GET-only field with benign value (silent?), wrong-type value (processing error?), then exploit value; verify via marker/state.
10. One variable per request; assert hostname per command in multi-lab sessions.

## Verification

- Mutation proof: 200 + read-back value + fresh-consumer state (new cart line).
- Deletion proof: safe-read GET baseline (victim renders) → mutation → same GET 404s + solved marker.
- Impact proof: charged total + confirmation + solved marker.
- Stale-state trap: re-read cart after mutation; remove/re-add before concluding the PATCH failed.

## Common Failure Modes

- Wordlist brute-force before reading JS (noisy, misses exact shapes).
- Testing mutations only anon (401) without low-priv session (the actual vulnerable context here).
- Reading stale cart lines as PATCH failure.
- Assuming other labs' credit balances ($100 vs $0 here) — read fresh per instance.

## Impact Considerations

- Global price rewrite → any authenticated user buys anything at any price (demonstrated $1337→$0 free order); catalog integrity affects all users.
- Documented user deletion → any authenticated session deletes arbitrary users (demonstrated carlos); account integrity for all users.

## Lessons Learned

- From PortSwigger “Finding and exploiting an unused API endpoint”: JS `productPrice.js` → `GET /api/products/1/price` 200; method matrix 405/405/401/405 singled PATCH; authed `PATCH {"price":0}` → global `$0.00`; remove/re-add refreshed the $1.00 snapshot; checkout + confirmation → `is-solved` on $0 credit.
- From PortSwigger “Exploiting an API endpoint using documentation”: 13-path docs sweep → only `/api/openapi.json` 200/2096B; contract read (`DELETE /user/{username}`, base `./` → `/api`); safe-read `GET /api/user/carlos` 200 → low-priv `DELETE` 200 `User deleted` → re-read 400/404 + `is-solved`. No fuzzing needed.
- From PortSwigger “Exploiting SSPP in a query string”: oracle mapped users ({carlos, administrator}) + parser (`&unknown=` rejected, `username` dups first-wins, `#` cuts server suffix, NUL 500s); `&field=x#` vs `#`-alone isolated combination semantics; page JS named `reset_token`; `field=reset_token#` disclosed admin token → reset → login → delete → `is-solved`. No inbox needed.
- From PortSwigger “Exploiting a mass assignment vulnerability”: `GET /api/checkout` shape held `chosen_discount` absent from client POSTs; benign `0` silent, `"x"` → type-error (processing proof), `100` → 201 + confirmation + `is-solved`. Shape-diff + type-probe + exploit value.
- From PortSwigger “Exploiting SSPP in a REST URL”: oracle {carlos, administrator} + `..` ladder attributing layers (API JSON vs web HTML) → escaped to `openapi.json` disclosing `/api/internal/v1/users/{username}/field/{field}` → versioned `field/passwordResetToken` path → admin token → reset → login → delete → `is-solved`. Field names vary per lab — read page JS.

## Related Concepts

- Undocumented/shadow endpoints (unused mutations beside documented reads)
- Exposed machine-readable documentation (OpenAPI/Swagger paths as discovery oracles)
- GET-vs-POST JSON shape diff on state-changing endpoints: server GET responses containing objects the client never POSTs (e.g. `chosen_discount`) — hidden bindable parameters.
- methodology/verification.md (differential testing + state proof)
- Business-logic price trust (same impact via shop flow when no price field exists — contrast)

## Sources

- PortSwigger lab: Finding and exploiting an unused API endpoint (knowledge/portswigger/labs/api-unused-endpoint-price-patch.md)
- PortSwigger lab: Exploiting an API endpoint using documentation (knowledge/portswigger/labs/api-docs-delete-user.md)
- PortSwigger lab: Exploiting SSPP in a query string (knowledge/portswigger/labs/api-sspp-query-string.md)
- PortSwigger lab: Exploiting a mass assignment vulnerability (knowledge/portswigger/labs/api-mass-assignment-discount.md)
- PortSwigger lab: Exploiting SSPP in a REST URL (knowledge/portswigger/labs/api-sspp-rest-url.md)
