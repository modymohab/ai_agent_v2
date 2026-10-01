# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When an escaper handles quotes/brackets/backslashes but leaves `&` raw, smuggle
> the terminator as an ENTITY (`&apos;`, `&#x27;`, `&quot;` per target quoting):
> the server stores it inert, the victim parser decodes it into a live delimiter
> AFTER (downstream of) the defense — at the exact layer where code is parsed.
> Always assert on the DECODED value (`getAttribute`, never raw grep), keep inner
> payloads quoteless, parenthesize assignments, and read click-results synchronously
> before navigation destroys them.**

Coupled rules:
1. **Decode-stage ordering**: enumerate every decoder between escaper and sink
   (HTML entities → attribute computation; `%` → URL parsing; JS escapes → string
   eval; CSS escapes → stylesheet). The escaper must neutralize its metachars
   (`&` FIRST for HTML) against ALL of them — test `&apos;`/`&#x27;` survival as a
   first-class probe, not an afterthought.
2. **Smuggled-payload discipline**: inner quotes get escaped (balanced-quote rule
   from prior labs applies INSIDE smuggled regions too) → quoteless/numeric inner
   JS; `-(x=1)` parens (precedence reflex); `//`-awareness where tails exist.
3. **Click-proof harness for navigating anchors**: sync same-turn click+read (or
   preventDefault) — plain click+read observes the HREF target, a classic
   evidence-destruction race.
4. **Template revelation via benign store**: `onclick` shapes with per-field
   reflections are undiscoverable without a populated record — seed benign data
   first, attack second.

## Recon indicators (how to find this class again)
- `onclick="track('USER')"` / analytics-in-markup patterns with user data
  (author URLs, campaign params, usernames in handlers) — grep `onclick=.*\+?\s*'`
  + user-controlled sources.
- Escapers handling `'"<>` but silent on `&` (one `&apos;` probe decides).
- Comment/profile/social-link features rendering URLs into BOTH href and JS
  (dual reflections = dual chances; test each).
- Tracker-pixel/callback markup carrying identifiers into handler strings.

## Verification techniques (reusable)
1. **Benign-seed template revelation** (populate, then read the shape).
2. **Single probe with trailing `&apos;`** (maps all five char classes at once).
3. **Decoded-value assertion** (`getAttribute` > raw grep for code sinks).
4. **Sync click+read** (or preventDefault) for navigating-anchor proofs.
5. **Trap checklist per payload**: inner quotes? precedence? navigation race? tail?
   (Four forensics in this lab — run the list before firing.)

## Common mistakes that miss this
- **Trusting a "complete" escaper** (`'"<>\\` all handled ⇒ safe) without testing
  `&` — the exact blind spot, and the cheapest probe (`&apos;`) catches it.
- **Asserting on raw response bytes** for code sinks (shows inert `&apos;` —
  looks safe; the DECODED value is live).
- **Inner quoted strings** inside smuggled payloads (server escapes them too).
- **Unparenthesized `-x=` assignments** (precedence throw misread as filter win).
- **Async click+read on navigating anchors** (observes wrong document).
- **Assuming `href`-twin means href-vector** (test each reflection's OWN sink
  semantics — here only onclick executes).
- **Forgetting client-side `pattern=` hints are bypassable** (direct POST).

## Cross-cutting
- Decode-stage matrix (new KB axis): HTML-entity (this lab: `&`-first rule),
  URL-percent (canonical lab: `'`-survives rule), JS-escape (backslash-first rule),
  CSS-escape (future). Every escaper must be evaluated against its DOWNSTREAM
  decoders, not its input alphabet — the invariant restated for the third time
  because it keeps being the bug.
- Twenty labs; the method absorbs decode stages without change: sweep → per-layer
  map (encode AND decode stages) → family-correct payload → decoded-value proof →
  trap checklist → negatives → knowledge.