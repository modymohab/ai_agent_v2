# Impact — Reflected XSS (HTML text context)

## Applicability-based reasoning

- **Does the input reach a browser-executable context?** YES — the `search`
  value is rendered into HTML element text in the initial document; markup
  executes. → XSS class applicable, CONFIRMED.
- **Does the input reach an XML parser?** NO — output is HTML text, not XML
  parsed server-side. → XXE NOT APPLICABLE.
- **Does the input control a server-side URL/request?** NO. → SSRF NOT APPLICABLE.
- **Does the input reach a filesystem path?** NO. → traversal NOT APPLICABLE.
- **Does the input reach an OS command?** NO. → command injection NOT APPLICABLE.
- **Is this a state-changing action with missing authz/CSRF?** The search is a
  read-only GET. The vulnerability is XSS itself. → CSRF-as-vulnerability
  NOT APPLICABLE; XSS→CSRF chaining is a *use* of the XSS (PLAUSIBLE).

## Confirmed impact

- **Client-side code execution** in the lab origin: attacker-controlled script
  runs in any browser that opens the crafted URL (proven by alert firing in the
  emulated victim and the lab "Solved" flip).

## Impact categories assessed

| Category | Status | Reason |
|---|---|---|
| Client-side code execution | CONFIRMED | alert(1)/(2) executed in-origin |
| Sensitive information exposure | NOT TESTED / NOT APPLICABLE | no sensitive same-origin data to demonstrate on lab |
| Account/session compromise | PLAUSIBLE (NOT TESTED) | session cookie HttpOnly → cookie theft blocked; in-session actions via same-origin fetch remain possible on a real app |
| Unauthorized modification | PLAUSIBLE (NOT TESTED) | XSS can drive same-origin state-changing calls under victim authority |
| Privilege escalation | NOT TESTED | no roles in app |
| Arbitrary file access | NOT APPLICABLE | no file sink |
| Server-side request behavior | NOT APPLICABLE | no URL-fetch sink |
| Deletion/destructive | NOT TESTED | nothing destructive attempted (and no target object) |
| DoS | NOT TESTED | avoid; out of scope for severity claims |

## Real-world impact escalation (read-only search reflection)

1. **Delivery hindrance:** reflected XSS needs the victim to open a crafted URL
   (click/phish/redirect/iframe), lowering reach relative to stored XSS.
2. **From click to compromise:** once executed, the script can:
   - call same-origin APIs/fetch with the victim's cookies (HttpOnly or not) →
     arbitrary authenticated actions (profile change, data export, order ops);
   - steal `document.cookie` ONLY for non-HttpOnly cookies;
   - keylog, screen-scrape, redirect;
   - if the reflected page is used by privileged users (admin search, support
     tools), privilege rises sharply.
3. **Chain combination:** reflected XSS + CSRF-protected endpoints = no real CSRF
   protection matters (same-origin call carries cookies+token); combine with an
   open redirect for delivery.
4. **Mobility:** the same reflection primitive works on every browser; impact
   limited by context (element-text) not by sophistication.

## Boundary crossed (stated precisely)

`attacker-controlled bytes (URL query)` → `server response markup` → `victim
browser same-origin script context`. The crossing point is the server's
missing output-encoding decision. Nothing about the app's authentication was
bypassed (the vuln is not an auth bypass; it is code-injection at the render
layer usable against authenticated sessions).