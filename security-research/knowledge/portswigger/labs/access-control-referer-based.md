# PortSwigger Lab

## Lab

Referer-based access control

URL: https://0a47004903f7917e806153c4000000c0.web-security-academy.net

## Vulnerability Class

Access control — vertical privilege escalation via Referer-header-based authorization (spoofable client header trusted as proof of admin navigation)

## Objective

Escalate low-priv user `wiener:peter` to administrator and access the admin panel (`Solved` on `/` and `/admin` after escalation; `/admin/delete` does not exist here — 404). Official description page intentionally not read.

## Initial Observations

- `GET /` → 200 shop, `is-notsolved`.
- `GET /admin` anon → 401 HTML; `GET /admin/delete?username=carlos` anon → 401. (Role message: “Admin interface only available if logged in as an administrator”.)
- Login `wiener:peter` → 302, session only, no role cookie.
- As wiener: `GET /admin` → 401 with no Referer AND with `Referer: …/admin`, `…/`, `…/admin/delete?username=carlos`, `https://example.com/` — panel view is role-gated, not Referer-gated.
- As wiener: `GET /admin/delete?username=carlos` → 401 under all Referer values tried (NONE, /admin, /admin/delete?…, /). Delete path not the flaw here.
- Referer variants (trailing-slash, bare host, `null`, `/my-account`), misspelled `Referrer`, `Origin` (host/null), Referer+Origin combo, lowercase `referer` → all 401 on panel + delete. Header-spelling tricks exhausted.
- `GET/POST /admin-roles` (no params) as wiener → 401; `POST username=wiener&action=upgrade` → 401 (guarded step, like multistep lab).

## Hypotheses

- H1: Panel view requires real admin role; the Referer gate sits on the role-MUTATION endpoint, not the panel.
- H2: `POST /admin-roles` trusts `Referer: <lab>/admin` (exact panel URL) as authorization — low-priv + that header executes upgrade.
- H3: After upgrade, fresh login → `GET /admin` 200 (no Referer needed) → solved.
- Prior labs used as principles only (isolation, fresh-login proof); cookie/verb/confirm/URL-header payloads not assumed.

## Attempts

1. Denial baselines anon + wiener on `/admin`, `/admin/delete`, `/admin-roles` → 401. Boundary set.
2. Referer matrix on panel + delete (exact/related/foreign values, spelling/case/Origin variants) → all 401. Taught the gate is NOT on those paths.
3. `POST /admin-roles username=wiener&action=upgrade` + `Referer: …/admin` → **302** (executes); same with `Referer: …/admin-roles` → 401; `Referer: …/` → 401. Single-header delta — H2 confirmed. (`+confirmed=true` variant also 302; unnecessary here.)
4. Fresh `POST /login (wiener:peter)` → `GET /admin` → **200** both with and without Referer: `carlos (NORMAL), administrator (ADMIN), wiener (ADMIN)` + upgrade/downgrade form. WORKED.
5. `GET /admin/delete?username=carlos` as admin → 404 (no such endpoint). `/` + `/admin` already `is-solved`/`Solved` from escalation — objective is access, not deletion (differs from cookie/URL labs).

## What Failed

- Referer matrix on `/admin` and `/admin/delete` (10+ values/spellings) → all 401. Useful: localized the gate to the mutation endpoint instead of the panel.
- Assumed-next-step errors avoided: did not force-fit cookie flip (no marker), verb matrix (GET+POST uniformly 401 → moved on per verb-lab lesson), confirm flag (untested first; proved unnecessary), URL-header trick (anon panel already 401-HTML not 403-filter — different stack shape).

## What Worked

- `POST /admin-roles` body `username=wiener&action=upgrade` + `Referer: <lab-URL>/admin` under low-priv session → 302; fresh login → `GET /admin` → 200 `wiener (ADMIN)`, `Solved`.

## Burp Observations

- Not used via Burp MCP; curl header matrix sufficed. Repeater equivalent for Referer tampering.

## Browser Observations

- Not required. No navigation-dependent behavior to reproduce — header crafted directly over HTTP (browsers would always send genuine Referers, which is exactly why the check is flawed).

## CLI / Tool Observations

- curl `-H` matrix with `%{http_code} %{size_download}`; oracles 401-14B (`Unauthorized`) vs 302-0B (executed) vs 200-panel (role list).
- Fresh-login proof pattern reused from method/multistep labs.

## Root Cause

The role-mutation endpoint authorizes via the client-controlled `Referer` header instead of server-side role state: `POST /admin-roles` with `Referer: <lab>/admin` executes `upgrade` for a low-priv session, while all other Referer values (including the endpoint's own URL and site root) are rejected. Attackers forge one header to self-promote; the next login carries admin role. Panel view itself is correctly role-gated — the flaw is authorization-by-navigation-header on the mutation.

## Verification

- Same-session, same-body, Referer-only delta: `…/admin-roles`/`…/` → 401 vs `…/admin` → 302. Header is the sole variable.
- Fresh-session proof: new login → `GET /admin` 200 + `wiener (ADMIN)` + upgrade/downgrade form + `is-solved`/`Solved` on `/` and `/admin`. Deterministic.
- Ruled out: caching (fresh sessions), cookie/verb/confirm mechanisms (each tested, absent here), spelling tricks (matrix).

## Impact

Any authenticated low-priv user self-promotes to admin with one forged header; gains panel control over account tiers (upgrade/downgrade any user — can demote real admins).

## Why The Successful Approach Worked

- Exhausting the panel/delete Referer matrix first PROVED the gate's absence there, forcing the pivot to the mutation endpoint (avoids sunk-cost on wrong path).
- Testing the mutation endpoint with/without the panel-URL Referer isolated the exact trusted value.
- Fresh login + panel content proved server-side promotion, not a rendering artifact.

## Generalization

- When panel + action paths ignore Referer, test the STATE-CHANGING admin endpoint (roles/upgrade) with navigation-URL Referers (`/admin`, panel path, action path).
- Exact-value matching is common: test the panel URL precisely (trailing-slash and root variants rejected here).
- Browsers send honest Referers, so this flaw is invisible in normal UI flows — direct HTTP header crafting is the required tool, minimal and sufficient.
- 401-everywhere on views + 302-on-mutation-with-header is the signature; prove via fresh session.

## Lessons Learned

- Locate the gate before attacking it: panel (role-gated, correct) vs mutation (header-gated, flawed) are different checks — matrix each.
- A 401 body naming roles (“logged in as an administrator”) does not mean roles are correctly enforced everywhere; the mutation told another story.
- Cross-lab reuse done right: isolation + fresh-login proof transferred; no payload did.

## Related Methodology

- methodology/access-control.md (vertical / referer-based — to be extended)

## References

- Solved instance: https://0a47004903f7917e806153c4000000c0.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
