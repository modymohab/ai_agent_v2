# Impact — CSP policy injection (report-uri token)

## Applicability reasoning
The input (`token`) is interpolated into the enforced CSP header; a `;` splits a
forged `script-src-elem 'unsafe-inline'` directive out of the value, re-permitting
the reflected inline `<script>` in the victim's browser on the application origin
upon crafted-URL visit (parse-time, no interaction). Relevant categories:
**client-side (defense-collapse), link-delivered**. No storage, no state change.

## CONFIRMED
- **Complete CSP neutralization + inline execution at app origin** on crafted-URL
  visit (A/B proof: blocked without token, executes with it; real `alert(1)` +
  acceptance). The policy contributes ZERO residual resistance post-injection —
  impact equals unprotected reflected XSS.
- **Single-character primitive**: one `;` promotes URL data to policy syntax.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Full post-XSS set** (session theft — in-context actions given HttpOnly here —
  ATO, admin, keylogging, phishing, CSRF-token theft) — the bypass RESTORES the
  entire impact surface the CSP was meant to erase.
- **Other forged directives** through the same hole (`form-action` to exfiltrate
  form posts, `frame-src`/`object-src` loosening where not already `none`,
  `base-uri` for relative-URL hijack) — same `;`-split, different directive.
- **Report-endpoint confusion** (the mangled `report-uri` may misroute violation
  reports — defender-visibility impact, untested).
- **Redirected `report-uri` to attacker host**: reasoned NOT viable (first-
  directive-wins: the original precedes any injected one) — listed here as
  considered-and-rejected, not tested.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Execution without the token | NOT APPLICABLE (disproven baseline) | `script-src 'self'` holds |
| `object`/`embed` vectors | NOT APPLICABLE (by policy) | `object-src 'none'` — sound clause, respected |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | header value only |
| Stored/persistent delivery | NOT APPLICABLE | per-request header + echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GETs |

## NOT TESTED
- Non-Chrome engines (`script-src-elem` support is the stated Chrome-only gate).
- Alternate smuggled directives (only `script-src-elem` fired; others reasoned).
- Other params/headers feeding the policy (only `token` mapped).
- `report-uri` token endpoint behavior itself (`/csp-report` unprobed).

## What would increase impact in a real application
- **Authenticated app**: restored XSS → ATO; the CSP was likely the compliance
  control justified as "XSS mitigation" — its collapse voids audits built on it.
- **Report-uri tokens in the wild** (analytics897/correlation IDs echoed into
  policies, `Report-To` JSON with user fields) — the production shape of this sink.
- **Verbose policies with many directives** (more parsing surface; more smuggle
  targets like `form-action`, `frame-ancestors` REMOVAL is impossible via injection —
  injection only ADDS directives, and for most directives multiple instances
  INTERSECT... except `report-uri` first-wins and `script-src-elem` overrides
  `script-src` — directive-combination semantics decide each case; test, don't assume).
- **Missing HttpOnly** → trivial cookie read post-bypass (here HttpOnly present).
- **Long-lived, widely-shared crafted links** (search URLs are eminently shareable).

## Lab-scoped confirmed impact
`alert()` despite CSP — accepted first poll; policy fully bypassed.