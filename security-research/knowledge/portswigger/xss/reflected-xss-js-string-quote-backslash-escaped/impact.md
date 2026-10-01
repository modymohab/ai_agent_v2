# Impact — Reflected XSS into JS string (quotes+backslash escaped)

## Applicability reasoning
The input (`search`) is echoed into a script string with JS metachars neutralized
but `</script>` raw; the HTML tokenizer ends the element and a fresh attacker block
executes in the victim's browser on the application origin upon crafted-URL visit
(parse-time, no interaction). Categories: **client-side, link-delivered,
full-statement** (fresh block = arbitrary JS). No storage, no state change, no
non-JS consumer.

## CONFIRMED
- **Parse-time arbitrary JS at the application origin** on crafted-URL visit
  (title-mutation proof; real `alert(1)` + acceptance). The fresh block has no
  statement constraints beyond avoiding server-mangled chars.
- **Clean execution**: original script's tail becomes inert body text; page otherwise
  functional.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as victim).
- **Admin compromise** via crafted search link.
- **Keylogging / credential capture / phishing overlays / CSRF-token theft**.
- **Exfil-rich multi-statement blocks** (fresh `<script>` has no URL-grammar
  constraints beyond the escaper's survivors).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| JS-layer breakout (`';`, `\`-shift) | NOT APPLICABLE (disproven) | `'`→`\'`, `\`→`\\` — terminator set empty |
| Single-quoted inner payloads | NOT APPLICABLE (disproven §3) | escaper covers post-closure text |
| Tag injection elsewhere / h1 context | NOT APPLICABLE | h1 fully encoded |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |

## NOT TESTED
- Other echo points/params (only `search` mapped).
- `"`-containing inner payloads beyond the title marker (proven sufficient; `"` raw).
- CSP interplay (no CSP here; note `script-src` without unsafe-inline WOULD blunt
  this vector — depth that works, unverified on this stack).

## What would increase impact in a real application
- **Authenticated app**: crafted link → ATO; script-block echoes on login-adjacent
  pages (errors, "welcome" configs) are prime real-world instances.
- **Analytics/config echoes** (`var user = '…';`, dataLayer, feature flags with user
  values) — the most common production shape of this sink.
- **Long/POST-echo variants** (bigger payloads; evade log review).
- **Shared-encoder blind spots**: teams that "fixed" quote-escaping and stopped
  auditing will all share this hole wherever `<` survives near `</script>`.
- **Missing HttpOnly** → trivial cookie read.

## Lab-scoped confirmed impact
`alert()` via script-element closure — accepted first poll.