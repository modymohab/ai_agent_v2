# PortSwigger Lab

## Lab

Blind OS command injection with output redirection

URL: https://0a2a002e04df9763870b4ced00a300f8.web-security-academy.net

## Vulnerability Class

OS command injection — blind with output redirection into the web-accessible images directory

## Objective

Execute commands and exfiltrate output (established by evidence: no submit mechanism; `/` flipped to `is-solved` after redirection exfiltration). Official description not read.

## Initial Observations

- Shop + `/feedback/submit` (csrf + name/email/subject/message, session-bound); no stock form, no account system.

## Hypotheses

- H1: A feedback field reaches shell (email classic) — prove with `sleep` delay.
- H2: Output redirectable to a web-fetchable path (`/var/www/images/`, served via `/image?filename=`).
- H3: Exfiltrated output satisfies the objective → solved.

## Attempts

1. Session-bound baseline 0.35s; email `; sleep 8 #` → 8.42s (H1 confirmed, timing oracle).
2. `; whoami > /var/www/images/out1.txt #` → `/image?filename=out1.txt` → `peter-u9i2Gm` (H2 confirmed — redirection channel works first try).
3. `ls /home/`, `/home/carlos/`, `/home/peter-u9i2Gm/ + /home/user/` redirected and read (enumeration; no secret needed).
4. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; each step confirmed before the next.

## What Worked

- Sleep-proof → redirect `whoami` → redirect listings → solved (no secret file required — capability itself sufficed).

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP POST + GET reads.

## CLI / Tool Observations

- curl `%{time_total}` for the initial proof; `>` redirection with `#` trailer (from simple-case lesson); `/image?filename=` as the read-back primitive.

## Root Cause

Feedback email value interpolated into a shell command without sanitization; combined with a web-served writable images directory, `cmd > /var/www/images/<file>` converts blind execution into readable output — full RCE with exfiltration.

## Verification

- Timing differential (0.35s vs 8.42s) proves execution; redirected `whoami` output proves user context; directory listings prove read primitive; `/` `is-solved` proves objective. Deterministic chain.

## Impact

Blind RCE as app user with arbitrary file read (demonstrated home listings); writable web dir turns blind into visible — full host compromise path.

## Why The Successful Approach Worked

- Proved execution (sleep) BEFORE building exfiltration (redirect) — layered confirmation.
- Reused the exact `#`-trailer + images-path knowledge from prior labs as hypotheses, confirmed live.
- Stopped at capability proof (no secret hunt needed once solved flipped).

## Generalization

- On blind sinks with a writable web dir nearby: sleep-proof → `whoami > <webdir>/<rand>.txt` → fetch → enumerate → solved-check early (objective may need no secret).
- `#` trailer + session-bound csrf carry over from the simple-case lesson unchanged.
- Check the marker after EACH capability rung, not just at the end.

## Lessons Learned

- First redirection lab: file-write converts blind→visible; methodology extends (not new file — OS command section exists).
- Solved-state can precede secret discovery — verify the marker continuously during capability building.

## Related Methodology

- methodology/injection.md (blind output-redirection — to be extended)

## References

- Solved instance: https://0a2a002e04df9763870b4ced00a300f8.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
