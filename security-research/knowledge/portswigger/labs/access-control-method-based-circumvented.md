# PortSwigger Lab

## Lab

Method-based access control can be circumvented

URL: https://0a4000d803fdeb4d801308b5008e006f.web-security-academy.net

## Vulnerability Class

Access control — vertical privilege escalation via method-based (verb-scoped) authorization bypass

## Objective

Escalate low-priv user `wiener:peter` to administrator and gain admin-panel access (solved marker observed on `/` and `/admin` after escalation; panel exposes user upgrade/downgrade). Official description page intentionally not read (contains solution); objective inferred from evidence + solved state.

## Initial Observations

- `GET /` → 200 shop, `is-notsolved`.
- `GET /admin` anon → 401 “Admin interface only available if logged in as an administrator”.
- `GET /login` → 200, `POST /login` form. Login `wiener:peter` → 302 `/my-account?id=wiener`, session only (no `Admin` cookie — different mechanism from previous cookie lab).
- `GET /admin`, `POST /admin` as wiener → 401 identical. `GET/POST /admin/delete?username=carlos` as wiener → 401. Direct admin paths uniformly denied.
- `GET /my-account/change-email` → 405 `Allow: POST` (framework reveals allowed methods); my-account page shows only change-email form + logout, no admin refs, no role display.

## Hypotheses

- H1: Some privileged endpoint enforces authZ only for one HTTP method (e.g. POST), while other methods bypass the check.
- H2: Role management lives outside `/admin` (e.g. `/admin-roles`), reachable by low-priv via the unprotected method.
- H3: After self-upgrade, fresh login yields admin session → `GET /admin` 200 → solved.
- Prior cookie-lab knowledge (`Admin=false→true`) explicitly NOT transferred; no cookie marker exists here.

## Attempts

1. Baseline denial: `GET /admin`, `POST /admin`, `GET/POST /admin/delete?username=carlos` anon + as wiener → all 401. Establishes boundary on known paths.
2. Method matrix on `/admin/delete?username=carlos` and `/admin` (GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS/TRACE) as wiener → all 401. Rules out verb trick on those paths.
3. Targeted path probes (`/admin/users`, `/admin/roles` → 401; `/administrator`, `/roles`, `/my-account/change-role` → 404). One justified guess from lab-series structure: top-level `/admin-roles` → `GET` 400 “Missing parameter 'username'”, `POST` 401 “Unauthorized”. LIVE endpoint with method-dependent handling — H1/H2 supported.
4. `GET /admin-roles?username=wiener` (+ `&action=upgrade` variants) → 302 `/admin`, but `GET /admin` still 401 with same session AND with fresh login. FAILED as upgrade vector (query-param GET executes redirect but no role effect observed).
5. Method matrix on `/admin-roles?username=wiener`: GET→302, POST→401, PUT→400 “Missing parameter 'username'”, PATCH→302, DELETE→400, HEAD/OPTIONS→302. Key inference: PUT/DELETE read params from BODY (query ignored → 400), and only POST is authZ-blocked — GET/PUT/PATCH bypass the check.
6. `PUT /admin-roles` body `username=wiener` → 302; body `username=wiener&action=upgrade` → 302. Fresh login as wiener → `GET /admin` → **200**, panel lists `carlos (NORMAL)`, `administrator (ADMIN)`, `wiener (ADMIN)` + upgrade/downgrade form (`POST /admin-roles`, actions `upgrade`/`downgrade` — confirms semantics). WORKED.
7. `GET /admin/delete?username=carlos` as admin → 404 “Not Found” (no such endpoint in this lab). Homepage + admin page already `is-solved`/`Solved` from the escalation itself.

## What Failed

- All `/admin` + `/admin/delete` method variations as low-priv → 401. Taught the flaw is not on those paths.
- `GET /admin-roles?username=...` (query) → 302 but no role change (verified via same-session AND fresh-login `/admin` → 401). Taught to verify role effect, not redirect; query-vs-body parameter handling differs per method.
- `GET /admin/delete?username=carlos` as admin → 404. This lab has no delete endpoint; objective is escalation + panel access, not deletion (unlike previous lab — do not assume identical objectives).

