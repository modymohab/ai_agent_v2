# Root Cause — Stored XSS in comment field (no output encoding)

## The vulnerability
A **stored XSS** where attacker-controlled comment content is persisted and later
re-emitted into an HTML text context (`<p>` element) **without any output encoding
or sanitization**. When any user (including a victim) views the post, the payload
parses and executes in the application's origin.

## Root cause (framing)
- The application is a **server-rendered** blog. Comments are the only user-generated
  content stored and later displayed to other users.
- At the **data-acceptance boundary** (`POST /post/comment`), no validation or sanitization
  is applied to `comment`. This is acceptable *only if* the **output (render) boundary**
  encodes the value.
- At the **render boundary**, the comment is inserted directly into the HTML template:
  `<p>${comment}</p>`. **There is no context-aware output encoding.**
- Contrast: the same server *does* encode the `name` and `website` fields
  (HTML entities / character references). This proves the developers knew how to encode —
  the encoding was simply **omitted/inconsistent** for the `comment` field.
- The result: the browser interprets `<script>` (and any other markup) in the comment as
  **code**, not **data**.

## Boundary model
```
Attacker input ──(transport)──► POST /post/comment
                                    │  (server PERSISTS raw string)
                                    ▼
                 Storage (data at rest)
                                    │  (server RENDERS into HTML without encoding)
                                    ▼
              [TRUST BOUNDARY CROSSED]
                 HTML parser in victim browser ──► script execution
```

- **Assumption that failed**: "content stored by our users is safe text" / "we only need
  to sanitize on input, not encode on output".
- **Trust boundary crossed**: the **data → code** boundary at HTML rendering time in the
  client. The server trusted `comment` to remain inert data across its persistence and
  render pipeline.

## Security-relevant facts observed
| Observation | Implication |
|---|---|
| `<p>COMMENTPROBE<<<>>></p>` renders verbatim | no encoding, no filtering on comment |
| `<script>alert(1)</script>` stored and executes | persistence + render pipeline is blind to code |
| `name`/`website` encoded at render | encoding exists in codebase but is per-field, inconsistent |
| CSRF token required on POST | state-changing action is CSRF-protected, but attacker obtains token with own session |
| `SameSite=None` + `Secure` + `HttpOnly` session cookie | session cookie is HttpOnly → XSS needed to steal sessions (exactly what we gain) |

## Why this is a stored (not reflected) XSS
- The payload is persisted server-side and served to **all** subsequent visitors of the page,
  independent of the original request. Stealth/durability: a single submission compromises
  every viewer (mass exploitation), unlike reflected XSS which needs a crafted link.

## Fix (for reference)
Apply context-aware output encoding (HTML-entity encode) to `comment`, `name`, `website`
at render time, and/or sanitize markup server-side. Never rely on client-side only.