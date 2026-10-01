# Metadata — DOM XSS in AngularJS expression (angle brackets + quotes encoded)

| Field | Value |
|---|---|
| Lab | DOM XSS in AngularJS expression with angle brackets and double quotes HTML-encoded |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-angularjs-expression |
| Target | `https://0af2009903f7c2ff851ec6cd00a200a2.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **DOM-based CSTI** (client-side template injection; new class file: `xss/class-angularjs-csti.md`) |
| Sub-type | `?search=` server-reflected into `<h1>` inside `<body ng-app>` (AngularJS 1.7.7); `{{…}}` delimiters + `"` survive raw (`'`→`&apos;`, `<>`→entities); expression `{{constructor.constructor("alert(1)")()}}` executes as global JS (no sandbox in Angular ≥1.6) |
| Severity | High (load-time arbitrary global JS at app origin on crafted URL; no interaction; no tags/quotes-breakout needed) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium (`--dump-dom`) |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.
> (Standard reading: break out of the AngularJS expression context — the `{{…}}`
> payload is evaluated client-side by the framework.)

## First of its class in this KB
All prior labs injected markup/URIs/JS-source into parsers, fragment builders,
navigation targets, selectors, or `eval`. This one injects into a **client-side
template compiler**: the payload is neither markup nor script — it's an AngularJS
EXPRESSION evaluated by `$parse`/`$compile` during DOM bootstrap. New sink family,
new payload family (`{{constructor…}}`), new constraint set (no window globals in
expressions; sandbox absent ≥1.6).

## Honesty note on the lab title
The title claims double quotes are HTML-encoded. EMPIRICALLY on this target they are
NOT (`"` reflected raw; only `'`→`&apos;`, `<`→`&lt;`, `>`→`&gt;`). The solve depends
on raw `"`. Titles describe families loosely — the per-build encoding map decides.

## Attack surface at a glance
- `GET /?search=X` → `<h1>0 search results for 'X'</h1>` inside `<body ng-app>`
  (AngularJS 1.7.7 from `/resources/js/angular_1-7-7.js`).
- No CSP observed. No sandbox (Angular ≥1.6 removed it).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Reflection → compile → constructor-chain flow |
| `root-cause.md` | Template-compilation sink; scope/global boundary |
| `verification.md` | Encoding map, 7×7 proof, scope-restriction diagnosis |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | CSTI method; expression-payload rules |