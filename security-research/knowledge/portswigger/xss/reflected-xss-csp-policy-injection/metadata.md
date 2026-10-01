# Metadata — Reflected XSS protected by CSP, with CSP bypass (policy injection)

| Field | Value |
|---|---|
| Lab | Reflected XSS protected by CSP, with CSP bypass |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/content-security-policy/lab-csp-bypass |
| Target | `https://0a4f0042035ce49a8085a9ce00a10085.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected, CSP-bypassed via policy injection** (new class file: `xss/class-csp-bypass.md`) |
| Sub-type | `?search=` echoed raw into `<h1>` (CSP `script-src 'self'` is the only barrier); attacker-controlled `token` query param flows into the `report-uri` directive VALUE of the `Content-Security-Policy` header; a raw `;` splits a forged `script-src-elem 'unsafe-inline'` directive out of the value (Chrome) → inline `<script>alert(1)</script>` executes |
| Severity | High (CSP — the last line of defense — fully neutralized by its own header construction; full reflected-XSS impact restored) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl (header inspection), headless Chromium (A/B block-vs-execute proof) |

## Lab objective (verbatim)
> This lab uses CSP and contains a reflected XSS vulnerability.
> To solve this lab, perform a cross-site scripting attack that bypasses the CSP
> and calls the `alert` function. Intended solution is Chrome-only
> (`script-src-elem` support).

## First CSP lab in this KB
All 21 prior labs had NO `Content-Security-Policy` header (explicitly noted as an
enabler each time). This is the first lab where a real policy exists AND is defeated —
shifting the KB from "CSP absent" to "CSP present-but-injectable," with a new class
file covering policy-injection primitives generally.

## Attack surface at a glance
- `GET /?search=X` → `<h1>0 search results for 'X'</h1>` (verbatim, no encoding).
- Response header `Content-Security-Policy: default-src 'self'; object-src 'none';
  script-src 'self'; style-src 'self'; report-uri /csp-report?token=TOKEN`
  where TOKEN = raw `token` query param.
- Session cookie HttpOnly (theft needs in-context actions — noted for impact).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Echo + policy-injection + execution flow |
| `root-cause.md` | Delimiter-naive header construction; trust boundary |
| `verification.md` | A/B block-vs-bypass proof, header evidence |
| `impact.md` | CSP-restored full XSS impact analysis |
| `lessons.md` | Policy-injection method; CSP-audit checklist |