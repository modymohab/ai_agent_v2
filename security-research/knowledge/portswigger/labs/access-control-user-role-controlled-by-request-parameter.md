# PortSwigger Lab

## Lab

User role controlled by request parameter

URL: https://0a3d008b049878a4812339b8009c00bd.web-security-academy.net

## Vulnerability Class

Access control — vertical privilege escalation via forgeable request parameter (Admin cookie)

## Objective

Access the admin panel at `/admin` and delete the user `carlos`. Credentials provided: `wiener:peter`.

## Initial Observations

- `GET /` → 200, shop homepage, lab header `Not solved`, links to `/my-account`, `/product?productId=N`.
- `GET /admin` unauthenticated → 401, 2692 bytes, `Not solved`, new `session` cookie issued.
- `GET /login` → 200, login form `POST /login` with hidden `csrf` token bound to `session` cookie.
- Lab title explicitly indicates role is controlled by request parameter.

## Hypotheses

- H1: `/admin` enforces role server-side but relies on client-controllable value (cookie/parameter), so low-priv user is denied by default (401).
- H2: Login issues a forgeable role marker (e.g. `Admin=false` cookie) that can be flipped client-side to `Admin=true`.
- H3: After flipping, `/admin` renders user management with `GET /admin/delete?username=carlos`, and requesting it deletes carlos and marks lab solved.
- Stored SQLi knowledge (WHERE/UNION/blind) is NOT applicable — used only as negative reference; no SQL payloads tested.

## Attempts

1. Baseline `GET /admin` (no auth) → 401. Establishes denial state.
2. `GET /login` → 200, extracted `csrf` + `session`. Required for bound login.
3. `POST /login` with `csrf=<fresh>`, `username=wiener`, `password=peter`, same `session` cookie → 302 to `/my-account?id=wiener`, `Set-Cookie: Admin=false` + new `session`. Confirms H2 marker exists.
4. `GET /admin` with `Admin=false` → 401. Confirms low-priv denial.
5. `GET /admin` with `session=<same>; Admin=true` → 200, `Admin panel`, `Users`, links `/admin/delete?username=wiener` and `/admin/delete?username=carlos`. Confirms vertical bypass.
6. `GET /admin/delete?username=carlos` with `Admin=true` → 302 to `/admin`. Then `GET /admin` and `GET /` show `is-solved` / `Solved`.

## What Failed

- `GET /admin` unauthenticated and with `Admin=false` → 401. Useful as denial baseline, not a bypass. Taught that role check exists but is client-controlled.

## What Worked

- Login as `wiener:peter` preserving `session`+`csrf` pair, then cookie flip `Admin=false` → `Admin=true`, then:
  - `GET /admin` with `Admin=true` → 200 admin panel
  - `GET /admin/delete?username=carlos` with `Admin=true` → 302, carlos deleted, lab solved

## Burp Observations

- Not used via Burp MCP for this lab; curl provided sufficient HTTP-level evidence with fewer interactions. Burp MCP would be equivalent for inspecting `Set-Cookie: Admin=false` and replaying with `Admin=true` to compare 401-vs-200.

## Browser Observations

- Not required. No JS/session workflow beyond standard login form. Homepage and login HTML fetched via HTTP confirmed structure; browser automation would add no value.

## CLI / Tool Observations

- curl used for all steps: baseline, login (csrf extraction via grep), cookie-jar comparison, Admin flip, delete + verify.
- Response discriminators: status (401 vs 200 vs 302) + body markers (`Not solved` vs `is-solved`/`Solved`) + presence of `delete?username=carlos`.
- `session` + `csrf` must be paired from same `GET /login` response; resubmitted as pair on `POST /login`.

## Root Cause

Authorization decision for `/admin` trusts a client-side forgeable cookie:

```
POST /login (wiener:peter) → Set-Cookie: Admin=false
GET /admin with Admin=false → 401
GET /admin with Admin=true  → 200 + user management
```

Server does not bind role to server-side session; editing the cookie upgrades from low-priv to admin. Admin function `GET /admin/delete?username=<user>` then executes with attacker-controlled admin context.

## Verification

- Reproducible: denial with `Admin=false` (401) vs access with `Admin=true` (200) on same `session`, deterministic.
- Ownership/context confirmed: low-priv session `wiener`, target resource `carlos` (other user), admin function `/admin/delete`.
- App-state verified: after delete request, `/admin` and `/` both changed from `is-notsolved`/`Not solved` to `is-solved`/`Solved`.
- Alternative explanations ruled out: not caching (Set-Cookie + status flip tied to cookie value), not already-authorized (false→401, true→200 on same session).

## Impact

Vertical privilege escalation: any authenticated low-priv user becomes admin by flipping one cookie. Demonstrated impact: deletion of arbitrary user `carlos` via exposed admin function. Same class in real apps allows admin-panel access, user/data management, further privilege actions.

## Why The Successful Approach Worked

- Baseline denial established the security boundary.
- Login response exposed the client-side role marker (`Admin=false`) — evidence, not assumption.
- Single-variable flip (`false`→`true`, same session) isolated the authorization check.
- State verification (`Solved` marker) proved server-side effect, not just 200 body change.

## Generalization

- When login/register responses set role-like cookies/parameters (`Admin`, `role`, `isAdmin`, `user-type`), test server trust by flipping to privileged value and re-requesting denied function with same session.
- 401-vs-200 on same session with one cookie delta is a strong signature of parameter-based access control.
- Always verify with state-changing admin action + solved/state marker, not just panel render.

## Lessons Learned

- Map denied function first (`/admin` → 401) before authenticating.
- Inspect `Set-Cookie` on login for role markers; they are first-class authZ test points like any parameter.
- Keep `session`+`csrf` bound; flip only the role marker to isolate variables.
- Verify vertical escalation via affected victim resource (`carlos` deleted) + app solved state.

## Related Methodology

- methodology/access-control.md (vertical / parameter-based access control)
- methodology/verification.md (differential 401-vs-200 + state verification)
- methodology/impact-analysis.md (vertical impact via victim account)

## References

- Lab: https://portswigger.net/web-security/access-control/lab-user-role-controlled-by-request-parameter
- Solved instance: https://0a3d008b049878a4812339b8009c00bd.web-security-academy.net/
