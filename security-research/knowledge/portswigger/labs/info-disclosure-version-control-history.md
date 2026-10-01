# PortSwigger Lab

## Lab

Information disclosure in version control history

URL: https://0a3e00e403e251a880088040000300e9.web-security-academy.net/

## Vulnerability Class

Information disclosure — exposed `.git` history; deleted secret recoverable from a prior commit (`ADMIN_PASSWORD` in `admin.conf`) → administrator login → user deletion

## Objective

Recover the deleted admin password from git history, log in as administrator, delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: 12-path backup/debug sweep → only `.git/HEAD` (23B), `.git/config` (157B), `.git/logs/HEAD` (369B), `.git/` listing (1201B) hit; classic backup/debug paths all 404.
- CURRENT EVIDENCE: logs show 2 commits; second message: `Remove admin password from config` — deletion marker pointing at the first commit.

## Hypotheses

- H1: the pre-removal commit tree holds a credential file (admin.conf pattern).
- H2: the recovered password authenticates as administrator; admin function deletes carlos.

## Attempts

1. Sweep + HEAD/config/logs reads (refs/heads/master, author carlos@carlos-montoya.net, both hashes).
2. Fetched both commit objects (zlib), parsed trees: first tree holds `admin.conf` + `admin_panel.php`.
3. Blob-hash parsing bug first (eyeballed raw bytes as hex — wrong hashes, zlib failures); redid with proper 20-byte SHA parsing → correct hashes.
4. Fetched blobs: `admin.conf` → `ADMIN_PASSWORD=2374rax7sbtbl7a5ifn9`; `admin_panel.php` → TODO stub (no auth logic).
5. CSRF-bound `administrator` login → 302 `/my-account?id=administrator` + identity render. H1+H2 credential half CONFIRMED.
6. `GET /admin` → 200 roster (wiener, carlos); `GET /admin/delete?username=carlos` → re-read: `is-solved` ×2, roster (wiener) only. SOLVED.

## What Failed

- Eyeball-hex blob hashes (zlib rejections) — fixed by programmatic tree parsing; never trust hand-transcribed hashes.
- Assumed `/admin` might take Basic auth (401, no form) — resolved by using the main login as administrator instead.

## What Worked

Logs → commit → tree → blob chain with exact SHA parsing → credential → login → delete → solved (~20 requests total).

## Burp Observations

- Login/admin/delete proofs via Burp-equivalent flows; object fetching via CLI (binary/zlib advantage).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl object downloader (`/.git/objects/XX/YYYY` layout); Python `zlib` + 20-byte-SHA tree parser; `/tmp` working copy (lab-derived objects, NOT repo wordlists/knowledge).

## Root Cause

Two compounding exposures: (1) `.git` served over HTTP (history, not just HEAD, is retrievable object-by-object); (2) secrets committed then "removed" — deletion in a later commit does not erase history. The removal commit message itself advertises exactly where to look.

## Verification

- Password works first try as administrator (302 + identity render) — credential validity proof.
- Delete → re-read: `is-solved` ×2 + victim absent. Victim state change confirmed.
- Deterministic end-to-end.

## Impact

Production-equivalent admin credential disclosure (password reuse across the disclosed DB-style secret pattern) + full data-layer source (JDBC shape, SQLi-sink-shaped query) + commit metadata (author identity).

## Why The Successful Approach Worked

- Read the logs FIRST (commit messages narrate the secret's location; "Remove X" = X exists one commit back).
- Exact-SHA parsing discipline after the eyeball failure (no hand-transcribed hashes ever again).
- Credential used at the main login (observed 401-hintless `/admin` correctly bypassed as auth entry).

## Generalization

- NEW reusable technique for methodology/reconnaissance.md: git object-graph recovery (`HEAD` → `logs` → commits → trees → blobs via `objects/XX/YY`, zlib decompress, programmatic SHA parsing) targeting deletion-marker commits.

## Lessons Learned

- Deletion commits are pointers, not erasures — prioritize them in log order.
- Hand-transcribed hashes fail silently into zlib errors; parse tree bytes programmatically always.

## Related Methodology

- methodology/reconnaissance.md (git-recovery sequence — genuinely new; update justified, applied separately)
- methodology/verification.md (credential-validity by login + marker + victim absence)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Solved instance: https://0a3e00e403e251a880088040000300e9.web-security-academy.net/ with `administrator:2374rax7sbtbl7a5ifn9` from pre-removal commit → delete carlos
