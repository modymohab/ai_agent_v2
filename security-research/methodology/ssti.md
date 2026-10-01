# SSTI Methodology

## Core Concept

Server-side template injection occurs when attacker-controlled input is concatenated into a server-side template and evaluated. The data/template boundary dissolves: probe strings become code. One validated evaluation primitive (`49` from `7*7`) upgrades to RCE via engine-native OS execution (`system()`, namespaces, `exec`).

First shape validated: reflected `message` param → ERB (`<%= %>`) → `system('rm ...')` → file delete → `is-solved`. No auth required.
Second shape validated (code context, stored): profile preference (`POST /my-account/change-blog-post-author-display`) rendered as blog comment author name inside Tornado template executable code → bare Python expression evaluated → `__import__('os').system('rm ...')` → file delete → `is-solved`. Write→read loop (preference + comment view) required.
Third shape validated (authorized editor, documented objects): privileged product-description template editor using Freemarker (`${product.*}`) → math proof via Preview (`${7*7}`→`49`) → documented `?new()` + `freemarker.template.utility.Execute` RCE on Preview render alone (no save needed) → `is-solved`. Non-standard role account per description.
Fourth shape validated (unknown language, documented chain): reflected `message` param → Handlebars/Node.js (500 names `handlebars/compiler/parser.js`, v19.8.1) → logic-less engine needs helper chain (`#with` string games → `string.sub.constructor` → compiled `require('child_process').exec(...)`) → `is-solved` on load. Fuzz-string `${{<%[%'"}}%` or single `{{7*7}}` for fingerprint; then documented chain, not one-liners.
Fifth shape validated (custom object chain, Twig): stored preference evaluated with developer-supplied `user` object → upload-error forensics discloses `setAvatar(path,mime)` + source path → `/etc/passwd` read via avatar endpoint proves file-path primitive → `User.php` source reveals symlink-plant + `gdprDelete()` (`rm(readlink(avatarLink))`) → point at target + invoke delete → `is-solved`. Read→source→delete escalation, one proven rung at a time.

## Security Boundary

Intended: user input = rendered data.
Violated when: `query/body param → template source → engine evaluates` with attacker syntax intact.

## Recognition Patterns

- Reflection points fed by redirects (`/product?...` → `302` → `/?message=...` → `<div>`).
- Profile-preference → display-name flows (preferred name / nickname rendered on posts/comments) – STORED sinks needing write→read loops.
- Privileged template editors (`/product/template?productId=N`, Preview/Save) – editor's own `${...}` syntax is a free engine fingerprint; Preview pane is both oracle AND trigger.
- 500s with template stack traces (`handlebars/.../parser.js`, Node version, `Expecting ID/STRING/NUMBER... got INVALID`) – unknown-language fingerprint; fuzz `${{<%[%'"}}%` deliberately to trigger them.
- Upload/error surfaces adjacent to template sinks (`setAvatar(path,mime)` traces, source paths, arity errors) – API documentation for object-method chains.
- Literal reflection of one engine's syntax (`{{7*7}}` verbatim) alongside evaluation of another's (`<%= 7*7 %>` → `49`).
- `{{49}}`-style artifacts: braces retained around evaluated math = set/dict-literal evaluation inside a code slot – submit WITHOUT braces next.
- 500 pages naming template frameworks (`tornado/template.py`, Python version, `NameError`) – error forensics over retry.
- `true`/output rendering where `system()`-style calls execute (truthy return = ran); `0` exit-status rendering for Python `os.system`.
- Shop/error/message surfaces with no auth gate.

## Common Locations

- `message`, `error`, `search`, `q`, `name`, `comment` params reflected into pages.
- Out-of-stock/error redirects carrying attacker-influenced text (`Location: /?message=...`).
- Product/blog templates rendering user content.
- Preference/display-name settings (`change-blog-post-author-display`) rendered on author lines – post a marker comment to create a readback.

## Indicators

- `{{7*7}}` → literal, `<%= 7*7 %>` → `49` (ERB, Ruby shop) – engine fingerprinted by differential.
- `<%= system('...') %>` → `true` (execution oracle).
- Global `is-solved` after RCE payload (impact oracle).

## Testing Methodology

1. Baseline: normal page + reflection point (`GET /`, empty session OK – SSTI rarely needs auth).
2. Map the sink: follow redirects carrying text (`302 Location: /?message=...`), note reflection container (`<div>`).
3. Syntax matrix, one family per request, stop at first evaluation:
   - `{{7*7}}` – Twig/Jinja family (expect `49` if vulnerable there).
   - `<%= 7*7 %>` – ERB family (Ruby).
   - `${7*7}` – Java EL / Spring family.
   - `7*7` bare – code-context slot (already inside `{{ }}`; expect `49` with NO braces).
   - Literal reflection of a syntax = evidence for the NEXT family, not absence of SSTI.
   - Code-context loop (stored preference → marker comment → author-line readback): classify stored value as literal / `{{49}}`-artifact (set-literal eval – drop braces next) / clean `49` (bare slot mapped) / 500-error (read framework path/version from trace, then match engine).
   - Authorized editor loop: login with description's role account (non-standard creds are normal here) → read editor's embedded syntax as engine fingerprint → Preview `${7*7}` (safe proof) → documented dangerous primitive for that engine (`"freemarker.template.utility.Execute"?new()` + invoke for Freemarker) → Preview RCE first (may suffice – test before saving) → global marker.
   - Unknown-language loop: fuzz string or single `{{7*7}}` → READ the 500 (engine file paths + runtime version + parser expectations) → if Handlebars/logic-less: skip one-liner RCE (string literals render empty – expected, not failure) → documented helper chain (`#with` + `lookup`/`apply` → `constructor` → compiled function) with adapted command → URL-encode fully → marker check on load.
   - Custom object-method loop (Twig + domain object): probe adjacent file features with INVALID input first (upload non-image → method signature + source path from trace) → satisfy the gate minimally (valid file + `image/` MIME) → test path method on `/etc/passwd` (read primitive via serving endpoint) → read app source through the primitive → chain plant (`setAvatar(target,mime)` symlink) + trigger (`gdprDelete()` readlink-unlink) → marker. 500 on destructive renders is normal – check marker, not trigger status.
