# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When an echo escaper handles quotes but passes backslashes raw, prepend `\` to
> your quote-breakout (`\';JS;//`): the raw backslash collapses with the escaper's
> own escape backslash (`\\` → one literal), stranding the quote as a terminator.
> Verify the asymmetry byte-exactly per location (`\` raw vs doubled) — and remember
> the iron rule it violates: ESCAPE THE ESCAPE CHARACTER FIRST. This is the cheapest
> bypass in the echo-into-code trilogy; test it before any grammar surgery.**

Coupled rules:
1. **Escaper-order auditing**: for every string-context escaper, check `\` FIRST —
   raw backslash + any quote-escaping = shift vulnerability, always, mechanically.
   `xxd` the backslash handling; reprs and rendered views hide doubling.
2. **Shift before surgery**: `\';JS;//` (one extra char) precedes object-closing,
   comment-architecture, and closure alternatives in test order — escalate payload
   complexity only as the template demands.
3. **Asymmetry as signal**: correct handling in one echo (h1 doubles `\`) next to
   broken handling in another (script passes raw) proves both knowledge and
   inconsistency — the coverage-gap signature that predicts siblings.

## Recon indicators (how to find this class again)
- Script-string echoes with `\'`-style escaping visible in view-source (if quotes
  are escaped, immediately test backslash passthrough with `\"` probes).
- The two-probe discriminator: `'` alone (contained?) then `\"` (shifted?).
  Contained-then-shifted = this lab in two requests.
- Analytics/config/dataLayer echoes, error-in-JS messages, JSON-in-HTML fields.
- Helpers named escapeJs/quoteEscape/jsEncode (read them: backslash-first?).

## Verification techniques (reusable)
1. **Per-location backslash check** (raw vs doubled — the load-bearing bit).
2. **Numeric-title `//`-tailed proof** (no inner-quote confounds).
3. **Derived-shape response inspection** (see `\\';` in the bytes before executing).
4. **Real-browser acceptance** to close.

## Common mistakes that miss this
- **Testing `';` without the shift prefix** → contained → false "escaped, safe".
- **Assuming one echo's escaper covers all echoes** (h1 correct ≠ script correct).
- **Jumping to `</script>` closure or grammar surgery** before trying the one-char
  shift (over-engineering past the cheapest win).
- **Reading escapers from rendered DOM** (serialization normalizes backslashes —
  curl + xxd the raw bytes).
- **Forgetting the `//` tail** (trailing `';` throws across the newline — noisy;
  commented = clean and stealthy).
- **Missing the h1's correct handling as evidence** (it's the inconsistency that
  predicts more instances of the same helper bug).

## Cross-cutting
- Echo-into-code escaper ladder (weakest→strongest attacker position): quotes-raw
  (direct) → quotes-escaped+`\`-raw (shift; this lab simplest, eval-JSON hardest
  template) → quotes+`\`-escaped (closure layer). Diagnose rung, pick shape —
  nineteen labs, and the terminator/escaper analysis now routes all echo-into-code
  encounters in O(2 probes).
- The invariant method once more: sweep → per-location byte map → family-correct
  payload (here: one-char shift) → side-effect proof → negatives → knowledge.