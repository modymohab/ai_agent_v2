# PortSwigger Lab

## Lab

File path traversal, traversal sequences stripped non-recursively

URL: https://0af300bc03a1dd42802776bc004d00b0.web-security-academy.net

## Vulnerability Class

Path traversal (file read) — non-recursive `../` stripping bypassed with nested `....//` sequences

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism; rendering flips `is-solved`). Official description not read.

## Initial Observations

- Shop; `/image?filename=61.jpg` → 200, 271KB jpeg (baseline oracle shape).

## Hypotheses

- H1: Naive sequences stripped once (verify: 400 oracle).
- H2: Nested `....//` collapses to `../` after one strip pass → traverses.
- H3: Display flips solved marker.

## Attempts

1. Baseline image (oracle shape).
2. Plain `..%2f`×3 → 400 `No such file` (strip confirmed, distinct oracle).
3. Nested `....%2f%2f`×3 + `etc%2fpasswd` → **200, 2316B, `root:x:0:0…`** — H2 confirmed first try.
4. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; the single strip-probe defined the bypass shape directly.

## What Worked

- Baseline → strip-confirm → nested sequences → solved (4 requests).

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP GET.

## CLI / Tool Observations

- Clean single-param URLs throughout (contamination discipline from simple-case lab).

## Root Cause

The image handler removes `../` substrings in a SINGLE non-recursive pass: nested `....//` becomes `../` after stripping and traverses normally, escaping to `/etc/passwd`.

## Verification

- Three-way differential: baseline jpeg (200/271KB) vs naive (400 `No such file`) vs nested (200/2316B `root:`) — strip behavior and bypass both evidenced on one variable each.
- `/` marker flip to `is-solved`. Deterministic.

## Impact

Arbitrary local file read (demonstrated `/etc/passwd`); single-pass sanitization is no defense.

## Why The Successful Approach Worked

- The 400 oracle characterized the defense (strip, not block) → nested form follows algebraically (`....//` − `../` = `../`).
- One nested attempt sufficed; no encoding matrix needed.

## Generalization

- On strip-behavior evidence (400/`No such file` on naive, not absolute-block), try nested `....//` and `..././` FIRST — single-pass strippers collapse them into live sequences — then encoded variants only if nested fails.
- Absolute path remains a parallel option; test both, keep whichever hits.

## Lessons Learned

- Sanitizer BEHAVIOR (strip vs block vs reject) dictates bypass shape: strip-once → nest; block → absolute/encode. The oracle message + code pair identifies which.
- Third traversal-read lab: same methodology file extends (variant, not new file).

## Related Methodology

- methodology/traversal.md (non-recursive-strip bypass — to be extended)

## References

- Solved instance: https://0af300bc03a1dd42802776bc004d00b0.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
