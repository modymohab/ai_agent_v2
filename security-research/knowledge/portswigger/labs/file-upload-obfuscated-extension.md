# PortSwigger Lab

## Lab

Web shell upload via obfuscated file extension

URL: https://0ae7007003f6e20482ac4e1e003c00e3.web-security-academy.net

## Vulnerability Class

File upload — extension blocklist bypass via null-byte truncation (`shell.php%00.png` stored as `shell.php`) → PHP RCE

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling labs; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form (multipart + per-form csrf — login token 400s, extracted per-form token).
- Plain `shell.php` (octet-stream) → 403 `Sorry, only JPG & PNG files are allowed` — extension blocklist confirmed (message oracle).

## Hypotheses

- H1: Blocklist is string/extension-based (case, alt-extensions, double-ext, semicolon, trailing-dot bypass candidates).
- H2: Null-byte truncation (`%00`) splits validator view (`.png`) from filesystem view (`.php`).
- H3: Truncated shell executes under known served path → secret → submit → solved.

## Attempts

1. Per-form csrf fix first (400 → valid token) so outcomes measure filtering, not binding.
2. Case (`.PHP`), alt-ext (`.phtml`, `.php5`, `.pht`, `.phar`), double-ext (`.png.php`), semicolon (`.php;.png`), trailing-dot (`.php.`), `.htaccess` → ALL 403 identical. Blocklist thorough on visible extensions — H1's easy variants eliminated with evidence.
3. `filename=shell.php%00.png` (hand-built multipart for byte control) → 200 `avatars/shell.php has been uploaded.` — H2 confirmed (validator saw `.png`, filesystem truncated at `%00`).
4. Control: `%2500` double-encoded → stored LITERALLY as `shell.php%00.png` (no truncation) — single-encoding required; documents the decode layer precisely.
5. `GET /files/avatars/shell.php?cmd=id` → `uid=12002(carlos)…` — RCE (served path reused from sibling labs as hypothesis, confirmed by output here).
6. `cat /home/carlos/secret` → `QqRH8QSmsz8tYy7fZM4866ak9QFTgkoy` → submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- Seven extension-obfuscation variants (useful negatives mapping a thorough-but-decodable blocklist).
- Double-encoded null (stored literally — decode-count matters: exactly one `%00` decode between validation and storage).

## What Worked

- Single-encoded null-byte filename → truncated storage as executable `.php` → RCE → secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; Python-built multipart (filename byte control beyond curl `-F` conveniences) + curl sufficed.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl `-F` cannot emit literal `%00` conveniently — hand-built multipart via Python (`filename="shell.php%00.png"`) was the required tooling step up.
- Stored-path message (`avatars/shell.php` vs literal `shell.php%00.png`) is the truncation oracle: truncated name = bypass, literal name = no-decode.

## Root Cause

Extension validation inspects the full client filename (ending `.png` ✓ passes) while the storage layer URL-decodes once and truncates at the null byte, writing `shell.php` into the web-executable avatars path. Validator view and filesystem view of the same string diverge on `%00`.

## Verification

- Blocklist proof: 7 variants → identical 403.
- Bypass proof: `%00` → 200 + TRUNCATED stored name (vs `%2500` → literal name) — decode layer isolated.
- Execution proof: `uid=…` output; secret bytes; `{"correct":true}` + `is-solved`. Deterministic.

## Impact

Full RCE as app user via one filename (demonstrated secret theft); null-byte class also enables overwrite/placement attacks.

## Why The Successful Approach Worked

- Eliminated the easy family completely before the exotic one (no premature null-byte guessing, no missed bypass).
- Controlled filename bytes exactly (hand multipart) instead of trusting `-F` conveniences.
- Read the stored-name message as the decode oracle (truncated vs literal).

## Generalization

- Against extension blocklists: matrix case/alt-ext/double-ext/semicolon/dot/htaccess FIRST (cheap, evidence), then null-byte single-vs-double (`%00` vs `%2500`) with hand-built multiparts; stored-name message adjudicates truncation.
- Exactly-one-decode gaps are version/stack-specific — verify truncated-vs-literal per instance, never assume.
- RCE chain after bypass is standard (served path → `?cmd=id` → secret → submit oracle).

## Lessons Learned

- Thorough-looking blocklists (7/7 blocked) still fall to decode-layer gaps — elimination breadth justifies the exotic test.
- Tooling limits (`-F` filename bytes) can hide primitives; drop to hand-built requests when conveniences constrain the variable.
- First null-byte lab: decode-count discipline (from SSRF `%2523` lesson) transfers across classes.

## Related Methodology

- methodology/file-security.md (null-byte extension bypass — to be extended)

## References

- Solved instance: https://0ae7007003f6e20482ac4e1e003c00e3.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
