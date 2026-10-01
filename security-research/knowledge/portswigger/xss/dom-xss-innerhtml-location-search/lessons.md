# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a script assigns URL-derived data to `innerHTML` (or `outerHTML`,
> `insertAdjacentHTML`, jQuery `.html()`), the payload must be an *event-handler-carrying
> element*, never a `<script>` tag — and if the assignment is whole-element content, no
> breakout prefix is needed.**

Two coupled rules this lab exists to teach:
1. **Sink semantics choose the payload family**: `document.write` runs written
   `<script>`s; `innerHTML` neuters them but keeps handlers live. Same source
   (`location.search`), opposite payloads. Always ask "what does THIS sink execute?"
   before writing a payload.
2. **Assignment context chooses the breakout**: whole-element assignment
   (`el.innerHTML = value`) needs none; interpolation inside a larger construct
   (`'…'+value+'…'`, attribute, JS string) needs the matching terminator
   (`"`, `>`, `'`, `</script>` respectively).

## Recon indicators (how to find this class again)
- Search/filter/echo features where the term visibly appears inside page text but NOT in
  the raw HTTP response → strong DOM-sink signal (compare response bytes vs rendered DOM).
- Grep JS for `innerHTML|outerHTML|insertAdjacentHTML|\.html\(` near
  `location\.|URLSearchParams|referrer|window\.name|postMessage|storage`.
- A sink assigned the *whole* of an empty container (`<span id=…></span>` + assignment)
  is the classic shape — payload is a bare fragment, no breakout.
- Absence of CSP / Trusted Types headers is the enabler; their presence changes payload
  selection, not the verdict (innerHTML of attacker data is still a finding).

## Verification techniques (reusable)
1. **Positive + negative pair in the same harness**: fire an event-handler probe AND a
   `<script>` probe; assert BOTH outcomes (handler executes, script does not). The pair
   proves you understand the sink instead of getting lucky.
2. **Assert on execution side-effects, not string presence**: serialized DOM contains
   inert nodes' text — `grep marker` false-positives on `<script>` text. Use
   `document.title='MARK'` (or a created element / network beacon) as the assertion.
3. **Non-blocking probes for headless work** (`document.title`, DOM markers); `alert()`
   freezes headless dumps.
4. **Zero-reflection check**: `curl` the URL with a unique marker and grep the response —
   absence proves the sink is purely client-side and scopes remediation correctly.

## Common mistakes that miss this
- **Firing `<script>alert(1)</script>` at an innerHTML sink**, seeing no alert, and
  concluding "not vulnerable" — the most common DOM-XSS miss. The sink was exploitable;
  the payload was wrong for the sink.
- **Carrying over the previous lab's payload verbatim** (`"><script>…`): the `">` prefix
  is harmless here but reveals copy-paste reasoning; worse, `<script>` itself is inert —
  blind reuse fails.
- **Response-only testing**: the term never appears in HTTP responses, so curl+grep
  reports "clean". DOM sinks require JS review + parser execution.
- **Confusing DOM presence with execution** when reading dumps (see technique 2).
- **Stopping at the first working vector** without recording WHY alternatives fail —
  the `<script>` negative is as valuable as the `onerror` positive for future payload
  selection.

## Cross-cutting
- With the sibling `document.write` lab, this completes the minimal DOM-XSS sink-semantics
  matrix every agent should internalize:
  | Sink | `<script>` executes? | Needs breakout? (attr-interpolated) | Needs breakout? (whole-content) |
  |---|---|---|---|
  | `document.write` | YES | YES (`"`, `>`) | no |
  | `innerHTML` et al. | NO (use handlers) | YES (same rule) | no |
- The methodology chain (source/sink audit → context map → sink-appropriate payload →
  side-effect assertion → negative control) transfers unchanged to `hash` sources,
  jQuery sinks, `postMessage` handlers, and stored-DOM variants.