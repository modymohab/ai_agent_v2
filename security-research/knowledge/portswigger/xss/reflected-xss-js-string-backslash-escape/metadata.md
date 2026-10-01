# Metadata — Reflected XSS into a JavaScript string with single quote and backslash escaped (backslash raw)

| Field | Value |
|---|---|
| Lab | Reflected XSS into a JavaScript string with angle brackets and double quotes HTML-encoded and single quotes escaped |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-javascript-string-angle-brackets-double-quotes-encoded-single-quotes-escaped |
| Target | `https://0a9600fd0398e608808d8fea00770022.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (JS-string echo, escape-shift breakout) |
| Sub-type | `?search=` echoed into `var searchTerms = '…';` with `'`→`\'`, `<>`→entities, `"` raw, `\` RAW → input `\';alert(1);//` shifts the escape (`\\` literal consumes both backslashes, `'` terminates) → statement runs, `//` eats the tail |
| Severity | Medium-High (load-time arbitrary JS at app origin on crafted URL; no interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.

## Position in this KB (the backslash diagonal)
- `reflected-xss-js-string-angle-brackets-encoded`: quotes RAW → direct `';JS;//`.
- `reflected-dom-xss-eval-json`: quotes escaped + `\` raw → shift, but inside an
  OBJECT literal (needed early-`}` + grammar surgery; three failed shapes).
- **THIS lab**: quotes escaped + `\` raw in a PLAIN statement string → shift with NO
  grammar surgery (`\';alert(1);//` — statement position directly). Same escaper
  fact, simplest template. The escaper—not the sink—sets difficulty, again.

## Attack surface at a glance
- `GET /?search=X` → `<h1>` text (fully encoded + backslash-doubled, dead) and
  `var searchTerms = 'X';` (`'`→`\'`, `<>`→entities, `"` raw, `\` raw).
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Echo → escape-shift → statement flow |
| `root-cause.md` | Escaper-ordering failure; trust boundary |
| `verification.md` | Map, shift proof, contrast with siblings |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Backslash-shift method; escaper-ordering rule |