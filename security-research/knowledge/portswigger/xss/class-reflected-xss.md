# Class Knowledge — Reflected XSS (server-rendered)

> Reusable reference derived from PortSwigger lab:
> `reflected-xss-attribute-angle-brackets-encoded` (see its folder for the worked case).
> Complements `class-stored-xss.md` (persistence) and `class-dom-xss.md` (client sinks):
> reflected XSS is server-rendered but per-request — no storage, no client sink.

## Definition
Reflected XSS occurs when request data (parameter, header, path, cookie) is inserted
into the server's HTML response without context-correct encoding, executing in the
victim's browser when they visit a crafted URL. Payload travels request → template →
response; it never persists and never touches a client-side sink.

## The trust-boundary model
```
Attacker URL ──► request value ──► server template concat (data)
                                                  │
              [TRUST BOUNDARY: template text(data) → response markup(code)]
                                                  ▼
                                   victim parser → execution (app origin)
```
Remediation lives server-side (encode at render), verified by RESPONSE inspection —
unlike DOM XSS (client fix, needs execution proof).

## Core method: sweep → per-context map → quote-accounted payload
1. **Reflection sweep**: benign unique marker; grep EVERY occurrence (h1, inputs,
   titles, hidden fields, JS blocks, comments, error text).
2. **Encoding map**: one metachar-set probe (`ENC"'<>&`); read EACH reflection's
   output encoding separately. Asymmetric encoding between reflections of the same
   input is the signature of a coverage gap.
3. **Payload by context** (never reuse across contexts without re-deriving):

| Reflection context | Must encode | Breakout payload shape |
|---|---|---|
| element text | `& < >` | `<script>` / `<img onerror>` (needs `<`) |
| double-quoted attribute | `& " < >` | `" [autofocus] onfocus="JS` |
| single-quoted attribute | `& ' < >` | `' [autofocus] onfocus='JS` |
| unquoted attribute | + whitespace `= backtick` | ` autofocus onfocus=JS` (space breaks) |
| JS single-quoted string | `\ ' " < > & /` + newlines | `';JS//` or `</script><script>JS</script>` |
Empirically confirmed (lab `reflected-xss-js-string-angle-brackets-encoded`): with
`<>`-only encoding, `';alert(1);//` is the forced shape; `</script>` dies on `&lt;`,
`"` is inert in `'…'`, trailing `\` strands across the newline. New rule learned
there: **escapers differ per location in the SAME response** (h1 doubled `\` while
the script passed it raw — byte-verified) — never generalize one echo's safety.
| URL param in `href=…` | scheme validation | `javascript:JS` |

4. **Quote accounting**: write `PAYLOAD + TEMPLATE-SUFFIX` on paper first. Every
   delimiter on both sides must resolve — a missing `"` silently folds the template's
   own quote into your JS (syntax error, no-fire, perfectly parsed DOM).

## Partial-encoding patterns (the actual bug class)
- `<>`-only encoding (this lab): kills tag injection, leaves attribute-breakout.
- Quote-encoding without `&`: `&`-based smuggling (`&quot;` decoding differentials).
- Blacklist stripping (`<script>` removed once): double-nesting / case / encoding bypasses.
- The operative question is always: "which EXACT characters survive into MY context?"

## Load-time triggers without angle brackets
`autofocus` + `onfocus` (inputs/buttons), `<body onload>` (if body injectable),
`<details open ontoggle>`, `<marquee loop=1 behavior=slide …>` (legacy), `<select
autofocus onfocus>`. Prefer zero-click over hover-gated handlers.

## Verification methodology (reusable)
1. Marker sweep → metachar map (2 requests characterize most pages).
2. Prove with side-effect payloads; prefer NUMERIC `document.title=N` while proving
   (no inner-quote balancing to confound template-quoting diagnosis).
3. Negative pair: `<script>` neutralization + sibling-context safety.
4. Focus-event vectors: CDP + settle (assert `title` AND `activeElement`); `--dump-dom`
   races autofocus and false-negatives.
5. Real-browser `alert()` + platform acceptance to close.

## Impact frame
- Link-delivered, per-request, zero-persistence; conversion depends on trigger
  (autofocus ≈ load-time ≈ highest; hover/click-gated lower).
- Same origin-consequences as all XSS (theft, ATO, phishing) once fired.
- `HttpOnly` raises theft cost (in-context actions instead of cookie read) but never
  prevents impact.
- Audit the ENCODER, not just the page: a shared `<>`-only helper means siblings.

## Fix shape (recognition = know the fix)
Context-correct output encoding at every template emission point (framework
auto-escaping with the right context mode), plus CSP as depth. Never blacklist input
as the primary defense.

