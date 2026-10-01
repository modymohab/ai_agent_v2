# Metadata — DOM XSS in document.write sink using source location.search inside a select element

| Field | Value |
|---|---|
| Lab | DOM XSS in `document.write` sink using source `location.search` inside a `select` element |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-document-write-sink-inside-select-element |
| Target | `https://0ace00c40391e6a880824ec6005700a8.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **DOM-based** (type-0, pure: zero server reflection) |
| Sub-type | `document.write` sink; source `location.search` (`storeId`); value wrapped in `<option selected>…</option>` inside a written `<select>`; e-commerce (not blog) app |
| Severity | Medium-High (load-time code execution at app origin on crafted product URL; no interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (`--dump-dom` ×4 incl. static-HTML control) |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability in the stock check
> functionality. To solve this lab, trigger `alert()`.

## Why this lab earns its own folder (not a sibling instance)
The sink family (`document.write` + `location.search`) matches the first DOM lab, but
the WRAPPING context (`<option>` inside `<select>`) changes the parser rules — and the
empirical result contradicts the textbook expectation: the `</select>` breakout is
UNNECESSARY on current Chrome (foreign elements parse and execute inside `<option>`),
and `<script>` executes in select context too. Three working vectors where the
textbook predicts one.

## Attack surface at a glance
- `/product?productId=N` — product page; stock-check form writes `<select>` via
  `document.write`, injecting `storeId` into `<option selected>`.
- `POST /product/stock` — stock-check endpoint (not in the XSS chain; not tested).
- `storeId` has zero server reflection (marker count 0) — pure client sink.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Sink code; three vectors + DOM shapes |
| `root-cause.md` | Parser-leniency rules; trust boundary |
| `verification.md` | Four headless proofs incl. static control + negatives |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Test-don't-assume parser contexts; generalizable pattern |