## What Worked

- `PUT /admin-roles` with body `username=wiener&action=upgrade` (same low-priv session) → 302, then fresh `POST /login (wiener:peter)` → `GET /admin` → 200 admin panel with `wiener (ADMIN)`, lab `Solved` on `/` and `/admin`.

## Burp Observations

- Not used via Burp MCP; curl method matrix gave precise status/body discriminators with minimal requests. Burp Repeater would be equivalent for method-tampering comparison.

## Browser Observations

- Not required. No JS-driven flow; all behavior HTTP-reproducible. Browser would add no value.

## CLI / Tool Observations

- curl throughout: baseline, login (session jar), per-method matrix with `%{http_code} %{size_download}`, body-vs-query isolation, fresh-login verification.
- Discriminators: 401 vs 400 vs 302 vs 200; bodies “Unauthorized” (authZ block), “Missing parameter 'username'” (passed authZ, failed validation), 302 `/admin` (executed), 200 + `wiener (ADMIN)` + form (effect).

## Root Cause

Authorization filter on `/admin-roles` is method-scoped: it blocks `POST` for non-admins but permits `GET`/`PUT`/`PATCH` (and HEAD/OPTIONS) without a role check. PUT/DELETE parse parameters from the request body. So a low-priv user sends the privileged mutation (`username=wiener&action=upgrade`) via `PUT` body, bypassing the POST-only check and promoting themselves; subsequent login issues an admin session with full `/admin` access.

## Verification

- Denial baseline (401s) vs bypass (302) vs effect (200 + `wiener (ADMIN)` + `Solved`) deterministic across sessions.
- Isolation: GET-query attempts + fresh login → still 401 (ineffective); PUT-body + fresh login → 200 + ADMIN (effective). One variable (method + param location) explains the difference.
- Solved markers `is-solved`/`Solved` on both `/` and `/admin`; admin form confirms role semantics (`upgrade`/`downgrade` actions).
- Alternative explanations ruled out: not caching (fresh sessions tested), not cookie trick (no role cookie issued), not same-objective-as-last-lab (no delete endpoint; 404).

## Impact

Any authenticated low-priv user self-promotes to administrator via one crafted request, gaining the admin panel (user upgrade/downgrade — full account-tier control, including downgrading real admins or upgrading attacker accounts).

## Why The Successful Approach Worked

- Denial baseline on `/admin` prevented false “bypass” claims.
- Full method matrix on the discovered `/admin-roles` endpoint exposed the filter gap (POST 401 vs GET/PUT 302) and the body-vs-query parsing split (PUT 400 on query → body required).
- Role effect verified via fresh login + panel content, not via redirect status.

## Generalization

- When an endpoint returns 401 for POST but 400/302 for other methods on the same path+params, the authZ check is method-scoped — test every method, and test params in both query AND body per method.
- 400-validation vs 401-authZ vs 302-executed is a three-way oracle: 400 means you passed authZ (endpoint parses your input); 302/200 means it acted.
- Always confirm state-changing authZ bypass with a fresh session + privileged UI/state marker, since role may load at login.

## Lessons Learned

- Discover admin-adjacent paths with a tiny targeted set before any fuzzing (`/admin-roles` found after `/admin/*` uniformly 401).
- Matrix methods × param-locations; frameworks often bind GET→query, PUT/DELETE→body.
- Redirect (302) ≠ effect; re-login + check role display is the proof for promotions.
- Lab objectives differ within a series (here: escalate + access; previously: delete user) — verify solved marker, don't force-fit prior flow.

## Related Methodology

- methodology/access-control.md (vertical / method-based bypass — to be extended)
- methodology/verification.md (differential + fresh-session state proof)

## References

- Solved instance: https://0a4000d803fdeb4d801308b5008e006f.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
