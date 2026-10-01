# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a page `eval()`s (or `Function()`s, or string-`setTimeout`s) a server
> response containing your input, forget markup entirely — you are writing JS source
> into a template position. Map the escaper byte-exactly, locate the ONE terminator
> source the escaper cannot suppress (here: raw `\` shifting the template quote),
> then satisfy the SURROUNDING grammar (close the object yourself, reach statement
> position, neutralize the template tail with `//`). Derive against EXACT server
> bytes (curl → base64 → in-page eval), never against remembered escaping.**

Coupled rules:
1. **Escaper asymmetry is the tell**: `"`-escaped + `\`-raw = terminator factory.
   Any escaper that doesn't handle `\` first (or isn't a real serializer) is suspect —
   test with `\"` input and read BYTES (xxd), not reprs.
2. **Template position dictates the tail**: end-of-object needs close-early + `//`;
   mid-object needs `,`-continuation awareness; end-of-input needs nothing trailing.
   Sketch `PREFIX + S + SUFFIX` tokenization on paper before firing.
3. **Failure messages ARE the map**: "Unexpected token ';'" = statement syntax in
   expression position (restructure to reach statement position); "Unexpected end of
   input" = something unclosed (usually your comment ate the closer); silent string
   containment = your terminator never terminated (check escaper composition).

## Recon indicators (how to find this class again)
- XHR/fetch + `eval(`/`new Function(`/`setTimeout("` on the response (grep JS for
  `eval\s*\(\s*['"]?var|eval\(.*responseText|eval\(.*data`).
- JSON endpoints echoing input (search terms, error messages, `query` fields,
  debug echoes) consumed by anything other than `JSON.parse`/`response.json()`.
- External JS files (like `searchResults.js`) — always fetch and read them; the sink
  is frequently one file away from the page.
- Benign-behavior baseline: confirm the XHR→render path works headlessly BEFORE
  blaming payloads (distinguishes environment issues from grammar issues).

## Verification techniques (reusable)
1. **Benign control first** (renders? path sound?) — isolates environment vs payload.
2. **Byte-exact escaper map** (xxd for controls; repr lies about `\n` vs `\\n`).
3. **Base64 eval harness**: `atob()` the curl-obtained bytes in-page — eliminates
   escape-mangling across Python/CDP/JS layers (the source of two phantom results
   here).
4. **Flag assignments, never `alert()`**, in proofs (`window.__k=1`; assert separately;
   `alert` wedges headless renderers beyond dialog-handler rescue).
5. **Mirror the sink expression EXACTLY** (`eval('var x = '+t)` — no appended code that
   a `//` would swallow; read produced vars in separate steps).
6. **End-to-end page proof** (real XHR path + title marker + normal-render check)
   before real-browser acceptance.

## Common mistakes that miss this
- **Markup thinking at a code sink** (`<script>`/`<img>` payloads — inert by category).
- **Trusting remembered escaper behavior** instead of byte-mapping (the `\`-raw fact
  is invisible in rendered views).
- **Stopping at the first grammar error** instead of reading it as positional
  information (each error message located the missing construct).
- **Appending assertion code inside the eval under test** (comment-swallowing).
- **Using `alert()` in automated proofs** (renderer wedging misread as payload failure).
- **Assuming `results[]` or other fields are attacker-controlled** without checking
  (they're DB data; only the echo field is live).
- **Missing the external JS file** (page HTML shows only `search('search-results')` —
  curl-only page review without fetching `.js` dependencies ends the hunt early).

## Cross-cutting
- Execution-moment matrix gains the **statement-execution** row: unlike markup sinks
  (payload = fragment/handler/URI), `eval` sinks take STATEMENTS — strictly more
  expressive, constrained only by template grammar. Same invariant method (source/sink
  audit → exact-context map → family-correct payload → side-effect proof → negatives),
  with "family" now including JS-source shapes and failure-message-driven derivation.
- This lab pairs with the reflected-attribute lab as the two server-reflection
  archetypes: reflection-into-MARKUP (encode per context) vs reflection-into-CODE
  (never `eval`; `JSON.parse`). Together they cover the response-side XSS surface;
  the DOM labs cover the client side.