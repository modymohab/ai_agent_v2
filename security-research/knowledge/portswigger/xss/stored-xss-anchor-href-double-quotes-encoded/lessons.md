# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When user input is stored into `href`/`src`/`action` (or any scheme-interpreting
> sink), quote-encoding is necessary but never sufficient — the value itself must pass
> scheme validation (allow `http(s)` + relative, reject `javascript:`/`data:`/
> `vbscript:`). Test the whole value (`javascript:…`) BEFORE testing breakouts: if no
> validation exists, no breakout is needed and the finding is already complete.**

Coupled rules:
1. **Two degrees of freedom per URI sink**: break OUT of the value (needs delimiter
   failure) vs. BE the value (needs validation failure). Audit both; this lab's defense
   closed only the first.
2. **Stored × navigation is the highest-conversion link-free shape**: DOM href needs a
   crafted link per victim; stored href poisons native UI for all future viewers.
   When triaging, stored-navigation outranks both parents.
3. **Never assume cross-build uniformity**: this build hardened `comment` (raw in the
   first stored lab) and left `website` open — the coverage gap MOVED. Re-map every
   field on every target, even "the same app".

## Recon indicators (how to find this class again)
- Profile/website/social-link fields, avatar links, "source" citations, author bylines,
  markdown `[text](url)` renderers, redirect-parameter links rendered into pages.
- Two-request discriminator: store `https://MARKER.…` (verbatim? encoded how?) then
  store `javascript:…` (accepted?). Verbatim + accepted = finding.
- Form inputs for URLs WITHOUT `pattern`/validation hints, or with client-only hints
  (bypassed by direct POST) — then confirm server-side absence the same way.
- Comment/review/profile + link rendering + no scheme check = hunt here first.

## Verification techniques (reusable)
1. **Per-field marker map on every build** (never port a previous build's map).
2. **Whole-value scheme probe before breakout probes** (cheapest decisive test).
3. **Parallel non-blocking stored comment** (`javascript:void(title=…)`) for CDP click
   proofs, keeping the acceptance payload pristine.
4. **CDP stored-click proof**: navigate → find anchor by text → `.click()` →
   side-effect assertion. Reuses the jQuery-href harness unchanged — stored vs DOM
   differs only in how the href got there.
5. **Negative pair**: `"`-breakout dead (`&quot;`) + text contexts encoded — proves you
   found the ONLY live reflection.

## Common mistakes that miss this
- **Reading the title as a verdict** ("double quotes encoded ⇒ safe") — the title
  names the closed degree of freedom, not the open one.
- **Only testing breakouts** (`" autofocus…`) → encoded → false "not vulnerable"
  without ever trying the whole value as `javascript:`.
- **Porting the previous build's field map** (comment-was-raw) instead of re-mapping —
  here `comment` is dead and `website` is the sink.
- **Firing markup at a URI sink** (`<script>`, `<img onerror>` as website) — inert
  strings in an href; wrong payload family (same category error as the DOM href lab).
- **Missing the click gate in verification**: loading the page proves storage, not
  execution — a click (CDP or physical) is mandatory for navigation sinks.
- **Forgetting transport encoding** on direct POSTs is less of an issue here (form
  fields), but crafted verification LINKS still need single-encoded reserved chars.

## Cross-cutting
- Execution-moment matrix gains its stored row: DOM-href (crafted link per victim,
  click) vs STORED-href (one store, all viewers, click). Same payload family, same
  gate, strictly greater delivery.
- The invariant audit (sweep → per-context map → family-correct payload → side-effect
  proof → negatives) now spans stored-text, stored-URI, reflected-attribute, and all
  four DOM sink shapes — eight labs, one method with context-specific payload rules.
- Remediation note for future reports: quote-encoding AND scheme allow-listing are
  BOTH required on URI sinks; either alone leaves one degree of freedom open.