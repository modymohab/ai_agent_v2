# Root Cause — URL-encoding blind spot + accesskey click synthesis

## The vulnerability
The canonical-link builder reflects the full request URL into a single-quoted `href`
after URL-encoding (not HTML-encoding) it. URL-encoding neutralizes `<>` and `"` for
HTML purposes but is transparent to `'` — which is both URL-legal and the attribute's
delimiter. The resulting attribute injection plants `accesskey` + `onclick` on the
`<link>` element, and the access-key mechanism converts a keypress into a click that
fires the handler.

## Root cause (framing, three layers)
1. **Wrong-encoding-family defense**: URL-encoding is for making strings safe INSIDE
   URLs; HTML-encoding is for making strings safe inside MARKUP. Applied to markup,
   URL-encoding stops only characters illegal in both languages (`<>`, and `"` only
   incidentally). `'` is legal in URLs and fatal in single-quoted attributes — the
   exact intersection the defense misunderstands. New filter species for the KB
   (prior labs: HTML-entity, reject-list, single-replace, none).
2. **`accesskey` as a click synthesizer**: on non-focusable elements (like `<link>`),
   activating the access key fires CLICK behavior — the keyboard equivalent of
   clicking an unclickable thing. Any element, however inert-looking, becomes a
   click handler host once `accesskey` + `on*` land on it. The `<head>` location is
   no protection (parsing and event dispatch don't care about renderability).
3. **Simulated-user threat model**: the lab platform presses the keys — collapsing
   the usual "victim must cooperate" objection. In reality this is social-engineering
   gated (lure text: "press Alt+Shift+X"), which bounds real-world severity below
   load-time vectors while keeping the primitive fully valid.

## Trust boundary model
```
Attacker URL ──► URL-encoded echo (') ──► single-quoted href (data?)
                                                                     │
              [TRUST BOUNDARY: attribute value(data) → live handler(code)]
                                                                     ▼
                        accesskey + onclick on <link> ──► keypress ──► click
                                                                     │
                                                                     ▼
                                              handler runs (page origin)
```

## Enabling conditions (checklist)
1. URL (or part of it: path, query, fragment-echoing pages) reflected into markup
   with URL-encoding (or no encoding) instead of HTML-encoding.
2. Single-quoted (or unquoted) attribute context — `'` (or space/`=`) survives.
3. `accesskey` unfiltered (it's a "harmless" global attribute no list includes).
4. A keypress source: platform simulation, victim cooperation, kiosk/assistive-tech
   flows where access keys are routinely used.
5. Chrome (accesskey→click on non-focusable elements is Chrome's behavior per the
   objective; verify per engine before assuming elsewhere).