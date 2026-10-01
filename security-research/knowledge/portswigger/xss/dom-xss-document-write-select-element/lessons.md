# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When attacker data is written inside a "restrictive" wrapper (`<select>`,
> `<option>`, `<title>`, `<textarea>`, `<noscript>`, `<template>`…), do NOT assume the
> wrapper neutralizes payload shapes — test bare-tag, breakout, and script shapes
> empirically against the CURRENT engine. Here all three fired: the wrapper
> constrained nothing. The operative rule is per-(sink × wrapper × shape) behavior,
> and only execution side-effects decide.**

Coupled rules:
1. **Content model ≠ parser behavior**: the spec's content model says what documents
   SHOULD contain; the tokenizer decides what RUNS. `<option>` tolerates foreign
   children with live handlers (proven, incl. static control).
2. **Sink semantics still dominate**: `innerHTML`-inserted `<script>` stays inert
   while parser-inserted `<script>` in select runs — same tag, opposite verdicts by
   insertion path. Always pair wrapper tests with sink-awareness.
3. **Redundant shapes are an impact fact**: three independent load-time vectors mean
   single-shape mitigations (strip `<script>`, strip `on*` once, block one pattern)
   each leave live alternatives. Report the sink, not the payload.

## Recon indicators (how to find this class again)
- Dropdowns/selects populated from URL state (store pickers, country/language/currency
  selectors, configurators, `?storeId=`/`?color=`/`?size=` echoed into `<option>`).
- `document.write` + `<select>`/`<option>` string building in JS (grep
  `document\.write.*select|option.*location|URLSearchParams`).
- E-commerce/product pages generally: stock checkers, variant pickers, and
  recently-viewed widgets that reflect query state into markup.
- Any `document.write(innerHTML-adjacent)` sink whose VALUE sits inside a wrapper tag
  — map the wrapper precisely (option? title? textarea? each has its own quirks:
  `</textarea>`/`<title>` need breakout; `<option>` needs nothing).

## Verification techniques (reusable)
1. **Shape matrix per wrapper**: fire bare-tag, breakout+tag, and bare-script with
   DISTINCT markers in parallel runs — one command batch, complete behavior table.
2. **Static-HTML control** (`data:` URL) to separate parser behavior from sink-path
   behavior when a result surprises you.
3. **Rendered-DOM shape dumps**: assert WHERE each node landed (in-option vs
   body-sibling), not just that code ran — shape explains mechanism.
4. **SSR-absence marker check** (one curl) to scope DOM-vs-server correctly.
5. **Real-browser acceptance with the canonical shape** even when shorter shapes work
   (demonstrates the textbook skill too).

## Common mistakes that miss this
- **"It's inside a select, so markup is dead"** — the single most expensive assumption
  in this lab; current Chrome disagrees for both handlers and scripts.
- **Testing only the breakout shape** → solves the lab but learns 1/3 of the behavior
  (and would MISS the vuln entirely on a build where `</select>` is filtered but bare
  tags pass — a realistic WAF scenario).
- **Testing only `<script>`** → in bodies it works, in `innerHTML` it doesn't, in
  select it does — shape verdicts don't transfer across sinks/wrappers.
- **Confusing content-model knowledge for parser knowledge** (reading specs instead of
  firing payloads).
- **Response-only testing** (pure DOM sink — curl sees nothing).
- **Forgetting single-encoding discipline** on `&`-joined multi-param URLs (`productId`
  + `storeId` — encode `&` boundaries correctly or params split wrongly).

## Cross-cutting
- The execution-moment matrix stands (all three shapes here fire at parse/load), with
  a new orthogonal axis — **wrapper leniency**: body ≈ option (everything fires) vs
  `innerHTML`-fragment (`<script>` neutered). Future wrapper encounters (`title`,
  `textarea`, `noscript`, `template`, `iframe srcdoc`, `style`) slot into the same
  test matrix: three shapes + static control + DOM-shape dump.
- Methodology invariant once more: source/sink audit → EXACT wrapper map → shape
  matrix → side-effect assertions → static control for surprises → canonical-shape
  acceptance. The lab count grows; the method doesn't change.