## Adversarial filters: WAF-oracle methodology (lab `reflected-xss-waf-bypass-body-onresize`)
When a reject-style filter fronts the echo, compute payload space as SET DIFFERENCE
with a 400-vs-200 oracle: (1) confirm reject-vs-strip with one battery; (2) sweep
tags (~45: known, case variants, separators, legacy/alias, custom); (3) sweep handlers
inside allowed hosts (common → obscure: pointer/capture/formdata/slot/storage/
language/rejection/resize/popstate/hashchange/unload/message); (4) test
parser composers (duplicate-`<body>` merges novel attributes onto document.body,
reflecting to window handlers). The winning shape is a COMPOSABLE unlisted pair
(here `<body>` × `onresize`) plus a MANUFACTURED trigger (framing iframe resized via
`onload` style mutation — zero interaction). Verify merge→handler→dispatch locally
(CDP), byte-verify served exploits after every server POST, and confirm victim legs
via access log + platform status (self-execution never equals victim acceptance).

## Custom elements vs tag blocklists (lab `reflected-xss-custom-tag-focus`)Finite tag deny-lists cannot cover unknown elements: `<xss>`, `<x>`, any unlisted tag
parses as a generic element supporting global attributes, event handlers, `id`, and
`tabindex`. Characterize filter shape with ONE probe (`<xss autofocus onfocus=X>`):
tag-only filtering (this lab — handlers open) vs tag+handler filtering (prior lab).
Zero-interaction trigger ships in the URL: `#id` fragment auto-focuses a
`tabindex`ed host on load (`<xss id=x onfocus=… tabindex=1>#x`). Signal discipline:
`alert(document.cookie)` proves data access where `alert(1)` proves only execution;
victim-gating must be verified by self-fire control (own alert must NOT flip the
banner) before delivery spend.

## Template literals: executable strings (lab `reflected-xss-template-literal-interpolation`)
Backtick echoes need NO breakout: `${7*7}`→`49` proves evaluation, `${JS}` is the
complete exploit — six neutralized classes (`'"<>\``) are irrelevant because
interpolation syntax (`$`, `{`, `}`) must survive for literals to function. Rules:
identify the STRING TYPE first (backticks = program, quotes = container); probe
interpolation before terminators; keep inner payloads quoteless. Strongest escaper,
simplest payload — the echo-into-code quartet's final member
(direct → shift → closure → interpolation).

## Backslash-shift in JS strings (lab `reflected-xss-js-string-backslash-escape`)
Escaper handles quotes but passes `\` raw → prepend `\` to the breakout
(`\';JS;//`): raw backslash collapses with the escaper's own (`\\` → one literal),
stranding the quote as a terminator. Iron rule violated: ESCAPE THE ESCAPE
CHARACTER FIRST. Diagnose per location with xxd (this lab: h1 doubled `\`, script
passed raw — asymmetry as coverage-gap signal); test the shift before any grammar
surgery. Ladder position: simplest of the three echo-into-code shapes
(direct → shift → closure).

## SVG-namespace gaps (lab `reflected-xss-svg-animatetransform-onbegin`)
Filters enumerated in HTML (+ headline SVG) miss the SVG event vocabulary: sweep tags
AND handlers per namespace. Here `<animateTransform>` passed while `<animate>`/
`<animateMotion>`/`<set>` were listed, and SMIL `onbegin` passed while
`onload`/`onerror`/`onfocus`/`onmouseover` were listed — composing into
`<svg><animatetransform onbegin=JS>`, which auto-fires at document load with no
attributes, no clicks, no obfuscation. Rules: (1) map SVG/MathML/custom vocabularies
separately from HTML; (2) test namespace-native events (`onbegin`, and by family
`onend`/`onrepeat`); (3) prefer intrinsic triggers (SMIL auto-begin) over
manufactured ones; (4) prove the pair survives TOGETHER (lists can interact).

## Script-closure over escaped JS strings (lab `reflected-xss-js-string-quote-backslash-escaped`)
When quotes AND backslashes are both escaped (JS-layer terminator set: EMPTY) but
`<>` survive, stop attacking JS and go one layer up: the HTML tokenizer ends script
elements at raw `</script>` before any JS parsing. Payload `</script><script>JS</script>`
with quoteless/`"`-only inner JS (the escaper covers post-closure text too — inner
single quotes throw). Completes the echo-into-code trilogy: quotes-raw → `';JS;//`;
quotes-escaped+`\`-raw → shift+grammar; quotes+`\`-escaped → `</script>` closure.
Diagnose the escaper, then select the LAYER — parser precedence is the primitive.

## URL-encoding as filter + accesskey triggers (lab `reflected-xss-canonical-accesskey`)
A distinct filter species: URL-encoding the echo (`"`→`%22`, `<>`→`%3c%3e`) while
leaving `'` raw — tags/double-quotes dead, single-quote breakout live in
single-quoted attributes. Identify the ENCODING FAMILY first (`%22` vs `&quot;` vs
400s), then match the breakout. Companion finding: `accesskey` + handler turns ANY
element (even non-rendered `<link>`) into a keypress-gated click host — the trigger
when load/error/click/fragment shapes are all unavailable. Byte-prove templates
(`xxd` the suffix); re-verify bytes whenever serialization disagrees with the model.