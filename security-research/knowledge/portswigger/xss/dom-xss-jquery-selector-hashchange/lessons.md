# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When untrusted text is concatenated into jQuery `$()` (or any dual-purpose
> select-or-create API), test whether `<…>` content flips it from selection to
> construction — and remember constructed elements can fire resource handlers while
> still detached. If the sink sits behind an event (hashchange, message, storage,
> popstate), a cold crafted link is inert: delivery must manufacture the event in the
> victim's browser (framed fragment mutation is the canonical template).**

Three coupled rules this lab exists to teach:
1. **Dual-purpose APIs are sinks with two personalities**: `$()` selects OR creates
   based on a sniff. Audit the *actual build's* sniff (jQuery 1.x/2.x lenient,
   3.x strict) — exploitability is version-dependent, the audit pattern is not.
2. **Detached ≠ inert**: `<img src=x onerror=…>` fires without insertion. Never dismiss
   a construction sink because "nothing is appended".
3. **Event-gated sinks need event-manufacturing delivery**: map the gate first
   (cold-load test), then build the cheapest trigger (iframe + onload fragment append
   for hashchange; postMessage for message handlers; etc.).

## Recon indicators (how to find this class again)
- `$()` / `jQuery()` calls with string concatenation of `location.hash`, `location.search`,
  `referrer`, `postMessage` data, `localStorage`, or any widget state — especially inside
  `:contains()`, attribute selectors, or plugin options.
- `$(window).on('hashchange'| 'popstate' | 'message' | 'storage', …)` handlers that read
  ambient browser state into DOM APIs.
- jQuery 1.x/2.x (or unknown-version vendor bundles) + framing-permissive responses
  (missing `X-Frame-Options` / `frame-ancestors`) = victim-delivery viable.
- Exploit-server-style labs (or real bug-bounty targets with user inboxes/sharing):
  any feature that lets you get the victim to load YOUR page framing THE page.

## Verification techniques (reusable)
1. **Direct-sink probe before end-to-end**: `Runtime.evaluate` the exact concatenated
   expression in-page; `len` + exception-status tells you selection vs construction
   without any delivery machinery.
2. **Cold-vs-change pair**: fresh target (cold navigation with payload → must be inert)
   vs same-document mutation (must fire). The pair proves the gate and dictates delivery.
3. **Side-effect assertions** (`document.title='MARK'`), never string presence; `alert()`
   freezes headless harnesses.
4. **Delivery hygiene on exploit servers**: after EVERY form POST, re-GET the served
   bytes before delivering — some servers persist the posted body on any action, and a
   placeholder body silently disarms your exploit (observed firsthand).
5. **Access-log + banner double-confirmation**: victim UA in the log proves visit;
   banner flip proves the platform-observed signal (`print()` here) actually fired in
   the victim context. One without the other is inconclusive.

## Common mistakes that miss this
- **Assuming `$()` only selects** → treating selector injection as a DoS/cosmetic issue
  instead of testing construction.
- **Assuming detached elements can't execute** → dismissing the finding after seeing no
  insertion.
- **Testing only cold crafted links** → no event, no execution, false "not vulnerable".
- **Firing markup-parser payloads** (`<script>` for its own sake) instead of matching the
  sink: here the winner is a resource-handler element, for the same reason as the
  `innerHTML` lab — know which personality of the sink you're feeding.
- **Reasoning about jQuery from memory** instead of evaluating the concatenated string
  in the real build (version sniffing matters).
- **Breaking your own exploit via the tooling** (placeholder-body overwrite) and then
  blaming victim latency — verify served bytes, read the access log.

## Cross-cutting
- Completes the DOM-XSS quartet with a new axis — **trigger dimension**:
  | Sink | Fires when | Payload family | Interaction | Delivery note |
  |---|---|---|---|---|
  | `document.write` | parse | HTML (`<script>` OK) | none | self-URL |
  | `innerHTML` | resource error / auto event | event-handler element | none | self-URL |
  | jQuery `href` | navigation follow | `javascript:` URI | click | self-URL |
  | jQuery `$()` selector | **hashchange event** | constructed-element handler | **victim fragment change** | **framed delivery** |
- The invariant method (source/sink audit → context+trigger map → family-correct payload
  → side-effect assertion → negative control → delivery matched to the gate) now covers
  load-time, error-time, click-time, and event-time DOM XSS.