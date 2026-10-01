# PortSwigger Lab

## Lab

Blind OS command injection with time delays

URL: https://0a95008504553a3a818bb25800a2001b.web-security-academy.net

## Vulnerability Class

OS command injection — blind, time-based oracle via feedback email field (no output reflected)

## Objective

Cause a server-side delay (established by evidence: no submit mechanism exists; `/` flipped to `is-solved` after delay injections). Official description not read.

## Initial Observations

- Shop + `/feedback` form (`POST /feedback/submit`: csrf + name/email/subject/message, session-bound csrf).
- Baseline submit → 200 `{}` in ~0.34s (timing oracle shape).

## Hypotheses

- H1: A field (email classic) reaches shell; `sleep` separators cause measurable delay.
- H2: Delay differential (0.3s vs 10s) proves execution without output.
- H3: Triggered delay satisfies the objective → solved marker.

## Attempts

1. Session-less POST → 400 (csrf+session binding — fixed with jar before measuring; timing requires valid requests).
2. Email `test@test.com; sleep 10 #` → **10.43s**; `& sleep 10 #` → **10.33s**; `|sleep 10` → 0.36s (no pipe context). H1+H2 confirmed — `;`/`&` execute, `|` doesn't here.
3. `/` → `is-solved`/`Solved`. WORKED (delay itself is the criterion).

## What Failed

- Unbound POST (400) — session discipline, not flaw.
- `|` separator (context-specific; `;`/`&` are the winners here — test all three, keep what delays).

## What Worked

- `email=test@test.com; sleep 10 #` → 10s delay → solved.

## Burp Observations

- Not used via Burp MCP; curl `%{time_total}` sufficed. Repeater+timer equivalent.

## Browser Observations

- Not required. Pure HTTP POST.

## CLI / Tool Observations

- curl `-w "%{time_total}"` as the oracle instrument; session jar mandatory (invalid requests have no comparable timing); `sleep 10` magnitude dwarfs jitter (~0.34s baseline).

## Root Cause

Feedback email value interpolated into a shell command without sanitization: `;`/`&`-chained `sleep 10` (with `#` neutralizing any trailer) executes server-side, observable only as response delay — classic blind command injection.

## Verification

- Baseline 0.34s vs injected ~10.4s (×2 separators agree; `|`-negative bounds the finding) — delay magnitude attributable solely to `sleep`.
- `/` marker flip to `is-solved` after the injections. Deterministic.

## Impact

Blind OS command execution (demonstrated timing control); same primitive enables time-based exfiltration and, with output channels, full compromise.

## Why The Successful Approach Worked

- Fixed session binding BEFORE timing (invalid-request timings are meaningless).
- Tested all three separators; kept the two that delay instead of assuming `;` alone.
- Large sleep (10s) vs small baseline makes jitter irrelevant — no statistics needed.

## Generalization

- On blind sinks: bind session first, baseline time, matrix `;`/`&`/`|`(+`#` trailer) with `sleep 10`, compare magnitudes; ≥2 agreeing separators + one negative = proof.
- Delay-causing payload IS the solve criterion in detection labs — check the marker right after.
- No-output ≠ no-flaw: time is a first-class oracle alongside content.

## Lessons Learned

- First blind-command lab: timing replaces content as the evidence channel; methodology extends (not new file — OS command section exists).
- Separator behavior is contextual (`|` failed where `;`/`&` worked) — always matrix all three.

## Related Methodology

- methodology/injection.md (blind time-based OS command — to be extended)

## References

- Solved instance: https://0a95008504553a3a818bb25800a2001b.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
