# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When an application accepts user-generated content on a multi-tenant page (comments,
> posts, reviews, profiles, message boards) and re-renders it for other users, enumerate
> EVERY user-controlled field and map each one to its exact output context before testing.**
> Then ask, per field: does the output context defender (encoding/sanitizer) exist?
> The vulnerability is usually a **single field** whose encoding was omitted while sibling
> fields were correctly encoded.

Generalized rule:
"When a form persists multiple fields and re-renders them in distinct locations
(text node, attribute, element content), an XSS sink exists **iff** a field is emitted
into an HTML context without context-aware encoding. Test by placing a unique marker
(including raw `<'">`) in each field in a single submission, then diff the rendered DOM."

## Recon indicators (how to spot this class again)
- Any app feature where: user input → **stored** → **shown to other users**
  (blog comments, reviews, chat, support tickets, display names, profile fields).
- Look for the classic three-field comment/profile pattern: `content`, `name` (display),
  `website` (URL). They usually map to distinct render contexts and are encoded
  inconsistently — exactly the setup here.
- HTTP response **without `Content-Security-Policy`** → inline `<script>` likely viable.
- Server-rendered (classic form posts → 302 → re-fetch) rather than a modern JSON SPA:
  the output is deterministic server HTML, easy to grep for markers.

## Verification techniques (reusable)
1. **Unique-marker field mapping.** One request, one marker per field
   (`COMMENTPROBE<<<>>>`, `NAMEPROBE"'<b>`, URL with a breakout try). Re-fetch and grep.
   Reads: encoded vs raw = injectable vs not, per context.
2. **Non-blocking execution proof.** If the goal is `alert()`, headless dumps freeze on the
   dialog (a hang is itself evidence, but use `document.title='X'` for a clean assertion).
3. **Clean-room post.** Prove execution on a page *without* the blocking payload (different
   noun/object) so the assertion is isolated.
4. **Storage vs render separation.** Re-fetch hours later (or via a second, fresh session)
   to confirm persistence and delivery to a *new* viewer — this is what makes it *stored*,
   not reflected. (Here: a new curl session with a fresh cookie still renders the payload.)

## Common mistakes that make agents miss this
- **Trusting the lab title** instead of locating the sink; or conversely **ignoring the
  title** and spray-payloading random fields.
- **Stopping after the first field check.** `name` (encoded) and `website` (encoded)
  both look "safe" — only `comment` is the sink. Map ALL fields.
- **Not persisting/loading properly:** posting but then checking the redirect/confirmation
  (which does NOT echo the comment) instead of re-fetching the post page where it renders.
- **Forgetting CSRF/session juggling** and blaming the app for failures that are really
  broken token/session handling.
- **Assuming attribute-context "quotes" from `href` are injectable** because the *client*
  pattern (`pattern="(http:|https:).+"`) is only a UI constraint; the real constraint is
  server-side output encoding. Always verify server behavior, not client hints.
- **Treating "no sanitize on input" as binary.** Input sanitization is not required if
  output encoding exists; the bug is that encoding exists for some fields and not the
  comment field — a consistency/coverage bug, not a missing "filter".

## Cross-cutting notes for future labs
- Same app (blog, form-encoded, CSRF-tokenized) with different roots: comment XSS variants
  in attribute context, "photo-upload XSS", "HTML context with tag stripping/encoding"
  all share the same input→output mapping methodology.
- The cookie is `SameSite=None` — in a real engagement note this allows cross-site
  state-carrying requests (CSRF-adjacent checks may be weakened server-side).