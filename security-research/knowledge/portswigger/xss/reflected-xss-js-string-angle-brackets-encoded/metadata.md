# Metadata — Reflected XSS into a JavaScript string with angle brackets HTML encoded

| Field | Value |
|---|---|
| Lab | Reflected XSS into a JavaScript string with angle brackets HTML encoded |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-javascript-string-angle-brackets-html-encoded |
| Target | `https://0afe00ba045ab5db80fe9e3e00520071.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (server-rendered into JS-string context) |
| Sub-type | `?search=` echoed into `var searchTerms = '…';` (single-quoted JS string); `<>`→entities but `'"\` raw → quote-breakout `';alert(1);//` (no tags needed or usable) |
| Severity | Medium-High (load-time arbitrary JS at app origin on crafted URL; no interaction; full statement position) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, xxd (byte-exact escaper proof), headless Chromium |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.

## Position in this KB
- Empirical confirmation of the `class-reflected-xss.md` JS-string row (previously
  tabulated, now proven with full evidence): single-quoted sink + `<>`-encoding ⇒
  `';JS;//` is the forced shape.
- Mirror of the reflected-attribute lab (breakout char differs: `"` there, `'` here;
  both forbid tags). Pair completes the reflected-context breakout set: text (dead
  when encoded), attribute, JS-string.
- Contrast with the eval-JSON lab: there quotes were escaped (needing `\`-shift);
  here quotes are raw (direct breakout). The escaper — not the sink shape — decides
  payload complexity.

## Attack surface at a glance
- `GET /?search=X` → two reflections: `<h1>` text (fully encoded + backslash-doubled)
  and `var searchTerms = 'X';` (`<>`-only encoding; `'","\` raw).
- No CSP. Tracker `document.write` downstream of the sink (runs normally post-exploit).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Request→template→script flow; exact breakout bytes |
| `root-cause.md` | Wrong-context encoding + asymmetric escapers; trust boundary |
| `verification.md` | Byte-exact map, proof, terminator analysis |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | JS-string breakout method; terminator enumeration |