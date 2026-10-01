# Metadata — Reflected XSS into HTML context with most tags and attributes blocked

| Field | Value |
|---|---|
| Lab | Reflected XSS into HTML context with most tags and attributes blocked |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-html-context-with-most-tags-and-attributes-blocked |
| Target | `https://0ac9002f04e71ad880b8fd5200de0000.web-security-academy.net/` |
| Exploit server | `https://exploit-0a2700c904961ab48011fc8601160058.exploit-server.net` |
| Class | Cross-Site Scripting (XSS) — **Reflected, WAF-bypassed, victim-delivered** |
| Sub-type | `?search=` echoed into `<h1>`; WAF 400-rejects blocklisted tags/handlers; gaps: `<body>` (any case) + `onresize` (unlisted) → body-attribute merge sets `window.onresize` → victim iframe programmatically resized → `print()` with zero interaction |
| Severity | High (WAF-defended surface still yields interaction-free victim code execution; `print()` here, arbitrary JS by identical chain) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`; victim `GET /exploit/` in access log) |
| Tools used | curl (400-oracle fuzzing), headless Chromium + CDP (merge/dispatch proof), exploit-server form API |

## Lab objective (verbatim)
> This lab contains a reflected XSS vulnerability in the search functionality but uses
> a web application firewall (WAF) to protect against common XSS vectors.
> To solve the lab, perform a cross-site scripting attack that bypasses the WAF and
> calls the `print()` function.
> NOTE: the solution must not require user interaction; manually causing `print()`
> in your own browser will not solve the lab (victim delivery required).

## Why this lab earns its folder
It is the KB's first **adversarial-filter** lab: the vulnerability is trivially visible
(reflected search term, no encoding observed) but a reject-style WAF gates every
obvious payload. The work is (1) differential oracle-mapping of the filter, (2) finding
the single unlisted tag+handler pair whose COMBINATION yields an interaction-free
trigger, (3) victim delivery that manufactures the trigger event. Each step is a
reusable tradecraft unit.

## Attack surface at a glance
- `GET /?search=X` → `<h1>0 search results for 'X'</h1>` (verbatim echo); WAF: 400 on
  blocklisted tags/handlers (case-insensitive, separator-tolerant), 200 otherwise.
- Exploit server `/` (STORE/VIEW/DELIVER/LOG), `/exploit`, `/log` (victim-UA + status).
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Full chain incl. WAF-gap selection + victim delivery leg |
| `root-cause.md` | Blocklist incompleteness; body-merge; trust boundary |
| `verification.md` | Oracle maps, CDP merge/dispatch proof, delivery evidence |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | WAF-oracle methodology; interaction-free trigger design |