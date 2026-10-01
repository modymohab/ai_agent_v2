# Class Knowledge — AngularJS (1.x) Expression Injection / CSTI

> Reusable reference derived from PortSwigger lab:
> `dom-xss-angularjs-expression` (see its folder for the worked case).

## Definition
Client-Side Template Injection into an AngularJS 1.x compilation boundary: attacker
text containing `{{…}}` is compiled as an expression by `$parse`/`$compile` (ng-app
bootstrap, ng-include, compiled templates) and escalated — via the scope-chain
`constructor` → global `Function` — to arbitrary JS. Neither markup nor script
payloads apply; the payload is an EXPRESSION that manufactures global code.

## The two-privilege-level model (the core skill)
- LEVEL 1 — expression scope: NO window globals (`window`, `document`, `alert`,
  `String` all invisible); only scope objects, literals, operators, and the prototype
  chain. Verdicts here: arithmetic works (`{{7*7}}`→`49`); global references die
  silent-empty.
- LEVEL 2 — generated function body: FULL globals. Everything Level 1 lacks lives
  here, reached through exactly one bridge: `constructor.constructor("…")()`.
- Method: prove Level 1 with arithmetic FIRST, then cross with the constructor chain
  carrying a global side effect (`document.title=`). Attribute failures to the correct
  level before changing anything.

## Version gating (payload families differ)
| Angular | Sandbox? | Payload family |
|---|---|---|
| 1.0–1.5 | YES | sandbox-bypass gadget chains (version-specific, longer) |
| ≥1.6 (incl. 1.7.7, this lab) | REMOVED | direct `{{constructor.constructor("GLOBAL-JS")()}}` |
Fingerprint first: script URL (`angular_1-7-7.js`), `angular.version`. Never assume.

## Recognition checklist
1. AngularJS 1.x script + `ng-app` (or include/compiled-template) boundary.
2. Reflection (server echo, DOM text, stored content, route param) landing INSIDE it.
3. `{{}}` delimiters surviving (server HTML-encoding is the wrong layer — compiler
   doesn't parse markup; test empirically, distrust titles).
4. ONE surviving quote type for the inner string (either works; verify per build).
5. No CSP (or a policy still permitting the compiled execution).

## Sinks beyond ng-app (same class)
`ng-include` of attacker-influenced templates, `ng-bind-html` without `$sanitize`,
directive `template`/`templateUrl` from user data, `$interpolate` on user strings,
server-side Angular template rendering with user data (stored CSTI — severest form:
user content compiled for all viewers).

## Verification methodology (reusable)
1. `{{7*7}}` → `49` (compiler alive?).
2. Constructor chain + global side effect (full breakout?).
3. Level-attributed failure analysis (empty render = Level 1; evaluated-inert = Level 2).
4. Quote-survival + version checks per build.
5. Real-browser acceptance last.

## Impact frame
- Full global JS (strongest client primitive: no tag/handler/scheme limits).
- Link-delivered when reflected; STORED when user content is compiled (SPA comments,
  profiles, bios in ng-app — hunt these as the upgrade).
- Same origin-consequences as all XSS, with the shortest payload path of any class
  (no breakout chars at all — only `{{}}` + one quote type).

## Fix shape (recognition = know the fix)
Never let untrusted text reach the compiler: `ng-bind`/`innerText` assignment instead
of interpolation points; `$sanitize`/strict contextual escaping where HTML needed;
framework upgrade away from 1.x where possible; CSP as depth. Server HTML-encoding
alone is structurally insufficient.