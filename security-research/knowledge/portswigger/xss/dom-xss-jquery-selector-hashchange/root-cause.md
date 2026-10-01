# Root Cause — jQuery selector sink with hashchange gating

## The vulnerability
The home page registers a `hashchange` handler that concatenates the decoded URL
fragment into a jQuery selector string using the `:contains()` pseudo-selector. jQuery
1.8's `$()` HTML-sniffing behavior diverts strings containing `<…>` from CSS selection
to DOM-fragment construction, turning attacker fragment text into a live (if detached)
element whose resource-error handler executes in the page origin.

## Root cause (framing, three layers)
1. **Insecure sink API**: jQuery `$()` is dual-purpose — selector engine AND HTML
   factory — disambiguated by a regex sniff (`rquickExpr`-family: optional non-`#`/`<`
   prefix + `(<…>)` + non-`>` suffix). Any user input that can smuggle `<…>` into the
   string flips the function from "find" to "create". Safe alternatives: `document.
   querySelector` (pure selector, throws on garbage instead of creating), or never
   concatenating untrusted text into selectors (use `.filter()`/text comparison).
2. **Detached-element execution**: the created `<img src=x>` is never inserted, yet
   `onerror` fires — resource loading and its error events do not require document
   attachment. "Not inserted ⇒ inert" is a false assumption many testers hold.
3. **Event-gated reachability**: the sink is wrapped in `$(window).on('hashchange', …)`.
   Code that only runs on an event is unreachable by cold navigation; the attacker must
   manufacture the event in the victim context (here: iframe fragment mutation).

## Trust boundary model
```
Attacker iframe (exploit origin) ──► victim iframe navigation (LAB origin)
                                                │  fragment CHANGE (same-document nav)
                                                ▼
                                  [EVENT GATE: hashchange]
                                                ▼
   location.hash ──► decodeURIComponent ──► selector-string concat (data)
                                                │
              [TRUST BOUNDARY: selector text(data) → constructed element(code)]
                                                ▼
                    jQuery HTML-sniff → buildFragment → detached <img>
                                                │
                                                ▼
                              resource-error → onerror (LAB origin, victim ctx)
```

## Version dependence (scope the claim honestly)
- CONFIRMED on this stack: jQuery 1.8.2 (+ Migrate 1.4.1, which only logs here).
- The sniff-then-create behavior for `<…>`-containing non-`<`-leading strings is a
  1.x/2.x-era semantic; jQuery 3.x tightened `$()` HTML detection (leading-`<` after
  whitespace). Same-shape code on jQuery 3 routes to Sizzle and throws instead of
  executing. So: the PATTERN to hunt (untrusted text → `$()`) is version-independent;
  the EXPLOITABILITY verdict requires testing the actual jQuery build.

## Enabling conditions (checklist)
1. Untrusted string concatenated into `$()` (selector position, any pseudo-selector).
2. jQuery build whose HTML-sniff accepts the smuggled `<…>` (test, don't assume).
3. An event (or flow) that actually invokes the sink in the victim's browser.
4. A delivery path to the victim (framing permitted here — no `X-Frame-Options` on lab
   responses; otherwise link-based fragment delivery + a change trigger).
5. No CSP blocking inline handlers (none here).