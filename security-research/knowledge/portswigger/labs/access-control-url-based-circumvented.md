# PortSwigger Lab

## Lab

URL-based access control can be circumvented

URL: https://0a890070035d218780d0763600b100af.web-security-academy.net

## Vulnerability Class

Access control — vertical privilege escalation via URL-matching discrepancy (rewrite-header bypass)

## Objective

Access the admin panel and delete user `carlos` (panel links + solved state confirm this; official description page intentionally not read).

## Initial Observations

- `GET /` → 200 shop, `is-notsolved`; nav exposes `Admin panel (/admin)` link even anon — panel existence is public, function is not.
- `GET /admin` anon → **403** `Access denied` (15 bytes, non-HTML — filter-level block, unlike prior labs' 401 HTML).
- No login needed for the bypass itself (panel + delete reached anon). No role cookie involved.

## Hypotheses

- H1: The 403 filter matches the raw URL path while the router normalizes differently — path variations (case, slash, dot, encoding, query) may desync them.
- H2: If paths fail, rewrite headers (`X-Original-URL`, `X-Rewrite-URL`) may be honored for routing but not for the access check.
- H3: Bypassed panel exposes `delete?username=carlos`; executing it flips `is-notsolved` → `is-solved` + removes carlos.
- Prior labs (cookie/verb/confirm-step) are principle sources only; none assumed applicable.

## Attempts

1. Baseline `GET /admin` → 403. Boundary established.
2. Path matrix (one variable each): `/ADMIN`, `/Admin`, `/admin/`, `/admin//`, `/admin/.`, `/admin?x=1` → all 403 (filter normalizes/case-folds); `//admin`, `/admin..;/`, `/%61dmin`, `/admin%2f`, `/admin%3b`, `/admin;foo`, `/admin%00`, `/admi%6e` → 404 (no route). Ruled out naive variants.
3. `/admin/.%2e` → 200 but renders HOMEPAGE (router normalized to `/`), still `is-notsolved`. PARTIAL: proves filter/router desync exists (filter passed what router normalized away) but lands on wrong route. Taught to look for a variant that resolves TO `/admin`.
4. Second path batch (`/admin/%2e`, `/admin/./`, `/x/../admin`, `/admin/../admin`, `/./admin`, `/%2e/admin`, …) → all 403/404. Path tricks exhausted on this stack.
5. Header batch on `GET /`: `X-Original-URL: /admin` → **200, 3218 bytes** (vs homepage 10808) rendering **Admin panel** (`Users wiener - Delete carlos - Delete`, links `/admin/delete?username=...`), still `is-notsolved`. `X-Rewrite-URL: /admin` → 200 homepage (not honored); `X-Custom-IP-Authorization` → homepage. WORKED for access.
6. `GET /` + `X-Original-URL: /admin/delete?username=carlos` → 400 `Missing parameter 'username'`. FAILED as framed — header value treated as path only; query inside header not parsed. Taught to split: path in header, params in real query string.
7. `GET /?username=carlos` + `X-Original-URL: /admin/delete` → **302** `/admin`; `/` → `is-solved`/`Solved`; panel via header now shows `User deleted successfully! Users wiener - Delete` (carlos gone). WORKED.

## What Failed

- All raw-path evasions (case/slash/dot/encoding/semicolon/double-slash/parent-traversal) → 403/404. This stack's filter matches normalized equivalents.
- `/admin/.%2e` → 200-homepage: desync without useful routing. Distinguishes “filter passed” from “admin reached”.
- Query-inside-header (`X-Original-URL: /admin/delete?username=carlos`) → 400. Header is path-only; params must ride the real query string.
- `X-Rewrite-URL` honored for nothing here — only `X-Original-URL` rewrites. Do not assume all rewrite headers behave alike; test each.

## What Worked

- `GET /` + `X-Original-URL: /admin` → admin panel (200).
- `GET /?username=carlos` + `X-Original-URL: /admin/delete` → 302, carlos deleted, `Solved`.

## Burp Observations

- Not used via Burp MCP; curl header injection + size/body discriminators sufficed. Burp Repeater equivalent for header matrix.

## Browser Observations

- Not required. No auth/session/JS involved; fully HTTP-reproducible anon.

## CLI / Tool Observations

- curl with `-H` matrix; oracles: 403-15B (filter block) vs 404-11B (no route) vs 200-size (3218 panel vs 10808 shop) + link grep + `is-solved` marker.
- `head -c` + link extraction distinguished panel (delete links) from homepage faster than full reads.

## Root Cause

Two-layer URL handling desync: a front filter authorizes the RAW request path (`/` → allow), while the application routes on the `X-Original-URL` header (`/admin…` → privileged handler) without re-checking authorization. Query strings attach to the real URL, so path-in-header + params-in-query composes the full privileged request (`/admin/delete` + `?username=carlos`) past the filter.

## Verification

- Baseline 403 (`/admin`) vs 200-panel (header) on otherwise identical requests — single header explains access.
- Failed framing (400 missing-param) vs working split (302) isolates param handling.
- Victim-state proof: panel before = `carlos - Delete`; after = `User deleted successfully!`, carlos absent; `/` marker `is-notsolved` → `is-solved`. Deterministic, anon, no caching confound (state change persists across fresh requests).

## Impact

Unauthenticated full admin-panel access + arbitrary user deletion (demonstrated: `carlos` deleted) via one header — complete vertical bypass with no credentials.

## Why The Successful Approach Worked

- Bounded path matrix first (cheap, ruled out the common class) instead of assuming headers.
- The `/admin/.%2e`→homepage partial proved desync exists, motivating the header batch.
- Size + link oracles (3218 + delete links) identified the panel without auth; the 400 taught the path/query split that made the delete work.

## Generalization

- When 403-filter + router coexist, test filter-vs-router desync in order: case/slash/dot/encoding → traversal-to-self (`/x/../admin`, `/admin/../admin`) → rewrite headers (`X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-*`) EACH independently.
- 200 + wrong-page (homepage) still proves desync — pivot, don't stop.
- Headers-as-path usually ignore embedded query strings: put the path in the header, the parameters in the real query string.
- 403-15B vs 404-11B vs 200-size is a three-way routing oracle; panel proof = privileged links + victim state change + solved marker.

## Lessons Learned

- Exposed `/admin` link anon ≠ vulnerable; the 403 body shape (short non-HTML) signals filter-level blocking — header/path desync is the corresponding test family.
- Stop path-fuzzing once the matrix is uniformly 403/404; switch families (headers) instead of deepening the same list.
- Verify rewrite behavior per-header; `X-Original-URL` worked where `X-Rewrite-URL` did not.

## Related Methodology

- methodology/access-control.md (vertical / URL-matching discrepancy — to be extended)

## References

- Solved instance: https://0a890070035d218780d0763600b100af.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
