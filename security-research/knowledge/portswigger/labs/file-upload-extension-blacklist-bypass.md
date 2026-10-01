# PortSwigger Lab

## Lab

Web shell upload via extension blacklist bypass

URL: https://0aac008103b663da809d808a00d90083.web-security-academy.net

## Vulnerability Class

File upload — extension blacklist bypass via unlisted-but-executable extension (`.phar`) → PHP RCE

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling labs; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form (multipart + per-form csrf — extracted per-form token).
- Plain `shell.php` → 403 `Sorry, php files are not allowed` — extension blacklist confirmed (message oracle names the matched concept).

## Hypotheses

- H1: Blacklist covers obvious PHP spellings but misses executable alternates (`.phtml`, `.phar`, `.pht` — none contain the `php` substring).
- H2: At least one unlisted extension both uploads AND executes under the served path.
- H3: Standard RCE chain (secret → submit → solved).

## Attempts

1. Plain `.php` → 403 (blocklist baseline).
2. `.phtml` → 403 (covered — blocklist broader than substring; useful negative).
3. `.phar` → 200 `avatars/shell.phar has been uploaded.`; `.pht` → 200 stored. Both pass upload — H1 confirmed for two candidates.
4. Execution differential: `/files/avatars/shell.phar?cmd=id` → `uid=12002(carlos)…` (EXECUTES); `/files/avatars/shell.pht?cmd=id` → PHP source (static). H2 confirmed for `.phar` only — upload-acceptance ≠ executability, tested per candidate.
5. `cat /home/carlos/secret` → `t6hMoV1iWi8ZV5v5LmwCp3LNt61NIZzQ` → submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- `.phtml` (blocked — don't assume all alternates survive; test each).
- `.pht` uploads but serves static (same trap as traversal lab's static store — execution must be proven per extension).

## What Worked

- `.phar` upload → execution → secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; curl `-F …;filename=` sufficed.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl `-F` with explicit `;filename=` per variant; execution differential (`uid=` vs source) adjudicates each candidate independently.

## Root Cause

Extension validation blacklists known-bad spellings (including `.php`, `.phtml`) but omits `.phar`, which the PHP/Apache stack executes as code. The unlisted executable extension sails through the filter and runs under the standard served path — blacklist incompleteness, not a parsing trick.

## Verification

- Block proof: `.php`/`.phtml` → identical 403.
- Upload-vs-execution split: `.phar` + `.pht` both 200-stored, but only `.phar` returns `uid=` (`.pht` returns source) — executability proven per candidate, not assumed from acceptance.
- Secret bytes + `{"correct":true}` + `is-solved` — deterministic chain.

## Impact

Full RCE as app user via one unlisted extension (demonstrated secret theft); blacklist gaps recur per stack (phar/phtml/phpN/food for Apache+PHP).

## Why The Successful Approach Worked

- Tested upload AND execution as separate gates per candidate (acceptance ≠ exploitability — `.pht` proved the distinction live).
- Stopped at first executing candidate instead of exhausting the list (`.phar` hit on variant 3 of the matrix).
- Sibling-lab path reuse (`/files/avatars/`) as hypothesis, confirmed by `uid=` output here.

## Generalization

- Against extension blacklists: matrix unlisted-but-executable-per-stack extensions (`.phar`, `.pht`, `.phtml`, `.php5/7`, `.htaccess`, case) AND prove execution per candidate (`?cmd=id` → `uid=` vs source).
- 403-message wording hints at match style (“php files” = concept list, compare with “only JPG & PNG” = allowlist) — read it before choosing the family.
- Stored-200 is step one of two; executed-output is step two. Never conflate.

## Lessons Learned

- Blacklist vs allowlist messages dictate strategy (unlisted-alternate vs header-spoof) — the 403 text is the first oracle.
- First blacklist-gap lab: unlisted-executable matrix replaces decode-trickery when the list itself is incomplete.
- `.pht`-static vs `.phar`-executes on the same host proves handler mappings vary per extension — always test, never infer.

## Related Methodology

- methodology/file-security.md (blacklist-gap executable extensions — to be extended)

## References

- Solved instance: https://0aac008103b663da809d808a00d90083.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
