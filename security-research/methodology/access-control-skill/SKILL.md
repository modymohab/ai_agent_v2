# Access Control Skill

> Provenance: migrated from `methodology/access-control.md`. Content preserved verbatim; original file kept as source of truth.

## Core Concept

Access control fails when the server trusts client-controllable role markers (cookies, parameters, headers) instead of server-side session state. Flipping the marker elevates low-priv to high-priv (vertical escalation).

A second variant fails when the authorization filter is method-scoped: it checks only one HTTP verb (e.g. `POST`) while other verbs (`GET`/`PUT`/`PATCH`) execute the same privileged function unchecked.

A third variant fails when a multi-step workflow guards an early step but not a later one: step 1 (select user+action) returns 401 for low-priv while the confirm step (same endpoint plus a continuation flag such as `confirmed=true`) executes unchecked.

A fourth variant fails when a front filter authorizes the raw URL path while the application routes on a rewrite header (`X-Original-URL`): requesting an allowed path (e.g. `/`) with the privileged path in the header executes the admin handler unchecked (URL-matching discrepancy).

A fifth variant authorizes a state-changing admin function by the client-controlled `Referer` header (e.g. trusting `Referer: <panel-URL>` as proof of admin navigation): forging the exact panel URL executes role mutation for a low-priv session.

