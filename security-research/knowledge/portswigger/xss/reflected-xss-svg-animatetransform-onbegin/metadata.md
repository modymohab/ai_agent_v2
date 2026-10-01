# Metadata — Reflected XSS with some SVG markup allowed

| Field | Value |
|---|---|
| Lab | Reflected XSS with some SVG markup allowed |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-some-svg-markup-allowed |
| Target | `https://0a5600ab04a413f68183612f00ee00a9.h1-web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected, filter-gapped (SVG-namespace)** |
| Sub-type | `?search=` echoed into `<h1>`; reject-filter (400) blocks standard tags + common handlers, but `<svg>`/`<animateTransform>`/`<text>`/`<title>`/`<image>`/`<circle>`/`<rect>`/`<ellipse>`/`<line>` pass and SMIL `onbegin` is unlisted → `<svg><animatetransform onbegin=alert(1)>` fires on load, zero interaction |
| Severity | Medium-High (load-time code execution at app origin on crafted URL; no interaction; no click) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl (400-oracle tag/attribute mapping), headless Chromium |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality with some SVG markup allowed. To solve this lab, trigger `alert()`.
> (Standard reading: find the allowed SVG vector that fires without interaction.)

## Position in this KB
- Third filter-adversarial lab after the two WAF labs, same 400-oracle methodology —
  but the gap class is new: NAMESPACE-SPECIFIC (SVG animation events) rather than
  unlisted-generic (`body`, custom tags). The filter authors enumerated HTML dangers
  and SVG-obvious dangers (`<animate>`, `<animateMotion>`, `<set>` blocked) yet missed
  `<animateTransform>` + `onbegin`.
- Execution is load-time self-fire (no victim infrastructure, unlike the two
  victim-delivery WAF labs) — the oracle work is identical, the trigger needs nobody.

## Attack surface at a glance
- `GET /?search=X` → `<h1>0 search results for 'X'</h1>` (verbatim when passing).
- Filter: 400 on listed tags/handlers (case-insensitive); SVG subset + `onbegin` pass.
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Echo → SVG parse → SMIL begin-event flow |
| `root-cause.md` | Namespace-blind blocklist; trust boundary |
| `verification.md` | Oracle maps, execution proof, alternative analysis |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | SVG/SMIL gap hunting; filter-family comparison |