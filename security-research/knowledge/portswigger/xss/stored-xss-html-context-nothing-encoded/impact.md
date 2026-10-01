# Impact — Stored XSS via unencoded comment field

## Applicability reasoning
The discovered input (`comment`) is persisted and re-emitted into an **HTML-render sink**
in the **victim's browser context** on the application origin. It therefore reaches a
browser-executable context → client-side script execution. Every other impact category
below is judged against that.

## CONFIRMED
- **Stored client-side script execution (any viewer, zero interaction).**
  Arbitrary JavaScript executes in the application's origin with the viewing user's
  identity/cookies. Proven via `document.title='…'` mutation in a stock browser parse.
- **Persistence / mass distribution.** One stored payload is delivered to every subsequent
  visitor of the post (post 1). Attack is "fire and forget"; no per-victim luring needed.

## PLAUSIBLE (same primitive, not separately lab-verified)
- **Session hijacking / account takeover of any comment-page viewer.** Cookies are
  `HttpOnly` but that is irrelevant—XSS runs in page JS context and can:
  fetch/exfiltrate anything the page could (tokens, abilities), perform authenticated
  actions as the victim (e.g., add comments/posts), or use CSRF tokens present in the page.
- **Admin compromise.** If an admin dashboard renders the same stored comments (common in
  real moderation UIs) or an admin merely visits the public post, the admin's privileges
  are directly reachable.
- **Phishing / malware-in-context.** Render a deceptive login overlay on the same origin
  (bypasses origin phishing heuristics).
- **Defacement.** Change what every visitor sees on the post indefinitely.

## NOT APPLICABLE (tested or structurally irrelevant)
| Category | Verdict | Basis |
|---|---|---|
| Server-side injection (SQLi, command, SSRF, XXE) | NOT APPLICABLE | commented HTML reaches HTML renderer only; no evidence of SQL/OS/URL sink from `comment` |
| Reflected/DOM XSS elsewhere | NOT TESTED beyond this lab | not part of demonstrated primitive |
| Attribute-context XSS via `website` | NOT APPLICABLE | server output-encodes `"` → `&quot;`; no attribute breakout (verified) |
| Text-context XSS via `name` | NOT APPLICABLE | server HTML-encodes name (verified) |
| Unauthenticated destructive action | NOT APPLICABLE | comment POST is CSRF-token protected; attacker uses own valid session |
| CSP / WAF bypass | n/a | no CSP observed; page had no `Content-Security-Policy` header |
| Cookie flags bypass | n/a | `HttpOnly`+`SameSite=None` present; not a bypass, XSS obviates them |

## What would increase impact in a real application
- Comments displayed inside an **admin or moderation interface** → instant admin RCE-equivalent.
- Absence of per-user rate limiting on comment POST → **mass spam + mass XSS** delivery.
- Cookie **without HttpOnly** → trivial credentials steal; with HttpOnly still exfiltratable
  via in-context actions.
- **No `Content-Security-Policy`** (true here) lets inline `<script>` run unimpeded;
  a CSP would force an rXSS/styles/attribute route instead of a trivial `<script>` tag.
- **Delete/approve workflow** where a moderator action acts on the comment content (DOM XSS
  chaining) or a "notify admin by email" feature that reflects comment content into HTML mail.
- Mounting a **self-propagating** payload (fetch other posts, inject) — worm potential on
  any multi-user app with the same flaw plus an authenticated write primitive.

## Lab-scoped confirmed impact
"Submit a comment that calls `alert()` when the blog post is viewed" → delivered and
accepted; browser-level execution independently confirmed.