4. URL-encode template metachars (`<`→`%3C`, `%`→`%25`, `>`→`%3E`) – encoding is load-bearing.
5. RCE in the winning syntax only (`<%= system('rm /home/carlos/morale.txt') %>` for ERB), then check solved/state marker – return-value rendering (`true`) is execution evidence, marker is impact proof.
6. One variable per request (only the probe param changes).

## Verification

- Differential across families at the same sink/position (literal vs `49`).
- Execution via function return rendering (`true`), not reflection alone.
- Impact via global marker (`is-solved`) or victim/state change – fresh anon request, not the trigger session.
- Do not fire RCE chains for an unproven engine – math proof first.

## Common Failure Modes

- Twig-first habit against ERB apps (and vice versa) – firing RCE payloads for the wrong engine; one refuting probe is cheaper than ten assumed exploits.
- Treating literal reflection as “not vulnerable” instead of “wrong family”.
- Assuming standard credentials on role-feature labs – verify Content-Length math → csrf/session binding → account (descriptions define role accounts) → objective source, in that order.
- Treating validated non-sinks (`400 Invalid product ID`) as retry candidates – one-probe ruling, log and move on.
- Forgetting URL-encoding of `<%= %>` (proxies/servers mangle raw `<>%`).
- Reporting `49` (evaluation) as impact – evaluation proves sink, only side-effect/marker proves RCE.
- Treating logic-less string-literal emptiness (`{{"PROBE"}}` → empty div) as failure – expected Handlebars path semantics; pivot to helper chains.
- Hand-building logic-less chains from intuition – documentation provides them; adapt command only.
- Jumping to delete primitives without a read primitive – prove file-path control with `/etc/passwd` + source read first; MIME gates validate labels, not targets (pass `image/jpg` freely).

## Impact Considerations

- Remote code execution as app user (demonstrated file delete; `system()` runs arbitrary commands).
- Real-world extension: reverse shell, exfiltration, config access where the same sink exists.

## Lessons Learned

- From PortSwigger “Basic server-side template injection”: `message={{7*7}}` literal → `message=<%= 7*7 %>` renders `49` → `<%= system('rm /home/carlos/morale.txt') %>` renders `true` → `/` `is-solved`. 5 requests, anon. Engine triage before payload.
- From PortSwigger “Basic SSTI (code context)”: stored preference → comment author `{{49}}`-artifact → 500 names `tornado/template.py` (Python 2.7) → bare `7*7` renders clean `49` → `__import__('os').system('rm ...')` renders `0` → `is-solved`. Slot already inside `{{ }}` – no delimiters; error forensics over retry.
- From PortSwigger “SSTI using documentation”: `content-manager` role (wiener rejected twice – length math then account questioned) → editor shows `${product.*}` (free fingerprint) → Preview `${7*7}`→`49` → `<#assign ex="freemarker.template.utility.Execute"?new()> ${ ex("rm ...") }` on Preview render alone → `is-solved`. Preview is oracle AND trigger; `?new()` docs pattern.
- From PortSwigger “SSTI unknown language + documented exploit”: `message={{7*7}}` → 500 names `handlebars/compiler/parser.js` (Node v19.8.1, `Expecting ID/STRING/NUMBER... got INVALID`); `{{"PROBE"}}` → empty div (logic-less path semantics, expected) → documented @Zombiehelp54 `#with`/`lookup`/`apply`→`constructor` chain with `require('child_process').exec('rm ...')` URL-encoded → `is-solved` on load. Fuzz-then-read-500 for unknown engines; helper chains from docs, not one-liners.
- From PortSwigger “SSTI custom exploit”: stored preference + Twig `user` object; invalid upload discloses `setAvatar(path,mime)` + `/home/carlos/User.php:28`; arity error defines the call shape; `/etc/passwd` via avatar endpoint proves read; `User.php` reveals symlink-plant + `gdprDelete()`; point + invoke → `is-solved`. Read→source→delete, one proven rung at a time; 500 on destructive render is normal.

## Related Concepts

- Injection family (methodology/injection.md – disjoint sinks; SSTI needs its own workflow, hence this file).
- methodology/verification.md (differential + state proof).

## Sources

- PortSwigger lab: Basic server-side template injection (knowledge/portswigger/labs/ssti-basic-erb-rce.md)
- PortSwigger lab: Basic SSTI (code context) (knowledge/portswigger/labs/ssti-code-context-tornado-rce.md)
- PortSwigger lab: SSTI using documentation (knowledge/portswigger/labs/ssti-freemarker-execute-rce.md)
- PortSwigger lab: SSTI unknown language + documented exploit (knowledge/portswigger/labs/ssti-handlebars-documented-rce.md)
- PortSwigger lab: SSTI custom exploit (knowledge/portswigger/labs/ssti-twig-custom-exploit-user-object.md)
