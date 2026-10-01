# Impact — Template-literal interpolation breakout

## Applicability reasoning
The input (`search`) is echoed into a backtick literal with six classes escaped but
`${}` intact; the engine evaluates the interpolated expression in the victim's
browser on the application origin upon crafted-URL visit (parse-time, no
interaction). Categories: **client-side, link-delivered, full-expression**
(arbitrary JS inside `${}`). No storage, no state change, no non-JS consumer.

## CONFIRMED
- **Parse-time arbitrary-expression execution at the application origin** on
  crafted-URL visit (title-mutation proof; real `alert(1)` + acceptance).
  `${}` admits any expression (function calls, assignments, nested templates).
- **No breakout/defense interaction**: nothing to terminate, nothing to close —
  the payload is well-formed by construction.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as victim).
- **Admin compromise** via crafted search link.
- **Keylogging / credential capture / phishing overlays / CSRF-token theft**.
- **Nested/chained interpolations** (`${`${…}`}`, multi-expression payloads).
- **Sibling echoes** into literals sharing the escaper (audit the helper).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Quote/backtick breakout | NOT APPLICABLE (disproven) | `\u00XX` sextet |
| `</script>` closure | NOT APPLICABLE (disproven) | no literal `<` survives |
| `\`-shift | NOT APPLICABLE (disproven) | `\u005c` |
| Inner quoted strings | NOT APPLICABLE (structural) | would mangle (quoteless discipline) |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |

## NOT TESTED
- Other echo points/params (only `search` mapped).
- Nested-template and tagged-template shapes (same primitive family).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Authenticated app**: crafted link → ATO; i18n/template strings with user data.
- **SSR state blobs using literals** (Next/Nuxt-style `__DATA__` in backticks with
  user fields — the production shape of this sink).
- **Analytics/telemetry JS** echoing identifiers into literals.
- **Long/POST-echo variants** (payload room; log evasion).
- **Missing HttpOnly** → trivial cookie read.

## Lab-scoped confirmed impact
`alert()` via template-literal interpolation — accepted first poll.