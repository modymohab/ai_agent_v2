# PortSwigger Lab

## Lab

Exploiting server-side parameter pollution in a query string — https://0a1d00f9041511c881d2757c00690028.web-security-academy.net/ (PortSwigger Web Security Academy, API testing). No seeded creds (wiener invalid; only carlos + administrator exist per oracle); no inbox, no registration.

## Vulnerability Class

Server-side parameter pollution (query string): user input concatenated into an internal API query; injected `field` selector + `#` truncation disclose arbitrary user fields including reset tokens. NOT injection.

## Objective

Log in as administrator; delete carlos.

## Initial Observations

- `/forgot-password` (csrf + username) returns JSON API responses: valid user → `{"type":"email","result":"*****@..."}`, invalid → `{"type":"ClientError",...,"Invalid username."}`. Oracle: only carlos + administrator exist.
- Page-specific JS overlooked initially (`/static/js/forgotPassword.js` — homepage-only JS sweep missed it).

## Hypotheses

- H1: username value is split server-side on `&` with strict name allowlist (error oracle maps it). Confirmed via 17-candidate matrix (only `username` duplicates pass).
- H2: `#` truncates server-appended suffix (token) → "Field not specified". Confirmed (`administrator#foo`, `%23` variants).
- H3: `&field=<F>#` combination selects returned field; `reset_token` leaks admin's token. Confirmed after solution nudge (stuck clause) — then verified independently end-to-end.

## Attempts

1. Account oracle (~24 names) → {carlos, administrator}; credential guesses (incl. empty) failed.
2. `&`-matrix (17 names) → only `username` passes; first-username drives lookup (empty-first invalid; `USERNAME` case rejected; empty middle name rejected).
3. `#`/`%23`/NUL probes → "Field not specified." / 500 ISE (no leak) — truncation + crash characterized, not weaponized alone.
4. Form-field vs in-value test → "not supported" comes from in-value query parsing (separate form fields ignored) — located the SSPP layer.
5. Binding-divergence attempts (dup second invalid → ignored; no inbox to observe binding) — dead without token visibility.
6. Post-nudge: `administrator&field=x#` → "Invalid field." vs `administrator#` → "Field not specified." (combination semantics); `field=email#` → normal (valid field); JS read → `reset_token` endpoint shape; `field=reset_token#` → `{"type":"reset_token","result":"069i2ltyonigls3jl7lobixkkwuxx674"}`.
7. `/forgot-password?reset_token=<leaked>` → set Adminpass123 → login administrator (302) → `/admin` 200 → delete carlos 302 → `is-solved` ×2.

## What Failed

- ~45 pre-nudge probes circling binding-divergence without inbox observability (unwinnable angle — token visibility, not binding, was the flaw).
- Credential guessing; NUL crash (500, no leak); double-encoding (`%2526` treated as data).

## What Worked

Field-selector injection + fragment truncation + JS-derived field name → direct token disclosure → standard reset → login → delete.

## Burp Observations

Not used (curl sufficed; Repeater/Intruder are GUI equivalents for the field matrix).

## Browser Observations

Mapping only.

## CLI / Tool Observations

- curl jars per phase; form-encoded `%26`/`%23` inside values (careful: `--data-urlencode` double-encodes pre-encoded input — account for decode counts).
- Page-specific JS enumeration (not just homepage) for endpoint/param contracts.

## Root Cause

Forgot-password builds an internal API query by concatenating the (once-decoded) username value, then appending its own `&token=`. It validates injected param names against an allowlist that includes a `field` selector controlling which user attribute the API returns, and it never re-encodes `#` — so `username=administrator&field=reset_token#` yields a query asking for the victim's reset token while truncating the server's own suffix.

## Verification

- Differential chain: `field=x#` → Invalid field; `field=email#` → normal; `field=reset_token#` → token JSON (each step isolates one axis).
- Token use: reset submit 302 → admin login 302 + `Your username is: administrator` → panel 200 → delete 302 → `is-solved` + success string.

## Impact

Any unauthenticated client reads arbitrary users' reset tokens (demonstrated administrator) → full account takeover → victim deletion.

## Why The Successful Approach Worked

Combined the two primitives the errors advertised separately (`&` splits into validated params; `#` cuts the server suffix) with the field name the JS advertised, turning a blind reset flow into a token-disclosure oracle.

## Generalization

Wherever user input is concatenated into a server-side query: map the parser with `&unknown=` (allowlist), `#` (truncation), `field`-like selectors (combination), and read page-specific JS for internal endpoint/param names before brute-forcing values.

## Lessons Learned

- Sweep page-specific JS, not just homepage JS, for API contracts (missed `forgotPassword.js` initially — cost ~40 probes).
- Bare `{"error":...}` (no type/code) vs typed errors fingerprints outer app vs internal API — attribute oracles to layers before theorizing.
- Test the `&field=x#` COMBINATION, not just each operator alone — truncation + injection compose.
- `--data-urlencode` double-encodes `%` — track decode counts explicitly when crafting nested encodings.
- No-inbox does not mean no-token: field-selector disclosure bypasses email entirely.

## Related Methodology

- methodology/api-security.md (SSPP query-string pattern added below)
- methodology/verification.md (axis-isolating differentials, token-use proof)
- methodology/injection.md — compared, NOT applicable (no interpreter; query-assembly flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/api-testing/server-side-parameter-pollution/lab-exploiting-server-side-parameter-pollution-in-query-string
