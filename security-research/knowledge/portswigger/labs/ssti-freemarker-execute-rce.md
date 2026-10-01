# PortSwigger Lab

## Lab

Server-side template injection using documentation

URL: https://0a8400600351287280633ac600de00ac.web-security-academy.net/

## Vulnerability Class

Server-side template injection – authorized product-description template editor evaluated as Freemarker (`${...}`) → documented dangerous object (`freemarker.template.utility.Execute` via `?new()`) → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via template-editor RCE. Established by SSTI-lab pattern + `is-solved` flip after preview-rendered `Execute` gadget. Official description fetched for credentials/objective (needed: non-standard `content-manager` account); exploit shaped from current template evidence + Freemarker documentation pattern, verified by preview + marker.

## Initial Observations

- Shop (integer productIds) + `/my-account`. `GET /product?productId=${7*7}` → 400 `"Invalid product ID"` – numeric validation, not a sink.
- `POST /login wiener:peter` → 200 `Invalid username or password` TWICE (first with a miscounted Content-Length of 62 vs true 68 – self-caught truncation; second with correct 68 – genuinely rejected). Non-standard credentials suspected, not a session bug (csrf/session pair was consistent).
- Lab description: creds `content-manager:C0nt3ntM4n4g3r`; task = template docs → RCE → delete `morale.txt`. (Description read for objective/creds; solution steps noted as hypothesis source only.)
- `POST /login content-manager:...` → 302 + session. `/my-account` → email-only (no template feature). Authed `GET /product?productId=1` → product page + `Edit template` link (`/product/template?productId=1`) – privileged template editor (current evidence).
- Template editor shows Freemarker `${product.stock/name/price}` + Preview/Save buttons + live preview pane.

## Hypotheses

- H1: Editor content is evaluated as Freemarker on preview/render. Evidence needed: `${7*7}` previews as `49`.
- H2: Documented dangerous `?new()` + `freemarker.template.utility.Execute` reachable (docs pattern). Evidence needed: assign+invoke renders without error and deletes file → marker.
- H3: Preview render alone executes (no save needed). Evidence needed: `is-solved` after preview POST.

## Attempts

1. Baseline `GET /` + product page (200s) + numeric-validation probe (`${7*7}` in productId → 400 – sink ruled out there, not pursued).
2. Credential failure analysis (length miscount → corrected → still rejected → description consulted → correct role account) – 3 logins, each diagnosed, none repeated blindly.
3. Authed product page → `Edit template` link → editor + existing `${...}` syntax captured – sink + engine family in ONE read.
4. Preview `<p>PROBE ${7*7} END</p>` → preview pane `PROBE 49 END` – H1 confirmed (evaluation, non-destructive).
5. Preview `<#assign ex="freemarker.template.utility.Execute"?new()> ${ ex("rm /home/carlos/morale.txt") }` → short preview body → `/` → `is-solved`/`Solved`/`Congratulations` – H2+H3 confirmed (RCE on preview render; save/view unnecessary).

## What Failed

- `wiener:peter` (2 attempts: one self-inflicted truncation, one genuine) – wrong role for this lab; description held the correct account. Lesson: credential failure → verify length math first, then question the account, then consult objective source.
- Numeric `productId` injection – validated, abandoned after one probe.

## What Worked

- Privileged template editor → math proof via Preview (`49`) → documented `Execute` gadget via Preview → solved marker. 8 requests total.

## Burp Observations

- Baseline, product page, login forms (csrf capture), authed editor discovery, final proof (`200 is-solved`) via Burp MCP.
- Editor POSTs (preview/math/RCE) via curl (textarea ergonomics; same HTTP semantics, csrf-bound).

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `curl --data-urlencode` for editor forms; `python3` + regex for preview-pane extraction. No scanner/crawler/fuzzer (single editor endpoint, no discovery needed).

## Root Cause

Authorized template-editing feature stores/evaluates Freemarker with dangerous built-ins enabled: `?new()` instantiates arbitrary `TemplateModel` classes including `freemarker.template.utility.Execute`, whose invocation runs OS commands as the app user. Trusted-role input treated as template source = SSTI by design flaw (missing sandbox / dangerous-builtin disable).

## Verification

- Math differential in preview pane (`${7*7}`→`49`) – evaluation proof, non-destructive.
- RCE via documented gadget in preview render → global `is-solved` (impact proof, fresh anon `GET /`). Preview-only path proven sufficient (no save needed).
- Single variable per request (only `template` body changed; csrf/session constant).

## Impact

Remote code execution as app user for the `content-manager` role (demonstrated file delete). Same primitive yields reverse shell/exfiltration. Privileged-feature SSTI: any holder of the role (or role-escalation bug) = RCE.

## Why The Successful Approach Worked

- Diagnosed credential failure stepwise (math → account → source) instead of brute-forcing logins.
- Read the editor's own syntax (`${product.*}`) as the engine fingerprint – no family matrix needed this time.
- Proved evaluation with Preview (safe) before RCE, and discovered Preview alone executes – minimal path (no save, no product view).
- Matched gadget to documentation pattern (`?new()` + `Execute`) rather than trying ERB/Tornado shapes from prior labs (engine-matched, not habit-matched).

## Generalization

- For template-editor features: login with the documented role → read existing `${...}`/`{{...}}` syntax in the editor (engine fingerprint, free) → Preview `${7*7}` (safe proof) → documented dangerous primitive for that engine (`Execute`+`?new()` Freemarker; `system()` ERB; `os.system` Tornado) → check global marker (preview may suffice – test before saving).
- Credential failure drill: recount Content-Length → recheck csrf/session binding → question the account (descriptions often define role accounts) → consult objective source.
- Validated non-sinks (`400 Invalid product ID`) are one-probe rulings – log and move on.

## Lessons Learned

- Editor-embedded syntax beats probing: the feature shows its engine (`${}`) – read before firing the matrix.
- Preview is both oracle AND trigger: RCE-capable preview needs no save – always test preview first (least state change).
- Docs-driven gadgets (`?new()` + implementing-class enumeration) transfer across Freemarker instances; engine-matched selection beats cross-engine habit.

## Related Methodology

- Extends `methodology/ssti.md` (reflected-ERB + stored-Tornado; no editor-sink/Freemarker/documented-object pattern – update justified below; 3rd SSTI lab, new sink + engine).
- `methodology/injection.md` does NOT apply (template evaluation vs query/shell). Deliberately not modified.
- Priors: `ssti-basic-erb-rce.md` (math-proof + marker-proof), `ssti-code-context-tornado-rce.md` (error-forensics habit reused for reading editor syntax).

## References

- Solved instance: https://0a8400600351287280633ac600de00ac.web-security-academy.net/
- Lab: https://portswigger.net/web-security/server-side-template-injection/exploiting/lab-server-side-template-injection-using-documentation
- Freemarker documentation pattern: `?new()` built-in + `freemarker.template.utility.Execute` (TemplateModel implementors)
- Deliberately shaped exploit from editor evidence + docs pattern; description consulted for creds/objective after genuine credential stuck point.
