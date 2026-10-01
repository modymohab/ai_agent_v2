# Metadata — Reflected XSS into a JavaScript string with single quote and backslash escaped

| Field | Value |
|---|---|
| Lab | Reflected XSS into a JavaScript string with single quote and backslash escaped |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-javascript-string-single-quote-backslash-escaped |
| Target | `https://0a510075030148be813ebbd300e70032.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (JS-string echo, parser-level breakout) |
| Sub-type | `?search=` echoed into `var searchTerms = '…';` with `'`→`\'`, `\`→`\\`, `<>` raw → `</script>` terminates the script ELEMENT (HTML parser runs before JS parsing) + fresh `<script>alert(1)</script>` executes; inner single quotes must be avoided (server-escaped → syntax error in the new block) |
| Severity | Medium-High (load-time arbitrary JS at app origin on crafted URL; no interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality with single quotes and backslashes escaped. To solve this lab,
> trigger `alert()`.

## Trilogy position in this KB (echo-into-JS, ordered by escaper strength)
1. `reflected-xss-js-string-angle-brackets-encoded` — quotes RAW → direct `';JS;//`.
2. `reflected-dom-xss-eval-json` — quotes escaped, `\` raw → escape-shift + grammar.
3. **THIS lab** — quotes AND backslash escaped, `<>` raw → HTML-parser-level
   `</script>` closure (JS-layer breakout impossible; go one layer up).
The escaper decides the LAYER of breakout: unescaped quotes → JS layer; escaped
quotes → HTML-parser layer (this lab) or encoding-shift layer (eval-JSON).

## Attack surface at a glance
- `GET /?search=X` → `<h1>` text (fully encoded, dead) + `var searchTerms = 'X';`
  (`'`→`\'`, `\`→`\\`, `"` raw, `<>` raw).
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Echo → parser-precedence → fresh-script flow |
| `root-cause.md` | Escaper completeness vs parser layering; trust boundary |
| `verification.md` | Map, inner-quote diagnosis, closure proof |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Parser-precedence method; trilogy synthesis |