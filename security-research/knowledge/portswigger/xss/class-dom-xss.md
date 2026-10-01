# Class Knowledge — DOM-Based XSS

> Reusable reference derived from PortSwigger lab:
> `dom-xss-document-write-location-search` (see its folder for the worked case).

## Definition
DOM-based XSS is executed when a **client-side** script reads an attacker-controllable
**source** and passes it, unsanitized, into a **sink** that hands data to the HTML/JS
parser. The server is not (necessarily) involved in the vulnerable step — payloads often
never appear in any HTTP response ("type-0" DOM XSS).

## Source → sink model (the core skill)
| Source (attacker influence) | Sink (execution) |
|---|---|
| `location.search` / `location.hash` / `location.href` | `document.write()`, `document.writeln()` |
| `document.URL`, `document.documentURI` | `element.innerHTML = …`, `outerHTML` |
| `document.referrer` | `insertAdjacentHTML()`, `DOMParser.parseFromString()` |
| `window.name` | `eval()` / `Function()` / `setTimeout/setInterval(string)` (semi-harmful) |
| `postMessage` events | `jQuery .html()` / attribute setters / `element.location`, `location=…` |
| `localStorage`/`sessionStorage`/cookies | anchor/`href` assignment, `src`/`srcdoc` |
| `returnPath`/`next`/`redirect`-style params | jQuery `.attr("href"/"src"/"action")`, `location=`, `window.open()` — CLICK-gated |
| `location.hash` (or any text) into `$()` | jQuery selector/HTML-sniff sink — EVENT-gated (`hashchange`/`popstate`/`message`) |

Recognition test: does a JS variable reach a parser/HTML-modifying API without escaping?
Then derive the **context** the value occupies to pick the breakout primitive.

## Execution-moment matrix (empirically backed by five labs)
| Sink | Fires when | Payload family | Interaction | Lab ref |
|---|---|---|---|---|
| `document.write` | parse | HTML (`<script>` runs) | none | `dom-xss-document-write-location-search` |
| `innerHTML` et al. | resource error / auto event | event-handler element (`<script>` inert) | none | `dom-xss-innerhtml-location-search` |
| jQuery/anchor `href` (`.attr`, `location=`, `open()`) | navigation follow | `javascript:` URI (no markup) | **click required** | `dom-xss-jquery-href-location-search` |
| jQuery `$()` selector w/ HTML-sniff | `hashchange`/event | constructed-element handler (`<img onerror>` on detached node) | **victim fragment change** | `dom-xss-jquery-selector-hashchange` |
| `eval()`/`Function()` of server JSON (XHR/fetch response) | response arrival (load-time) | JS STATEMENTS (`..."};CODE;//` grammar) | none | `reflected-dom-xss-eval-json` |
Statement sinks subsume markup sinks (any JS goes, constrained only by template
grammar): map the escaper byte-exactly (`"`-escaped + `\`-raw = terminator factory),
close the template construct yourself (raw `}`), reach statement position, eat the
tail with `//`. Verify against EXACT server bytes via base64 in-page eval; use flag
assignments (never `alert`) in proofs; mirror the sink expression exactly.
Dual-personality APIs (`$()` selects OR creates by sniff) and detached-element
execution (`onerror` fires without insertion) are the two non-obvious facts here.
Event-gated sinks need event-manufacturing delivery: cold crafted links are inert
(proven: fresh-target navigation with payload never runs the handler); the canonical
template is a framing iframe that mutates the fragment post-load
(`src="…/#"` + `onload="this.src+='PAYLOAD'"`). jQuery-version caveat: the lenient
sniff is 1.x/2.x-era (1.8.2 confirmed); 3.x tightened `$()` HTML detection — always
evaluate the concatenated string in the real build.
Navigation sinks are simultaneously XSS (script scheme) and open redirect (http
scheme) — test both values. Harness note for click-gated sinks: local headless
Chromium + `--remote-debugging-port` + `Runtime.evaluate(el.click())`, asserting on a
`void()`-wrapped side effect; a bare `javascript:` expression returning a string
replaces the document (noisy signal, destroyed page).

## Wrapper leniency (content model ≠ parser behavior)
Empirically (Chrome 150, lab `dom-xss-document-write-select-element`): values written
inside `<option>` (in `<select>`) admit THREE live shapes — `</select>`-breakout+img,
bare-`<img onerror>` as an option child (proven incl. static-HTML control: general
parser leniency, not a document.write quirk), and bare `<script>` (in-select scripts
run per in-head rules). The wrapper constrains nothing here. Rule: test bare-tag,
breakout, and script shapes per (sink × wrapper) and assert on side-effects; never
deduce inertness from the content model. Contrast with `innerHTML` fragments, where
`<script>` IS neutered — same tag, opposite verdict by insertion path.