A sixth variant is horizontal: object access keyed by unpredictable IDs (GUIDs) with NO ownership check (`/my-account?id=<guid>` renders whoever's data). Unguessability fails when the app itself leaks victim IDs (blog author links) — leak discovery replaces guessing.

A seventh variant discloses credentials inside victim pages: the password-update form pre-fills the victim's CURRENT cleartext password in an input `value`. Reading page SOURCE (not rendered text) yields logins — chain low-priv → administrator → admin function.

An eighth variant authorizes by a client-controlled IP header whose NAME is disclosed via `TRACE` request echo: the 401 denial states locality-only access while `TRACE /admin` returns the server-appended `X-Custom-IP-Authorization: <client-IP>` in its `message/http` body — forging `127.0.0.1` passes the localhost check with zero authentication.

A ninth variant authorizes by the client-controlled `Host` header itself: the 401 denial states the interface is `only available to local users` while `GET /admin` with `Host: localhost` (same path, same connection target, sessionless) renders the admin panel — the locality check compares the Host string rather than the connection source.

## Security Boundary

Intended: low-priv session ≠ admin function.
Violated when: `low-priv session + forged role marker → admin function executes`.
Also violated when: `low-priv session + unprotected HTTP method → privileged mutation executes`.

## Recognition Patterns

- Denied sensitive path (`/admin` → 401/403) as low-priv/anon.
- Login/register response sets role-like cookie/parameter (`Admin=false`, `role=user`).
- Same session + one marker flip (`false→true`) → 200 + privileged UI (user list, delete links).
- Method split on one endpoint: `POST` → 401 “Unauthorized” but `GET`/`PUT`/`PATCH` → 400/302 (validation/execution) — authZ is verb-scoped.
- `PUT`/`DELETE` returning 400 “Missing parameter” for query-string params means the handler reads the BODY — resend params as body.
- Multi-step split on one endpoint: step 1 (`username`+`action`) → 401, same + continuation flag (`confirmed=true`) → 302 — first step guarded, confirm step unguarded.
- URL/header desync: `GET /admin` → 403-15B (filter block) vs `GET /` + `X-Original-URL: /admin` → 200-panel (3218B + delete links); path variants uniformly 403/404. Header-as-path usually ignores embedded query strings — path in header, params in real query (`/?username=carlos` + `X-Original-URL: /admin/delete` → 302 + solved).
- Referer gate on mutation: panel + delete ignore Referer (401 under all values), but `POST /admin-roles (username+action)` + `Referer: <panel-URL-exact>` → 302 while own-URL/root Referers → 401. Exact panel URL is the trusted value; prove via fresh login.
- Horizontal IDOR: own `/my-account?id=<own-guid>` shows own API key; victim GUID in public author links (`/blogs?userId=<guid>`); swapped id → 200 victim data (`carlos` + key); key submission oracle `{"correct":true}` + `is-solved`.
- Credential-disclosure IDOR: username-string ids (`?id=carlos`, `?id=administrator`) render 200 with `name=password value='<cleartext>'` in page SOURCE; each password logs in (302 + identity page); administrator → `/admin` 200 → delete carlos → `User deleted successfully!` + `is-solved`. Rendered text shows nothing — grep input values.
- Host-header locality gate: anon `GET /admin` → 401 stating `only available to local users`; same path with `Host: localhost` → 200 panel (user roster + delete links). `robots.txt Disallow: /admin` + denial wording map the target in 2 requests.

## Common Locations

- `/admin` panels and admin-only routes.
- `Set-Cookie` role flags on login.
- User-management actions (`/admin/delete?username=<user>`).
- Role parameters in cookies, hidden fields, query strings.
- Role-mutation endpoints outside `/admin` (e.g. `/admin-roles` with `username` + `action=upgrade|downgrade` — form in admin panel reveals semantics).

## Indicators

- 401/403 with `Admin=false` vs 200 with `Admin=true` on same `session` — single-variable delta proves parameter-based check.
- Privileged UI leak: `Admin panel`, `Users`, `delete?username=<victim>` rendered only after flip.
- State marker flip: `is-notsolved`/`Not solved` → `is-solved`/`Solved` after admin action.

## Testing Methodology

1. Baseline denied function anon (`GET /admin` → 401).
2. Login as low-priv (preserve `session`+`csrf` pair), record `Set-Cookie` role markers.
3. Re-request denied function with original marker → confirm denial (401).
4. Flip only the role marker (`Admin=false`→`Admin=true`, same session) → compare status + body.
5. Execute minimal privileged state change (delete test/victim user) → verify solved/state marker.
6. Keep session constant; change one variable at a time.
7. Method-bypass extension: for each candidate privileged endpoint, matrix methods (GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS) × param locations (query vs body). Read the three-way oracle: 401 = authZ-blocked, 400-validation = passed authZ, 302/200 = executed.
8. Multi-step extension: test each workflow step standalone with low-priv. Guarded step (401) + unguarded confirm step (302/200 on same params + continuation flag) = confirm-step flaw. Fire the final step directly.
9. URL-desync extension: baseline the filter block (`GET /admin` → 403-15B) and no-route (`404-11B`); matrix path variants (case/slash/dot/encoding/traversal-to-self) one variable each, then rewrite headers (`X-Original-URL`, `X-Rewrite-URL`, …) independently. A 200-wrong-page proves desync — pivot to headers. Split path (header) from params (real query string).
10. Referer-gate extension: matrix Referer separately on views AND on mutations. Views 401-under-all-values + mutation 302-with-panel-URL = header-gated mutation. Test exact panel URL, trailing-slash, root, own-URL, foreign, `null`, spelling/case variants, `Origin` — one variable each; browsers send honest Referers so craft over raw HTTP.
11. Horizontal-IDOR extension: baseline self-access (own id → own data, note data-on-page facts like API keys); hunt victim IDs in authored content/shared URLs/JS/API responses (never brute-force unguessable IDs); swap one variable; prove via victim data + submission/solved oracle.
12. Credential-disclosure extension: on IDOR pages inspect RAW HTML for pre-filled secrets (`value=` on password inputs, hidden fields, tokens) — rendered text is half the surface. Verify each disclosed credential by login (302 + identity page); let the solved marker (not assumptions) pick the objective — carlos-login may be insufficient where administrator-login + admin action solves. Keep one session per identity.
13. TRACE-header extension: where a denial cites locality/IP gating, send `TRACE` at the gated endpoint and read the `message/http` echo for server-appended trust headers (`X-Custom-IP-Authorization: <client-IP>` names the exact header). Forge loopback (`127.0.0.1`) on the same endpoint — 401-without vs 200-with isolates the axis. No authentication needed at any step.
14. Host-header extension: where a denial cites local-only access, replay the identical path with `Host: localhost` (then `127.0.0.1` and case/port variants, one variable each) over HTTP/1.1 raw keeping the connection target (SNI) on the lab host. 401-without vs 200-with-privileged-UI isolates the axis. Confirm via delete + re-read (victim-row absence + success string + solved marker); 302 alone is not proof.
15. Confirm mutations via fresh login + privileged UI (role may load at login); redirect alone is not proof.

## Verification

- Reproduce 401-vs-200 on same session; do not rely on status alone — confirm privileged UI + victim-affecting state change + `Solved` marker.
- Confirm victim context (e.g. `carlos` deleted by `wiener` session).
- Rule out caching by tying flip to cookie value deterministically.

## Common Failure Modes

- Testing `/admin` without establishing denial baseline → cannot measure bypass.
- Changing session and marker together → cannot isolate check.
- Reporting panel render without victim state change/solved marker as confirmed escalation.
- Breaking `session`+`csrf` binding on login → false login failure.

## Impact Considerations

- Vertical escalation: low-priv → admin via one cookie edit.
- Demonstrated via victim user deletion; same primitive typically yields full admin-panel control.

## Lessons Learned

- From PortSwigger “User role controlled by request parameter”: `Set-Cookie: Admin=false` on `POST /login (wiener:peter)`; `GET /admin` 401 with `false`, 200 + `delete?username=carlos` with `true`; `GET /admin/delete?username=carlos` → 302 + `is-solved`. Single-cookie delta is the discriminator; victim deletion + solved marker is the proof.
- From PortSwigger “Method-based access control can be circumvented”: no role cookie; `/admin*` uniformly 401 across methods; `/admin-roles` method-split — `POST`→401 but `GET/PUT/PATCH`→302, `PUT/DELETE` read body (query→400). `PUT` body `username=wiener&action=upgrade` + fresh login → `GET /admin` 200, `wiener (ADMIN)`, `is-solved`. `GET`-query 302 had NO role effect (fresh-login still 401) — redirect ≠ effect; matrix methods × param-locations and prove via fresh session.
- From PortSwigger “Multi-step process with no access control on one step”: `/admin-roles` GET+POST uniformly 401 (no verb gap); `POST username=wiener&action=upgrade` → 401 but same + `confirmed=true` → 302 → fresh login → `GET /admin` 200, `wiener (ADMIN)`, `is-solved`. Guarded-step 401 vs confirm-step 302 on one-flag delta is the signature; prove via fresh session.
- From PortSwigger “URL-based access control can be circumvented”: `GET /admin` → 403 (filter); path matrix uniformly 403/404 except `/admin/.%2e` → 200-homepage (desync, wrong route); `GET /` + `X-Original-URL: /admin` → 200-panel + delete links; `GET /?username=carlos` + `X-Original-URL: /admin/delete` → 302 → `is-solved`, `User deleted successfully!`. Header is path-only (embedded query → 400); test each rewrite header independently.
- From PortSwigger “Referer-based access control”: panel + delete 401 under ALL Referer values (gate not there); `POST /admin-roles (username+action)` + `Referer: <lab>/admin` → 302 vs own-URL/root → 401; fresh login → `GET /admin` 200 (Referer-independent), `wiener (ADMIN)`, `is-solved`. No delete endpoint (404) — objective is access. Locate the gate per-endpoint; craft headers over raw HTTP.
- From PortSwigger “User ID controlled by request parameter, with unpredictable user IDs”: own GUID shows own API key; carlos GUID `0e64…` leaked in blog author links; swapped id → 200 carlos key; `POST /submitSolution` → `{"correct":true}` + `is-solved`. Leak-hunt replaces guessing; submission oracle is key-validity proof.
- From PortSwigger “User ID controlled by request parameter with password disclosure”: username ids, no GUID leak needed; carlos + administrator pages disclose cleartext passwords in input values; carlos-login valid but not solved (admin 401); administrator-login → `/admin` 200 → delete carlos → `User deleted successfully!` + `is-solved`. Source-inspect IDOR pages; chain credentials; solved-marker arbitrates the objective.
- From PortSwigger “Authentication bypass via information disclosure”: seeded creds rejected (no seeded account — registration path would apply, but unneeded); `/admin` anon → 401 local-users-only; `TRACE /admin` → echo discloses `X-Custom-IP-Authorization: <client-IP>`; same endpoint + `127.0.0.1` → 200 admin panel → delete carlos → `is-solved` + `User deleted successfully!`. Zero authentication throughout; brute-force correctly killed by zero-302 evidence first.
- From PortSwigger “Host header authentication bypass”: `GET /robots.txt` → `Disallow: /admin`; `GET /admin` true Host → 401 `only available to local users`; same path + `Host: localhost` (HTTP/1.1 SNI/Host split, sessionless) → 200 panel (wiener/carlos + delete links); `GET /admin/delete?username=carlos` same forged Host → 302 → re-read → `User deleted successfully!` + carlos absent + `is-solved`. Locality wording is the header-trust pointer; 5 Burp requests total, no login, no crawling.

### Per-origin credential state must be invalidated when the origin changes
A distinct class from ordinary authorisation failure: the application *did* enforce
access control, correctly, against a value that was valid for a **previous**
principal. The check passed because the leaked credential genuinely authenticates
the request — the defect is that the credential was carried across a trust boundary
and then presented to a different origin.

Recognition shape: a client object, connection, or session handle is documented for
reuse across requests, and it carries **authentication state derived from the first
peer** — negotiated auth tokens, challenge-response headers, session cookies
established by a challenge, bound credentials. The handle is then pointed at a
different origin, and the stale state is emitted to the new peer without re-authenticating.

- **The tell is state continuity, not a failure.** Look for an internal marker that
  spans the boundary: a counter that increments across origins, a nonce or
  client-nonce that does not restart, a negotiated identifier, a handle reused
  across both operations. These prove one in-memory structure survived the boundary
  and turn "state appears to have leaked" into a demonstration.
- **A second, independent control failure often sits next to the first, and finding
  it is what makes the finding unarguable.** The obvious defence is "the application
  misconfigured the credential" — and the decisive test is to change the credential
  explicitly between the two operations. If the *new* credential is then transmitted
  under the *previous* peer's authentication challenge parameters, the bug is
  decoupled from configuration entirely: no reasonable configuration avoids it. This
  converts a configuration question into a code defect.
- **Do not confuse this with the adjacent known issue.** Protection-space directives
  (for example RFC 7616's `domain=` parameter for Digest) are frequently reported
  with an adjacent "this is really the known `domain=` bug" objection. State
  explicitly whether your finding depends on that parsing, and if it does not, say
  so and cite the specification's **default** behaviour: absent explicit directives,
  the default protection space already excludes other origins. That single sentence
  closes the objection before it is raised.
- **Distinguish the two impact primitives explicitly, and claim only what you
  demonstrated.** A leaked challenge-response header typically yields both a
  *replay* primitive (the same header works against the legitimate server within the
  challenge's validity window, impersonating the user for the same URI) and an
  *offline cracking* primitive (the response digest is derived from a known secret
  composed of user, realm and password, so candidate passwords can be tested
  locally). State which you demonstrated. Replay of a *specific already-performed
  request* is a narrow, time-boxed primitive and should not be inflated into general
  impersonation; offline cracking is often the stronger claim, but it requires the
  algorithm to be a fast unsalted hash — state the algorithm and why it is
  crackable, or do not claim it.
- **Scope the affected surface precisely: library versus reference tool.** Where the
  pattern lives in a library API and the bundled command-line tool is unaffected
  because it uses a fresh handle per operation, say that explicitly. It narrows the
  blast radius honestly, identifies who must fix it, and pre-empts the "our own tool
  does not have this problem" reply — while making clear that applications following
  the library's recommended reuse pattern are exactly the affected population.

## Related Concepts

- Vertical privilege escalation (low vs high)
- Horizontal IDOR (A-vs-B, GUID-keyed objects, leak-driven discovery)
- Parameter-based access control (cookie/param trust)
- Method/verb-scoped authorization bypass (verb tampering, body-vs-query parsing split)
- Multi-step workflows with unguarded confirm steps (continuation-flag skipping)
- URL-matching discrepancy (filter-vs-router desync, rewrite-header bypass)
- Navigation-header trust (Referer-gated mutations, exact-value matching; TRACE-disclosed IP headers with loopback spoofing)
- methodology/verification.md (differential testing + state verification)

## Sources

- PortSwigger lab: User role controlled by request parameter (knowledge/portswigger/labs/access-control-user-role-controlled-by-request-parameter.md)
- PortSwigger lab: Method-based access control can be circumvented (knowledge/portswigger/labs/access-control-method-based-circumvented.md)
- PortSwigger lab: Multi-step process with no access control on one step (knowledge/portswigger/labs/access-control-multistep-missing-check.md)
- PortSwigger lab: URL-based access control can be circumvented (knowledge/portswigger/labs/access-control-url-based-circumvented.md)
- PortSwigger lab: Referer-based access control (knowledge/portswigger/labs/access-control-referer-based.md)
- PortSwigger lab: User ID controlled by request parameter, with unpredictable user IDs (knowledge/portswigger/labs/access-control-user-id-unpredictable.md)
- PortSwigger lab: User ID controlled by request parameter with password disclosure (knowledge/portswigger/labs/access-control-user-id-password-disclosure.md)
- PortSwigger lab: Authentication bypass via information disclosure (knowledge/portswigger/labs/infoleak-authentication-bypass-trace-header.md)
- PortSwigger lab: Host header authentication bypass (knowledge/portswigger/labs/host-header-authentication-bypass.md)
