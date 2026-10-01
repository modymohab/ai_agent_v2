# Root Cause — HTML-encoding applied to a JavaScript-string sink

## The vulnerability
The `search` parameter is echoed into a single-quoted JavaScript string literal with
an HTML-oriented encoding (`<>`→entities) that leaves the operative characters
(`'`, `"`, `\`) untouched. The attacker terminates the string with a raw `'`,
injects a statement, and comments out the template tail — the encoding defends
against tag injection into a sink that never parses tags.

## Root cause (framing)
- **Wrong-context encoding**: the escaper neutralizes HTML metacharacters (`<>`)
  for a value embedded in JAVASCRIPT SOURCE. In a JS string context the dangerous
  set is `' " \ <newline>` (+ `</script>` for the HTML-parser layer above). Encoding
  `<>` while passing `'` raw is defending a threat the sink doesn't have while
  ignoring the one it does.
- **Asymmetric escapers per location** (verified byte-exact): the `<h1>` echo encodes
  `'"<>&` AND doubles `\`; the script echo encodes only `<>`. Same input, two
  escapers, two verdicts (dead vs live). Coverage gaps move per location — re-map
  every reflection even within one response.
- Failed assumption: *"`<`/`>` filtering makes echoes safe."* Third appearance of
  this fallacy in the KB (reflected-attribute, eval-JSON-adjacent, now JS-string):
  tag-encoding only ever closes the TAG degree of freedom.

## Trust boundary model
```
Attacker URL ──► GET param ──► server template concat into <script> (data?)
                                                                     │
              [TRUST BOUNDARY: template text(data) → script source(code)]
                                                                     ▼
                         var searchTerms = '';alert(1);//';
                                                                     │
                                                                     ▼
                                              statement execution (page origin)
```

## The terminator enumeration (general rule for JS-string sinks)
Given template `'…TERM…'` (or `"…"`), enumerate which characters can END the string
in the token stream: the matching quote (iff raw), a raw newline (breaks without
executing — denial, not injection), `\` (escapes the NEXT char — useful only if what
follows forms a terminator, cf. eval-JSON lab). Here exactly one works: `'`. The
payload is then forced: `TERM quote + statement + tail-neutralizer (// or balancing
code)`. No creativity required once the terminator set is known — enumerate, don't
guess.

## Enabling conditions (checklist)
1. Request data echoed into `<script>` string literals (search echoes, error messages
   in JS, JSON-in-HTML with string fields, config blobs with user values).
2. Quote (matching the delimiter) surviving raw; `<>`-only encoding is the classic
   enabler signature.
3. A tail-neutralizer available (`//` needs no newline control; otherwise balance
   with `';` + valid continuation or trailing string).
4. No CSP blocking inline script execution (none here — and the injection IS inline
   script, so `script-src` self/none would still need evaluation; only removing the
   echo fixes it).