## Stored delivery + sanitizer bypass (stored-DOM hybrid)
Lab `stored-dom-xss-single-replace`: persisted comment JSON rendered client-side via a
first-occurrence-only escaper (`String.replace` with STRING pattern) into `innerHTML`.
Rules: (1) single-pass transforms are bypassed deterministically with DOUBLED
metacharacters (sacrificial first `<>`, survivor executes — verify the survivor is
byte-clean); grep `replace('<')` with string literals as a high-signal smell.
(2) Stored-DOM pairs stored reach with DOM triggers (load-time, no click) — triage
above both parents. (3) Probe server gates FIRST (benign-302 control + scheme/case
matrix): a 400-class allowlist (this lab's `website` scheme check) kills vectors the
client code promises — attack the thinnest layer; disambiguate stale-token 400s with
a benign rerun on the same token.

## Context → breakout-char map
| Context | Breakout primitive | Example payload prefix |
|---|---|---|
| double-quoted attribute of dynamically-written HTML | `"` (and `>` for tag-close) | `"><script>…</script>` or `" onload=… x="` |
| text node / element body | `<` | `<svg onload=…>` / `<script>` |
| single-quoted JS string `var x='…'` | `'` | `';alert(1)//` |
| script block raw text | `</script>` | `</script><script>alert(1)</script>` |
| CSS context (`url('…')`, style) | `')` / `;` | `');background:url(javascript:…)` |

## Key pitfalls that characterize DOM XSS
1. **Invisible in responses**: identical server response for benign vs malicious input.
2. **Server-side encoding ≠ protection**: the SSR reflection can be safely encoded while an
   unrelated client sink is exploitable. Only client sanitization/CSP/Trusted Types at the
   sink boundary help.
3. **document.write executes written `<script>`s** during parsing by spec — no event handler
   needed (unlike innerHTML, where script tags don't execute — requiring
   `<img src=x onerror=…>` style payloads).
4. **The sink API matters**: innerHTML won't run `<script>` but will run img/svg event
   handlers; document.write runs both. Choose payload to the sink semantics.
   Empirically backed sink-semantics matrix (labs: `dom-xss-document-write-location-search`,
   `dom-xss-innerhtml-location-search`):
   | Sink | `<script>` executes? | Breakout if attr-interpolated | Breakout if whole-content assignment |
   |---|---|---|---|
   | `document.write` | YES | YES (`"`, `>`) | none |
   | `innerHTML` / `outerHTML` / `insertAdjacentHTML` / jQuery `.html()` | NO — use event handlers | YES (same rule) | none |
   The innerHTML lab additionally proved the `<script>` neuter directly: the node is
   inserted (visible in serialized DOM) but never runs — so verifiers must assert on an
   execution side-effect (`document.title`), never on marker-string presence.
5. **URL decoding chain**: `URLSearchParams.get` decodes once; browsers may percent-collapse
   (`%25`→`%`, `%2F`→`/`) during navigation. Deliver single-encoded reserved chars and
   verify per browser.

## Verification methodology (reusable)
1. Static audit: find sink+source couple; reproduce the exact concatenation.
2. Map SSR reflections separately (marker + observe encoding) — separates server-side
   XSS from DOM XSS.
3. Execute in a real parser: headless dump / CDP / real tab; assert with a NON-BLOCKING
   probe (`document.title='MARK'`). `alert()` freezes headless rendering.
4. Dump the resulting DOM to confirm the breakout shape.
5. If CSP blocks `alert`/script, test scriptless variants for the same primitive
   (event handlers, img/svg).
6. Consider multiple sources to the same sink (search + hash + referrer) — each may need a
   different delivery link.

## Impact frame
- Executes in the app origin with victim privileges — same trust consequences as
  server-rendered XSS (theft, account takeover, phishing, data exfiltration).
- Delivery is link-based (victim must visit the crafted URL) unless a second bug stores
  the link (e.g., a stored-URL in an admin panel) → chains to stored DOM XSS.
- document.write-based sinks add a page-replacement quirk (write-after-load may tear down
  the page) useful for same-origin phishing.

## Fix shape (recognition = know the fix)
- Avoid string-building sinks entirely (use `textContent`, `createElement`/attribute APIs).
- Enforce **Trusted Types** and a restrictive **CSP** (both block document.write-style sinks).
- Never interpolate URL-derived data into HTML strings; validate/encode per context if a
  NO safe API exists — but sink avoidance is the durable fix.