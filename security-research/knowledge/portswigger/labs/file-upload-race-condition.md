# PortSwigger Lab

## Lab

Web shell upload via race condition

URL: https://0a4600ee0486d6e1815e21c4008f00a9.web-security-academy.net

## Vulnerability Class

File upload — TOCTOU race (synchronous 403 rejection lies: file is stored, then an async scanner deletes it; execution wins the window)

## Objective

Read `/home/carlos/secret` and submit via `POST /submitSolution` (established by evidence: same contract as sibling labs; `{"correct":true}` + `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; avatar form (multipart + per-form csrf).
- Plain `.php` → 403 `only JPG & PNG` (sync block). Case/alt-ext (`.PHP`, `.php5/7`, `.pht`, `.htaccess`), MIME spoof, null-byte-literal, traversal-literal all blocked or inert — synchronous gate looks airtight.
- Parallel valid+malicious uploads (TOCTOU on validation) → all 404 — validation itself is race-free.
- `.png`+PHP bytes stores but serves static and PERSISTS — no async deletion of compliant files.

## Hypotheses

- H1: The 403 arrives AFTER storage; an async scanner deletes malicious files — a brief execution window exists per upload.
- H2: Parallel upload + execution requests catch the window (`uid=` hits among 404s).
- H3: Window allows full secret exfiltration → submit → solved.

## Attempts

1. Extension/MIME/null/traversal/TOCTOU families eliminated with evidence (each correctly negative; static `.png` assumption verified by execution, not assumed).
2. Race test: upload `winN.php` + 10 parallel `?cmd=id` GETs × 6 rounds → **49 `uid=12002(carlos)` hits** among 404s. H1+H2 confirmed — the 403 lies; store-then-delete is real.
3. Race exfiltration: fresh upload + 15 parallel `cat /home/carlos/secret` → repeated 32-char token `a89VTS3MYKRFwhd73cQGilm1Det6manP` (concatenated in shared output file; deduped).
4. Submit → `{"correct":true}` → `is-solved`/`Solved`. WORKED.

## What Failed

- All synchronous bypass families (correctly — the gate IS synchronous; the flaw is temporal, found only by testing across time).
- Sequential upload-then-execute (404 always — the window closes before a serial follow-up; parallelism is mandatory, not optional).
- Assuming `.png` persistence implied “no scanner” — wrong inference; the scanner targets malicious (executable-extension) files, and only racing reveals it.

## What Worked

- Upload + parallel-execution bursts per round; shared-output capture with post-hoc `uid=`/token grep; secret dedup from repeats.

## Burp Observations

- Not used via Burp MCP; backgrounded curl (`&` + `wait`) sufficed. Intruder-parallel equivalent for the burst.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- Shell backgrounding for bursts; single shared output file + `sort -u`/`grep` post-processing; RANDOMIZED filenames per round (`win$R.php`) to avoid cross-round contamination.

## Root Cause

Validation responds 403 but the file has already been written to the web-executable avatars path; a subsequent asynchronous scan deletes it. The store→scan gap (milliseconds–seconds) is directly hittable: parallel execution requests land inside the window and run PHP as the app user before deletion.

## Verification

- 49/≈60 `uid=` hits vs 404s in the probe burst — execution inside the window, deletion outside it, same bytes both times.
- Secret token repeated identically across independent hits (dedup, not single-sample luck).
- `{"correct":true}` + `is-solved` — deterministic end state.

## Impact

Full RCE as app user despite a “correct” synchronous blocklist (demonstrated secret theft); any async-scan-then-delete pipeline without atomic store-and-hold is bypassable by burst execution.

## Why The Successful Approach Worked

- Questioned the 403's honesty (stored-vs-rejected is itself testable via parallel reads) instead of accepting it as ground truth.
- Made time a variable: sequential tests all agreed (404), parallel tests disagreed (uid hits) — the flaw lives in timing.
- Randomized filenames per round so hits attribute to the current upload, not stale state.

## Generalization

- On “airtight” upload gates: test TEMPORAL bypass — upload + N parallel executions per round (N=10–15), grep shared output for `uid=`; a single hit proves store-before-scan.
- 403-then-404 sequences deserve one parallel burst before concluding “blocked”; serial retests cannot see millisecond windows.
- Burst economics: one upload seeds many execution attempts; randomize names per round; dedupe exfiltrated repeats.

## Lessons Learned

- Rejection messages describe INTENT (“not allowed”), not mechanism (stored-then-deleted) — verify storage independently of status.
- First race lab: time-parallelism replaces payload-variety as the core technique when synchronous families eliminate cleanly.
- Persistence of compliant files says nothing about malicious-file lifetimes — test each class separately.

## Related Methodology

- methodology/file-security.md (store-then-delete race — to be extended)

## References

- Solved instance: https://0a4600ee0486d6e1815e21c4008f00a9.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
