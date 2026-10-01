# PortSwigger Lab

## Lab

Web shell upload via Content-Type restriction bypass

URL: https://0a3200960434daca8004a3d0006c0021.web-security-academy.net

## Vulnerability Class

File upload — Content-Type validation bypass (MIME spoofing) → PHP RCE

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling lab; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form `POST /my-account/avatar` (multipart + own csrf per page — login-page csrf REJECTED with 400, must use the avatar form's token).
- Plain `.php` upload (default `application/octet-stream`) → 403 `Sorry, file type … is not allowed. Only image/jpeg and image/png are allowed` — client MIME restriction confirmed (message oracle).

## Hypotheses

- H1: Validation checks only the client-supplied Content-Type header (spoofable), not content/extension.
- H2: Spoofed shell stores + executes under the known served path (`/files/avatars/`).
- H3: Secret exfiltration + submission → solved.

## Attempts

1. Login-page csrf on avatar form → 400 invalid-token (per-form csrf binding — noted, corrected).
2. Plain shell (octet-stream) → 403 with allowlist message. Restriction mapped, not yet bypassed.
3. Same `shell.php` with `Content-Type: image/png` → 200 `avatars/shell.php has been uploaded.` — H1 confirmed (header-only check).
4. `GET /files/avatars/shell.php?cmd=id` → `uid=12002(carlos)…` — RCE first try (H2, path reused from sibling lab but re-verified by execution output here).
5. `cat /home/carlos/secret` → `72MTZwX2wa9XivNqb7uak4Nux2kwy6bb` → submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- Wrong-csrf (login token on avatar form) and unspoofed upload — both correctly-enforced controls that bounded the flaw to MIME checking (useful negatives).

## What Worked

- Extension kept (`.php`), MIME spoofed (`image/png`) → stored executable → RCE → secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; curl `-F …;type=` sufficed. Repeater equivalent for MIME tampering.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl `-F "avatar=@file;type=image/png"` for header spoofing; per-page csrf extraction (each form render rotates/binds its own token — never reuse across forms).

## Root Cause

Avatar upload validates ONLY the client-supplied multipart Content-Type against an allowlist (`image/jpeg`, `image/png`), ignoring file extension (`.php` kept) and content (PHP code stored verbatim). The file lands in the web-executable avatars path, yielding RCE as the app user.

## Verification

- Restriction proof: octet-stream → 403 naming the allowlist.
- Bypass proof: identical bytes + `image/png` → 200 stored-path message.
- Execution proof: `uid=…(carlos)` output; secret bytes; `{"correct":true}` + `is-solved`. Deterministic chain.

## Impact

Full RCE as app user via one header edit (demonstrated secret theft); same primitive as unrestricted upload once the header check falls.

## Why The Successful Approach Worked

- Mapped the restriction EXACTLY (403 message names the allowlist) before bypassing — spoof the named values, nothing else.
- Fixed the csrf binding first so upload outcomes measured MIME handling, not token errors (one variable).
- Sibling-lab path knowledge (`/files/avatars/`) reused as hypothesis, confirmed by execution output on THIS instance.

## Generalization

- On MIME-restricted uploads: record the 403 allowlist verbatim → resubmit identical bytes with each allowed type → stored-path message = bypass → execution proof.
- Per-form csrf tokens: extract from the SAME form render being submitted; cross-form reuse fails misleadingly (400 looks like upload flaw, is actually token binding).
- Keep filename/extension constant while varying ONLY Content-Type to isolate header-only validation.

## Lessons Learned

- 403 messages that name allowed types are bypass recipes, not dead ends.
- First MIME-bypass lab: header-spoofing replaces extension-tricks as the minimal test when the message names types.
- Cross-lab path reuse is legitimate as hypothesis-only; execution output on the live instance is the confirmation.

## Related Methodology

- methodology/file-security.md (Content-Type spoofing — to be extended)

## References

- Solved instance: https://0a3200960434daca8004a3d0006c0021.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
