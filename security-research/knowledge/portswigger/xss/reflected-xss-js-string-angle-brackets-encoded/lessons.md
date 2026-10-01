# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When request data is echoed into `<script>` string literals, enumerate the
> TERMINATORS (matching quote iff raw; `\` iff it yields a terminator; newline =
> breakage not breakout; `</script>` iff brackets raw), then emit
> `QUOTE + STATEMENT + TAIL-NEUTRALIZER`. `<>`-encoding is expected and irrelevant —
> the breakout never uses brackets. Byte-verify escapers per location (xxd beats
> repr), read continuation lines (raw newlines split responses), and prefer
> `//`-tailed numeric-title probes while proving.**

Coupled rules:
1. **Wrong-context encoding is the whole bug class**: HTML-encoding a JS-string sink
   (like quote-encoding an href without scheme checks, like tag-filtering an
   attribute) always leaves the operative charset open. Name the SINK's charset,
   not the filter's.
2. **Asymmetric escapers are the norm, not the exception**: two echoes, two escapers,
   two verdicts — in ONE response. Map each; never generalize one location's safety.
3. **Terminator enumeration beats payload guessing**: list what CAN end the string,
   pick the first viable, shape follows mechanically (`';JS;//` here;
   `\"`-shift+`}`+`//` where quotes are escaped — cf. eval-JSON lab).

## Recon indicators (how to find this class again)
- Search echoes, error messages, config blobs, analytics vars (`var x = 'USER';`,
  `dataLayer = {...}`, `window.__INITIAL_STATE__` with user fields) inside `<script>`.
- The two-request discriminator: marker (find echoes incl. script blocks) →
  `'"<>\`;`-newline set (map per echo, read continuations).
- `<>`-encoded-but-quotes-raw inside `<script>` = instant finding; verify with
  `';<harmless side effect>;//`.
- JSON-in-HTML + `eval` nearby = the harder cousin (needs escape-shift); plain
  string echo = this lab (direct breakout).

## Verification techniques (reusable)
1. **Continuation-line reading**: raw-LF probes split server lines — always view the
   region (`sed -n '/a/,+1p'`), never a single grepped line.
2. **xxd for escaper truth** (doubling vs raw; `0A` vs `5C 6E` — repr conflates them).
3. **Numeric-title `//`-tailed probes** for clean automated proof.
4. **Negative `</script>` probe** (confirms the stated defense, scopes the claim).
5. **Terminator table** per sink (worked/structural/unneeded) — the durable artifact.

## Common mistakes that miss this
- **Trusting `<>`-encoding as safety** (third KB appearance of this fallacy).
- **Checking only the visible echo** (`<h1>`, fully encoded) and missing the script
  block below the fold.
- **Firing tag payloads only** → encoded → false "not vulnerable".
- **Forgetting the tail neutralizer** (`';alert(1);` without `//` → trailing `';`
  throws — and worse, the throw occurs AFTER alert… actually order: `'';alert(1);';`
  — alert fires THEN throw on `';`+newline. Still solves, but noisy/breaks downstream
  code; `//` keeps the page functional and stealthy).
- **Line-grepping a newline-containing probe** and misreading truncated evidence.
- **Assuming `"` works like `'`** in a single-quoted string (inert).
- **Repr-based escaper reading** (`\n` vs `\\n` ambiguity) instead of hexdumps.

## Cross-cutting
- With the reflected-attribute lab, the reflected server-side pair is complete:
  attribute-breakout (`"`) vs JS-string-breakout (`'`) under identical `<>`-encoding —
  same method (sweep → per-context map → quote-accounted payload → side-effect proof
  → negatives), mirrored payloads.
- Against the eval-JSON lab: same "echo into code" shape, opposite escaper facts
  (quotes raw here → direct; quotes escaped there → shift) — the escaper, not the
  sink, sets difficulty. Both live under "reflection-into-code" in future triage.
- Twelve labs, one invariant method; payload families now span markup, fragment, URI,
  JS-source (string + evaled-JSON), template-expression, and JS-string-derivation.