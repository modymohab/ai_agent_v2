# PortSwigger Lab

## Lab

Username enumeration via different responses

URL: https://0abe004f0318f770822de77c001800b7.web-security-academy.net/

## Vulnerability Class

Authentication – username enumeration via overtly different login failure messages (`Invalid username` vs `Incorrect password`) → password brute-force → account takeover (agenda)

## Objective

Enumerate a valid username, brute-force its password, access the account (solved marker flips on authenticated homepage visit). Established by `is-solved` after `agenda:princess` login + `/` visit. Official description not fetched; Academy candidate lists used as published inputs.

## Initial Observations

- Blog + `/my-account`; login form has NO csrf (simpler than prior auth labs).
- `POST /login notauser123:wrongpassXYZ` → 200 `Invalid username` (overt message baseline).
- `POST /login administrator:wrongpass` → 200 `Invalid username` – administrator does NOT exist here (common-name anchoring refuted immediately; per-instance account base).
- Hand-tried wiener/carlos/peter/admin/user/guest/test → all `Invalid username` – need the real candidate list, not memory.
- Stored `methodology/authentication.md` (READ fully for this lab: enumerate-first economics, oracle families, 302+session proof standard). Prior labs: subtle-space enumeration + 2FA logic (index entries; full contents not re-read – overt oracle here differs anyway).

## Hypotheses

- H1: Failure messages distinguish unknown vs known users overtly (`Invalid username` vs `Incorrect password`-style). Evidence needed: one candidate from Academy list returning the second message.
- H2: Enumerated user's password falls to the Academy password list (single 302 among 200s). Evidence needed: 302 + session + redirect naming user.
- H3: Authenticated session + account render + homepage marker = proof chain.

## Attempts

1. Baseline invalid login (raw bytes recorded) + administrator probe (ruled out) + 7 hand guesses (all invalid – stopped guessing, switched to lists).
2. Fetched Academy lists (`auth-lab-usernames`, `auth-lab-passwords`): meta-description truncated (`...`), body text truncated mid-word – extracted FULL lists (101 + 100) from `<code class="code-scrollable">` block to `/tmp` (outside repo, per methodology).
3. Username scan (101 × fixed wrong password): 100× `Invalid username`, exactly one `Incorrect password` → **`agenda`** – H1 confirmed (overt oracle, no byte-forensics needed).
4. Password scan (100 × agenda): 99× 200, exactly one 302 → **`princess`** – H2 confirmed.
5. Burp `POST /login agenda:princess` → 302 to `/my-account?id=agenda` + `Set-Cookie: session` → `GET /my-account?id=agenda` → 200 renders `agenda`/`agenda@normal-user.net` (identity proof) but banner still `is-notsolved` → `GET /` with session → `is-solved`/`Solved`/`Congratulations` – H3 confirmed (marker flips on authenticated homepage visit here).

## What Failed

- Hand-guessed usernames (8 names incl. administrator) – wrong account base for this instance; stopped after evidence (administrator invalid) instead of guessing further.
- Meta/body text list extraction (truncated) – switched to `<code>` block parse (101+100 exact).

## What Worked

- Overt-oracle population scan → single-user brute-force (enumerate-first: 101+100 requests vs 10100 cluster bomb) → session → identity render → marker.

## Burp Observations

- Baseline, administrator probe, login proof (302 + session + redirect target), identity render, final proof (`200 is-solved`) via Burp MCP.
- Bulk scans via curl loops (101 + 100; Burp-per-request would add no value; Intruder equivalent).

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `curl --data-urlencode` loops with `grep is-warning` oracle filter; response-code filter for 302-outlier. Python for list extraction. No scanner/crawler/fuzzer.

## Root Cause

Login failure messages leak account existence: unknown usernames → `Invalid username`, known username + wrong password → `Incorrect password`. Attacker enumerates the user population with a fixed wrong password, then brute-forces only that account's password. No rate limiting/throttling observed (201 sequential auth attempts uninterrupted).

## Verification

- Oracle determinism: `agenda` → `Incorrect password` reproduced across scan + targeted re-requests; 100 others uniformly `Invalid username`.
- Password proof: single 302 + `Set-Cookie: session` + `Location: /my-account?id=agenda` among 100× 200.
- Identity proof: account page renders `agenda`; solved marker on authenticated `/` (noted: marker flips on homepage visit, not on account page – checked both, reported honestly).

## Impact

Full account takeover of `agenda` (authenticated session, PII email render). Same primitive yields admin takeover wherever the enumerated account is privileged.

## Why The Successful Approach Worked

- Quit hand-guessing after 8 failures (evidence: administrator invalid → different account base) and sourced the published candidate lists instead.
- Solved list-truncation twice (meta `...` → body mid-word cut → `<code>` block) – exact 101/100 counts matched prior lab's scale, confirming completeness.
- Enumerate-first economics (201 requests) + single-outlier reads in both phases – no threshold tuning needed with overt oracles.

## Generalization

- For `Invalid username`-vs-other login oracles: baseline random → rule out assumed accounts (administrator!) → fetch Academy candidate lists (parse `<code class="code-scrollable">`, verify ~101/~100 counts) → population scan (fixed wrong password, exact-message compare) → brute-force ONLY the outlier (302-outlier) → login → identity render → homepage marker check (not just account page).
- Overt oracles need no byte-forensics (unlike subtle-space lab) – match effort to oracle overtness, but keep raw bytes anyway.

## Lessons Learned

- Common-name anchoring fails per-instance (administrator/wiener/carlos all invalid here; `agenda` valid) – population scan beats memory every time.
- Published candidate lists truncate in meta/body extracts – `<code>` block is the complete source; count-check against known scale (~101/~100).
- Marker location varies (homepage, not account page, flipped here) – verify both surfaces before concluding.

## Related Methodology

- Extends `methodology/authentication.md` (subtle-space + 2FA lessons; no overt-oracle variant, no list-sourcing notes, no-CSRF shape – update justified below; 3rd auth lab).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: subtle-responses lab (enumerate-first economics reused; byte-forensics correctly skipped for overt oracle), 2FA lab (302+session proof standard reused).

## References

- Solved instance: https://0abe004f0318f770822de77c001800b7.web-security-academy.net/
- Lab: https://portswigger.net/web-security/authentication/password-based/lab-username-enumeration-via-different-responses
- Candidate sources (lab-published, kept in /tmp per methodology): `auth-lab-usernames` (101), `auth-lab-passwords` (100) – `<code class="code-scrollable">` parse
- Solved credentials (instance-bound): agenda / princess
- Deliberately did NOT fetch official solution; oracle + lists from evidence/published inputs.
