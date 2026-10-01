# Metadata — Reflected XSS into HTML context with all tags blocked except custom ones

| Field | Value |
|---|---|
| Lab | Reflected XSS into HTML context with all tags blocked except custom ones |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-html-context-with-all-standard-tags-blocked |
| Target | `https://0a5e00df041bb628818d116d00b300c7.web-security-academy.net/` |
| Exploit server | `https://exploit-0ad9005304a8b6d6818e109c01d80092.exploit-server.net` |
| Class | Cross-Site Scripting (XSS) — **Reflected, filter-shaped, victim-delivered** |
| Sub-type | `?search=` echoed into `<h1>`; WAF blocks all standard tags (custom/unknown pass, handlers unfiltered here) → `<xss id=x onfocus=alert(document.cookie) tabindex=1>` + `#x` fragment auto-focuses on load → victim `alert(document.cookie)`, zero interaction |
| Severity | High (victim code execution with cookie exfil primitive demonstrated; no interaction) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`; victim `GET /exploit` in access log) |
| Tools used | curl (filter probing), headless Chromium (focus-chain proof), exploit-server form API |

## Lab objective (verbatim)
> This lab blocks all HTML tags except custom ones.
> To solve the lab, perform a cross-site scripting attack that injects a custom tag
> and automatically alerts `document.cookie`.
> (Official solution: exploit-server page navigating victim to the payload URL with
> `#x` fragment; victim delivery required.)

## Companion position in this KB
- Direct sequel to `reflected-xss-waf-bypass-body-onresize` (same 400-oracle WAF
  family, same victim-delivery mechanics) with the INVERSE filter shape: there,
  standard tags blocked + most handlers blocked (gap: body×onresize); here, standard
  tags blocked + HANDLERS OPEN (gap: custom tag × onfocus × fragment-focus).
- Same delivery template (exploit-server lure → victim browser → platform signal),
  different trigger (fragment auto-focus vs iframe resize).

## Attack surface at a glance
- `GET /?search=X` → `<h1>0 search results for 'X'</h1>` (verbatim incl. `on*`
  handlers on custom tags; standard tags → 400).
- Exploit server `/`, `/exploit`, `/log` (same form API + overwrite caution as before).
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Reflection → custom-tag → fragment-focus → victim alert flow |
| `root-cause.md` | Tag-blocklist vs custom elements; focus-trigger trust boundary |
| `verification.md` | Filter behavior, focus proof, delivery evidence |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Custom-tag vectors; fragment-focus triggers; delivery discipline |