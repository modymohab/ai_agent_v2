# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When an echo lands inside backticks, skip terminator analysis entirely — test
> `${7*7}` FIRST: if it evaluates, the literal is a program and `${YOUR-CODE}` is
> the complete exploit (no breakout, no closure, no shift, no quotes needed).
> Escapers enumerating string metacharacters (`'"<>\``) are answering the wrong
> question; the right question is "is this string type executable?" — for template
> literals the answer is always yes.**

Coupled rules:
1. **String-type identification before escaper analysis**: backticks = executable
   (interpolation); quotes = inert (needs terminators). One glance at the delimiter
   routes the whole engagement — this lab solves in two requests once routed.
2. **Interpolation-first probing**: `${7*7}`→`49` proves evaluation with zero
   exploit assumptions (works under every escaper that spares `$`, i.e., all of
   them — no escaper can touch interpolation syntax).
3. **Quoteless inner discipline by default** (escapers mangle inner quotes; numeric
   markers and bare calls avoid the issue class entirely).

## Recon indicators (how to find this class again)
- Backtick literals containing user data in view-source (`` var x = `…USER…` ``,
  i18n strings, telemetry, SSR state blobs, GraphQL-in-JS with variables).
- The two-request discriminator: marker (echo inside backticks?) → `${7*7}`
  (evaluates?). `49` = game over.
- Frameworks/codegen emitting literals around user content (template engines,
  styled-components-like CSS-in-JS with interpolations, translation pipelines).

## Verification techniques (reusable)
1. **Arithmetic-interpolation probe** (`${7*7}`→`49`) as the compiler-alive equivalent.
2. **Numeric-title proof** (`${document.title=N}`) for code execution.
3. **Full-set escape map** (all six classes + `${}` in one probe) to document WHY
   interpolation is forced (every alternative dead — the map IS the argument).
4. **Downstream-sink note** (`innerText` here — record safe sinks too; they bound
   second-order claims).

## Common mistakes that miss this
- **Treating backticks as quotes** (firing `';`-shaped payloads → escaped → false
  "not vulnerable" — the costliest misroute in this class).
- **Admiring the six-class escaper** ("thoroughly escaped ⇒ safe") without asking
  whether the STRING TYPE executes.
- **Trying `</script>` closure** (dead — no literal `<`; and unnecessary — the
  literal itself runs code).
- **Inner quoted strings** (mangled — quoteless by default).
- **Missing the echo** (script blocks below the fold; grep backticks around user
  data as a habit).
- **Overlooking `innerText`-style sinks as evidence of safety** (the sink is safe;
  the LITERAL already executed — layer confusion in reverse).

## Cross-cutting
- Echo-into-code quartet complete: plain-string breakout, shift, script-closure,
  template-interpolation — ordered by escaper strength, inverse-ordered by payload
  complexity (strongest escaper → simplest payload). The audit method is now fully
  general: identify the CODE-SHAPED container (string? literal? eval? template?
  compiler?) FIRST, then derive reachability — twenty-one labs, one method, and the
  container question asked up front.
- Interpolation joins the trigger set as the zero-footprint member (no breakout
  chars at all — 7-bit-safe, WAF-friendly shape, log-innocuous).