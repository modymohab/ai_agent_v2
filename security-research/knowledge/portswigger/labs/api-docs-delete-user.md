# PortSwigger Lab

## Lab

Exploiting an API endpoint using documentation — https://0a06006d0472104384e6fa5e00d30089.web-security-academy.net/ (PortSwigger Web Security Academy, API testing). Creds wiener:peter.

## Vulnerability Class

API security: exposed OpenAPI documentation advertising an unauthorized user-deletion endpoint. NOT injection.

## Objective

Find exposed API docs; delete carlos.

## Initial Observations

- Homepage/account: no app JS, no API refs in markup; `/robots.txt` 404.
- Docs sweep (13 candidates): only `/api/openapi.json` → 200 (2096B, OpenAPI 3.0.0, "We Love To Shop API"); `/api` → 302; all swagger/redoc/docs variants 404.
- Doc contract: `/user/{user.username}` supports get/delete/patch; servers `./` (same mount as doc → `/api` base).

## Hypotheses

- H1: documented `DELETE /api/user/carlos` executes without adequate authorization (low-priv wiener session). Confirmed first try.

## Attempts

1. Login → JS/markup refs (none) → docs sweep → openapi.json → contract read.
2. Baseline `GET /api/user/carlos` → 200 `{"username":"carlos",...}` (existence + shape proof).
3. `DELETE /api/user/carlos` (wiener session) → 200 `{"status":"User deleted"}`.
4. Re-read `GET /api/user/carlos` → 400 `404 User not found` + homepage `is-solved`. No failed variants needed.

## What Failed

Nothing material (13-path docs sweep: 12 misses, 1 hit — the misses are mapping, not failures).

## What Worked

Docs-driven endpoint call with attacker session; no method tampering or parameter fuzzing required.

## Burp Observations

Not used (curl sufficed; Burp MCP flaky on adjacent hosts).

## Browser Observations

None required.

## CLI / Tool Observations

- curl + jar; `python -m json.tool` for contract reading.
- Docs-sweep discipline: fixed candidate list, record code+size per path (200/2096 stood out vs 404/11s and 302/0).

## Root Cause

OpenAPI document exposed at predictable path discloses a user-deletion operation that enforces no meaningful authorization: any authenticated session can delete any user.

## Verification

- Pre: GET renders carlos (200 + fields). Post: same GET → 404 User not found (victim gone) + `is-solved` marker. Demonstrated state change, not status assumption.

## Impact

Arbitrary account deletion by any low-priv user (demonstrated carlos); same primitive deletes administrators.

## Why The Successful Approach Worked

Documentation removed all guesswork (exact path, method, parameter); the only hypothesis (missing authZ) was directly falsifiable in one request.

## Generalization

Wherever machine-readable API docs are exposed: read the contract first (paths/methods/params), baseline with a safe read (GET), then test the sensitive operation with a low-priv session; 200-vs-404 on re-read is the proof.

## Lessons Learned

- Sweep docs paths before JS/crawl discovery when the lab theme names documentation (13 fixed candidates suffice here).
- `servers: ./` anchors the base path to the doc's own mount — resolve relative, don't guess siblings.
- Safe-read baseline (GET) before state-changing call isolates existence from authorization findings.

## Related Methodology

- methodology/api-security.md (docs-discovery pattern added below; prior lab covered undocumented PATCH)
- methodology/verification.md (GET-before/after differential + marker)
- methodology/reconnaissance.md (cheap candidate sweeps, size oracles)
- methodology/injection.md — compared, NOT applicable (no interpreter; exposed-function flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/api-testing/lab-exploiting-api-endpoint-using-documentation
- Prior lab (different API flaw): knowledge/portswigger/labs/api-unused-endpoint-price-patch.md
