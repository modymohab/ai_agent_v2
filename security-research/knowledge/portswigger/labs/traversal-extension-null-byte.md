# PortSwigger Lab

## Lab

File path traversal, validation of file extension with null byte bypass

URL: https://0a29005904de32a28131f288007f000c.web-security-academy.net

## Vulnerability Class

Path traversal (file read) — extension allowlist bypass via null-byte truncation combined with relative traversal

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism; rendering flips `is-solved`). Official description not read.

## Initial Observations

- Shop; `/image?filename=38.jpg` → 200, 277KB jpeg (baseline oracle shape).

## Hypotheses

- H1: Extension allowlist (`.jpg`/`.png`) rejects bare `/etc/passwd` (verify: 400 oracle).
- H2: Null byte (`%00.jpg`) satisfies the allowlist while truncating to `/etc/passwd` at read time — combined with traversal depth for the image dir.
- H3: Display flips solved marker.

## Attempts

1. Baseline image (oracle shape).
2. `/etc/passwd` (absolute, no extension) → 400 `No such file` (extension gate confirmed).
3. `/etc/passwd%00.jpg` (absolute + null) → 400 (absolute form rejected or depth wrong — absolute alone insufficient here; images live nested).
4. `..%2f..%2f..%2fetc%2fpasswd%00.jpg` (3-level traversal + null, `.jpg` and `.png` variants) → **200, 2316B, `root:x:0:0…`** — H2 confirmed (both extensions work; 1-level variant 400s on depth).
5. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Absolute paths (with and without null) — this instance requires relative traversal (depth 3); absolute-path lesson from sibling lab does NOT transfer blindly.
- 1-level traversal+null (depth matters — matrix depth, don't stop at one).

## What Worked

- Baseline → extension-gate confirm → traversal+null at sufficient depth → solved (6 requests).

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP GET.

## CLI / Tool Observations

- Clean single-param URLs throughout; depth × extension matrix (3 levels × jpg/png) in one batch.

## Root Cause

The image handler requires an image extension (allowlist) but the read path truncates at the null byte: `..%2f..%2f..%2fetc%2fpasswd%00.jpg` passes validation as `.jpg` while the filesystem opens `/etc/passwd` (3-level `../` escaping the nested image dir first).

## Verification

- Four-way differential: baseline jpeg (200/277KB) vs bare (400) vs absolute+null (400) vs traversal+null (200/2316B `root:`) — extension gate, depth requirement, and bypass each evidenced.
- `/` marker flip to `is-solved`. Deterministic (both extensions).

## Impact

Arbitrary local file read (demonstrated `/etc/passwd`); extension allowlists without null-safe handling are decorative.

## Why The Successful Approach Worked

- Separated the two dimensions (extension gate vs traversal depth) instead of changing both at once after the first null failure.
- Absolute-path failure (sibling lesson) correctly redirected to relative+depth rather than abandoning null byte.

## Generalization

- On extension-gated file reads: confirm gate (bare → 400), then matrix traversal-depth × null-suffixed extensions (`%00.jpg`, `%00.png`); absolute and relative are independent axes — test both.
- Depth insufficiency (400) vs gate rejection (400) look identical — escalate depth before concluding the technique fails.

## Lessons Learned

- Sibling lessons compose, not copy: absolute-path (prior lab) FAILED here; null-byte (upload labs) + depth (simple lab) composed into the winner.
- Fifth traversal-read lab: same methodology file extends (variant, not new file).

## Related Methodology

- methodology/traversal.md (extension + null-byte combination — to be extended)

## References

- Solved instance: https://0a29005904de32a28131f288007f000c.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
