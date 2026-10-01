# PortSwigger Lab

## Lab

OS command injection, simple case

URL: https://0a5700c903cedb5a8033b74d00df0086.web-security-academy.net

## Vulnerability Class

OS command injection — stock-check parameter interpolated into shell (`stockreport.sh`), with exit-code-gated output and appended store-ID trailer

## Objective

Display `/etc/passwd` (established by evidence: no submit mechanism; reading flips `is-solved`). Official description not read.

## Initial Observations

- Shop; stock form `POST /product/stock` (`productId` hidden + `storeId` select).
- Baseline `productId=1&storeId=1` → small count (oracle shape).
- `productId=1;whoami` → error NAMES the sink (`/home/peter-6yImYl/stockreport.sh: line 5: $2: unbound variable`) + `whoami: extra operand '1'` — shell interpretation proven; a trailer (`1` = storeId) appends to the line.

## Hypotheses

- H1: Both params concatenate into one shell line; separators inject commands; trailer appends.
- H2: Output displays only on exit-0 (errors-only otherwise) — file reads need exit-code control.
- H3: `#`-commenting the trailer yields clean reads → `/etc/passwd` → solved.

## Attempts

1. `1|id` → `uid=1(daemon)` (works — `id <uid>` is legal; misread initially as “no trailer”, corrected later).
2. `1|pwd` → peter's home (works — ignores args). `1|whoami`, `1|ls`, `1|cat</etc/hostname` → errors only (trailer breaks them).
3. Long mechanism hunt (storeId-executes? output-truncation? user-contexts? via `;id` dual-uid, echo-marker mapping, storeId=9 variants) — established the REAL rules below; not wasted (each falsified a model).
4. Decisive echo mapping: `1|echo AAA` → `AAA 1` (trailer proven); `1|id;id` → peter-uid + daemon-uid (segments run; second clean).
5. `1|cat</etc/hostname;id` → HOSTNAME + daemon-uid — file content appears iff overall exit is 0 (H2 confirmed: output gated on exit code).
6. `1|cat /etc/passwd #` (trailer commented) → FULL passwd, no errors. H3 confirmed.
7. `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Early mis-models (truncation, user-context, storeId-executes) — each falsified by targeted probes (storeId=9 `id`-queries-uid-9 was the key disambiguator).
- `;cat` without `#` (trailer still kills); `cat</FILE` without `;id`/comment (exit-gated suppression).

## What Worked

- `1|cat /etc/passwd #` → solved-on-display.

## Burp Observations

- Not used via Burp MCP; curl sufficed.

## Browser Observations

- Not required. Pure HTTP POST.

## CLI / Tool Observations

- `--data-urlencode` per param (spaces/separators intact); echo-marker mapping (`1|echo AAA`) to expose line construction; `;id` suffix as exit-code probe; `#` trailer neutralization.

## Root Cause

`productId` is interpolated unquoted into a shell command line in/around `stockreport.sh`, with `storeId` appended after it. Shell metacharacters (`;`, `|`) inject arbitrary commands. Output displays only when the command exits 0, so file reads must neutralize the appended trailer (comment `#`), yielding clean exfiltration.

## Verification

- Sink-naming error + `uid=`/`pwd` outputs prove injection; echo mapping proves trailer mechanics; `#`-commented read returns full `/etc/passwd` with zero errors.
- `/` marker flip to `is-solved`. Deterministic.

## Impact

OS command execution as the app user (demonstrated arbitrary file read); same primitive allows full host compromise (reverse shell, keys, lateral movement).

## Why The Successful Approach Worked

- Refused to stop at “RCE proven” (`id`/`pwd`) — file READ needed exit-code control, a second distinct problem.
- Echo-marker mapping made the invisible (line construction, gating rule) visible instead of theorized.
- `#` neutralizes the trailer in one character once the model is right.

## Generalization

- On shell-error leaks naming scripts (`stockreport.sh: line N`): map construction with `|echo MARKER` (trailer exposure), probe exit-gating with `;id` suffixes, then comment trailers (`#`) for clean reads.
- `id <int>`/`pwd`/`echo` are trailer-tolerant probes; file commands need `#`.
- Solved-on-display needs no submission — marker is the oracle.

## Lessons Learned

- First OS-command lab: metachar proof (`;`, `|`) is step one; output-gating + trailer mechanics are step two — related but separate problems.
- Long mechanism hunts pay off when each probe falsifies exactly one model (storeId=9 disambiguation pattern).
- Never mistake early RCE (`id`) for objective completion — file READ is the actual criterion here.

## Related Methodology

- methodology/injection.md (OS command injection — first executable lesson; file extends SQL core with command section)

## References

- Solved instance: https://0a5700c903cedb5a8033b74d00df0086.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
