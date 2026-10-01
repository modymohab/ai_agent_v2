# PortSwigger Lab

## Lab

SQL injection vulnerability allowing login bypass

URL: https://0a89007a035baa1d80220dfc000a0029.web-security-academy.net

## Vulnerability Class

SQL injection — authentication bypass via WHERE-clause comment (login form, POST)

## Objective

The lab contains a SQL injection vulnerability in the login function. The goal is to log in as the administrator user without knowing the password.

## Relevant Application Behavior

- E-commerce store with a `My account` link leading to `POST /login`.
- Login form fields: `csrf` (hidden), `username`, `password` — all `required`.
- Failed login → 200 with "Invalid username" (rejection rendered in-page).
- Successful login → 302 redirect to `/my-account?id=administrator`.

## Initial Observations

- The login endpoint requires a per-session CSRF token; crafted requests must fetch the token with a matching session cookie.
- Baseline credentials (`testuser`/`testpass`) → 200, "Invalid username".

## Hypotheses

- H1: The `username` value is interpolated into a credential query like `SELECT ... FROM users WHERE username='<u>' AND password='<p>'`; a single quote would break the query (observable 500/error).
- H2: `administrator'--` in the username comments out the password condition, authenticating without a password.
- H3: If the query structure differs, `' OR 1=1--` variants might be required.

## Attempts

1. Baseline `testuser`/`testpass` → 200 "Invalid username" (reference).
2. `username=administrator'` + arbitrary password → HTTP 500 (interpolation into SQL confirmed).
3. `username=administrator'--` + arbitrary password → 302 to `/my-account?id=administrator` (bypass succeeded).

## What Failed

- Nothing materially; the incremental sequence from lab 1 (baseline → syntax-break → comment bypass) resolved the lab on the first deliberate payload chain. The baseline and syntax-break steps were still necessary to confirm the injection context before asserting a bypass.

## What Worked

`POST /login` with `username=administrator'--` and any password value.

## Burp Observations

- Requests were issued via curl through the Burp-managed environment; the differential (500 vs. 302) was captured at HTTP level without needing browser state.

## Browser Observations

- Not required: the login is a plain HTML form with no JavaScript-driven behavior; HTTP-level testing was sufficient (smallest toolset).

## CLI / Tool Observations

- curl with cookie jars to bind CSRF tokens to sessions (each crafted request fetched a fresh token+cookie pair where needed).
- 500 on `administrator'` (syntax break), 302 on `administrator'--` (bypass) — clean differential.
- Verification of authenticated state via `/my-account?id=administrator` response body.

## Root Cause

The application concatenates the `username` form value directly into a SQL query resembling:

`SELECT ... FROM users WHERE username='<username>' AND password='<password>'`

The payload `administrator'--` closes the username string literal and comments out the remainder (`' AND password='...'`), so the query matches the administrator row using the username condition alone. The password check is never evaluated.

## Verification

- The 302 redirect targeted `/my-account?id=administrator`, indicating the server accepted the credentials.
- Replaying with the session cookie: `/my-account` renders "Your username is: administrator" and a "Log out" link — a real authenticated session, not merely an error page or soft redirect.
- Lab status header changed from "Not solved" to "Solved".

## Impact

Complete authentication bypass as the administrator user without any password knowledge. In a real deployment this grants full account takeover of the administrative account: access to other users' data, administrative functionality, and any action available to that identity.

## Why The Successful Approach Worked

- The single-quote 500 confirmed string interpolation in the credential query (same recognition pattern as lab 1).
- The comment `--` neutralized the trailing `AND password='...'` condition exactly as predicted by the WHERE-clause model.
- The application trusts the query result as proof of valid credentials — data (input) becomes logic (authentication decision).

## Generalization

- Login bypass is WHERE-clause injection applied to authentication: the credential check is a query, so modifying the query modifies the authentication decision.
- Targeted bypass (`known-user'--`) is preferable to blanket tautology (`' OR 1=1--`): it authenticates as a specific, high-value identity and produces deterministic, verifiable state.
- Success criterion differs by context: data disclosure is measured by row counts (lab 1); authentication bypass is measured by an authenticated session state (redirect + account page + session cookie).

## Lessons Learned

- Reused lab 1's incremental methodology on a different injection context with zero failed-bypass attempts — the differential sequence (baseline → syntax break → comment) transfers across injection points.
- CSRF tokens couple requests to sessions; test harness must fetch token and cookie from the same response (cookie jar discipline).
- A 302 to an authenticated page is a stronger success indicator than a 200 body change; verify the resulting session state directly.

## Related Methodology

- methodology/injection.md (authentication bypass context, comment-based trailing-SQL neutralization)
- methodology/authentication.md (empty scaffold at time of this lab)

## References

- Lab: https://portswigger.net/web-security/sql-injection/lab-login-bypass
- Solved instance: https://0a89007a035baa1d80220dfc000a0029.web-security-academy.net
