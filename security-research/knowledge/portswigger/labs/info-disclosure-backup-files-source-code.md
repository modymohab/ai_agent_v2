# PortSwigger Lab

## Lab

Source code disclosure via backup files

URL: https://0a7a00bb04b55307804aa39000400073.web-security-academy.net/

## Vulnerability Class

Information disclosure — robots.txt advertises `/backup`, whose open directory listing serves a `.bak` Java source file containing the production database password

## Objective

Retrieve the database password and submit via `POST /submitSolution` (`answer` parameter). Solved on `{"correct":true}` + `is-solved` flip.

## Initial Observations

- CURRENT EVIDENCE: 12-path backup sweep → `/backup` 200/435 bytes (directory listing), `/robots.txt` 200/32 bytes (`Disallow: /backup`); everything else 404/11.
- CURRENT EVIDENCE: listing holds `ProductTemplate.java.bak` (1647B) — full JDBC source with hardcoded postgres password `dqunvsgrlntq23purkvviswz3yk7l1ud`.

## Hypotheses

- H1: the disclosed password is the submittable answer (submit mechanism present in lab header).
- H2: answer is the password verbatim.

## Attempts

1. Backup-path sweep (12 GETs, 200-vs-404 + size oracle) + robots corroboration.
2. Fetched `.bak` source, extracted password (only secret-pattern hit of note).
3. `POST /submitSolution answer=<password>` → `{"correct":true}`. H1+H2 CONFIRMED first try.
4. `GET /` → `is-solved` ×2. SOLVED (~16 requests total).

## What Failed

- Nothing: 11 sweep misses are elimination by oracle, not failures.

## What Worked

robots → listing → source → password → verbatim submit → solved.

## Burp Observations

- Sweep via CLI (counting advantage); submission via Burp MCP with full request/response evidence.

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl sweep with code+size oracle; robots read as sweep-list source (advertised path first).

## Root Cause

Two compounding exposures: (1) `robots.txt` advertises the sensitive path (attackers read robots as a target list); (2) the backup directory is world-listable and serves source with embedded production credentials. Either alone is minor; together they hand out the database password unauthenticated.

## Verification

- `{"correct":true}` JSON verdict + `is-solved` ×2 on re-read. Deterministic end-to-end.

## Impact

Production database credential disclosure (postgres password) + full source of the data layer (connection shape, query construction — notably a `String.format` SQLi sink, useful for follow-on work in other lab families).

## Why The Successful Approach Worked

- Read robots FIRST (advertised paths before guessed ones — hit on attempt 1 of the meaningful list).
- Followed the chain mechanically: listing → largest/most-source-like file → secret grep → verbatim submit.

## Generalization

NONE new beyond reconnaissance discipline (robots-as-target-list + backup sweeps + verbatim submission). No methodology update justified — but NOTE the cross-lab link: `ProductTemplate.java` source is the exact gadget/source file of the deserialization custom-Java-chain lab (already documented there).

## Lessons Learned

- robots.txt is recon input, not a boundary — `Disallow` entries go to the TOP of the sweep list, not the bottom.
- Backup extensions to sweep: bare dir, `/`, `.bak`, `.zip`, `.tar(.gz)`, `.swp`, `~`, `.git/HEAD` — 200-vs-404 + size adjudicates each in one request.

## Related Methodology

- methodology/reconnaissance.md (robots-first sweeps — already covers; NO update)
- methodology/verification.md (JSON verdict + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Cross-lab link: knowledge/portswigger/labs/deserialization-custom-gadget-chain-java.md (same ProductTemplate.java source file)
- Solved instance: https://0a7a00bb04b55307804aa39000400073.web-security-academy.net/ with answer `dqunvsgrlntq23purkvviswz3yk7l1ud`
