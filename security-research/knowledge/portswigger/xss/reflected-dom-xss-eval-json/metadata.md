# Metadata — Reflected DOM XSS (eval of server JSON)

| Field | Value |
|---|---|
| Lab | Reflected DOM XSS (`lab-dom-xss-reflected`) |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-dom-xss-reflected |
| Target | `https://0aad00270464fa9184f4ea9b00eb00eb.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **hybrid**: server-reflected JSON × client-side `eval()` sink |
| Sub-type | `?search=` reflected into `/search-results` JSON `searchTerm` (`"`→`\"`, `\` raw) → page XHRs the JSON → `eval('var searchResultsObj = ' + responseText)`; breakout via backslash escape-shift + early object-close + `//` |
| Severity | High (load-time arbitrary JS at app origin on crafted URL; page renders normally — stealthy; no interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, headless Chromium, Chromium+CDP (exact-bytes eval harness via base64), real browser tab |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.
> (Standard reading: the search page fetches JSON and `eval()`s it — break the JSON.)

## Why this lab is the KB's hardest-won folder
The breakout grammar had to be derived character-by-character against a deceptive
escaper (`"` escaped, `\` raw), surviving FIVE failed payload shapes plus three
analyst-harness bugs (each failure diagnosed to its exact JS-grammar cause). The
winning shape — `x\"};alert(1);//` — is forced by the template, not chosen: terminator
via escape-shift, object closed early with raw `}`, statement position, `//` eating the
template tail. Every alternative dies for a distinct grammatical reason, all recorded
in verification.md.

## Attack surface at a glance
- `GET /?search=X` — search page; inline `search('search-results')` triggers
  `XHR GET search-results?search=X` (external `searchResults.js`).
- `GET /search-results?search=X` — JSON `{"results":[…],"searchTerm":"ESC(X)"}`;
  `results[]` are server DB data (not attacker-influenced); multi-param: last wins.
- Sink: `eval('var searchResultsObj = ' + this.responseText)` on XHR 200.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Full URL→XHR→JSON→eval flow; winning bytes + grammar proof |
| `root-cause.md` | eval-of-JSON + asymmetric escaper; trust boundary |
| `verification.md` | Encoding map, all failed shapes with causes, harness discipline |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | eval-JSON breakout method; failure-driven derivation |