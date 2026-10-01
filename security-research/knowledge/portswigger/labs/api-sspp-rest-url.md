# PortSwigger Lab

## Lab

Exploiting SSPP in a REST URL — https://0a380049041854a7824b380a009900fc.web-security-academy.net/ (PortSwigger Web Security Academy, API testing). No seeded creds (only carlos + administrator exist); no inbox, no registration.

## Vulnerability Class

Server-side parameter pollution in REST path: username embedded in internal API path with `..` normalization + `field` sub-resource + versioned routes; token disclosure. NOT injection.

## Objective

Log in as administrator; delete carlos.

## Initial Observations

- `/forgot-password` JSON API (csrf + username): valid → masked email; invalid → typed "does not exist" (echoes input); wiener absent.
- `A/../B` normalizes to B (multi-level too); sub-paths → "Invalid route"; 4+ `..` escapes to internal web server (HTML 404 proxied); `&` does NOT split (literal lookup); case/space/NUL → 500; `%2e`-encoded dots NOT decoded (single-decode).

## Hypotheses

- H1: internal route table enumerable via `..`-escape differentials (HTML proxy vs JSON route error). Partially — mapped layers, no direct target.
- H2: sub-resource/field pattern (query-lab family) exists under versioned path. Confirmed post-nudge via openapi disclosure.

## Attempts

~80 probes: oracle (~24 names), `&`-matrix (dup first-wins, empty/case rules), `#`/`%23`/NUL/space/case crash taxonomy, backslash/double-encoding (literal), sibling enumeration (15 names, all Invalid route), absolute paths (`/admin` literal-lookup), query-in-path (`?token=` etc.), version hunting (v0–v100, headers, query, methods, bodies), API wordlist (295, all 404), login pollution, credential guesses.
- Post-nudge (stuck clause): `..`-depth ladder → `../../../../openapi.json%23` → disclosed `/api/internal/v1/users/{username}/field/{field}` → `administrator/field/foo%23` (version-gated error) → `field/email%23` (normal) → JS `passwordResetToken` name → `../../v1/users/administrator/field/passwordResetToken%23` → token → reset → login → delete → `is-solved`.

## What Failed

- Everything assuming query-lab transfer (`&field=` without path shape → Invalid route; `reset_token` vs actual `passwordResetToken` naming).
- Blind sibling/wordlist enumeration without the definition (route table unknowable; definition discloses it).
- Missed page-specific `/static/js/forgotPassword.js` initially (same mistake as query lab).

## What Worked

Depth-laddered escape to the API definition → definition-driven field/version construction → token disclosure → standard reset/login/delete.

## Burp Observations

Not used (curl sufficed).

## Browser Observations

Mapping only.

## CLI / Tool Observations

- curl jars; `%2F`-preserving value construction (curl `--data-urlencode` double-encodes pre-encoded input — track counts).
- `..`-depth ladder (1..6) to separate outer validation, API routing, and web-server layers by error shape.

## Root Cause

Username concatenated into internal REST path (`/api/internal/v1/users/<input>/...`) with `..` normalization; traversable to the API definition (`openapi.json`), which documents a `field` sub-resource; versioned field gating bypassed by explicit version in traversed path — yielding arbitrary user fields including `passwordResetToken`.

## Verification

- Differential chain: definition leak → field/foo (version error) → field/email (normal) → versioned passwordResetToken (token JSON).
- Token use: reset 302 → admin login 302 + `Your username is: administrator` → panel 200 → delete 302 → `is-solved` + success string.

## Impact

Unauthenticated reset-token disclosure for any user (demonstrated administrator) → full takeover → victim deletion.

## Why The Successful Approach Worked

Read the API's own definition (via traversal) instead of guessing its routes; combined path traversal + field selector + explicit version exactly as the definition describes.

## Generalization

For REST-path SSPP: ladder `..` depth to map layers (validation vs API routing vs web server); escape to the API definition (`openapi.json` + `%23` truncation); build field/version paths from the definition; read page JS for exact field names (they differ per lab).

## Lessons Learned

- `..`-depth laddering attributes errors to layers — don't enumerate blindly without the definition.
- Trailing `%23` matters on escape payloads (truncates server suffix, same as query family).
- Field/token names differ per instance (`reset_token` vs `passwordResetToken`) — always read THIS lab's JS.
- Single-decode confirmed (`%2e` inert, `%2F` active) — craft traversal in the decoded alphabet only.

## Related Methodology

- methodology/api-security.md (SSPP REST-path pattern added below)
- methodology/verification.md (layer-attribution differentials, token-use proof)
- methodology/injection.md — compared, NOT applicable (no interpreter; path-assembly flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/api-testing/server-side-parameter-pollution/lab-exploiting-server-side-parameter-pollution-in-rest-url
- Sibling lab (query family): knowledge/portswigger/labs/api-sspp-query-string.md
