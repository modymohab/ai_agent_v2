# Root Cause — eval() of server JSON with quote-escape-only sanitizer

## The vulnerability
The search page fetches server-generated JSON over XHR and passes the raw response
text to `eval()`. The server escapes double quotes but leaves backslashes (and all
other characters) untouched, so an attacker smuggles a string terminator via the
backslash escape-shift (`\"` input → `\\"` in stream → `\\` + TERMINATOR), closes the
object early, and runs a statement — all inside data the application treats as JSON.

## Root cause (framing, three layers)
1. **Code-execution sink on a data channel**: `eval(responseText)` hands a
   network-derived string to the JS compiler. Safe alternatives: `JSON.parse`
   (data-only, throws on code), `response.json()`. `eval` on XHR bodies is the
   canonical DOM-XSS primitive for a reason — it erases the data/code distinction
   by design.
2. **Asymmetric escaper defeats its own purpose**: escaping `"` while passing `\`
   through raw is worse than no escaping at all for readers of the code (looks safe)
   while remaining breakable: the escaper's OWN output (`\"`) combines with the
   passthrough (`\`) to manufacture terminators. Rule: a JSON-string escaper MUST
   handle `\` FIRST (or, equivalently, use a real JSON serializer) — quote-only
   escaping of attacker text embedded in JS is a known-broken pattern.
3. **Template-position trap**: even with termination achieved, the value sits inside
   an object literal at END of input, so only the close-early + comment-tail shape
   parses. The vulnerability is fully determined by (escaper gaps × template
   position × eval sink); changing any one kills it.

## Trust boundary model
```
Attacker URL ──► location.search ──► XHR URL ──► server JSON template (data?)
                                                                     │
              [TRUST BOUNDARY: response text(data) → eval argument(code)]
                                                                     ▼
                         eval('var searchResultsObj = ' + responseText)
                                                                     │
                                                                     ▼
                                              statement execution (page origin)
```
Note the boundary is crossed TWICE in spirit (server trusts input as JSON-data;
client trusts response as code), but a single fix at EITHER layer (`JSON.parse` /
real serializer) closes it — defense in depth wants both.

## Enabling conditions (checklist)
1. `eval()`/`Function()`/`setTimeout(string)` applied to a network response (grep XHR/
   fetch handlers for `eval`, `new Function`, `setTimeout(` with dynamic args).
2. Attacker-influenced substring inside the response (any JSON field echoing input —
   here `searchTerm`; error echoes and debug fields count too).
3. Escaper that leaves a terminator-manufacturing gap (raw `\` is the classic; also
   raw `</script>`-adjacent chars for HTML-embedded JSON, raw newlines for JS-string
   contexts).
4. No CSP blocking the resulting inline execution (`unsafe-eval` would additionally be
   needed to even allow `eval` under a policy — absent policy here).

## Fix shape (recognition = know the fix)
Client: `JSON.parse(this.responseText)` (or `xhr.responseType='json'`). Server: real
JSON serialization (which escapes `\` before `"`). Either alone fixes; the class fix
is never-`eval`-on-wire-data.