# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a URL (or part of it) is echoed into markup, determine the ENCODING FAMILY
> first: URL-encoding kills `<>`/`"` but spares `'`; HTML-encoding kills markup
> metachars per context; a reject-filter 400s. Then match the breakout to the
> survivors — here `'` out of a single-quoted `href`. And when the host element is
> inert (`<link>`, `<meta>`, `<title>`, `<base>`), reach for `accesskey` + handler:
> keypresses synthesize clicks on unclickable things. Byte-prove the template
> (`xxd` the suffix) instead of modeling it.**

Coupled rules:
1. **Encoding-family identification before payload shape**: `%22`/`%3c` in the echo
   = URL-encoding (breakout: `'`); `&quot;`/`&lt;` = HTML-encoding (breakout depends
   on context gaps); 400s = reject-list (oracle-map). Three families, three methods.
2. **Inert-element activation via accesskey**: any element + `accesskey` + `on*` =
   keypress-gated click host, including `<head>` children. Check focusability needs
   (`<link>` worked WITHOUT tabindex here — accesskey click-synthesis doesn't require
   focusability, unlike fragment-focus).
3. **Byte-prove templates**: `xxd` the exact suffix bytes (`'/>'` here) — mid-session
   misreads of quote mechanics cost more time than one hexdump. Serialization
   (`getAttribute`, dump-dom) can mislead; bytes don't.
4. **Trigger–objective matching**: load (best) → fragment/event (good) → click
   (needs lure) → keypress (needs keys). This lab FORCES keypress (inert host, no
   load-fire shape) — accept the constraint early instead of fighting for autofocus.

## Recon indicators (how to find this class again)
- Canonical/OG/meta robes reflecting URLs: `view-source:` + unique query marker,
  then check the echo's encoding family with `'"<>` in ONE probe.
- `accesskey` anywhere in your payload vocabulary when hosts are inert but
  attributes are free.
- Objectives mentioning key combos / simulated users = accesskey lab (read FIRST —
  it selects the whole approach).
- Single-quoted attributes echoing URLs (redirects, canonicals, share links,
  `<base href>`, analytics `data-*` URLs).

## Verification techniques (reusable)
1. **One-probe family ID** (`'"<>` → `%22`/`%3c` vs `&quot;`/`&lt;` vs 400).
2. **xxd template reconstruction** (prefix quote + suffix bytes — no modeling).
3. **Path-vs-query routing check** (`/MARKER` → 404 here constrained input to query).
4. **Headless handler-liveness attempt** (honest anomalies recorded, not hidden).
5. **Platform acceptance as ground truth** when automation can't reproduce the
   trigger (simulated keys, victim bots, time-based events).

## Common mistakes that miss this
- **Assuming URL-encoding = safe for markup** (the defense's exact error — `'`).
- **Assuming `<head>`/`<link>` elements can't host execution** (attributes don't
  care about renderability).
- **Firing tag payloads at `%3c`-encoded echoes** (dead by category).
- **Trying `"`-breakout** (literal `%22` text — dead by category).
- **Modeling template quotes from memory** instead of hexdumping (the mid-session
  misread cost a full CDP detour here).
- **Trusting serialization over bytes** when they disagree (re-verify bytes first).
- **Missing the objective's keypress note** and optimizing for load-time fire that
  the sink cannot provide.
- **Forgetting `+` vs `%20`/literal spaces** in query payloads (cosmetic here, fatal
  in exact-match filters).

## Cross-cutting
- Trigger taxonomy now spans: parse/load, resource-error, click, fragment-change,
  fragment-focus, compiler-bootstrap, manufactured-resize, and KEYPRESS
  (accesskey-synthesized click). Seventeen labs; the invariant method (sweep →
  per-context/family map → byte-proven template → family-correct payload →
  side-effect proof → negatives) keeps absorbing new trigger physics unchanged.
- URL-encoding-as-filter joins the filter-species inventory (HTML-entity,
  reject-list, single-replace, none): identify family → match breakout → verify.