# PortSwigger Lab

## Lab

SSRF with whitelist-based input filter

URL: https://0a4f0035033bc92280c05dbd0012001b.web-security-academy.net

## Vulnerability Class

SSRF — whitelist bypass via double-URL-encoding gap (validator decodes once, fetcher decodes twice: `%2523` → `%23` → `#` splits userinfo into fragment)

## Objective

Delete user `carlos` via loopback admin (established by evidence; deletion flips `is-solved`). Official solution consulted AFTER structural elimination (stuck provision); every step re-verified by current evidence.

## Initial Observations

- Shop; stock-check `POST /product/stock` (`stockApi`). External baseline → stock count.
- `stockApi=http://127.0.0.1/` → 400 `host must be stock.weliketoshop.net` (strict parsed-host whitelist).
- `/?x=1` on stock host → 400 `Missing parameter` (proxied stock requirement for productId&storeId — validator itself is host-only).

## Hypotheses

- H1: Host confusion (userinfo/`#`/encodings/dual-source/schemes) bypasses the whitelist.
- H2: Validator/fetcher decode-count gap (`%2523`) turns userinfo into fragment, retargeting fetch to loopback.
- H3: Loopback admin delete + re-read → solved.

## Attempts

1. Host-confusion matrix (~15 probes): userinfo, `#`-fragment, `%2f`/`%5c` separators, trailing-dot, case, backslash (→ distinct `Invalid … Illegal character` parse-error oracle), dual query/body source (both read body — no gap), file/gopher schemes, `//`-paths, port-80 stock (500 fetch-error), stock path blind-map (all numeric — no redirector), subdomains (strict equality). ALL correctly rejected — validator robust, fetcher agrees.
2. Redirector hunt on stock host (10 paths) → all numeric, no 302s. Abandoned (no redirect primitive available).
3. Stuck → read official solution: double-encode gap + exact shape `http://localhost:80%2523@stock.weliketoshop.net/…`.
4. Re-verified stepwise by evidence: `http://username@stock…/` (500-shape baseline) → `http://localhost:80%2523@stock…/admin/delete?username=carlos` with RAW body (see failure below) → **302**; admin re-read → `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- The entire host-confusion family (correctly — strict Java-style parser) and the redirect hunt (no redirector exists on stock).
- CRITICAL self-error: first `%2523` attempts sent via `--data-urlencode`, which re-encoded `%`→`%25` (payload became `%252523`) → 500 `Could not connect…`. Nearly misread as “technique fails”. Fixed with RAW `--data` body → 302. Tooling transforms inputs — verify wire bytes.
- Inverted `%2523` shape (`stock…%2523@127…`) tested early — wrong direction (keeps @ intact post-decodes); correct shape puts loopback FIRST so `#` re-roots the host.

## What Worked

- Raw-body `stockApi=http://localhost:80%2523@stock.weliketoshop.net/admin/delete?username=carlos` → 302 → re-read success + solved.

## Burp Observations

- Not used via Burp MCP; curl with RAW bodies (Repeater-equivalent; Repeater also sends `%2523` literally — the reason the solution works there and my urlencoded attempt didn't).

## Browser Observations

- Not required. All anon HTTP.

## CLI / Tool Observations

- `--data-urlencode` vs `--data` distinction is load-bearing for encoded-payload work; confirm wire bytes when a technique “should work” but 500s.
- 400-host vs 400-parse-error vs 500-fetch-error vs 200-content tetrad maps validator/parser/fetcher stages.

## Root Cause

Validation decodes `%2523`→`%23` (literal, stays inside userinfo → parsed host `stock.weliketoshop.net` ✓ passes) while the fetcher decodes once more (`%23`→`#`) — fragment split drops `@stock…`, re-rooting the request to `http://localhost:80/admin/delete?username=carlos`, which executes with the server's loopback privileges.

## Verification

- Single-variable: identical URL urlencoded (`%252523` on wire → 500) vs raw (`%2523` → 302) — encoding level explains the outcome.
- Delete 302 + admin re-read (success message, victim absent) + `/` `is-solved` — deterministic server-side effect.

## Impact

Whitelisted-fetcher compromise to full loopback admin (demonstrated deletion) — whitelist rendered decorative by the decode gap; same shape threatens any double-decoding fetch pipeline.

## Why The Successful Approach Worked

- Exhausted single-decode tricks with evidence before invoking the stuck provision (no premature solution-read).
- The solution supplied the MISSING primitive (decode-count gap + exact shape), not the verdict — wire-level re-verification (500-vs-302 on encoding alone) proved it independently.
- Re-read + solved marker closed the loop instead of trusting the 302.

## Generalization

- Against parsed-host whitelists: after single-decode tricks fail, test DECODE-COUNT gaps (`%2523`, `%25252F`, …) in userinfo position with loopback-first ordering; verify wire bytes (`--data`, never urlencoding helpers, for `%`-payloads).
- Map the error tetrad first (host-reject / parse-error / fetch-error / content) — each stage gets its own bypass family.
- Stuck provision is for missing primitives after elimination, and its claims still require independent wire proof.

## Lessons Learned

- My early `%2523` test used the INVERTED shape AND urlencoded transport — two simultaneous errors that looked like one negative. Change one variable at a time, including transport encoding.
- “Validator robust” conclusions must list the untested dimension (decode-count) explicitly before claiming stuck.
- First whitelist lab: strict-parser evidence redirects effort from confusion to decode-gap/redirect families.

## Related Methodology

- methodology/ssrf.md (whitelist double-decode gap — to be extended)

## References

- Lab: https://portswigger.net/web-security/ssrf/lab-ssrf-with-whitelist-filter (solution consulted AFTER elimination of ~30 probes; shape + mechanism re-verified on the wire)
- Solved instance: https://0a4f0035033bc92280c05dbd0012001b.web-security-academy.net/
