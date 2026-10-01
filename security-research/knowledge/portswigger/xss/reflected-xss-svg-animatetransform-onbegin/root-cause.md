# Root Cause — namespace-blind tag/handler blocklists

## The vulnerability
The search echo is fronted by a reject-filter (400) whose tag list blocks standard
HTML and the OBVIOUS SVG vectors (`animate`, `animateMotion`, `set`, `a`, `image`,
`foreignObject`, …) and whose handler list blocks common `on*` — but omits the
`<animateTransform>` element and the SMIL `onbegin` event. The surviving pair
recreates a complete load-time execution primitive inside the SVG namespace.

## Root cause (framing)
- **Namespace-blind enumeration**: the list authors thought in HTML (`script`, `img`,
  `iframe`, `onload`, `onerror`) plus headline SVG (`svg` itself passed — arguably
  deliberate "some SVG allowed" — but `animate`/`animateMotion`/`set` blocked as the
  known-dangerous animation tags). They missed that SMIL EVENTS (`onbegin`, and by
  the same logic likely `onend`/`onrepeat`) are handlers too, and that the overlooked
  `<animateTransform>` element hosts them. Blocklists fail at namespace edges because
  list authors enumerate what they FEAR, not what EXECUTES.
- **SMIL auto-begin**: an animation element with no timing attributes begins at
  document load — the trigger is intrinsic, needing no attributes beyond the handler
  itself. Minimal payload surface = minimal filter touchpoints = maximal bypass odds.
- Failed assumption: *"blocking the dangerous tags and the common handlers leaves
  only inert markup."* SVG is a second, parallel execution environment (SMIL timing
  events, `href`/`xlink:href` navigation, `<foreignObject>` HTML re-entry where
  allowed) with its own handler vocabulary the HTML-centric list never covered.

## Trust boundary model
```
Attacker URL ──► GET param ──► WAF tag/handler check (data? passes gaps)
                                                        │
              [TRUST BOUNDARY: echoed text(data) → parsed SVG + SMIL(code)]
                                                        ▼
                        <svg><animateTransform onbegin=…> ──► begin event
                                                        │
                                                        ▼
                                              handler runs (page origin, load)
```

## Filter-family comparison (three labs, three gap classes)
| Lab | Filter shape | Gap class | Winning pair |
|---|---|---|---|
| most-tags/attrs blocked | known tags + common handlers listed | unlisted generic (`body`) × unlisted window event (`onresize`) | body-merge + iframe resize |
| all-tags-except-custom | standard tags listed, handlers open | infinite custom set + `onfocus` + fragment focus | custom tag + `#id` focus |
| THIS lab (some-SVG-allowed) | HTML + obvious-SVG listed | SVG-namespace remainder (`animateTransform` × `onbegin`) | SMIL auto-begin, self-fire |
Same invariant: enumerate the filter's ontology (HTML tags, common handlers) and hunt
the namespaces it DIDN'T enumerate (window events, custom elements, SMIL).

## Enabling conditions (checklist)
1. Reflected echo with a reject/allow filter that permits SOME markup (any 200 with
   `<svg>`-family content is the signal to map further).
2. An unlisted executable pair in the survivor set (element that lives in DOM +
   event that fires without interaction — SMIL begin, focus, resize, error).
3. No CSP blocking inline handlers (none here).
4. Crafted-URL delivery to the victim (link-based; load-time fire).