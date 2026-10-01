# PortSwigger Lab

## Lab

User ID controlled by request parameter with password disclosure

URL: https://0ae9006e03610a3a80137cf70065002c.web-security-academy.net

## Vulnerability Class

Access control — horizontal IDOR with password disclosure in victim pages, chained to vertical escalation (administrator login → admin panel → delete carlos)

## Objective

Delete user `carlos` (established by evidence: no submit mechanism exists; `/admin` as administrator exposes delete links; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Shop; login `wiener:peter` → 302 `/my-account?id=wiener` (USERNAME-string IDs, unlike GUID lab). Own page: username/email + update forms, NO secret shown.
- `GET /my-account?id=carlos` and `?id=administrator` as wiener → 200 each victim's page (no ownership check — IDOR sibling of GUID lab, different ID shape and payload).

## Hypotheses

- H1: Victim pages disclose usable credentials (lab title) — inspect page SOURCE, not just rendered text.
- H2: Disclosed password enables login as that user; administrator's gives admin panel.
- H3: Admin panel permits deleting carlos → solved.

## Attempts

1. Own-page baseline (wiener: no secret) vs `?id=carlos` page (rendered text also shows no secret) — rendered-text comparison insufficient; inspected raw HTML inputs.
2. Raw HTML of carlos page: `name=password value='muzfz591ku3d3b43429g'` in the update-password form. H1 confirmed — pre-filled credential.
3. Login `carlos:<disclosed>` → 302 `?id=carlos`, account renders carlos — credential valid — but `/` still `is-notsolved` and `/admin` as carlos → 401. Objective is NOT carlos-login (differs from assumption; evidence redirected to administrator).
4. No `submitSolution` mechanism on homepage (grep) — submission-style solve ruled out.
5. Same source inspection on administrator page: `value='peciygxkojosyc5cq2gg'` → login → 302 `?id=administrator` → `GET /admin` → 200 `Users wiener - Delete carlos - Delete`. H2 confirmed.
6. `GET /admin/delete?username=carlos` → 302; panel `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Rendered-text-only comparison (both pages “show nothing”) — the secret lived in input VALUES, not text.
- Stopping at carlos-login (valid creds, wrong objective) — solved marker is the arbiter, not credential validity.
- `admin` id → 302 (unknown-user handling, not a bypass).

## What Worked

- Source-level IDOR inspection → two credential disclosures → administrator login → admin delete → solved.

## Burp Observations

- Not used via Burp MCP; curl + HTML-source grep sufficed.

## Browser Observations

- Not required. (Browsers render pages but hide pre-filled password values no differently — source inspection over HTTP was the tool.)

## CLI / Tool Observations

- curl session jars per identity (wiener/carlos/administrator kept separate); input-tag extraction for `value=` secrets; solved-marker grep as arbiter.

## Root Cause

Missing object-level authorization on `/my-account?id=` COMBINED with server-side pre-filling of the password-update field with the victim's CURRENT password in cleartext. Any authenticated user reads any account's password from page source and logs in as them — here chained from low-priv to administrator to admin-panel deletion.

## Verification

- Own-vs-victim differential (same session; id swap only) for both carlos and administrator.
- Credential validity: each disclosed password yields 302 + identity-rendered account page.
- Chain proof: carlos-login insufficient (401 admin, not solved) vs administrator-login → 200 panel → delete → `User deleted successfully!` + carlos absent + `is-solved`. Each link evidenced; deterministic.

## Impact

Any-user password disclosure → account takeover at will (demonstrated twice) → privilege escalation to administrator → arbitrary user deletion. Cleartext password handling compounds the IDOR into full compromise.

## Why The Successful Approach Worked

- Inspected SOURCE after rendered text showed nothing (secret class: input values, not content).
- Let the solved marker (not assumptions) pick the objective: carlos-login → not solved → kept climbing to administrator → delete → solved.
- Separate sessions per identity kept each link attributable.

## Generalization

- On IDOR pages, always inspect raw HTML for pre-filled secrets (passwords, API keys in values/hidden fields, tokens) — rendered text is half the surface.
- Disclosed credentials chain: victim → higher-privileged victim → admin function; verify EACH link (login works ≠ objective met).
- Solved-marker arbitration beats objective-guessing when descriptions are unread.

## Lessons Learned

- Sibling labs share the flaw family (IDOR) but differ in ID shape (GUID vs username), payload (key vs password), and objective (submit vs delete) — re-derive all three per instance.
- Pre-filled password fields are a distinct disclosure class worth its own grep pattern (`value=` on password inputs).

## Related Methodology

- methodology/access-control.md (IDOR with credential disclosure → login chain — to be extended)

## References

- Solved instance: https://0ae9006e03610a3a80137cf70065002c.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
