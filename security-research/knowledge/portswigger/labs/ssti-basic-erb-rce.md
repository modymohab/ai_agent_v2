# PortSwigger Lab

## Lab

Basic server-side template injection

URL: https://0ac900b004cd869882c86ff800b200c5.web-security-academy.net/

## Vulnerability Class

Server-side template injection (SSTI) – user input (`message` query param) evaluated by server template engine (ERB) → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via template injection. Established by SSTI-lab pattern (prior RCE labs delete `morale.txt`) + `is-solved` flip after `system()` trigger. Official description not fetched; engine and payload derived from probes.

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty session, shop (integer productIds) + no account links (first lab without auth so far).
- `GET /product?productId=1` → 302 to `/?message=Unfortunately this product is out of stock` – `message` param reflected in homepage `<div>`.
- `GET /?message={{7*7}}` → 200, `<div>{{7*7}}` literal – Twig/Jinja syntax NOT evaluated (first hypothesis refuted, not ignored).
- No SSTI methodology exists in repo (`methodology/` has no `ssti.md`; `server-side.md` is a 25-line stub, content not inspected; `injection.md` names SSTI once with zero test content). No prior SSTI labs.

## Hypotheses

- H1: Sink is `message` reflection; engine is not Twig-style. Evidence needed: per-engine math probes render distinct results.
- H2: Engine is ERB (`<%= %>`, Ruby shop). Evidence needed: `<%= 7*7 %>` renders `49`.
- H3: ERB RCE via `<%= system('rm ...') %>` → renders `true` + deletes file → `is-solved`.

## Attempts

1. Baseline `GET /` (200, empty session) + `GET /product?productId=1` (302 → message flow mapped) – sink located in 2 requests.
2. `GET /?message={{7*7}}` → literal reflection – Twig refuted; did NOT escalate to Twig RCE payloads (would have been blind guessing).
3. `GET /?message=<%= 7*7 %>` → 200, `<div>49` – H1+H2 confirmed, engine fingerprinted in ONE probe.
4. `GET /?message=<%= system('rm /home/carlos/morale.txt') %>` → 200, `<div>true` (`system()` returned true = command ran) – H3 supported.
5. Anon `GET /` → `is-solved`/`Solved`/`Congratulations` – side-effect proof.

## What Failed

- `{{7*7}}` (Twig-first habit) – reflected literally. Valuable: ruled out an engine family in one request instead of firing Twig RCE chains blindly.

## What Worked

- ERB math proof (`49`) → ERB `system()` RCE (`true`) → solved marker. 5 requests total.

## Burp Observations

- All HTTP via Burp MCP (baseline, sink mapping, both probes, RCE, proof). URL-encoded `<%= %>` (`%3C%25%3D...%25%3E`) – encoding is load-bearing for `<>%` chars.

## Browser Observations

- Not required. No JS/state workflow; anon requests suffice.

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known param, no discovery needed).

## Root Cause

User-controlled `message` query value concatenated into a server-side ERB template and evaluated. `<%= %>` executes arbitrary Ruby with the app's privileges: math in the probe, `Kernel#system` in the exploit. Data (query param) → code (template) boundary dissolved – classic SSTI.

## Verification

- Engine proof: `{{7*7}}` literal vs `<%= 7*7 %>` → `49` – differential across engine families, same sink/position.
- Execution proof: `system(...)` rendered `true` (truthy return = ran) – stronger than reflection alone.
- Impact proof: global `is-solved` via fresh anon `GET /` – file-delete side-effect, not status-alone. Single variable per request (only `message` changed).

## Impact

Remote code execution as app user (demonstrated file delete; `system()` sink runs arbitrary OS commands → reverse shell/exfiltration in real apps).

## Why The Successful Approach Worked

- Probed engine FAMILY before payload (literal `{{}}` → switch syntax instead of forcing Twig exploits).
- Used math evaluation (`49`) as the cheapest execution oracle before attempting RCE.
- Read the return value (`true` from `system()`) as execution evidence, then confirmed via solved marker.

## Generalization

- For reflected `message`-style params: baseline → `{{7*7}}` (Twig/Jinja family) → `<%= 7*7 %>` (ERB family) → `${7*7}` (Java EL family) – first rendered math wins; only then craft RCE for that engine (`system()`/`exec`/namespace lookups per engine).
- Literal reflection of one syntax is ENGINE evidence (try next family), not absence of SSTI.
- `true`/output rendering of `system()`-style calls is the execution oracle; solved/state marker is the impact proof.

## Lessons Learned

- SSTI triage is a syntax matrix, not a single payload: order probes by likelihood, stop at first evaluation.
- Auth is not required for SSTI – anon sink testing is valid and minimal.
- Engine misidentification is the top failure mode (Twig habit vs ERB reality) – one refuting probe beats ten assumed payloads.

## Related Methodology

- New `methodology/ssti.md` created (no SSTI methodology existed; `injection.md` names SSTI once with zero test content – verified by grep – so the recipe belongs in a dedicated file, not appended to injection).
- `methodology/injection.md` does NOT apply (query/shell sinks vs template evaluation). Deliberately not modified.
- No prior SSTI labs; all prior notes contributed only generic discipline (single-variable, solved-marker proof).

## References

- Solved instance: https://0ac900b004cd869882c86ff800b200c5.web-security-academy.net/
- Lab: https://portswigger.net/web-security/server-side-template-injection/exploiting/lab-server-side-template-injection-basic
- Deliberately did NOT fetch official solution; engine + payload from probes.
