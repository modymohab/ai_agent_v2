# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When stored data is rendered by CLIENT code, audit the client sanitizer as the
> primary attack surface: `String.replace` with a STRING pattern (or any single-pass
> transform) replaces only the FIRST occurrence — feed DOUBLED metacharacters so the
> first is sacrificed to the filter and the second survives executable. And before
> investing in the flashy client hole, probe the SERVER gates (a 400 on `javascript:`
> killed the "obvious" vector here): attack the thinnest layer, which the code audit
> alone cannot rank.**

Coupled rules:
1. **Sacrificial-prefix construction**: for a first-only escaper, prefix exactly one
   consumable unit per replaced charset (`<>` here) ahead of the live payload; verify
   the survivor is byte-clean (a half-consumed tag corrupts handlers silently).
2. **Server-gate probing before sink investment**: benign-302 control, then
   scheme/case matrix. A 400-class rejection reshapes the whole plan (href→innerHTML
   pivot here) — learn it in two requests, not after building an exploit.
3. **Stored × DOM is a distinct triage class**: persistence of stored XSS with
   triggers of DOM XSS (load-time, no click) — mass, passive, interaction-free. When
   scoping, stored-DOM outranks both parents; hunt it wherever APIs serve user data
   to client renderers (comments, profiles, notifications, activity feeds).

## Recon indicators (how to find this class again)
- Client renderers fetching user-data JSON: `loadComments`, `renderFeed`,
  `displayResults` + `innerHTML`/`.html()`/`document.write` nearby.
- Sanitizer named `escapeHtml/sanitize/clean` implemented with string-pattern
  `replace` (grep `replace('<'`, `replace(">"`, `replace(/…/ ` WITHOUT `/g` flag).
- Filenames/comments advertising the sink (`…VulnerableEscapeHtml.js` here; real
  world: `// TODO: proper escaping`, `sanitizeInput`, `safeHtml`).
- Comment/profile/review features on SPA or hybrid apps (server stores, client renders).
- Server 400s on `javascript:`-style values = scheme allowlist present (note it, pivot).

## Verification techniques (reusable)
1. **Read the client renderer fully** (fetch external JS — the sink is usually one
   file away from the page).
2. **Per-field client-path table** (avatar→src, website→href, author/body→innerHTML)
   BEFORE choosing payloads — the audit, not the form, ranks targets.
3. **Gate matrix first** (benign control + scheme/case variants) to kill or confirm
   the server layer in three requests.
4. **Verbatim-persistence check** (JSON endpoint) separating store issues from
   render issues.
5. **Load-time headless proof** with title side-effect (no click needed — and its
   absence is itself signal about trigger type).
6. **Disambiguate 400s**: stale-token vs validation — rerun benign on the same token
   (control experiment, one request).

## Common mistakes that miss this
- **Auditing only server responses** (stored JSON looks inert — it's valid JSON with
  raw `<` inside strings; the vuln activates only in the client renderer).
- **Auditing only the client OR only the server**: client-only view picks the dead
  `website` vector; server-only view sees "sanitized" JSON. Both layers required.
- **Single-metachar probes** (`<img…>` once → encoded → "sanitized, safe") without
  testing DOUBLED metacharacters against first-only transforms.
- **Assuming `replace` is global** (the single most common JS sanitizer misread).
- **Firing `<script>` at `innerHTML`** (neutered — handlers mandatory).
- **Giving up at the first 400** instead of classifying it (token vs validation) and
  pivoting vectors.
- **Forgetting which layer solved it**: report must credit the CLIENT escaper (fix:
  `textContent`/global-regex/DOMPurify/Trusted Types) AND note the server allowlist
  that held (keep it).

## Cross-cutting
- Execution-moment matrix: stored-DOM rows as load-time fire with STORED delivery —
  the matrix now spans delivery (link/stored/victim-framed) × trigger
  (parse/error/click/event/compiler/load) × family (markup/fragment/URI/JS-source/
  expression/JS-string). Thirteen labs, one invariant method: audit ALL layers →
  map per-location → family-correct payload → side-effect proof → negatives.
- The 400-disambiguation control (benign rerun on same token) joins the method
  inventory as a general tool for any rejected-request diagnosis.