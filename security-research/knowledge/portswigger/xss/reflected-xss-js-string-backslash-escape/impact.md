# Impact — Backslash-shift breakout in JS string

## Applicability reasoning
The input (`search`) is echoed into a single-quoted JS string whose escaper leaves
`\` raw; a leading backslash shifts the escape so `'` terminates the string and an
injected statement runs in the victim's browser on the application origin upon
crafted-URL visit (parse-time, no interaction). Categories: **client-side,
link-delivered, full-statement**. No storage, no state change, no non-JS consumer.

## CONFIRMED
- **Parse-time arbitrary JS at the application origin** on crafted-URL visit
  (title-mutation proof; real `alert(1)` + acceptance). Statement position admits
  any JS within URL limits.
- **Clean execution**: `//` neutralizes the template tail; downstream code runs
  normally.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as victim).
- **Admin compromise** via crafted search link.
- **Keylogging / credential capture / phishing overlays / CSRF-token theft**.
- **Multi-statement exfil chains** (`;s1;s2;//` — same shape, more room needed).
- **Sibling echoes** sharing the broken escaper (audit the helper, not the page).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Direct quote-breakout (no shift) | NOT APPLICABLE | lone quotes arrive `\'` (containment verified by map) |
| Tag injection / h1 context | NOT APPLICABLE | entities + full encoding + backslash doubling |
| `"`-breakout | NOT APPLICABLE (structural) | inert content inside `'…'` |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |

## NOT TESTED
- Other echo points/params (only `search` mapped).
- `</script>`-closure fallback (unneeded; JS layer yielded directly).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Authenticated app**: crafted link → ATO; script-string echoes in auth flows.
- **Analytics/config echoes** (`var user = '…';`, dataLayer, feature flags).
- **Shared broken escaper** (quote-escape without backslash-first) across templates.
- **Long/POST-echo variants** (payload room; log evasion).
- **Missing HttpOnly** → trivial cookie read.

## Lab-scoped confirmed impact
`alert()` via backslash-shift breakout — accepted first poll.