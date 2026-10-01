# PortSwigger Lab

## Lab

SSRF with blacklist-based input filter

URL: https://0a260017038877b2802b44ed00070083.web-security-academy.net

## Vulnerability Class

SSRF — blacklist-filter bypass via equivalent host representations (short-form IP) + case-sensitive path matching, reaching loopback admin

## Objective

Delete user `carlos` via the loopback admin interface (established by evidence; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Shop; stock-check `POST /product/stock` (`stockApi` URL). External baseline → 200 stock count.
- `stockApi=http://127.0.0.1/` → **400** `External stock check blocked for security reasons` — naive string blacklist confirmed (block message oracle).

## Hypotheses

- H1: Blacklist matches literal `127.0.0.1` (and known forms) but misses equivalents (`127.1`, `localhost`, decimal/hex, userinfo, case).
- H2: The `/admin` path may be filtered separately (possibly case-sensitively) — bypass independently.
- H3: Bypassed admin + delete + re-read → solved.

## Attempts

1. External baseline (oracle shape) + direct loopback (400-block confirmed). Boundary set.
2. Host matrix (one variable each): `localhost`→400, `127.1`→**200 homepage HTML (10765B)**, `127.0.0.1.`→400, `2130706433`→421 `Invalid host`, `0x7f000001`→500, `stock…@127.0.0.1`→400, `%09`→400, uppercase scheme→400. ONLY short-form `127.1` passes — H1 confirmed (single outlier).
3. File-overwrite self-error: loop reused one output file, then I inspected it as the 127.1 response (it held the LAST iteration's block message) — caught by size mismatch (51B vs recorded 10765B), re-fetched separately. Process lesson.
4. `http://127.1/admin` → 400 (path ALSO filtered). Path matrix: `/Admin`, `/ADMIN`, `/%61dmin`, `/adm%69n` → **200/3178B**; `/admin`, `/admin/`, `//admin`, `/./admin`, encoded-slash/null → 400. Filter is case-SENSITIVE lowercase match — H2 confirmed.
5. `http://127.1/Admin` → 200 panel (`Users … Delete` links); `…/Admin/delete?username=carlos` → 302; re-read → `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- localhost/trailing-dot/decimal/hex/userinfo/whitespace/scheme-case host tricks — all blocked or rejected (each a data point mapping the blacklist, not wasted).
- Lowercase-path variants with slashes/dots — blocked (filter matches the substring, not exact path).
- Stale-file misread (caught by size check before any conclusion).

## What Worked

- `127.1` (host) + `/Admin` (case) bypass chain → panel → delete → re-read + solved.

## Burp Observations

- Not used via Burp MCP; curl matrix sufficed.

## Browser Observations

- Not required. All anon HTTP.

## CLI / Tool Observations

- curl `--data-urlencode` for nested URLs; per-target output files (lesson learned mid-lab); 400-51B-block vs 200-size/content oracles; `delete?username=` grep as hit criterion.

## Root Cause

Two naive string blacklists, each bypassable: host matching misses short-form IPv4 (`127.1` ≡ `127.0.0.1`) while blocking `localhost`, dotted variants, decimal/hex, and userinfo forms; path matching is case-sensitive lowercase (`admin` blocked, `Admin`/`ADMIN`/encoded pass). Combined, `http://127.1/Admin…` reaches the loopback admin and its delete action from an unauthenticated request.

## Verification

- Host differential: 7 blocked forms vs 1 pass (200 + reflected homepage) — single variable (representation).
- Path differential: 5 blocked vs 4 pass (200 + panel links) — single variable (case/encoding).
- Delete 302 + re-read (success message, victim absent) + `/` `is-solved` — deterministic server-side effect.

## Impact

Unauthenticated loopback admin compromise despite an explicit SSRF filter (demonstrated deletion); bypass primitives transfer to any blacklist-filtered fetcher.

## Why The Successful Approach Worked

- Treated host and path as INDEPENDENT filter dimensions (matrix each) instead of combined guessing.
- Size/content oracles (51B-block vs KB-panel) adjudicated every probe; the stale-file trap was caught by the same discipline.
- Stopped at first working pair per dimension rather than exhausting lists.

## Generalization

- Against SSRF blacklists, matrix host equivalents (`127.1`, `0.0.0.0`, `[::]`, decimal/hex/octal, trailing-dot, userinfo, DNS rebinding names) × path evasions (case, encoding, dot-segments, `//`, `;`, `%00`) independently; 400-message vs 200-content splits map each filter.
- 200-wrong-page still proves host bypass — then attack the path dimension separately.
- Per-target output files; verify sizes before reading (loop-overwrite trap).

## Lessons Learned

- Blacklists enumerate BADNESS — probe for the unlisted equivalent, one dimension at a time.
- First blacklist lab: filter-mapping (block-message oracle) replaces open-fetch assumptions as the core technique.
- Router case-insensitivity (`/Admin` serves panel) vs filter case-sensitivity is the classic desync — test case first on paths.

## Related Methodology

- methodology/ssrf.md (blacklist-bypass matrix — to be extended)

## References

- Solved instance: https://0a260017038877b2802b44ed00070083.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
