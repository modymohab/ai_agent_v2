# Impact — Reflected XSS into JS string (`<>` encoded)

## Applicability reasoning
The input (`search`) is server-rendered into a single-quoted JS string with the
delimiter unencoded, yielding statement execution in the victim's browser on the
application origin upon crafted-URL visit (parse-time, no interaction). Categories:
**client-side, link-delivered, full-statement** (arbitrary JS between `;` and `//`).
No storage, no state change, no non-JS consumer.

## CONFIRMED
- **Parse-time arbitrary-JS execution at the application origin** on crafted-URL
  visit (title-mutation proof; real `alert(1)` + acceptance). Statement position
  (`;…;//`) admits any JS, multi-statement within URL limits.
- **Clean execution**: `//` neutralizes the template tail; downstream tracker code
  runs normally (no breakage signals for the victim).
- **Per-request delivery, no account/storage/interaction needed**.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as victim).
- **Admin compromise** via crafted search link.
- **Keylogging / credential capture / phishing overlays / CSRF-token theft**.
- **Exfil-rich multi-statement payloads** (`;s1;s2;//` chains).
- **Sibling echoes** on real apps sharing the `<>`-only helper (audit the encoder).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Tag injection (`</script>`, `<img>`) | NOT APPLICABLE (disproven) | `&lt;&gt;` in the script block |
| `"`-breakout | NOT APPLICABLE (structural) | inert content inside `'…'` |
| `\`/newline terminators | NOT APPLICABLE (reasoned) | strand-across-newline throw; no code position |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |

## NOT TESTED
- Other echo points/params on the app (only `search` mapped).
- Backslash-heavy exotic shapes (unneeded — quotes raw; noted for completeness).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Authenticated app**: crafted link → ATO; reflected JS-string XSS is a top-tier
  session-theft primitive (full statements, stealthy render).
- **High-trust echo contexts** (errors, invoices, "welcome <name>" in script configs).
- **Long/POST-echo variants** (bigger exfil payloads; POST bodies evade log review).
- **Shared `<>`-only encoder** across templates → many live echoes from one helper.
- **Missing HttpOnly** → trivial cookie read (here HttpOnly present → in-context
  actions instead; still full impact).

## Lab-scoped confirmed impact
`alert()` via search-term JS-string breakout — accepted first poll.