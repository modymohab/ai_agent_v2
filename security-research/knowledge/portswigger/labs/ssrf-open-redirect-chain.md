# PortSwigger Lab

## Lab

SSRF with filter bypass via open redirection vulnerability

URL: https://0aa80086038e118282eb488c00c00078.web-security-academy.net

## Vulnerability Class

SSRF — relative-path stock parameter chained through an open redirect (`nextProduct?path=`) to an internal backend, bypassing path-shape validation

## Objective

Delete user `carlos` via the internal backend admin (established by evidence; victim absence + `is-solved`). Official description not read.

## Initial Observations

- Shop; stock form takes RELATIVE `stockApi` (`/product/stock/check?...`); absolute URLs → 400 `Invalid … 'Invalid URL'` (shape validation, not host whitelist).
- Product pages link `/product/nextProduct?currentProductId=1&path=/product?productId=2` — redirector with attacker-controlled `path`.
- Direct `GET …/nextProduct?…&path=http://127.0.0.1/admin` → 302 there (open redirect confirmed).

## Hypotheses

- H1: `stockApi` accepts relative paths resolved + fetched server-side; the fetcher follows redirects (validate with benign target first).
- H2: Admin is NOT on loopback:80 here (to be tested) — likely a second backend (`192.168.0.0/24:8080` per sibling lab), reachable through the redirector.
- H3: Redirect-chain delete + re-read → solved.

## Attempts

1. Valid relative baseline → stock count (oracle shape). Absolute URLs → 400 (shape gate).
2. `//127.0.0.1/admin` → 404; extra-param (`&redirect=`) → stock number; lab `/redirect`, `/cart?redir=` → 404 (no lab redirector there).
3. StockApi `/product/nextProduct?…&path=/product?productId=2` (benign) → 200 product HTML — redirect-following CONFIRMED through SSRF.
4. Loopback via redirector: `:8080/admin` → 500 (fetch error, nothing there); `localhost`, `127.1`, `127.0.0.1` `/admin` → 404 (alive but no admin — follow happened, target absent). H2 supported.
5. Direct `stockApi=/admin` → 404 (no self-base shortcut).
6. /24 sweep through redirector (25 threads): 253 silent/irrelevant vs **`192.168.0.12:8080/admin` → 200 admin page** (`Users … Delete` links). Single outlier.
7. Delete-URL through same chain → 200; re-read panel (carlos absent, wiener remains); `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Absolute-URL stockApi (shape gate, correctly rejected — defines the relative-only constraint that makes the redirector necessary).
- Loopback admin assumptions from sibling labs (different topology here — verified absent, not assumed present).
- Direct `/admin` as stockApi (no self-base shortcut).

## What Worked

- Relative-path SSRF → open-redirector → cross-host follow → backend-range sweep → single-hit admin → delete → re-read + solved.

## Burp Observations

- Not used via Burp MCP; curl sufficed. Repeater equivalent for chained paths.

## Browser Observations

- Not required. All anon HTTP.

## CLI / Tool Observations

- curl `--data-urlencode` for nested query-in-query values; per-host sweep files; admin-marker grep as hit criterion; 500-fetch-error vs 404-absent vs 200-content trichotomy maps target liveness.

## Root Cause

Two individually-limited features compose: (a) stock-check fetches relative paths server-side and FOLLOWS redirects; (b) an open redirect (`nextProduct?path=`) accepts absolute URLs including internal hosts. Chained, an allow-shaped relative input (`/product/nextProduct?…&path=http://192.168.0.12:8080/admin…`) escapes to the internal network, where a second backend exposes an unauthenticated admin with user deletion.

## Verification

- Benign-redirect control (product HTML via chain) proved follow-before-payload.
- Sweep: 253 non-hits vs 1 admin page — single variable (octet).
- Delete + re-read (victim absent, wiener remains) + `/` `is-solved` — deterministic server-side effect.

## Impact

Unauthenticated internal admin compromise on a second backend (demonstrated deletion); open-redirect + SSRF composition reaches any internal HTTP service.

## Why The Successful Approach Worked

- Read the constraint first (relative-only) instead of forcing absolute-URL payloads from sibling labs.
- Proved redirect-following with a benign target before weaponizing it (avoids conflating validator blocks with missing targets).
- Let topology evidence (loopback 404s) redirect the sweep to the private range rather than assuming loopback admin.

## Generalization

- When fetched input is path-constrained, hunt redirectors that accept absolute targets (`nextProduct?path=`, `redir`, `returnUrl`, `continue`) — the redirector converts relative-only SSRF into arbitrary-destination SSRF.
- Always validate follow-behavior benignly first; trichotomy fetch-error/absent/content maps liveness per target.
- Sibling-lab topologies differ per instance (loopback vs second backend) — probe, don't port conclusions.

## Lessons Learned

- Open redirect + SSRF composes across shape validations that neither flaw beats alone — test combinations, not just singles.
- First redirect-chain lab: benign-control-then-payload replaces direct-payload as the safe order.
- 404-through-chain is informative (follow happened, target absent) vs validator blocks — read which layer answered.

## Related Methodology

- methodology/ssrf.md (open-redirect SSRF chain — to be extended)

## References

- Solved instance: https://0aa80086038e118282eb488c00c00078.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
