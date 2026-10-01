# Attack Chain — SVG animateTransform/onbegin through a tag filter

## Data flow
```
Attacker crafts URL   /?search=<svg><animatetransform onbegin=alert(1)>
   │  (transport-encoded; decoded once server-side into the echo)
   ▼
[INPUT] GET /?search=…  →  filter checks tags/handlers → svg, animateTransform,
onbegin ALL UNLISTED → 200 (not 400)
   │
   ▼
[PROCESSING] template:  <h1>0 search results for '<svg><animatetransform onbegin=alert(1)>'</h1>
   │  verbatim echo, no encoding observed
   ▼
[SINK] victim parser builds SVG namespace subtree; SMIL timeline starts the
<animateTransform> element at document load → begin event
   │
   ▼
[TRUST BOUNDARY CROSSED] SMIL event handler runs attacker JS in page origin
   ▼
RESULT: alert(1) during page load, zero interaction
```

## Why this pair (oracle-derived, not guessed)
- Tags probed (~25 SVG/HTML): blocked include `animate`, `animateMotion`, `set`,
  `g`, `use`, `foreignObject`, `path`, `a`, `image`-as-`<img>`-alias (deliberately
  listed), `textPath`, `desc`, `switch`; passing include `svg`, `animateTransform`,
  `text`, `title`, `image`, `circle`, `rect`, `ellipse`, `line`.
- Handlers: `onload` blocked; `onbegin` passes; `onerror`/`onfocus`/`onmouseover`
  re-tested here → blocked (so the `<image src=x onerror>` shortcut is dead).
- `onbegin` is the SMIL begin-event — it fires when the animation element's active
  duration starts, which for a bare `<animateTransform>` is document load. No
  attributes (`attributeName`, `dur`, …) needed, no click, no hover.
- The pair is essentially FORCED: the only passing executable combination found —
  every common handler dies on the list, every obvious SVG vector tag dies with it.

## Expected response sequence (verified)
1. `GET /?search=<svg><animatetransform onbegin=alert(1)>` → 200, verbatim echo.
2. Browser parses SVG, SMIL begins the transform element, handler fires on load.
3. Real-browser `alert(1)` → `is-solved` (first poll).