# OAuth / SSO Methodology

## Core Concept

OAuth integrations fail when the client binds the local session to attacker-influenced fields (email, username) instead of the token owner's verified identity. The access token proves SOMEONE authenticated — the binding step decides WHO the session belongs to, and that decision must come from the provider, not the client request.

## Security Boundary

Intended: session identity === token owner's provider-verified identity.
Violated when: client-supplied `email`/`username` alongside a valid (but unrelated) token selects a different local account.

## Recognition Patterns

- No local `/login` (404); `/my-account` → `/social-login` → meta-refresh to OAuth `auth` (`response_type=token` = implicit flow).
- Callback page JS reveals the contract: fragment token → provider `/me` (Bearer) → `POST /authenticate {email, username, token}`.
- Opaque access tokens (not JWTs) — capturable from the resume redirect's fragment without a browser.
- Profile-attach flow with a stateless linking endpoint (`/oauth-linking?code=`, no `state`/CSRF): the code binds its IdP identity to WHOEVER's session redeems it — a victim redeeming your code links your identity to their account.

## Common Locations

- `/social-login`, `/oauth-callback` (client contract source), `/authenticate` (binding decision), provider `/auth`, `/interaction/*`, `/me`.
- `/my-account` (identity render), `/` authenticated (marker surface).

## Indicators

- Spoofed `username` + own token → session renders token owner = username ignored for binding.
- Garbage token → 500 = token validated server-side (500-vs-302 token oracle).
- Victim `email` + own token → session renders victim = email confusion confirmed.

## Testing Methodology

1. Trace the full baseline flow first (auth → provider login → consent → resume → fragment token) with valid low-priv credentials.
2. Read the callback JS to extract the exact `/authenticate` contract (field names, token source).
3. Baseline `/me` with own token (records true owner identity/email).
4. Field-authority matrix, one axis at a time: spoofed username + valid token → garbage token → victim email + valid token. Each variant gets an identity-render check.
5. Forced-linking extension: where an attach URL carries no `state`, mint your own code (provider login as yourself, stop at the 302 to the linking callback — never redeem it yourself), plant it in a victim-visited page auto-navigating to the linking endpoint, deliver, and poll for the victim hit. Prove the negative FIRST (identical self-login renders a shadow/self identity), then show the flip (same login renders the victim, e.g. `administrator`). Codes expire — mint, plant, deliver back-to-back; re-loop fresh on failure. Prove takeover via identity render + authenticated marker; no admin panel assumption (some labs end at impersonation).

## Verification

- Same-endpoint differentials (wiener-render vs carlos-render) isolate the confused axis exactly.
- Identity proof is the rendered username AND email; solved marker confirms.
- Deterministic end-to-end; fragment tokens need no browser to capture (resume redirect carries them).

## Common Failure Modes

- Assuming an admin panel endgame (verify the actual marker surface; some labs solve at impersonation).
- Combining spoofed fields in one request (breaks axis adjudication).
- Treating 302 as proof (check the rendered identity — H1's 302 rendered wiener, not administrator).
- Needing a browser for implicit flow (resume redirect + direct POSTs suffice).

## Impact Considerations

- Full account takeover of any email-known user with only a self-owned token — no victim interaction, no password, no brute-force.

## Lessons Learned

- From PortSwigger “Authentication bypass via OAuth implicit flow”: username-spoof → wiener render (falsified), garbage-token → 500 (oracle mapped), victim-email + own token → carlos render + `/` `is-solved` (~12 requests). Field-authority matrix, one axis at a time.
- From PortSwigger “Forced OAuth profile linking”: attach link with no `state` → own linking code minted and planted via CSRF auto-navigation → victim (`Mozilla/5.0 (Victim)`) redeemed it → identical self-login flipped from shadow `peter.wiener027231` to `administrator` → `GET /admin/delete?username=carlos` → 302 → re-read `is-solved`. Manual redirect handling at every hop (never auto-redeem your own code); per-identity cookie jars; `--http1.1` for providers sending `keep-alive` over h2.

## Related Concepts

- methodology/authentication.md (302+session proof, dual-surface markers)
- methodology/access-control.md (impersonation as escalation proof)

## Sources

- PortSwigger lab: Authentication bypass via OAuth implicit flow (knowledge/portswigger/labs/oauth-authentication-bypass-implicit-flow.md)
- PortSwigger lab: Forced OAuth profile linking (knowledge/portswigger/labs/oauth-forced-profile-linking.md)
