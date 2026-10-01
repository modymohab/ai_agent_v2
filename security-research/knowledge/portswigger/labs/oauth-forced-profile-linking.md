# PortSwigger Lab

## Lab

Forced OAuth profile linking — https://0ab6001f03f3bb4680530d2000d80069.web-security-academy.net/ (PortSwigger Web Security Academy, OAuth). Provider: https://oauth-0a1600cc0354bb57806d0b6f02c000a2.oauth-server.net. Exploit server: https://exploit-0a2c001a032fbb9080520c56010b0089.exploit-server.net.

## Vulnerability Class

OAuth account hijacking via CSRF on profile attach (missing `state`/CSRF on `/oauth-linking`). Distinct from implicit-flow email confusion.

## Objective

CSRF-attach own social profile to admin's blog account → OAuth-login as administrator → `/admin` → delete carlos. Creds: blog wiener:peter; social peter.wiener:hotdog. Admin opens exploit-server content with active session.

## Initial Observations

- Homepage: shop, no OAuth surface unauthenticated. Title `Forced OAuth profile linking`.
- `POST /login` wiener:peter (+csrf) → 302 `/my-account?id=wiener` + session.
- `/my-account?id=wiener` holds attach link: provider `/auth?client_id=…&redirect_uri=https://<lab>/oauth-linking&response_type=code&scope=openid%20profile%20email` — **no `state` parameter**.
- Social login link (logged-out page): same provider, `redirect_uri=…/oauth-login` (link vs login endpoints differ).

## Hypotheses

- H1: `/oauth-linking?code=` binds the code's social identity to WHOEVER's session redeems it, with no CSRF/state — so a victim redeeming MY code links MY profile to THEIR account. (Confirmed.)
- H2: `/oauth-login` then resolves my social profile to the linked (admin) account. (Confirmed: `administrator` render.)
- H3: admin panel reachable by the hijacked session; delete is GET-able like prior `/admin/delete?username=` labs. (Confirmed: GET → 302 → solved.)

## Attempts

1. Baseline attach dance (wiener blog session + provider login peter.wiener:hotdog → consent) → captured linking code `uPi44PFo…` WITHOUT redeeming (stopped at the 302 to `/oauth-linking?code=`).
2. Stored exploit `/exploit` (`<script>location='https://<lab>/oauth-linking?code=<CODE>'</script>`) → DELIVER_TO_VICTIM → access log showed 2× `Mozilla/5.0 (Victim)` hits on `/exploit/`.
3. Fresh `/oauth-login` code → redeemed in clean jar → `/my-account` rendered `administrator` (was `peter.wiener027231` before the victim visit — first login attempt pre-attach proved the negative).
4. `GET /admin` → 200 panel (delete links carlos/wiener/peter.wiener027231), `is-notsolved`.
5. `GET /admin/delete?username=carlos` → 302 → re-read → `User deleted successfully!` + `is-solved` ×2. No failed exploit variants needed.

Provider quirk: its HTTP/2 endpoint sends `keep-alive: timeout=5` (connection-specific header) which breaks curl over h2 — forced `--http1.1` for all provider requests.

## What Failed

- First `/oauth-login` test (before victim visit) yielded shadow identity `peter.wiener027231`, not admin — correct negative that framed the attach proof.
- Browser-Control domain dialog never cleared; entire lab done via curl + raw sockets + exploit-server form POSTs (field set: responseFile/responseHead/responseBody/urlIsHttps/formAction; log via ACCESS_LOG → `/log`).

## What Worked

Victim redeeming attacker code in admin session → profile bound to admin → self OAuth login lands in admin account → standard admin delete.

## Burp Observations

Burp MCP not used (flaky on prior hosts; curl/socket harness sufficient and byte-exact). No Burp dependency for this lab.

## Browser Observations

Homepage/account mapping only (permission dialog blocked automation); all state-changing work via curl.

## CLI / Tool Observations

- curl cookie jars per identity (blog-wiener, provider-social, fresh-victim-test) kept strictly separate — no cross-contamination.
- Manual redirect handling (`-D` + no `-L`) at every OAuth hop; code captured from `Location`, never auto-redeemed.
- Exploit-server driven entirely over HTTP (STORE/DELIVER_TO_VICTIM/ACCESS_LOG→`/log`); victim UA `Mozilla/5.0 (Victim)…Chrome/151` distinguished from curl in log.

## Root Cause

Profile-attach endpoint trusts the session cookie alone: `GET /oauth-linking?code=<attacker-code>` executed by the admin's browser binds the attacker's IdP identity to the admin's local account. No `state`, no CSRF token, no confirmation. Login then resolves IdP identity → most recently linked local account (admin).

## Verification

- Pre-attach negative: same login flow rendered `peter.wiener027231` (shadow), not admin.
- Post-visit: identical flow rendered `Your username is: administrator` (fresh jar, OAuth-only session — no password, no wiener cookie).
- Admin panel 200 + delete links; delete 302; re-read `is-solved` + success string + carlos absent. Marker + state, not status alone.

## Impact

Full admin account takeover with only self-owned social credentials + one victim pageview; demonstrated via carlos deletion. Same primitive yields full admin-panel control.

## Why The Successful Approach Worked

Attach and login are separate bindings sharing one IdP-identity key: poisoning the attach pointer (via CSRF) retargets all future lookups of that identity, including the attacker's own login, into the victim account.

## Generalization

Wherever IdP-linking lacks `state`/CSRF: mint own code (stop before redeem), plant it cross-session (CSRF page / victim visit), verify by identity render flipping from shadow/self to victim on an otherwise identical login.

## Lessons Learned

- `state`-absence in the attach URL is the tell — check before any code games.
- Never auto-follow at the code-issuing hop; the code is single-use currency for the victim, not for you.
- Prove the negative first (shadow-identity login) so the admin render is unambiguous proof, not assumption.
- Victim timing: poll `/log` for non-curl UA; codes expire — mint, plant, deliver back-to-back; re-loop with a fresh code if the render doesn't flip.
- Provider h2 + `keep-alive` header breaks curl — `--http1.1` for OAuth providers.

## Related Methodology

- methodology/oauth-sso.md (OAuth tracing discipline, identity-render proof; extended below with linking-CSRF variant)
- methodology/verification.md (negative-then-positive identity differential, re-read rule)
- methodology/access-control.md (impersonation → admin action proof)

## References

- Lab description: https://portswigger.net/web-security/oauth/lab-oauth-forced-oauth-profile-linking
- Prior lab (tracing precedent, different flaw): knowledge/portswigger/labs/oauth-authentication-bypass-implicit-flow.md
