# PortSwigger Lab

## Lab

Information disclosure in error messages

URL: https://0a9c006e042234b980cf9eee00a70070.web-security-academy.net/

## Vulnerability Class

Information disclosure — verbose Java stack trace on malformed input discloses the exact application framework and version (`Apache Struts 2 2.3.31`)

## Objective

Determine the framework version and submit it via `POST /submitSolution` (`answer` parameter). Solved on `{"correct":true}` + `is-solved` flip.

## Initial Observations

- CURRENT EVIDENCE: shop surface; no forms on product pages; bad product/path → tiny 404s (11 bytes — quiet).
- CURRENT EVIDENCE: `product?productId=1'` → 500 with full `java.lang.NumberFormatException` stack trace ending in `Apache Struts 2 2.3.31`.
- CURRENT EVIDENCE: lab header carries `submitSolution` button (`POST /submitSolution`, parameter `answer`).

## Hypotheses

- H1: the trailing version line is the objective answer (submit verbatim).
- H2: answer format is the full string `Apache Struts 2 2.3.31` (not bare `2.3.31`) — tested first as observed.

## Attempts

1. Surface mapping (homepage links, product pages, 404 behavior).
2. Quote probe on integer parameter → verbose 500 (first error-surface hit).
3. Full trace read → version line at the END (past 30+ frames of obfuscated `lab.*`/`r.b.v.t` frames — the prize is last, not first).
4. `POST /submitSolution answer=Apache Struts 2 2.3.31` → `{"correct":true}`. H1+H2 CONFIRMED first try.
5. `GET /` → `is-solved` ×2. SOLVED (~6 requests total).

## What Failed

- Nothing: first submission correct. No alternative formats needed.

## What Worked

Quote-probe → read trace to the last line → submit verbatim → solved.

## Burp Observations

- Error-surface probes and submission via Burp MCP (`burp_send_http1_request`) with full request/response evidence.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl for mapping/counting; full-body reads (the version sits past truncated previews — `head -c` would have cut it; read to the end).

## Root Cause

Unhandled exception rendering: a non-integer `productId` throws `NumberFormatException`, and the error page prints the full stack trace including the container's version banner. Verbose errors turn a type-validation failure into framework fingerprinting.

## Verification

- `{"correct":true}` JSON verdict + `is-solved` ×2 on homepage re-read. Deterministic end-to-end.

## Impact

Exact framework/version disclosure (`Apache Struts 2 2.3.31` — a version with known CVEs, e.g. S2-045 class) enables targeted exploit selection; also leaks internal class/package structure (`lab.*` frames) useful for further mapping.

## Why The Successful Approach Worked

- Probed the integer parameter with a quote FIRST (cheapest error-surface test) instead of crawling for errors.
- Read the ENTIRE trace (version banner is last) and submitted verbatim (no format guessing).

## Generalization

NONE new beyond reconnaissance discipline (error-surface probing + full-body reads + verbatim submission). No methodology update justified — single recon fact, already covered by reconnaissance.md (endpoint existence oracles, full-response reads).

## Lessons Learned

- 404-quiet vs 500-verbose asymmetry maps error surfaces fast: tiny 404s here, full traces on type errors.
- Submit-mechanism labs (`submitSolution` + `answer`) want observed strings verbatim — format invention is the only failure mode, avoided by copying exactly.

## Related Methodology

- methodology/reconnaissance.md (error-surface probing; full-response reads) — already covers; NO update
- methodology/verification.md (JSON verdict + marker proof)
- methodology/injection.md does NOT apply (quote produced a type error, not SQLi — correctly not pursued). Deliberately not modified.

## References

- Solved instance: https://0a9c006e042234b980cf9eee00a70070.web-security-academy.net/ with answer `Apache Struts 2 2.3.31`
