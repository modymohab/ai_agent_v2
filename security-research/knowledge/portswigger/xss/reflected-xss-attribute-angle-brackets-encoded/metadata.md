# Metadata — Reflected XSS into attribute with angle brackets HTML-encoded

| Field | Value |
|---|---|
| Lab | Reflected XSS into attribute with angle brackets HTML-encoded |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-attribute-angle-brackets-html-encoded |
| Target | `https://0afc004804ff7f1980e35df800750090.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Reflected** (server-rendered; new class file: `xss/class-reflected-xss.md`) |
| Sub-type | `?search=` reflected into double-quoted `<input value="…">`; `<`/`>` encoded, `"`/`'` raw → attribute-breakout + event handler (`autofocus`/`onfocus`, zero-click) |
| Severity | Medium (client-side code execution at app origin; requires victim to visit crafted URL; no further interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (`--dump-dom`), Chromium+CDP (focus-state diagnosis) |

## Lab objective (verbatim)
> This lab contains a reflected cross-site scripting vulnerability in the search
> functionality. To solve this lab, trigger `alert()`.

## First of its class in this KB
All prior labs were stored or DOM-based. This is the first **server-side reflected**
XSS: the payload travels `request → server template → response`, executes on load,
and never touches storage or client-side sinks. It establishes the reflected-XSS
methodology (per-context encoding map of every server reflection) that complements
the DOM labs' source/sink audit.

## Attack surface at a glance
- `GET /?search=<term>` — two server reflections: `<h1>` text (fully encoded) and
  `<input value="…">` attribute (`"`/`'` raw).
- No CSP; `X-Frame-Options: SAMEORIGIN` present (irrelevant to this self-URL vector).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Request→template→response flow; exact breakout bytes |
| `root-cause.md` | Partial-encoding failure; trust boundary |
| `verification.md` | Encoding map, quoting diagnosis, focus-timing harness lesson |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Reflected-XSS method; payload-accounting rule; harness timing |