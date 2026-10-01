# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a server reflects request data into markup, map EVERY reflection to its
> context and test the encoding FOR THAT CONTEXT. `<>`-encoding stops tag injection
> but leaves attribute-breakout (`"`/`'` + event handler) wide open; full encoding in
> one location says nothing about the next. The winning payload is
> `"<trigger> <handler>="<js>` with `autofocus` for zero-click fire — and every quote
> on both sides of the payload, including the template's own delimiters, must be
> accounted for.**

Coupled rules:
1. **Encode for the context, audit per location**: text needs `&<>`; attributes need
   `&"'<>`; JS strings need more. A single `<>`-only helper applied everywhere is a
   systematic hole, not a single bug — on a real app, go find its siblings.
2. **Payload accounting**: write the payload as `PREFIX + TEMPLATE-SUFFIX` on paper
   before firing. Here: `" autofocus onfocus="alert(1)` + `">`. A missing `"`
   silently converts the template delimiter into JS syntax (no-error, no-fire) — the
   most common reason "correct-looking" attribute payloads fail.
3. **Prefer load-time triggers**: `autofocus`+`onfocus` converts a click-gated vector
   into zero-click; always check whether the injectable element can carry `autofocus`
   (inputs, buttons, textarea, select, details, dialog…).

## Recon indicators (how to find this class again)
- Search boxes, error pages ("no results for X"), login/signup validation echoes,
  redirect `?next=`/bounce pages, 404 pages reflecting the path — anywhere a request
  value is mirrored into HTML.
- The two-request discriminator: benign marker (find reflections) → metachar set
  `"'<>&` (map encoding per reflection). Two requests fully characterize the sink.
- Responses without CSP + search/error reflection = prime reflected-XSS surface.
- Watch for ASYMMETRIC encoding between reflections of the same input — the
  signature of a coverage gap (fully-encoded `h1` next to raw-quote `value`).

## Verification techniques (reusable)
1. **Unique-marker reflection sweep first** (find ALL sinks before choosing ANY payload).
2. **Single metachar-set probe** (`ENC"'<>&`) read per location — cheapest complete
   encoding map.
3. **Numeric side-effect payloads for proving** (`document.title=918273`): no quote
   balancing inside the JS, so a fire/no-fire result isolates template-quoting issues
   from JS-syntax issues.
4. **CDP + settle for focus-event assertions**: `--dump-dom` races autofocus (stale
   serialization); drive with CDP, wait, assert `document.title` AND
   `document.activeElement`.
5. **Negative pair**: `<script>` neutralization (proves the stated defense is real) +
   sibling-context encoding (proves you picked the one live reflection).

## Common mistakes that miss this
- **Trusting the lab title's defense** ("angle brackets encoded ⇒ safe") and stopping —
  the title describes the filter, not the verdict; quotes are the operative charset here.
- **Payload without quote accounting**: `onfocus=` with no opening `"` (template quote
  absorbed → silent syntax error); or a trailing `"` that double-closes.
- **Testing only `<script>`/`<img>` payloads** → encoded → false "not vulnerable".
- **Checking only the first/visible reflection** (the `h1`) and missing the `value`
  attribute one line below.
- **Only verifying in `--dump-dom`** for focus-event vectors (timing false-negative).
- **Assuming `'` works like `"`** in a double-quoted attribute (it doesn't — inert).
- **Forgetting transport encoding**: raw `"`/spaces in the URL may be normalized by
  browsers/proxies — single-percent-encode reserved chars in delivered links.

## Cross-cutting
- This lab + the stored-XSS lab share the deep pattern (per-location encoding coverage
  gaps); this lab + the DOM labs share the payload-selection discipline (match the
  sink: markup vs fragment vs URI vs attribute). The reflected method (sweep →
  per-context map → quote-accounted payload → side-effect proof → negatives) now joins
  the KB's method inventory alongside field-mapping (stored) and source/sink audit (DOM).
- Reflected XSS is link-delivered like the DOM labs but server-rendered like the stored
  lab — remediation lives in the server template (context-correct encoding), verified
  by response inspection, unlike DOM sinks.