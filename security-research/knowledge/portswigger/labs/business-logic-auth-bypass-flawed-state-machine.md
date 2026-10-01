# PortSwigger Lab

## Lab

Authentication bypass via flawed state machine

URL: https://0a66008503e4989e83276ec4000f007c.web-security-academy.net/

## Vulnerability Class

Business logic — staged login (credentials → role selection) defaults to administrator when the role-selection step is never requested; skipping the step bypasses role assignment entirely

## Objective

Bypass authentication staging, access the admin panel, delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: CSRF-bound login → 302 `/role-selector` (STATE1: authed, role pending); role form offers `user`/`content-author` + csrf (STATE2 = selection).

## Hypotheses

- H1: unlisted `role=administrator` accepted — REJECTED (redirect `/`, wiener session, `/admin` 401).
- H2: stage skip (direct `/my-account`, anon role GET/POST) — REJECTED (bounced to `/login`; anon POST → 400).
- H3 (after stuck research): DROPPING the `GET /role-selector` request entirely leaves the default administrator role.

## Attempts

1. H1 (role=administrator) → `/` + wiener session + 401 admin. Falsified — allowlist enforced on values.
2. H2 variants (skip-to-account, anon GET/POST role) → login-bounce / 400. Falsified — step presence enforced, just not the right property.
3. Legitimate `role=user` mapping (full wiener session, identity + change-email) — baseline for contrast.
4. H3, attempt 1 (urllib default client): login POST auto-FOLLOWED the 302 → `GET /role-selector` fired implicitly → homepage WITHOUT admin link. FALSE NEGATIVE caused by the HTTP client, not the server — critical catch.
5. H3, attempt 2 (redirect-following DISABLED = true drop): login POST (302 un-followed) → direct `GET /` → Admin link present → `GET /admin` → roster (wiener, carlos). CONFIRMED — never requesting the step defaults to administrator.
6. `GET /admin/delete?username=carlos` → 302 (unhandled-302 traceback on one run proved nothing lost — session workflows rerun cleanly) → re-read: `is-solved` ×2, roster (wiener) only. SOLVED.

## What Failed

- Value confusion, stage skip, anon access (3 clean falsifications defining the flaw as step-OMISSION, not step-abuse).
- HTTP-client artifact (auto-followed redirect silently executed the skipped step) — tooling behavior mistaken for server behavior until isolated.

## What Worked

Drop `GET /role-selector` (redirects disabled) → default-admin session → delete → solved.

## Burp Observations

- Login/role forms + denial mapping via Burp-equivalent flows; redirect control via CLI (NoRedirect discipline — Burp Repeater/Proxy drop is the GUI equivalent).

## Browser Observations

- Not required. Pure HTTP workflow (browsers auto-follow redirects — must be suppressed for skip testing). Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `NoRedirect` opener for true step omission; `http.cookiejar` chains; error-tolerant wrappers (302-as-success on delete).

## Root Cause

Role defaults to administrator and is only ever DOWNGRADED by visiting the role-selection step: the application assumes the step always runs (client-driven state machine with no server-side step-completion enforcement). Omitting the step preserves the privileged default.

## Verification

- Value/skip/anon falsifications vs drop-success isolate omission exactly (same session shape, one request removed).
- Delete → 302 → re-read: `is-solved` + victim absent. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Any valid low-priv credential (wiener) becomes administrator by skipping one request: roster + arbitrary deletion (carlos deleted), zero exploit payload.

## Why The Successful Approach Worked

- Stuck provision supplied the exact omission shape after genuine exhaustion (values/skip/anon all falsified).
- Caught the client artifact (redirect auto-follow) before concluding — the false negative would otherwise have killed the true theory.

## Generalization

- NEW reusable variant for methodology/business-logic.md: step-omission with redirect suppression (clients auto-follow — disable it or drop in proxy); defaults observed pre-step vs post-step distinguish default-privileged machines.

## Lessons Learned

- Browsers and default HTTP clients FOLLOW redirects: step-skip tests REQUIRE redirect suppression (NoRedirect/drop), else the "skipped" step executes implicitly and falsifies true theories.
- Unlisted-value rejection + skip rejection ≠ secure machine — omission is a third axis beyond values and order.

## Related Methodology

- methodology/business-logic.md (step-omission variant — genuinely new; update justified, applied separately)
- methodology/verification.md (omission differentials + victim-state proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description + external writeups for this exact slug (hypothesis sources after stuck checkpoint: drop-GET shape; re-verified with redirect suppression)
- Solved instance: https://0a66008503e4989e83276ec4000f007c.web-security-academy.net/ with dropped role-selector → delete carlos
