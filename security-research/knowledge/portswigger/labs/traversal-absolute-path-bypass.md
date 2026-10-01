# PortSwigger Lab

## Lab

File path traversal, traversal sequences blocked with absolute path bypass

URL: https://0a7700c803ed77a680827b5d00b60011.web-security-academy.net

## Vulnerability Class

Path traversal (file read) — `../` sequences stripped/blocked, but absolute filesystem paths honored

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism; rendering flips `is-solved`). Official description not read.

## Initial Observations

- Shop; `/image?filename=8.jpg` → 200, 166KB jpeg (baseline oracle shape).

## Hypotheses

- H1: `../` sequences blocked/stripped (title) — verify with fresh evidence, don't skip.
- H2: Absolute path (`/etc/passwd`) bypasses sequence-stripping (nothing to strip).
- H3: Display flips solved marker.

## Attempts

1. Baseline image (oracle shape).
2. `..%2f..%2f..%2fetc%2fpasswd` → 400 `No such file` — H1 confirmed (sequences rejected, distinct 400 oracle vs 404s elsewhere).
3. `/etc/passwd` (clean single param) → **200, 2316B, `root:x:0:0…`** — H2 confirmed first try.
4. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; the blocked-sequences probe was a one-request confirmation, not a rabbit hole.

## What Worked

- Baseline → blocked-sequence confirm → absolute path → solved (4 requests).

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP GET.

## CLI / Tool Observations

- Clean single-param URL construction (lesson carried from simple-case contamination incident).

## Root Cause

The image handler strips/blocks `../` sequences but passes any remaining path — including absolute ones — to the filesystem read: `/image?filename=/etc/passwd` is honored verbatim, returning arbitrary local files.

## Verification

- Three-way differential on one variable: baseline jpeg (200/166KB) vs sequences (400 `No such file`) vs absolute (200/2316B `root:`) — block and bypass both evidenced.
- `/` marker flip to `is-solved`. Deterministic.

## Impact

Arbitrary local file read (demonstrated `/etc/passwd`); configs/keys/source in real estates — sequence-blocking alone is no defense.

## Why The Successful Approach Worked

- Verified the block (one probe) instead of assuming it, then picked the bypass the block implies (absolute needs no sequences).
- Clean URLs throughout (no duplicate-param contamination).

## Generalization

- When `../` is stripped/blocked (400/`No such file` oracle), try absolute paths FIRST — the cheapest bypass for sequence-only defenses — then nested/encoded variants only if absolute fails.
- Three-oracle mapping (baseline/blocked/bypass) fully characterizes such filters in ~4 requests.

## Lessons Learned

- Block messages name the defense (“No such file” on sequences) and imply its hole (absolute needs none) — read bypass off the block.
- Second traversal-read lab: same methodology file extends (variant, not new file).

## Related Methodology

- methodology/traversal.md (absolute-path bypass — to be extended)

## References

- Solved instance: https://0a7700c803ed77a680827b5d00b60011.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
