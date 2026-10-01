# Metadata — Stored DOM XSS (single-replace escape bypass)

| Field | Value |
|---|---|
| Lab | Stored DOM XSS (`lab-dom-xss-stored`) |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-dom-xss-stored |
| Target | `https://0a72008703f420ab800cd0be00a100cc.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Stored × DOM hybrid**: persisted comment JSON consumed by a client-side `innerHTML` sink with a first-occurrence-only escaper |
| Sub-type | `POST /post/comment` stores fields; `GET /post/comment?postId=N` serves JSON; `loadCommentsWithVulnerableEscapeHtml.js` renders via `escapeHTML()` (`String.replace` with string pattern = FIRST match only) into `innerHTML`; bypass with sacrificial leading `<>` |
| Severity | High (one store → load-time code execution for every future viewer; no interaction; no click) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium, real browser tab |

## Lab objective (verbatim)
> This lab contains a stored DOM-based cross-site scripting vulnerability in the
> comment functionality. To solve this lab, submit a comment that calls the `alert()`
> function when the blog post is viewed.

## Hybrid position in this KB
- Storage/persistence mechanics from the stored labs (comment form, CSRF, JSON
  persistence, mass delivery to all viewers).
- Sink/execution semantics from the DOM `innerHTML` lab (event-handler payloads,
  `<script>` neutered, load-time fire).
- New: the sanitizer itself is the bypass surface — first-occurrence `String.replace`
  as an "encoder" — plus a server-side scheme allowlist that KILLS the otherwise-obvious
  `website→href` vector (diagnosed via 400s, not assumed).

## Attack surface at a glance
- `POST /post/comment` (`csrf`, `postId`, `comment`, `name`, `email`, `website`);
  server rejects non-http(s) `website` with 400 (allowlist enforced).
- `GET /post/comment?postId=N` → JSON array of stored comments (verbatim).
- Client `displayComments()`: `avatar`→`src` (escaped, inert), `website`→`href`
  (UNESCAPED but scheme-gated server-side), `author`/`body`→`escapeHTML()`→`innerHTML`.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Store→JSON→escape→innerHTML flow; per-field verdicts |
| `root-cause.md` | Single-replace escaper; trust boundaries (two) |
| `verification.md` | 400 diagnosis, bypass proof, dead-end analysis |
| `impact.md` | Stored × load-time impact reasoning |
| `lessons.md` | Sanitizer-bypass method; hybrid pattern |