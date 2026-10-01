# Metadata — DOM XSS in innerHTML sink using source location.search

| Field | Value |
|---|---|
| Lab | DOM XSS in `innerHTML` sink using source `location.search` |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-innerhtml-sink |
| Target | `https://0a1800b304c440608118258300670073.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **DOM-based** (type-0: no server involvement) |
| Sub-type | `element.innerHTML` sink; source `location.search` via `URLSearchParams`; element-content context |
| Severity | Medium-High (client-side code execution at app origin; requires victim to visit crafted URL) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (`--dump-dom`), real browser tab |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.

## Relationship to sibling labs
- `dom-xss-document-write-location-search`: same source (`location.search`), different
  sink (`document.write` inside a quoted attribute → needed `"`+`>` breakout AND allowed
  `<script>`).
- This lab: sink is `innerHTML` into **element content** → NO breakout prefix needed,
  but `<script>` does NOT execute → event-handler payload required.
- The pair jointly proves the class rule: **payload shape is dictated by sink semantics,
  not by the source**.

## Attack surface at a glance
- Search box on homepage: `GET /?search=<term>` (form `action=/` method GET).
- Results page runs: `document.getElementById('searchMessage').innerHTML = query`.
- The search term has **zero** server-side reflection (pure client-side sink).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Source→sink flow; why event-handler, why no breakout |
| `root-cause.md` | innerHTML semantics; trust boundary |
| `verification.md` | Positive proof, `<script>` negative proof, reproducibility |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Sink-semantics payload selection; generalizable pattern |