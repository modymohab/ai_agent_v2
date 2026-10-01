# Impact — Stored DOM XSS (single-replace bypass)

## Applicability reasoning
Attacker comment text is persisted server-side and rendered client-side through a
first-occurrence-only escaper into `innerHTML`: event-handler markup survives and
executes in every viewer's browser on the application origin at page load. Relevant
categories: **client-side, stored-delivered, zero-interaction**. No non-HTML server
consumer; comment POST is CSRF-protected (attacker's own session used).

## CONFIRMED
- **Stored load-time code execution for every current and future viewer** with zero
  interaction (title-mutation proof through the real store→JSON→escape→innerHTML
  path; real `alert(1)` + acceptance). One comment poisons the post indefinitely.
- **Sanitizer bypass, not absence**: the defense EXISTS and runs — it just replaces
  once. Filters that "mostly work" are bypassed deterministically, not probabilistically.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Mass session theft / account takeover** of the readership (cookies, tokens,
  storage, in-page secrets; authenticated actions as each victim).
- **Admin/moderator compromise** via comment-review views rendering the same JSON.
- **Self-propagation (stored-XSS worm)**: payload posting further comments through
  victims' sessions (CSRF tokens present in page) — the classic stored escalation;
  this lab's write+read loop is worm-compatible (not attempted).
- **Author-field variant** (same escapeHTML→innerHTML code path).
- **Phishing overlays / keylogging / credential capture** at blog scale.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| `website=javascript:` execution | NOT APPLICABLE (disproven) | server 400s non-http(s) schemes, case-insensitive |
| `<script>` via this sink | NOT APPLICABLE | innerHTML neuter (prior-lab proof stands) |
| Lone-bracket payloads | NOT APPLICABLE (reasoned) | sole metachars consumed/corrupted by escaper |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | JSON store only; no other consumer |
| CSRF against comment POST via THIS primitive | NOT APPLICABLE | per-session token; attacker uses own session |
| Click/hover-gating | NOT APPLICABLE | img-error fires during load |

## NOT TESTED
- Author-field separate firing (PLAUSIBLE, same path — tagged honestly above).
- Other posts as injection hosts; admin-view chains.
- `avatar`-field exotic shapes (structurally inert via setAttribute — no test needed).
- CSP-hardened variants (no CSP here).

## What would increase impact in a real application
- **High-traffic user-content pages** (reviews, forums, docs comments) with client-side
  rendering — one payload reaches thousands passively.
- **SPA/API architectures** where ALL rendering is client-side: every stored field is
  a DOM-sink candidate, multiplying this lab's single sink across the app.
- **Moderation/admin JSON views** → privilege escalation on review.
- **Comment-write reachable with ambient credentials** (cookies + in-page CSRF) →
  wormability.
- **Hand-rolled sanitizers** (`replace` with string patterns, single-pass regexes,
  blacklist strips) anywhere in the render path — audit for first-occurrence and
  non-global semantics specifically.

## Lab-scoped confirmed impact
`alert()` via stored comment body on every post view — accepted first poll.