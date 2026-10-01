# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **Against a reject-style XSS filter, compute the payload space as a SET DIFFERENCE
> with a 400-vs-200 oracle: sweep tags, then handlers-in-context, then evasions —
> and treat every 200 as a candidate, every 400 as list membership. The win is a
> COMPOSABLE pair (unlisted tag × unlisted handler × parser/behavioral composer like
> body-merge) plus a PROGRAMMATIC trigger (iframe resize, not user gestures) when
> interaction is disallowed. Read the objective first: victim-signal requirements
> change what "solved" means.**

Coupled rules:
1. **Oracle-first methodology**: confirm reject-vs-strip behavior with one battery
   (400s = fast mapping; stripping = diff-based mapping, slower). Never hand-fuzz
   blind — the status code IS the filter's confession.
2. **Enumerate to the edges**: known tags, case variants, separators (`/`, newline,
   tab), legacy/alias tags, custom tags, bare words; then handlers the same way
   (common → obscure: pointer/capture/formdata/slot/storage/language/rejection +
   resize/popstate/hashchange/unload/message). The gap is where the list author's
   imagination stopped — hunt unglamorous corners (`onresize`, `body`).
3. **Composer + trigger design**: a live handler is half a chain — pair it with a
   parser composer (body-merge, misnesting quirks) and an event you can manufacture (resize via iframe style, hashchange
   via fragment mutation, message via postMessage from your page).
4. **Victim-signal labs need delivery proof**: access-log victim UA + platform status
   flip; self-execution proves mechanics, never acceptance. Distinguish victim
   latency (no log entries) from exploit breakage (log entries, no flip) via the log.

## Recon indicators (how to find this class again)
- Reflected echoes + 400s on `<>`/payloads (WAF signature) + exploit-server presence
  (victim-signal objective likely).
- 200 on WEIRD-but-valid markup (`<body>`, custom tags) amid 400s = list-shaped hole.
- Missing framing controls + search/error echoes = iframe-delivery viable.
- Objectives mentioning `print()`/no-interaction = trigger-design lab (resize,
  hashchange, onload-chains — never click-gated).

## Verification techniques (reusable)
1. **Status-code differential fuzzing** (explicit GET query building — never
   `--data-urlencode` for GETs).
2. **Three-phase mapping**: tags → handlers-in-allowed-host → evasions-of-blocked.
3. **CDP merge/handler/dispatch proof** (attribute present + `typeof handler` +
   synthetic event → side effect) before any victim run.
4. **Byte-verify served exploit after EVERY server POST** (hashchange-lab overwrite
   lesson — placeholders disarm exploits silently).
5. **Log + banner double-confirmation** for victim legs.

## Common mistakes that miss this
- **Stopping at the first 400s** ("WAF blocks XSS" — it blocks LISTED XSS).
- **Testing only glamorous tags/handlers** (script/img/onload) and never the
  unglamorous remainder where gaps live.
- **Assuming custom tags are inert** (they're inert without handlers — but they HOST
  unlisted handlers; test the combination, not the tag alone).
- **Forgetting parser composers** (body-merge turns an "impossible" position into a
  window handler; misnesting/form quirks do similar work elsewhere).
- **Designing click-gated triggers** for a no-interaction objective (read the
  objective FIRST — it dictates trigger design).
- **Self-solving and stopping** (own-browser `print()` fires ≠ platform acceptance
  when the signal must come from the victim).
- **Blaming latency without reading the log** (delivery vs breakage distinguished in
  one GET).

## Cross-cutting
- Execution-moment matrix gains the **manufactured-event** row: window-resize fired
  by the attacker's own framing page — neither load-time, nor user-gated, nor
  victim-action-dependent. Delivery and trigger are ONE engineered unit here.
- The invariant method extends cleanly to adversarial filters: audit layers (reflection
  × filter × parser × trigger × delivery) → oracle-map each → compose the surviving
  set → prove locally → deliver → log-confirm. Fourteen labs; the method absorbs WAFs
  without changing shape.