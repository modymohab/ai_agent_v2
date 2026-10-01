# Attack Chain — DOM XSS via innerHTML(source: location.search)

## The vulnerable code (as served verbatim to every client)
```html
<h1><span>0 search results for '</span><span id="searchMessage"></span><span>'</span></h1>
<script>
    function doSearchQuery(query) {
        document.getElementById('searchMessage').innerHTML = query;
    }
    var query = (new URLSearchParams(window.location.search)).get('search');
    if(query) {
        doSearchQuery(query);
    }
</script>
```

## Data flow
```
Victim URL          ?search=<img src=x onerror=alert(1)>
   │
   ▼
[SOURCE] window.location.search
   │
   ▼
new URLSearchParams(...).get('search') -> query = `<img src=x onerror=alert(1)>`  (decoded once)
   │
   ▼
[SINK] document.getElementById('searchMessage').innerHTML = query
   │   value parsed as CHILD NODES of the <span> (element-content context)
   ▼
[TRUST BOUNDARY CROSSED] HTML fragment parser builds a real <img> element with a
live onerror handler; the bogus src "x" fails to load → handler fires
   ▼
RESULT: alert(1) runs in app origin with victim's cookies/context
```

## Why this payload and not `<script>`
- `innerHTML`-inserted `<script>` elements are **inert by HTML spec** (parser inserts the
  element but never executes it) — proven by negative test (see verification.md).
- Event-handler attributes (`onerror`, `onload`, `onfocus`, …) on inserted elements ARE
  live. Hence the mandatory payload family: `<img src=x onerror=…>`, `<svg onload=…>`,
  `<details ontoggle=…>`, `<iframe srcdoc=… onload=…>`, etc.
- Contrast with the sibling `document.write` lab, where written `<script>` DOES execute.
  Same source, opposite payload rule — sink semantics decide.

## Why no breakout prefix is needed
- The value is assigned as the **entire content** of the span, not interpolated inside an
  attribute or a JS string. There is nothing to "close" first: the payload IS well-formed
  markup on its own.
- Contrast with the `document.write` lab (value inside `src="…"` → required `"` + `>`).
- General rule: breakout characters are only required when the sink interpolates the
  value *inside* a larger syntactic construct. Assignment-to-empty-element needs none.

## Expected response sequence (verified)
1. `GET /?search=<anything>` → 200; page contains static spans + the sink script.
   Server performs NO processing or reflection of the term (pure DOM sink).
2. Browser runs the inline script; `innerHTML` parses the fragment into `#searchMessage`.
3. `img` load error fires `onerror` → script executes (zero further interaction).