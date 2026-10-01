# PortSwigger Lab

## Lab

Web shell upload via path traversal

URL: https://0a55000d0301900e809d44ec00a1006c.web-security-academy.net

## Vulnerability Class

File upload — filename path traversal (stored outside the non-executing avatar dir into an executing parent) → PHP RCE

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling labs; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form (multipart + per-form csrf).
- Plain `shell.php` (as `image/png`) uploads 200 (`avatars/shell.php`) — NO extension/MIME block here.
- BUT `GET /files/avatars/shell.php?cmd=id` returns the PHP SOURCE (200, unexecuted) — avatar dir serves static. Traversal required (title-consistent).

## Hypotheses

- H1: Filename `../` sequences preserved in storage path (message echoes stored relpath — verify).
- H2: Parent dir (`/files/`) executes PHP — traversed shell runs there.
- H3: RCE → secret → submit → solved.

## Attempts

1. Plain shell → stored, served static (source leak, not execution). Establishes the non-executing baseline — do NOT mistake stored-200 for vuln.
2. `filename=../shell.php` → message `avatars/shell.php`; `/shell.php` → 404 (web-root guess wrong; traversal outcome unproven — abandoned that guess, not the technique).
3. Fresh marker `filename=..%2fmarker.php` → message echoes **`avatars/../marker.php`** — traversal PRESERVED (H1 confirmed; message is a storage oracle).
4. `GET /files/marker.php?cmd=id` → marker text + `uid=12002(carlos)…` — H2 confirmed (served path normalizes `avatars/..` away; parent executes).
5. Clean `..%2fshell2.php` → `/files/shell2.php?cmd=cat /home/carlos/secret` → `QlJovaLhM4Y2k7Pbo4uDKJYFBS5yGoYL` → submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- Executing in place (`/files/avatars/shell.php` → source) — correctly identifies the non-executing store; the flaw is placement, not filtering.
- Guessing web-root (`/shell.php` → 404) — derive served path from the stored-relpath normalization instead of guessing docroot.

## What Worked

- Traversal filename preserved → normalized served URL in parent dir → RCE → secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; curl `-F …;filename=` sufficed. Repeater equivalent for filename tampering.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl `-F "avatar=@file;filename=..%2fNAME;type=…"` for traversal names; upload-message relpath as storage oracle; `--get --data-urlencode` for command passing.

## Root Cause

The upload handler concatenates the client-supplied filename onto the avatar directory without normalizing `../` sequences: `..%2fmarker.php` stores outside `avatars/` while the message (`avatars/../marker.php`) and served URL (`/files/avatars/../marker.php` → `/files/marker.php`) preserve it. The parent directory executes PHP, so the escaped shell runs as the app user.

## Verification

- Static-vs-executed differential: same bytes return source in `avatars/` vs `uid=…` output in parent — placement (not content) decides execution.
- Secret bytes + `{"correct":true}` + `is-solved` — deterministic chain; commands as `carlos`.

## Impact

Full RCE as app user via filename alone (no filter to bypass at all here — demonstrated secret theft); arbitrary placement also enables overwrite attacks.

## Why The Successful Approach Worked

- Read the upload message as a STORAGE oracle (`avatars/../marker.php` proved preservation) instead of assuming stripping.
- Derived the served URL by normalizing the stored relpath against the known served prefix, instead of guessing docroot.
- Fresh marker filename isolated traversal behavior from the earlier `../shell.php` ambiguity.

## Generalization

- On uploads: baseline (source-or-exec?) → traversal filenames (`../`, `..%2f`, `..%252f`, `....//`) with UNIQUE marker names → read the message relpath → normalize to served URL → execution proof.
- Stored-200 ≠ vuln; executed-output (`uid=`) = vuln. Always distinguish.
- No-filter + non-executing-store is specifically a traversal setup — don't pivot to MIME/polyglot families.

## Lessons Learned

- First traversal lab: filename is a first-class attack surface alongside content/type/extension.
- Message-echoed paths are oracles — preserved `../` in text predicted the served location exactly.
- Fresh marker files per traversal variant prevent cross-contamination between attempts.

## Related Methodology

- methodology/file-security.md (path-traversal placement — to be extended)

## References

- Solved instance: https://0a55000d0301900e809d44ec00a1006c.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
