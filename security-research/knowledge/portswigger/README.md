# PortSwigger Web Security Academy — Research Knowledge Base

Reusable knowledge extracted from solved labs. Each lab folder uses a uniform structure:

```
<vuln-class>/<lab-slug>/
  metadata.md     — identity, scopes, status, tools
  attack-chain.md — full input→process→sink→result→impact data flow + field maps
  root-cause.md   — the actual flaw, trust boundary, assumptions that failed
  verification.md — evidence, probes, reproducibility, failed-candidate analysis
  impact.md       — confirmed / plausible / not-applicable impact
  lessons.md      — generalizable pattern, recon indicators, anti-mistakes
```

Class-level knowledge lives one directory up (e.g. `xss/class-stored-xss.md`).
Class files: `class-stored-xss.md`, `class-dom-xss.md`, `class-reflected-xss.md`, `class-angularjs-csti.md`, `class-csp-bypass.md`.

## Labs
### Cross-Site Scripting (xss/)
| Lab | Class / sub-class | Key lesson |
|---|---|---|
| `stored-xss-html-context-nothing-encoded` | Stored XSS — unencoded text context | Map ALL form fields→render contexts; the sink is the single field whose output encoding was omitted while siblings were encoded |
| `dom-xss-document-write-location-search` | DOM XSS — `document.write` sink, `location.search` source | DOM sinks are invisible in HTTP responses: client-side source→sink audit + browser execution proof required; attribute-context breakout `">`; never confuse with (encoded) SSR reflections |
| `dom-xss-innerhtml-location-search` | DOM XSS — `innerHTML` sink, `location.search` source | Sink semantics dictate payload family: `innerHTML` neuters `<script>` (proven inert) so event-handler elements are mandatory; whole-element assignment needs no breakout; assert on side-effects, not string presence |
| `dom-xss-jquery-href-location-search` | DOM XSS — jQuery `.attr(href)` sink, `location.search` source | Navigation sinks take URIs not markup (`javascript:`), fire only on click (CDP click-proof; `void()`-wrapped assertions), and double as open redirects — test both schemes |
| `dom-xss-jquery-selector-hashchange` | DOM XSS — jQuery `$()` selector sink, `location.hash` source, hashchange-gated, victim-delivered | Dual-purpose `$()` flips select→create on smuggled `<…>` (version-dependent); detached elements still fire handlers; cold links inert — manufacture the event (framing iframe + fragment mutation); verify served exploit bytes after every server POST |
| `reflected-xss-attribute-angle-brackets-encoded` | Reflected XSS — `?search=` into double-quoted `value`, `<>` encoded, quotes raw | Map EVERY reflection per context; `<>`-only encoding leaves `"`+handler open; account for all quotes incl. the template's; numeric title payloads isolate quoting bugs; CDP+settle for autofocus (dump-dom races focus) |
| `stored-xss-anchor-href-double-quotes-encoded` | Stored XSS — comment `website` into `href`, `"` encoded, scheme open | Quote-encoding without scheme validation is no defense for URI sinks: test whole-value `javascript:` BEFORE breakouts; stored×navigation = highest-conversion link-free shape; re-map every field per build |
| `dom-xss-document-write-select-element` | DOM XSS — `document.write` sink, `location.search` (`storeId`) inside `<select>`/`<option>` | Wrappers don't neutralize: breakout+img, bare-img-in-option, and bare-script ALL fire (static control proves parser leniency); test shape matrices per (sink×wrapper), assert side-effects |
| `reflected-dom-xss-eval-json` | Reflected-DOM hybrid — server JSON `searchTerm` into client `eval()` | Forget markup at code sinks: byte-map the escaper (`"`-escaped+`\`-raw=terminator factory), close the construct yourself (`}`), statement position, `//` tail; base64 exact-bytes harness; flags not alerts |
| `dom-xss-angularjs-expression` | DOM CSTI — reflected term compiled by AngularJS 1.7.7 (`ng-app`) | `{{7*7}}` first (compiler alive?), then `{{constructor.constructor("GLOBAL-JS")()}}`; scope has no globals — smuggle them in the generated string; verify surviving quote per build; version gates gadgets (no sandbox ≥1.6) |
| `reflected-xss-js-string-angle-brackets-encoded` | Reflected XSS — `?search=` into single-quoted JS string, `<>` encoded, quotes raw | `';JS;//` forced (tags dead, `"` inert in `'…'`); escapers differ per location in one response (xxd-verified); read continuation lines; terminator enumeration beats guessing |
| `reflected-xss-waf-bypass-body-onresize` | Reflected XSS + WAF bypass + victim delivery — unlisted `<body>`×`onresize` | 400-vs-200 oracle mapping (tags→handlers→evasions); body-merge sets window handler; iframe-resize manufactures the event (zero interaction); byte-verify exploits; log-confirm victim legs |
| `reflected-xss-custom-tag-focus` | Reflected XSS + tag-blocklist bypass + victim delivery — custom tag × focus | Unknown elements pass finite tag lists WITH handlers; `tabindex`+`#id` fragment auto-focuses on load (zero interaction, single URL); re-map filter shape per build; signal discipline (cookie-proof, victim-gated) |
| `reflected-xss-svg-animatetransform-onbegin` | Reflected XSS + SVG-namespace filter gap — `animateTransform`×`onbegin` | Sweep tags AND handlers per namespace (SVG/MathML/custom separately); SMIL `onbegin` auto-fires at load, no attributes/clicks/obfuscation; bypass by ontology gap, prove pairs survive together |
| `reflected-xss-canonical-accesskey` | Reflected XSS — full URL into single-quoted canonical `href`, URL-encoded | Identify encoding family first (`%22` vs `&quot` vs 400s); `'` survives URL-encoding → breakout; `accesskey`+handler = keypress-gated click on ANY element incl. `<link>`; byte-prove templates |
| `reflected-xss-js-string-backslash-escape` | Reflected XSS — `?search=` into JS string, quotes escaped, `\` raw | Prepend `\` to quote-breakout (`\';JS;//` — escaper's backslash collapses, quote strands); escape-the-escape-first rule; xxd per-location asymmetry; simplest echo-into-code shape |
| `stored-xss-onclick-entity-decode` | Stored XSS — comment `website` into `onclick`, `&` left raw | Smuggle terminators as entities (`&apos;` stored inert, decoded live at attribute computation — encode `&` first); assert decoded values; quoteless inner + parens; sync-read clicks |
| `reflected-xss-js-string-quote-backslash-escaped` | Reflected XSS — `?search=` into JS string, quotes+backslash escaped | JS-layer terminator set EMPTY → go one layer up: `</script>` closure (tokenizer precedes JS engine); inner payload quoteless/`"`-only; completes echo-into-code trilogy |
| `reflected-xss-template-literal-interpolation` | Reflected XSS — `?search=` into backtick literal, six classes escaped | String-type first: backticks EXECUTE — `${7*7}` proves, `${JS}` exploits; no breakout/closure/shift needed; quoteless inner discipline; strongest escaper, simplest payload |
| `reflected-xss-csp-policy-injection` | Reflected XSS + CSP bypass — `token` into `report-uri`, forged `script-src-elem` | Attacker bytes in policy + raw `;` = live directives (split before values); A/B blocked-vs-fired proof; directive-combination literacy; headers are injection surfaces too |
| `stored-dom-xss-single-replace` | Stored-DOM hybrid — comment JSON rendered via first-only `replace` into `innerHTML` | Doubled metacharacters beat single-pass sanitizers (sacrificial `<>`); probe server gates first (400-matrix killed the href vector); stored reach × DOM trigger = top triage |

