# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a markup filter allows ANY SVG (or MathML, or custom elements), map the
> SVG event vocabulary specifically — SMIL timing events (`onbegin`, and by family
> logic `onend`/`onrepeat`) are handlers the HTML-centric list author never
> considered, and animation elements auto-begin at document load. The winning shape
> is `<svg><animatetransform onbegin=JS>` — plain, well-formed, zero-interaction,
> zero-obfuscation. Bypass by ontology gap beats bypass by trickery.**

Coupled rules:
1. **Map namespaces separately**: HTML tags, SVG tags, SVG animation tags, MathML
   tags, custom elements — a filter strong in one namespace is routinely absent in
   another. Sweep each vocabulary on its own terms (~25 probes mapped this lab).
2. **Map handlers per namespace too**: `onload`/`onerror`/`onfocus` (blocked) vs
   `onbegin` (passed) shows handler lists are ALSO namespace-blind. Always test the
   exotic events of the allowed namespace (SMIL: begin/end/repeat; media: cuechange;
   fullscreen: fullscreenchange/error — each gated by its element, each potentially
   unlisted).
3. **Prefer intrinsic triggers**: SMIL auto-begin needs no attributes, no clicks, no
   second navigation — the smaller the payload's filter footprint (one tag + one
   handler), the fewer list entries it can trip.
4. **No-encoding echoes + 400-oracles = fastest mapping surface**: verbatim reflection
   shows exactly what survives; status codes classify everything else. Two signals,
   complete filter picture.

## Recon indicators (how to find this class again)
- Echoes reflecting `<svg>` verbatim while 400ing `<script>`/`<img>` (namespace gap
  signal — map SVG + MathML + custom immediately).
- Any "some HTML allowed" sanitizer (rich text, SVG upload, markdown-with-HTML,
  email HTML) — enumerate the ALLOWED set's executable members, not just the denied.
- Absence of CSP + reflected markup = full handler palette available once past the
  filter.
- Lab/objective mentions of SVG, animation, or "some markup allowed" (read as:
  "the gap is namespace-shaped").

## Verification techniques (reusable)
1. **Behavior battery first** (classic vectors + bare `<svg>`) to classify the
   filter (reject/strip/encode) in ≤5 requests.
2. **Namespace sweeps** (SVG tags one batch, attributes/keywords the next) with
   explicit GET construction.
3. **Combined-payload reflection check** before execution proof (confirms the pair
   survives TOGETHER — lists can interact).
4. **Title side-effect proof** headlessly; real-browser acceptance to close.
5. **Alternative-killing probes** (`<image onerror>`, common handlers on allowed
   hosts) to prove the pair is forced, not merely sufficient.

## Common mistakes that miss this
- **Assuming SVG-allowed means SVG-inert** (the filter author's error — "some SVG
  markup allowed" read as safe subset without checking WHICH subset).
- **Testing only HTML handlers** (`onload` blocked → "handlers filtered, give up")
  without trying the SVG event vocabulary (`onbegin`).
- **Testing only obvious SVG vectors** (`<animate>`, `<image onerror>`, `<a href>`)
  — all deliberately listed; the gap is one abstraction level sideways
  (`animateTransform`, `onbegin`).
- **Over-engineering evasions** (case/separator/encoding tricks) against a filter
  beaten by plain well-formed markup — try the ontology gap BEFORE the obfuscation.
- **Forgetting the combination check** (tag passes alone + handler passes alone ≠
  pair passes together — verify combined; here it did).
- **Click-gated fallbacks** (`<a href=javascript:>` needs clicks AND `<a>` is listed
  — worse on both axes than the load-time SMIL shape).

## Cross-cutting
- Filter-gap trilogy complete: unlisted-generic (`body`×`onresize`), infinite-custom
  (`<xss>`×`onfocus`), namespace-remainder (`animateTransform`×`onbegin`). Three
  labs, one method (oracle-map → compose survivors → prove → deliver/accept), three
  gap classes future agents should check IN ORDER when facing an selective filter:
  custom elements, obscure window events, SVG/MathML vocabularies — then evasions.
- Sixteen labs; the invariant method (sweep → per-context map → family-correct
  payload → side-effect proof → negatives → knowledge) is unchanged. Payload
  families now span markup, fragment, URI, JS-source (string/evaled-JSON),
  template-expression, JS-string-derivation, SMIL-event, and focus-event shapes.