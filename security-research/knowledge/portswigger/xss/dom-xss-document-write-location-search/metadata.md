# Metadata — DOM XSS in document.write sink using source location.search

| Field | Value |
|---|---|
| Lab | DOM XSS in `document.write` sink using source `location.search` |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-document-write-sink |
| Target | `https://0a7700dc03d3367d805303aa005b00ca.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **DOM-based** (type-0: no server involvement in the sink) |
| Sub-type | `document.write()` sink; source `location.search` via `URLSearchParams`; HTML attribute context |
| Severity | Medium-High (client-side code execution at app origin; requires victim to visit crafted URL) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (`--dump-dom`), real browser tab |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.

## Interesting contrast with previous lab
Previous lab (`stored-xss-html-context-nothing-encoded`) was a **server-rendered**
stored XSS. This lab is **purely client-side**: the server sends a fixed inline script
and never processes the payload. The sink executes entirely in the browser. This is
"type-0" DOM XSS — the payload never appears in the HTTP response as itself.

## Attack surface at a glance
- Search box on the homepage: `GET /?search=<term>` (form `action=/` method GET).
- Search-results page inlines a tracking script that reads `location.search`.
- Single sink: `document.write('<img src="/resources/images/tracker.gif?searchTerms='+query+'">');`

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Source→sink data flow, both working breakout vectors |
| `root-cause.md` | Why document.write of URL data is dangerous; trust boundary |
| `verification.md` | Proof of execution, edge-case encoding analysis, failed candidates |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Generalizable pattern, recon indicators, anti-mistakes |