## Cross-class cross-cutting methods (see per-lab lessons)
1. **Unique-marker field mapping** before any payload.
2. **Non-blocking execution proof** (`document.title`) for headless assertions
   (`alert()` freezes dumps).
3. **Fresh-session re-fetch** to distinguish stored from reflected; separate SSR vs DOM
   reflections separately.
4. **Failed-candidate analysis**: record why non-sinks (encoded fields / encoded SSR /
   wrong breakout primitive) failed — how the app is defended is actionable knowledge.
5. **Single-encode reserved chars** in delivery URLs; know the browser decode chain.

## Status log
| Date | Lab | Result |
|---|---|---|
| 2026-09-19 | Stored XSS into HTML context with nothing encoded | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in document.write sink using source location.search | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in document.write sink (2nd instance, new target) | SOLVED + pattern re-confirmed, see `xss/dom-xss-document-write-location-search/instances.md` |
| 2026-09-19 | DOM XSS in innerHTML sink using source location.search | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in jQuery anchor href attribute sink using location.search source | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in jQuery selector sink using a hashchange event | SOLVED (victim delivery) + knowledge written |
| 2026-09-19 | Reflected XSS into attribute with angle brackets HTML-encoded | SOLVED + knowledge written (+ new class file `xss/class-reflected-xss.md`) |
| 2026-09-19 | Stored XSS into anchor href attribute with double quotes HTML-encoded | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in document.write sink using source location.search inside a select element | SOLVED + knowledge written |
| 2026-09-19 | Reflected DOM XSS (eval of search JSON) | SOLVED + knowledge written |
| 2026-09-19 | DOM XSS in AngularJS expression (angle brackets/quotes encoded) | SOLVED + knowledge written (+ new class file `xss/class-angularjs-csti.md`) |
| 2026-09-19 | Reflected XSS into a JavaScript string with angle brackets HTML encoded | SOLVED + knowledge written |
| 2026-09-19 | Stored DOM XSS (single-replace escape bypass) | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS into HTML context with most tags and attributes blocked | SOLVED (victim delivery) + knowledge written |
| 2026-09-19 | Reflected XSS into HTML context with all tags blocked except custom ones | SOLVED (victim delivery) + knowledge written |
| 2026-09-19 | Reflected XSS with some SVG markup allowed | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS in canonical link tag (accesskey trigger) | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS into a JavaScript string with single quote and backslash escaped | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS into a JavaScript string with angle brackets and double quotes encoded and single quotes escaped (backslash raw) | SOLVED + knowledge written |
| 2026-09-19 | Stored XSS into onclick event (entity-decode smuggling) | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS into a template literal (Unicode-escaped) | SOLVED + knowledge written |
| 2026-09-19 | Reflected XSS protected by CSP, with CSP bypass (policy injection) | SOLVED + knowledge written (+ new class file `xss/class-csp-bypass.md`) |