# PortSwigger Lab

## Lab

Information disclosure on debug page

URL: https://0ad60045044fd26580334e320001004c.web-security-academy.net/

## Vulnerability Class

Information disclosure — publicly accessible `phpinfo()` debug page leaks `SECRET_KEY` (plus full PHP/env configuration)

## Objective

Retrieve the `SECRET_KEY` and submit via `POST /submitSolution` (`answer` parameter). Solved on `{"correct":true}` + `is-solved` flip.

## Initial Observations

- CURRENT EVIDENCE: title/header name the class (debug page).
- CURRENT EVIDENCE: 13-path debug sweep → exactly one hit: `/cgi-bin/phpinfo.php` → 200, 69KB; everything else 404/11 bytes.

## Hypotheses

- H1: the debug page contains a submittable secret (SECRET_KEY pattern from the deserialization-lab family knowledge).
- H2: the secret submits verbatim.

## Attempts

1. Debug-path sweep (13 GETs, 200-vs-404 + size oracle).
2. Full phpinfo read (69KB, not truncated) → `SECRET_KEY = stds7363pum54xtdd0ogj33m4wdt92em` in ENV + `$_SERVER` (grep for SECRET/KEY/AWS/password/token/FLAG — only SECRET_KEY material).
3. `POST /submitSolution answer=<secret>` → `{"correct":true}`. H1+H2 CONFIRMED first try.
4. `GET /` → `is-solved` ×2. SOLVED (~17 requests total).

## What Failed

- Nothing: 12 misses in the sweep are the method working (elimination by oracle), not failures.

## What Worked

Debug sweep → full read → secret grep → verbatim submit → solved.

## Burp Observations

- Submission via Burp MCP with full request/response evidence; sweep via CLI (counting advantage).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl sweep with code+size oracle; full-body save (69KB — truncated previews would risk missing buried secrets); targeted secret-pattern grep.

## Root Cause

A development `phpinfo()` endpoint deployed to production without access control: full interpreter/environment dump including secrets, paths, and module lists to any unauthenticated visitor.

## Verification

- `{"correct":true}` JSON verdict + `is-solved` ×2 on re-read. Deterministic end-to-end.

## Impact

Secret disclosure (`SECRET_KEY` — session-signing key material in sibling app architectures, enabling token forgery) plus full environment fingerprinting (PHP 7.4 paths, modules) for targeted follow-ups.

## Why The Successful Approach Worked

- Standard debug-path checklist first (phpinfo variants before exotic paths — hit on attempt 1 of the list).
- Full read + pattern grep instead of eyeballing (secret sat among 69KB of noise).

## Generalization

NONE new beyond reconnaissance discipline (debug-path sweeps + full-body secret greps). No methodology update justified — but NOTE the cross-lab link: this exact `SECRET_KEY`-in-phpinfo shape is the key-recovery step of the deserialization pre-built-gadget lab (already documented there).

## Lessons Learned

- Debug sweep lists are ordered by hit rate (`/cgi-bin/phpinfo.php` first) — 1 hit in 13 probes.
- Verbatim submission of observed secrets (no format invention).

## Related Methodology

- methodology/reconnaissance.md (debug-path sweep discipline — already covers; NO update)
- methodology/verification.md (JSON verdict + marker proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Cross-lab link (technique source): knowledge/portswigger/labs/deserialization-php-prebuilt-gadget-chain.md (phpinfo SECRET_KEY recovery step)
- Solved instance: https://0ad60045044fd26580334e320001004c.web-security-academy.net/ with answer `stds7363pum54xtdd0ogj33m4wdt92em`
