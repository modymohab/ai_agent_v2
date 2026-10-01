# Root Cause — client-side template compilation of reflected text

## The vulnerability
The search term is server-reflected into page text inside an AngularJS application
boundary (`<body ng-app>`). Angular's compiler treats `{{…}}` sequences in DOM text as
live expressions and evaluates them — converting reflected DATA into compiled CODE
client-side, regardless of server-side encoding that targets HTML/markup contexts.

## Root cause (framing, three layers)
1. **Compilation sink over untrusted DOM text**: `$compile`/`$parse` evaluate
   attacker-influenced text with near-JS expressiveness. Any reflection point inside
   `ng-app` (or any Angular-managed template: `ng-include`, `ng-bind-html` without
   `$sanitize`, directive templates) is a CSTI sink. The server encoded for HTML —
   the sink doesn't PARSE HTML, it COMPILES expressions, so HTML-encoding is the
   wrong defense layer (and `{{}}"` surviving raw is all the compiler needs).
2. **Scope-chain reachability of `Function`**: Angular expressions resolve `constructor`
   through the scope prototype chain to `Object`, whose `.constructor` is the global
   `Function` — a code-generation primitive reachable with zero globals, zero quotes
   beyond `"`, zero markup. The expression language's own object model defeats
   allow-list-style thinking ("no `window`, no `document`, no `eval` in expressions"
   is true and IRRELEVANT once `Function` is reachable).
3. **No sandbox (version fact)**: Angular 1.6 removed the expression sandbox, so on
   1.6+ (1.7.7 here) the constructor chain needs no bypass gadgets. Version determines
   payload length, not possibility.

## Trust boundary model
```
Attacker URL ──► server echo (HTML-encoded for MARKUP) ──► DOM text (data?)
                                                                     │
              [TRUST BOUNDARY: compiled template — text(data) → expression(code)]
                                                                     ▼
                    $compile/$parse ──► constructor → Function → global fn
                                                                     │
                                                                     ▼
                                              arbitrary JS (page origin, load-time)
```

## The two-privilege-level structure (core insight)
- LEVEL 1 (expression scope): no `window`/`document`/`alert`/`String` — only scope
  objects, literals, operators, and the prototype chain. Payload must live here
  using ONLY `constructor` + `"string"`.
- LEVEL 2 (generated function body): FULL globals — everything Level 1 lacks.
  The chain is a privilege ESCALATION from expression context to global context,
  and the inner string is where the real payload (`alert(1)`, exfil, DOM writes) lives.
- Diagnostic consequence: a `String.fromCharCode` (Level-1 global) attempt fails
  while the IDENTICAL logic inside the generated string succeeds — same code,
  different privilege level. Test failures must be attributed to the correct level.

## Enabling conditions (checklist)
1. AngularJS (1.x) app boundary enclosing a server (or DOM) reflection — `ng-app`,
   `ng-include`, dynamic templates, `ng-bind-html`.
2. `{{}}` delimiters surviving into the compiled text (server must not strip braces;
   HTML-encoding is insufficient).
3. A quotable string channel (`"` or `'` raw) for the inner payload (only ONE quote
   type needed).
4. No CSP blocking the resulting execution (compiled expressions run as JS; strict
   CSP with `unsafe-eval` absent complicates Angular itself — absent policy here).