# Metadata — Reflected XSS in canonical link tag (accesskey trigger)

| Field | Value |
|---|---|
| Lab | Reflected XSS in canonical link tag |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-canonical-link-tag |
| Target | `https://0acd00e80392b5a8829a47d90072004c.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (key-triggered, platform-simulated user) |
| Sub-type | Full request URL reflected into single-quoted `<link rel="canonical" href='…'>`; server URL-encodes (`"`→`%22`, `<>`→`%3c%3e`) but leaves `'` raw → breakout `?'accesskey='x'onclick='alert(1)`; platform simulates ALT+SHIFT+X / CTRL+ALT+X / Alt+X → click on the link → handler fires (Chrome-only) |
| Severity | Medium (code execution at app origin; requires crafted URL AND keypress — platform-simulated here, social-engineered in reality) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`, first poll) |
| Tools used | curl, xxd (byte-exact template proof), real browser tab |

## Lab objective (verbatim)
> This lab reflects user input in a canonical link tag and escapes angle brackets.
> To solve the lab, perform a cross-site scripting attack on the home page that
> injects an attribute that calls the `alert` function. Assume the simulated user
> presses ALT+SHIFT+X / CTRL+ALT+X / Alt+X. Intended solution is Chrome-only.

## Position in this KB
- The reflected-attribute pattern (cf. `reflected-xss-attribute-angle-brackets-encoded`)
  moved into `<head>` on a NON-rendered element (`<link>`): no autofocus, no load-fire —
  the trigger must be manufactured via `accesskey` + simulated keypress.
- URL-encoding-as-filter (not HTML-encoding): `<>`/`"` neutralized by percent-encoding,
  `'` survives because it's URL-legal — a new filter species for the KB (all prior
  labs used HTML-entity or reject filters).
- First lab whose trigger is neither load/error/click/fragment/compiler nor victim
  navigation, but KEYBOARD ACCESS (`accesskey` → synthetic click).

## Attack surface at a glance
- `GET /?<anything>` → canonical `href` echoes the full URL (path must exist; `/` used).
- No CSP observed. No exploit server (self-solve via platform-simulated keys).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | URL→canonical→accesskey→keypress flow |
| `root-cause.md` | URL-encoding blind spot; accesskey semantics; trust boundary |
| `verification.md` | Byte-exact template proof; keypress mechanics; CDP anomaly |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | accesskey vectors; URL-encoding filters; trigger taxonomy addition |