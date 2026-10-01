# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When reflected (or DOM) text lands inside an AngularJS (1.x) compilation boundary
> (`ng-app`, `ng-include`, compiled templates), test `{{7*7}}` FIRST — arithmetic
> evaluation proves the compiler sink before any exploit work. Then escalate with
> `{{constructor.constructor("GLOBAL-JS")()}}`: scope-chain `constructor` reaches
> `Function` with no globals, and the inner string runs with full global access. Put
> NOTHING global in the expression; put EVERYTHING global in the generated string.
> Only ONE raw quote type is needed — verify which one survives, distrust titles.**

Coupled rules:
1. **Compiler sinks need expression payloads, not markup**: `<script>`/`<img>`/
   `javascript:` thinking is a category error here (and `<>` are encoded anyway).
2. **Two privilege levels, test them separately**: `{{7*7}}` (Level 1: compiler alive?)
   before constructor chains (Level 2: global breakout?). A silent empty render means
   Level-1 failure (resolution/syntax) — diagnose there, not in the payload logic.
3. **Version gates the gadget set**: 1.6+ = direct constructor chain (this lab);
   1.0–1.5 = sandbox present = bypass gadgets required (different payload family,
   same sink). Fingerprint the Angular version (`angular.version` / script URL)
   BEFORE choosing payloads.

## Recon indicators (how to find this class again)
- `ng-app` / `ng-include` / `angular.js` script tags (any 1.x) enclosing reflections:
  search echoes, usernames, error text, notification strings, `title`/`h1` mirrors.
- The two-request discriminator: `{{7*7}}` (evaluates to 49?) + quote/bracket map.
  `49` in response/DOM = compiler sink, game on.
- Other client-template frameworks with the same shape: Vue (`{{ }}`/`v-html`),
  old Knockout/Ember/Handlebars-unescaped, Svelte `{ }`, Angular (2+) template
  injection — each has its own expression language, same audit shape (reflection
  inside compilation boundary?).
- Server frameworks that embed user data into Angular templates (the stored-CSTI
  upgrade: comments/profiles compiled by the SPA).

## Verification techniques (reusable)
1. **Arithmetic-first**: `{{7*7}}`→`49` proves compilation with zero exploit
   assumptions (works even where code execution later needs version-specific chains).
2. **Global-side-effect proof**: `constructor.constructor("document.title=N")()` —
   title assertion proves FULL global breakout, not just expression eval.
3. **Failure attribution by level**: empty render + no side effect = Level-1
   (resolution/syntax/encoding of delimiters); evaluated-but-inert = Level-2
   (inner-string issue). The fromCharCode case is the teaching exhibit.
4. **Quote-survival check per build**: send BOTH quote types in the map probe; build
   the chain with whichever survives (never assume from the lab title — `" `was raw
   here despite the title).
5. **Version fingerprint before gadget selection** (`/resources/js/angular_*.js`,
   `angular.version` in console).

## Common mistakes that miss this
- **Firing markup/URI/JS-source payloads** at a compiler sink (all inert by category).
- **Using single quotes because the classic payload does** → `&apos;` death; not
  checking which quote survives on THIS build.
- **Putting globals in the expression** (`String`, `document`, `alert` directly) →
  silent empty render, misread as "filtered" or "patched".
- **Assuming a sandbox exists (or doesn't)** without checking the version —
  payload families differ completely across the 1.6 boundary.
- **Reading the title as the encoding spec** ("double quotes encoded" was FALSE here).
- **Stopping at `{{7*7}}`** (proof of eval, not of code execution) — the constructor
  chain is a separate, required second step.
- **Missing `ng-app` scope**: testing reflections OUTSIDE the Angular boundary
  (e.g., content above/below the app root) where `{{}}` stays inert text.

## Cross-cutting
- The execution-moment matrix gains the **compiler-evaluated** row: load-time
  (bootstrap), expression family, no interaction — alongside parse/error/click/event
  rows. The invariant method holds: source/sink audit → EXACT mechanism map
  (delimiters? quotes? version? scope?) → family-correct payload → side-effect proof
  → negatives — with "family" now spanning markup, fragment, URI, JS-source, AND
  template-expression shapes across eleven labs.