# PortSwigger Lab

## Lab

File path traversal, simple case

URL: https://0ac300bb0358e24182d962dd00d000d8.web-security-academy.net

## Vulnerability Class

Path traversal (file read) — unsanitized `filename` parameter served from disk (`/image?filename=…` → `/etc/passwd`)

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism exists; rendering it flips `is-solved`). Official description not read.

## Initial Observations

- Shop; product images via `/image?filename=<N>.jpg` (baseline `14.jpg` → 200, 179KB `image/jpeg`).
- No login, no forms, no submit button — read-and-display objective.

## Hypotheses

- H1: `filename` concatenated onto a base dir without normalization → `../` escapes to filesystem.
- H2: `/etc/passwd` content renders in response body → solved marker flips on display.

## Attempts

1. Baseline image (oracle shape: 200 + jpeg + ~179KB).
2. First traversal batch FAILED (all 404) — root cause: my own URL contamination (GET URL already contained `?filename=IGNORED` while `--data-urlencode` appended a second `filename=`; server honored one of them, not my payload). Methodology lesson, not app behavior.
3. Clean single-param URLs (`..%2f..%2f..%2fetc%2fpasswd`, both `%2f`/`%2F` cases) → **200, 2316B, `root:x:0:0…`** — H1+H2 confirmed first clean try.
4. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Contaminated URLs (duplicate params) — 5 false 404s before noticing; single-param hygiene would have solved it in one request.

## What Worked

- Baseline → clean `..%2f`-traversal to `/etc/passwd` → solved-on-display.

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP GET.

## CLI / Tool Observations

- `--data-urlencode` on a URL that ALREADY has the same query key creates duplicates — build traversal URLs literally instead.
- `..%2f` and `..%2F` both accepted (case-insensitive decode here); depth 3 sufficed from the image dir.

## Root Cause

The image endpoint resolves `filename` against its image directory with no traversal normalization: `/image?filename=..%2f..%2f..%2fetc%2fpasswd` reads outside the web root and returns `/etc/passwd` with 200.

## Verification

- Baseline (179KB jpeg) vs traversal (2316B `root:x:0…` text) — content + size + type differential on one variable.
- `/` marker `is-notsolved` → `is-solved` after the read. Deterministic.

## Impact

Arbitrary local file read as app user (demonstrated `/etc/passwd`); same primitive reaches configs, keys, and source code.

## Why The Successful Approach Worked

- Baseline first gave the oracle shape that made the 404 batch suspicious (same 404 for valid-shape AND invalid-shape = request bug, not filter).
- Clean single-param URLs isolated the payload variable; depth-3 `../` sufficed immediately.

## Generalization

- On file-returning params: baseline (size/type) → clean single-param `../` matrix (depths, encodings) → sensitive files (`/etc/passwd` first) → solved/display check.
- Duplicate-param contamination mimics filters — construct URLs literally.
- Solved-on-display labs need no submission step; the marker is the oracle.

## Lessons Learned

- First traversal-read lab: read-side path handling is its own class (distinct from upload-side traversal) — new methodology file justified.
- Self-inflicted 404s (tooling) must be ruled out before concluding filters (compare against baseline shape).

## Related Methodology

- methodology/traversal.md (file-read traversal — NEW from this lab)

## References

- Solved instance: https://0ac300bb0358e24182d962dd00d000d8.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
