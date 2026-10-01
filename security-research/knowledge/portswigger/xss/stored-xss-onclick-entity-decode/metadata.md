# Metadata — Stored XSS into onclick event (entity-decode smuggling)

| Field | Value |
|---|---|
| Lab | Stored XSS into `onclick` event with angle brackets and double quotes HTML-encoded and single quotes and backslash escaped |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/contexts/lab-onclick-event-angle-brackets-double-quotes-html-encoded-single-quotes-backslash-escaped |
| Target | `https://0aeb006d04dee80a80600392009800e3.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — **Stored** (entity-decode smuggling into handler) |
| Sub-type | Comment `website` stored into `href` AND `onclick="…tracker.track('WEBSITE');"`; server encodes `'"<>`, doubles `\`, but leaves `&` RAW → `&apos;` smuggles a `'` past the escaper (browser decodes entities when computing the attribute value, BEFORE JS parsing) → `&apos;-alert(1)-&apos;` executes on author-link click |
| Severity | High (one store → click-gated code execution for every future viewer; native-UI lure) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium + CDP (click proofs, sync-read technique) |

## Lab objective (verbatim)
> This lab contains a stored cross-site scripting vulnerability in the comment
> functionality with angle brackets and double quotes HTML-encoded and single
> quotes and backslash escaped. To solve this lab, submit a comment that calls the
> `alert()` function when the blog post is viewed.
> (Note: fires when the author name is clicked — the lab counts click-driven execution.)

## Position in this KB
- The stored counterpart of entity/decoding-layer reasoning (cf. reflected
  `&`-handling notes): the escaper runs at STORE time, but HTML-entity decoding runs
  at RENDER time in the victim browser — a LATER decode stage the escaper must
  anticipate (encode `&` first, or the smuggled charset reconstitutes).
- Combines three prior lessons in one payload: quote-accounting (inner quotes get
  escaped — balanced/numeric discipline), operator precedence (`-(x=1)` parens —
  third appearance), and click-gated navigation sinks (sync-read proof technique
  against href-navigation evidence destruction).

## Attack surface at a glance
- `POST /post/comment` (`csrf`, `postId`, `comment`, `name`, `email`, `website`
  with client-only `pattern="(http:|https:).+"` — direct POST bypasses trivially).
- Rendered per comment: `name` (anchor text), `website` → `href` + `onclick`
  tracker call, `comment` (paragraph).
- No CSP observed.

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Store→decode→click flow; per-field map |
| `root-cause.md` | Decode-stage ordering failure; trust boundary |
| `verification.md` | Entity proof, trap diagnoses, click proofs |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Entity-smuggling method; layered-decode reasoning |