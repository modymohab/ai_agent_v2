# PortSwigger Lab

## Lab

Authentication bypass via OAuth implicit flow

URL: https://0a80009f042512d780291c7400220064.web-security-academy.net/

## Vulnerability Class

OAuth account linking confusion — `/authenticate` matches the local account by client-supplied `email` without verifying it belongs to the token owner → account takeover (carlos)

## Objective

Log in as `carlos`. Solved when the authenticated homepage flips to `is-solved` (no admin panel exists in this lab).

## Initial Observations

- CURRENT EVIDENCE: no local `/login` (404); `/my-account` → 302 `/social-login` → meta-refresh to OAuth `auth` endpoint (`response_type=token`, client/redirect/nonce/scope observed).
- CURRENT EVIDENCE: full OAuth dance via Burp (auth → interaction → wiener:peter login → consent → resume) → `oauth-callback#access_token=<opaque>` (fragment, server never sees it).
- CURRENT EVIDENCE: `GET /oauth-callback` body (726 bytes) reveals the client contract: read fragment token → `GET <oauth>/me` (Bearer) → `POST /authenticate {email, username, token}` → `/`.

## Hypotheses

- H1: `/authenticate` trusts `username` without verification — REJECTED (`username:administrator` + own token → session renders wiener).
- H2: garbage token → 500 (server DOES validate the token via `/me`; identity comes from token owner).
- H3: account matched by client-supplied `email` without token-email binding — `email:carlos@carlos-montoya.net` + own token → carlos session.

## Attempts

1. Flow trace (5 Burp requests): auth, interaction login, resume, consent, callback-token capture.
2. Callback-JS read (1 req): the exfiltration-free attack surface (direct `/authenticate` POSTs, no browser needed).
3. `/me` with own token → `{"sub":"wiener",...,"email":"wiener@hotdog.com"}` (baseline identity).
4. H1 (`username:administrator`) → 302 + session → renders wiener. Falsified — fields not blindly trusted for username.
5. Garbage token → 500. Token validated; 500-vs-302 is the token oracle.
6. H3 (`email:carlos@carlos-montoya.net` + own valid token) → 302 + session → renders `Your username is: carlos` + `carlos@carlos-montoya.net`. CONFIRMED.
7. Authenticated `GET /` → `is-solved`/`Solved`/congratulations. SOLVED (~12 requests total).

## What Failed

- Username confusion (H1) — correct falsification that redirected to the email axis.
- Assumed `/admin` endgame — 404 JSON; this lab has no admin panel (goal is takeover itself, proven by marker).

## What Worked

Email-confusion at `/authenticate`: valid own token + victim email → victim session.

## Burp Observations

- Entire flow (OAuth dance, callback-JS, `/me`, all `/authenticate` variants, identity + marker proofs) via Burp MCP with full request/response evidence. Fragment handling noted (Burp/CLI capture the token from the resume redirect, no browser needed).

## Browser Observations

- Not required. Pure HTTP flow despite the browser-oriented implicit grant. Browser Control MCP correctly unused.

## CLI / Tool Observations

- None needed beyond Burp; JSON bodies hand-crafted per variant (one axis at a time: username, then token validity, then email).

## Root Cause

`/authenticate` validates the access token (proves a real OAuth user) but then locates the local account by the CLIENT-SUPPLIED `email` field instead of the token owner's verified email: possession of ANY valid token plus knowledge of the victim's email yields the victim's session. Authentication (valid token) decoupled from authorization identity (unverified email).

## Verification

- H1 302-as-wiener vs H3 302-as-carlos on the same endpoint isolates the email axis exactly.
- Identity render (`Your username is: carlos` + victim email) + authenticated homepage `is-solved`. Deterministic end-to-end.

## Impact

Full account takeover of any user whose email is known/guessable, using the attacker's own valid OAuth token — no victim interaction, no password.

## Why The Successful Approach Worked

- Read the callback JS before theorizing (revealed the exact JSON contract + the spoofable fields).
- One-axis variants (username → token → email) instead of combined guessing; H1's failure redirected spend to the email axis.
- Garbage-token 500 established the token oracle, bounding the flaw to field-trust (not token absence).

## Generalization

- For OAuth callback endpoints accepting identity fields alongside tokens: test each field's authority independently (spoof username with valid token; garbage token; victim email with valid token) — the matrix isolates which field the server actually binds the session to.
- Fragment-flow tokens are capturable server-side from the resume redirect — no browser required for implicit-flow testing.

## Lessons Learned

- First OAuth family lab in the KB (oauth-sso.md was an empty stub; zero prior OAuth notes — grep-verified).
- 500-vs-302 on `/authenticate` is a token-validity oracle worth mapping before field-confusion tests.

## Related Methodology

- methodology/oauth-sso.md (first content — implicit-flow field-authority matrix; update justified, applied separately)
- methodology/authentication.md (302+session proof, dual-surface markers)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/oauth/lab-oauth-authentication-bypass-via-oauth-implicit-flow (objective only; solution not consulted — email axis found via H1-falsification redirect)
- Solved instance: https://0a80009f042512d780291c7400220064.web-security-academy.net/ with `{email:carlos@carlos-montoya.net, username:wiener, token:<own-valid>}` → carlos session
