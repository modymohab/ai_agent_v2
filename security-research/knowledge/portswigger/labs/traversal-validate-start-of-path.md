# PortSwigger Lab

## Lab

File path traversal, validation of start of path

URL: https://0a1b00ae03ddfc8b80de3a9f00e5002b.web-security-academy.net

## Vulnerability Class

Path traversal (file read) — start-of-path allowlist bypass (required prefix + `../` escape)

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism; rendering flips `is-solved`). Official description not read.

## Initial Observations

- Shop; image URLs already ABSOLUTE (`/image?filename=/var/www/images/20.jpg`) — validation evidently checks the path START.
- Baseline `20.jpg` → 200, 184KB jpeg (oracle shape).

## Hypotheses

- H1: Validator requires the `/var/www/images/` prefix; traversal after the prefix still resolves.
- H2: `/var/www/images/../../../etc/passwd` satisfies prefix and escapes → solved.

## Attempts

1. Baseline image (oracle shape).
2. `/var/www/images/%2e%2e/%2e%2e/%2e%2e/etc/passwd` → **200, 2316B, `root:x:0:0…`** — H1+H2 confirmed first try.
3. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing; no dead ends (prefix-preserving payload was the first and only attack request).

## What Worked

- Baseline → prefix+traversal → solved (3 requests).

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP GET.

## CLI / Tool Observations

- Clean single-param URL construction throughout.

## Root Cause

The image handler validates only that the path STARTS with `/var/www/images/` but resolves `../` sequences afterward: the allowed prefix plus `/../../../etc/passwd` escapes to the filesystem root and returns `/etc/passwd`.

## Verification

- Baseline jpeg (200/184KB) vs payload (200/2316B `root:`) on one variable (suffix after the fixed prefix).
- `/` marker flip to `is-solved`. Deterministic.

## Impact

Arbitrary local file read (demonstrated `/etc/passwd`); prefix checks without normalization are decorative.

## Why The Successful Approach Worked

- Read the constraint off the legitimate URLs (absolute + fixed prefix) and kept it while appending the escape — satisfy-then-escape in one payload.

## Generalization

- When legitimate values carry a fixed prefix (absolute base dirs, bucket names, prefixes), preserve it verbatim and append `/../` escapes — start-validated paths are bypassed without touching the checked portion.
- One request often suffices; verify content + marker immediately.

## Lessons Learned

- Prefix allowlists without canonicalization are traversal-equivalent to no check — test prefix+escape before any encoding matrix.
- Fourth traversal-read lab: same methodology file extends (variant, not new file).

## Related Methodology

- methodology/traversal.md (start-of-path bypass — to be extended)

## References

- Solved instance: https://0a1b00ae03ddfc8b80de3a9f00e5002b.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
