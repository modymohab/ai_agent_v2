# Metadata — Stored XSS into anchor href attribute with double quotes HTML-encoded

| Field | Value |
|---|---|
| Lab | Stored XSS into anchor `href` attribute with double quotes HTML-encoded |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-href-attribute-double-quotes-html-encoded |
| Target | `https://0a3b00dd03e1f6de82ab3eb4001e007d.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Stored** (persistence) × **navigation sink** (`href`) |
| Sub-type | Comment `website` field stored into `<a id="author" href="…">`; `"`→`&quot;` but NO scheme validation → whole-value `javascript:` URI; executes when any viewer clicks the author name |
| Severity | High (one store → every future viewer gets a poisoned native-UI link; click-gated but the lure is the page itself) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium (attribute proof), Chromium+CDP (stored-click proof), real browser tab (acceptance click) |

## Lab objective (verbatim)
> This lab contains a stored cross-site scripting vulnerability in the comment
> functionality. To solve this lab, submit a comment that calls the `alert()`
> function when the blog post is viewed.
> (Note: the `alert()` fires when the author name is clicked — the lab counts the
> click-driven execution.)

## Bridge position in this KB
- Stored mechanics from `stored-xss-html-context-nothing-encoded` (comment form,
  CSRF juggling, per-field mapping, persistence → mass delivery).
- Navigation-sink payload family from `dom-xss-jquery-href-location-search`
  (URI not markup, `javascript:` scheme, click gate, `void()`-proof harness).
- New lesson: **`"`-encoding without scheme validation is no defense for `href`** —
  the attacker never needs to break out when the whole value can BE the payload.

## Attack surface at a glance
- `POST /post/comment` (`csrf`, `postId`, `comment`, `name`, `email`, `website`);
  no client-side `pattern` on `website` in this build; no server-side scheme check.
- Rendered per comment: `name` (anchor text, fully encoded), `website` (href,
  `"`-encoded only), `comment` (paragraph, fully encoded — unlike the first stored lab).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Store→render→click flow; exact field map |
| `root-cause.md` | Encoding-without-validation failure; trust boundary |
| `verification.md` | Mapping probe, attr/click proofs, dead-end analysis |
| `impact.md` | Stored × click-gated impact reasoning |
| `lessons.md` | Scheme-validation rule; stored-navigation pattern |