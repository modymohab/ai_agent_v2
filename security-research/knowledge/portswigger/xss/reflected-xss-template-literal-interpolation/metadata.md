# Metadata — Reflected XSS into a template literal (Unicode-escaped)

| Field | Value |
|---|---|
| Lab | Reflected XSS into a template literal with angle brackets, single, double quotes, backslash and backticks Unicode-escaped |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-javascript-template-literal-angle-brackets-single-double-quotes-backslash-backticks-escaped |
| Target | `https://0ac500d203cbe8c081a766d7006900ed.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (template-literal interpolation) |
| Sub-type | `?search=` echoed into `` var message = `0 search results for 'TERM'`; `` with `'"<>\`` → `\uXXXX` escapes, but `${}` RAW → `${alert(1)}` interpolation executes during literal evaluation |
| Severity | Medium-High (load-time arbitrary JS at app origin on crafted URL; no interaction; no quotes/tags needed) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality with angle brackets, single, double quotes, backslash and backticks
> escaped. To solve this lab, trigger `alert()`.

## Position in this KB
- The echo-into-code quartet's fourth member: plain-string breakout (`';`), shift
  (`\';`), script-closure (`</script>`), and now TEMPLATE-LITERAL interpolation
  (`${}`). The escaper here is the STRONGEST yet (six char classes neutralized) —
  and still insufficient, because template literals are executable BY CONSTRUCTION.
- Downstream sink noted: `innerText = message` (safe — irrelevant once interpolation
  fires; defense-in-depth accident, not design).

## Attack surface at a glance
- `GET /?search=X` → `` var message = `0 search results for 'X'`; `` + `innerText` sink.
- Escapes: `'`→`\u0027`, `"`→`\u0022`, `<`→`\u003c`, `>`→`\u003e`, `\`→`\u005c`,
  backtick→`\u0060`; `$`, `{`, `}`, `(`, `)` raw.
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Echo → literal evaluation → interpolation flow |
| `root-cause.md` | Executable-string-type failure; trust boundary |
| `verification.md` | Map, interpolation proof |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Interpolation-first method for template echoes |