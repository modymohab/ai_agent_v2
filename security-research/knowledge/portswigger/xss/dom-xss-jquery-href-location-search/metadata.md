# Metadata — DOM XSS in jQuery anchor href attribute sink using location.search source

| Field | Value |
|---|---|
| Lab | DOM XSS in jQuery anchor `href` attribute sink using `location.search` source |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-jquery-href-attribute-sink |
| Target | `https://0a0f0099047582eb81ad582500c000e0.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **DOM-based** (type-0: no server involvement) |
| Sub-type | jQuery `.attr("href", …)` sink on an anchor; source `location.search` via `URLSearchParams`; `javascript:`-URI execution **on click** |
| Severity | Medium (client-side code execution at app origin; requires victim to visit crafted URL AND click the poisoned link) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (`--dump-dom`), Chromium+CDP click driver (python `websocket`), real browser tab |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the submit-feedback
> function. To solve this lab, trigger `alert()`.

## Relationship to sibling labs
- `dom-xss-document-write-location-search`: same source family, markup-parsing sink —
  payload executes on page load, no interaction.
- `dom-xss-innerhtml-location-search`: same source family, fragment sink — executes on
  resource error, no click.
- **This lab**: neither markup parsing nor load-time execution. The value becomes an
  attribute; execution needs a **user click** on the poisoned anchor. It completes the
  DOM-XSS interaction matrix: load-time vs error-time vs click-time execution.

## Attack surface at a glance
- `/feedback?returnPath=…` — feedback form page; inline jQuery sets `#backLink` href
  from `returnPath`.
- `/feedback/submit` (POST, CSRF-protected) — separate feedback feature, not the XSS path.
- `/`, `/post?postId=N` — blog pages; nav links into `/feedback?returnPath=…`.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Source→sink flow; why `javascript:` + click; `void()` nuance |
| `root-cause.md` | jQuery attr sink; trust boundary |
| `verification.md` | Attribute proof, CDP click proof, open-redirect proof, failed candidates |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Click-gated sinks; CDP verification method; generalizable pattern |