# Root Cause — executable string type (template literal) with data interpolated

## The vulnerability
The search term is echoed into a JavaScript TEMPLATE LITERAL — a string type that
evaluates `${…}` interpolations as code during construction. The escaper neutralizes
six character classes (quotes, brackets, backslash, backtick) but `${}` must survive
for literals to function, so attacker expressions execute with no breakout, no
terminator, and no tag — the payload is indistinguishable from legitimate use.

## Root cause (framing)
- **Wrong string type for untrusted data**: ordinary quoted strings are inert
  containers (breakout requires terminators); template literals are PROGRAMS with a
  data section (interpolation runs by design). Echoing attacker text into backticks
  while thinking in "quoted string" terms is the category error — the escaper list
  (`'"<>\``) is exactly the quoted-string threat model, blind to `${}`.
- Failed assumption: *"escaping string metacharacters makes echoes safe."* True for
  inert strings; meaningless for template literals, whose executable syntax (`${}`)
  no escaper may touch. The fix is structural (plain quotes + encoding, or no
  echo into literals), never a longer escape list.
- Contrast the trilogy: each prior lab's escaper left a terminator/closer/shift
  reachable; here NOTHING needs reaching — evaluation is unconditional. Strongest
  escaper, simplest payload, same root misunderstanding one level deeper.

## Trust boundary model
```
Attacker URL ──► GET param ──► server template into `…` (data?)
                                                                     │
              [TRUST BOUNDARY: literal text(data) → evaluated expr(code)]
                                                                     ▼
                              ${alert(1)} runs at literal construction
                                                                     │
                                                                     ▼
                                              arbitrary JS (page origin, parse)
```

## Enabling conditions (checklist)
1. Attacker-influenced text inside backtick literals (search echoes in scripts,
   i18n/template strings with user values, logging/telemetry JS, SSR'd state blobs
   using literals).
2. `${}` surviving (it always does — it's the literal's grammar, unfilterable
   without abandoning literals).
3. No CSP blocking inline scripts (none here — and the code IS inline script, so
   `script-src` self-or-stricter would blunt it as depth).
4. Crafted-URL delivery (link-based; parse-time fire, no interaction).