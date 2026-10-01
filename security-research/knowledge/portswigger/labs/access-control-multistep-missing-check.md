# PortSwigger Lab

## Lab

Multi-step process with no access control on one step

URL: https://0a990099034fa2c581124d980094000a.web-security-academy.net

## Vulnerability Class

Access control — vertical privilege escalation via missing authorization on one step of a multi-step workflow

## Objective

Escalate low-priv user `wiener:peter` to administrator and gain admin-panel access (solved markers on `/` and `/admin` after escalation). Official description page intentionally not read (contains solution); objective inferred from evidence + solved state.

## Initial Observations

- `GET /` → 200 shop, `is-notsolved`.
- `GET /admin` anon → 401 (2731 bytes).
- `GET /admin-roles` anon → 401 `Unauthorized` (GET blocked here — unlike method-bypass lab where GET bypassed).
- `POST /login` form; login `wiener:peter` → 302 `/my-account?id=wiener`, session only, no role cookie.
- As wiener: `GET /admin` → 401; `GET` + `POST /admin-roles` (no params) → 401. Direct paths uniformly denied.
- My-account page: only change-email form + logout; no role display, no admin refs.
- Probes as wiener: `/admin/upgrade`, `/admin/confirm`, `/admin/delete`, `/admin/users` → 401; `/admin-roles/upgrade`, `/admin-roles/confirm` → 404 (endpoint is param-driven, not subpath-driven).

## Hypotheses

- H1: Privileged role mutation is a multi-step flow on `/admin-roles` (select user+action, then confirm), and exactly one step omits the authZ check.
- H2: The confirm step is driven by an extra parameter (e.g. `confirmed=true`) invokable directly by low-priv, skipping the guarded first step.
- H3: After direct confirm-step invocation, fresh login yields admin session → `GET /admin` 200 → solved.
- Prior labs (cookie flip, verb bypass) used as principle sources only — neither payload assumed to work here (confirmed: no cookie marker; GET blocked).

## Attempts

1. Denial baselines anon + wiener on `/admin`, `/admin-roles` (GET/POST) → all 401. Boundary established.
2. Subpath probes (`/admin/*` → 401, `/admin-roles/*` → 404). Taught the endpoint is param-driven.
3. `POST /admin-roles` body `username=wiener&action=upgrade` → 401 `Unauthorized`. Step 1 guarded — H1 supported (a guarded step exists).
4. `POST /admin-roles` body `username=wiener&action=upgrade&confirmed=true` → **302** (0 bytes). Confirm step executes without authZ — H2 confirmed.
5. Fresh `POST /login (wiener:peter)` → `GET /admin` → **200**: `carlos (NORMAL), administrator (ADMIN), wiener (ADMIN)` + upgrade/downgrade form; `/` and `/admin` both `is-solved`/`Solved`. WORKED.

## What Failed

- All direct `/admin*` access as low-priv → 401 (no verb trick; matrix unnecessary beyond GET/POST since both denied identically and prior-lab verb lesson says to move on when uniform).
- `POST /admin-roles` without `confirmed` → 401. Useful: proves the FIRST step is guarded, isolating the missing check to the confirm step.
- Subpath guessing (`/admin/confirm`, `/admin-roles/confirm`) → 401/404. Taught to switch from path-guessing to param-driven testing on the known endpoint.

## What Worked

- `POST /admin-roles` with `username=wiener&action=upgrade&confirmed=true` under low-priv session → 302, then fresh login → `GET /admin` → 200 with `wiener (ADMIN)`, lab `Solved`.

## Burp Observations

- Not used via Burp MCP; curl param tests gave exact 401-vs-302 discriminators minimally. Burp Repeater equivalent for step-replay.

## Browser Observations

- Not required. No JS/multi-page wizard needed crafting — single confirm request reproducible over HTTP.

## CLI / Tool Observations

- curl with session jar; `%{http_code} %{size_download}` + bodies (`Unauthorized` vs 302-empty) as oracles.
- Fresh-login re-auth as role-effect proof (role loads at login), per method-lab lesson.

## Root Cause

The role-upgrade workflow enforces authorization on the initial step but not on the confirmation step. `POST /admin-roles (username+action)` → 401 for low-priv, while the same request plus `confirmed=true` skips the check entirely (302) and applies the mutation. Attackers invoke the unguarded final step directly, promoting themselves; the next login carries admin role.

## Verification

- Step isolation on same session: identical body minus `confirmed` → 401; plus `confirmed=true` → 302. One parameter explains execution.
- Fresh-session proof: new login → `GET /admin` 200 + `wiener (ADMIN)` + upgrade/downgrade form + `is-solved`/`Solved` on `/` and `/admin`. Deterministic.
- Ruled out: caching (fresh sessions), cookie trick (none issued), verb trick (GET/POST uniformly 401 on this endpoint).

## Impact

Any authenticated low-priv user self-promotes to admin in one request, gaining the admin panel (upgrade/downgrade any user — full tier control, can demote real admins).

## Why The Successful Approach Worked

- Denial baseline + guarded-step confirmation (401) framed the exact boundary before testing the skip.
- Adding the workflow-continuation parameter (`confirmed=true`) tested the “later step unguarded” hypothesis directly instead of enumerating paths/verbs.
- Fresh-login verification proved server-side role mutation, not a rendering quirk.

## Generalization

- For multi-step admin flows, test EACH step independently with low-priv: guarded step N (401) + unguarded step N+1 (302/200) = confirm-step flaw.
- Continuation flags (`confirmed`, `confirm`, `step`, `stage`, `verified`) are first-class authZ test points — replay the final step standalone.
- 401-vs-302 on identical bodies differing by one workflow flag is the signature; prove with fresh session + privileged UI.

## Lessons Learned

- Map the workflow before the verbs: here methods were uniform, steps were not.
- A guarded first step is evidence FOR a missing check later, not evidence of safety — always fire the last step directly.
- Reused across labs: fresh-login role proof, redirect ≠ effect (here 302 + verified effect, unlike method-lab GET 302 with no effect — always verify).

## Related Methodology

- methodology/access-control.md (vertical / multi-step — to be extended)
- methodology/verification.md (step isolation + fresh-session proof)

## References

- Solved instance: https://0a990099034fa2c581124d980094000a.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
