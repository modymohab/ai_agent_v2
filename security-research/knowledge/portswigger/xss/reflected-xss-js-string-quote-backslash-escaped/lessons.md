# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When an echo into `<script>` has quotes AND backslashes escaped, stop attacking
> the JS layer (terminator set: EMPTY) and go one layer up: the HTML tokenizer ends
> script elements at raw `</script>` before any JS parsing happens. Payload:
> `</script><script>QUOTLESS-JS</script>` — and quoteless/double-quoted discipline
> applies INSIDE the fresh block too, because the same escaper covers post-closure
> text. Parser precedence (tokenizer > script engine) is the exploit primitive.**

Coupled rules:
1. **Layer-ordered testing for script echoes**: JS-layer terminators first (`'`,
   `\`, newline); when the set is empty, HTML-layer (`</script>` closure) — never
   the reverse order, and never assume one layer's defense covers the other.
2. **Inner-payload charset discipline**: the escaper transforms your ENTIRE input
   including post-closure text — a closure that parses but throws (single quotes
   mangled) looks identical to "filter works" in a title check; assert execution,
   and keep inner payloads to surviving charsets (`"`, quoteless calls).
3. **Trilogy synthesis** (echo-into-code, ordered by escaper): quotes-raw →
   `';JS;//`; quotes-escaped+`\`-raw → shift+grammar; quotes+`\`-escaped →
   `</script>` closure. Diagnose the escaper, then select the layer — the three
   shapes share nothing except the audit method.

## Recon indicators (how to find this class again)
- `var x = 'USER';`-shaped echoes (search terms in scripts, analytics vars,
  config blobs, JSON-in-HTML string fields, error messages in JS).
- The two-probe discriminator: metachar map (`'"<>\`;newline) → which layers survive?
  Quotes raw = JS-layer game; quotes+backslash escaped + brackets raw = closure game.
- `</script>` appearing VERBATIM in script-block echoes (send it raw once — if it
  reflects, the lab is half-solved).
- View-source inspection of `<script>` blocks generally (curl + grep for user data
  inside script tags — the highest-yield 60 seconds in reflected-XSS hunting).

## Verification techniques (reusable)
1. **Terminator-set analysis per layer** (JS: which chars end strings? HTML: does
   `</script>` survive?) before choosing payload families.
2. **Inner-payload discipline**: quoteless/`"`-only inside fresh blocks when the
   escaper mangles quotes (prove with a title marker, not alert).
3. **DOM-split inspection**: confirm the closure PARSED (two script elements in the
   dump) separately from execution (title change) — mechanism vs effect isolated.
4. **Failed inner-quote attempt preserved** as escaper-scope evidence.
5. **Real-browser acceptance** to close (alert needs no quotes — ideal closer).

## Common mistakes that miss this
- **Stopping at "quotes escaped ⇒ safe"** (the defense's claim — true only at the
  JS layer; the hole moved up-stack).
- **Firing `';`-shaped payloads only** → escaped → false "not vulnerable".
- **Closure with single-quoted inner JS** → parses but throws → misread as "filter
  works" (the failure mode unique to this escaper scope).
- **Assuming the h1's full encoding covers the script block** (asymmetric escapers
  per location — established pattern, re-verified here).
- **Forgetting parser precedence** (reasoning about JS strings while the tokenizer
  decides first — the core mental-model fix this lab teaches).
- **Missing the echo entirely** (script blocks below the fold; grep `<script>` for
  user data as a habit, not just visible text).

## Cross-cutting
- Echo-into-code trilogy complete: JS-string-direct, eval-JSON-shift,
  script-closure — one audit method (sweep → per-layer map → terminator analysis →
  family-correct payload → side-effect proof → negatives), three layer selections.
  Future echo-into-code encounters start from the escaper map and pick a row.
- Eighteen labs; payload families now also include script-element-closure shapes.
  The invariant holds: name the PARSERS in play (HTML tokenizer? JS engine? JSON?
  Angular compiler? jQuery? SMIL?) and attack the weakest layer's survivors.