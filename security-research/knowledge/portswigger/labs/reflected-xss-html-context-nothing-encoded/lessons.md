# Lessons — Reflected XSS into HTML context with nothing encoded

## 1. What was the vulnerability?
Reflected XSS: the `search` query parameter is reflected unencoded into the HTML
`<h1>` heading; attacker markup is parsed and executed in the viewer's browser.

## 2. Root cause
Missing context-aware output encoding at the server-side renderer (user data
emitted as HTML markup). Quotes around the value offered no protection because
they are literal text inside element content.

## 3. Initial attack primitive
`<script>alert(1)</script>` injected into element-text via `?search=`; a bare
script tag in the initial document parse executes without any breakout.

## 4. Trust boundary crossed
Attacker data → HTML parser in the victim's browser within the application
origin (data used as code at the render boundary).

## 5. What made exploitation possible
Verbaitm reflection in element-text context + the browser's rule that
`<script>` inside parsed HTML text runs immediately; no encoding, no CSP, no
filter, no need to escape quotes.

## 6. Assumptions that made the application vulnerable
Quotes/wrapper-strings "contain" the value; the feature "seems harmless"; URL
encoding "protects it"; headings are considered safe to inject into.

## 7. Alternative attack paths considered
Event-handler primitives (`<img onerror>`, `<svg onload>`), attribute/JS-context
manipulation (unnecessary), cookie theft vs same-origin action chaining, and
delivery via open redirect.

## 8. Attack paths NOT applicable and why
XXE (no XML parser at the sink), SSRF (no server fetch), traversal/command
injection (no file/OS sinks), DOM-XSS (the reflection is server-side), CSRF as
the primary finding (the primitise is XSS, not a state change) — only XSS and
its chained uses were applicable.

## 9. Confirmed impact
In-origin client-side script execution in any viewer's browser (alert fired in
the emulated victim; lab solved).

## 10. How impact increases in a real app
Privileged viewers (admin/support search), sensitive same-origin APIs reachable
by in-session `fetch`, non-HttpOnly cookies, state-changing endpoints (XSS→
CSRF-lite chain), and role elevation already present in the session.

## 11. Recon indicators for the class
Any search/filter/param reflected into server-rendered HTML; responses where a
category/search term echoes verbatim (look at `<h1>`, `<title>`, table cells,
error pages); absence of `Content-Security-Policy` and of a templating engine
that auto-escapes; presence of traditional server-side rendering (JSP/PHP/ASP/
Rails ERB/Flask templates). Probe with a benign token, then check the exact
surrounding context (text/attribute/script/URL).

## 12. Reusable verification techniques
Marker-then-payload; read the reflection context before choosing a primitive;
independent event-handler confirmation; double-encode control to prove "no
encoding" vs "decode-re-encode"; no-browser fallbacks (headless Chromium /
platform emulator status flip).

## 13. Common mistakes that miss this vulnerability
- Assuming quotes around a value "sanitize" element-text (they don't).
- Testing only `<script>` and concluding "blocked" when a filter exists but an
  event-handler primitive still works.
- Checking for reflection only in the response of your own session and missing
  that the payload executes in the initial parse for every viewer.
- URL-encoding your payload once and reading the un-encoded response, then
  misreading encoding behavior.
- Treating "it's just a search term" as a non-execution context.
- Stopping at "it reflects" without confirming EXECUTION (reflection ≠ XSS).

## Reusable generalization

> When user-controlled input is interpolated into a server-rendered HTML
> response, determine the exact insertion context (text/attribute/script/URL/
> comment/CSS). In element-text context, quotes are inert and a `<script>` tag —
> or any event-handler-carrying tag (`<img onerror>`, `<svg onload>`) — executes.
> Deliverability defines severity: a crafted URL clicked by a privileged user
> converts read-only reflection into authenticated action, data theft (if any
> cookie is readable) or session-compromise chains. Verify by marker first,
> execution second, and an independent primitive third; classify other classes
> (XXE/SSRF/traversal/command injection) by sink reachability, not by checklist.

## Related methodology
- `methodology/xss.md` (sink/encoding discipline; marker proof)
- `methodology/client-side.md`
- `index/attack-impact-coverage.md` (XSS row)
- `knowledge/portswigger/labs/xss-scanning-non-standard-data-structures.md`
  (stored-XSS variant, same sink discipline)