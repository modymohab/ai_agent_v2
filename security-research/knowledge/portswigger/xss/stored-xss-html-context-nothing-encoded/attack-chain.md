# Attack Chain — Stored XSS via unencoded comment field

## Data flow

```
Attacker browser                       Server                         Victim browser
-----------                           ------                         --------------
GET /post?postId=N  ──►  (200, sets `session` cookie)
                          parse CSRF token from HTML
POST /post/comment  ──►  [trust boundary: trusting user comment as data]
  csrf=<token>
  postId=N
  comment=<script>alert(1)</script>
  name=Agent
  email=agent@example.com
  website=https://example.com
                   ◄──  302 → /post/comment/confirmation?postId=N
                          server PERSISTS comment verbatim

                                                       GET /post?postId=N ◄── (victim session)
                                                       server renders stored comment
                                                       into <section class="comment">
                                                       <p><script>alert(1)</script></p>
                                                       ◄── [SINK: output into HTML text context WITHOUT encoding]
                                                       script parses & executes → alert(1)
                                                       in victim's browser, app origin
```

## Stages

1. **Session + CSRF acquisition**
   - `GET /post?postId=1` returns a fresh `session` cookie and an HTML page containing
     `<input type="hidden" name="csrf" value="...">`. Comment submission requires this token.
   - The token is bound to the session cookie; a raw `curl` with a cookie jar handles this naturally.

2. **Store the payload**
   - `POST /post/comment` with the comment set to `<script>alert(1)</script>`.
   - Server validates presence of fields only (CSRF, postId, comment, name, email).
     No markup sanitization is applied to `comment`.

3. **Storage → every-future-visitor sink**
   - Comments persist; any `GET /post?postId=N` re-emits stored comments inside
     `<section class="comment">…</section>`.
   - The `comment` value is placed verbatim into a `<p>` element:
     `<p><script>alert(1)</script></p>`.
   - Because the `<script>` start tag reaches the browser's HTML parser, the raw-text
     script data is executed. No user interaction is required — page load is enough.

4. **Impact boundary crossed**
   - Execution runs in the **origin of the application** with the **victim's cookies/identity**
     (attack context = application origin, not attacker origin).

## Input -> output map (all four user-controlled fields)

| Field | Location | Server output encoding | Injectable? |
|---|---|---|---|
| `comment` | `<p>COMMENT_PROBE</p>` | **none** | **YES — main sink** |
| `name` | `<a id="author" href="…">NAME</a>` (text node) | HTML-encoded (`" ' < >`) | No |
| `website` | `href="…"` (double-quoted attribute) | Character-refs encoded (`"` → `&quot;`) | No |
| `email` | not reflected in this build | — | n/a (no sink) |

## Why per-field injection status differs — trust/render boundary

The server-side template encodes `name` and `website` at render time but emits `comment`
with no encoding. The vulnerability is therefore **specific to the comment field**, i.e.,
a "needle" (one field) in a "haystack" (four fields). A naive tester who stops after
checking `name`/`website` would falsely conclude the app is safe. Only a complete
input→output map exposes the actual sink.

## Sink summary

- **Source / primitive**: attacker-controlled `comment` string accepted by `POST /post/comment`.
- **Sink**: server HTML template inserting the persisted value into a text node
  `<p>${comment}</p>` without encoding/sanitization.
- **Props**: applications with user-generated content (comments, reviews, posts, profiles,
  message boards) that re-render raw stored HTML.

## Expected response sequence (verified)

1. `GET /post?postId=N` → 200, `set-cookie: session=…`
2. `POST /post/comment` → **302** → `/post/comment/confirmation?postId=N`
3. `GET /post?postId=N` → 200, comment rendered verbatim
4. Browser parsing executes script.