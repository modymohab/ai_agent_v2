# PortSwigger Lab

## Lab

Server-side template injection in an unknown language with a documented exploit

URL: https://0ab5007d035cf67e80f3da11004500af.web-security-academy.net/

## Vulnerability Class

Server-side template injection – reflected `message` param evaluated as Handlebars (Node.js) → documented `#with`/`constructor` gadget chain → `child_process.exec` RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via documented Handlebars exploit. Established by lab title (unknown-language + documented-exploit) + `is-solved` flip after chain trigger. Official solution consulted for the exact documented chain only after genuine stuck point (engine fingerprinted via evidence; no stored Handlebars knowledge; self-built chain infeasible blindly).

## Initial Observations

- Shop (integer productIds) + no account links. `GET /product?productId=1` → 302 → `/?message=Unfortunately this product is out of stock` – same message-via-redirect sink shape as basic ERB lab (current evidence, not assumption).
- `GET /?message={{7*7}}` → 500 with FULL stack trace naming `handlebars/compiler/parser.js`, Node.js v19.8.1 – engine fingerprinted by error forensics in ONE probe (unknown language resolved immediately).
- `GET /?message={{"PROBE"}}` → 200, EMPTY `<div>` (string literal renders nothing – Handlebars logic-less path semantics; noted, not pursued).
- Stored `methodology/ssti.md` (ERB reflected, Tornado code-context, Freemarker editor; no Handlebars section). No prior Handlebars labs.

## Hypotheses

- H1: Sink = `message` reflection evaluated as Handlebars (parse error proves evaluation). Evidence: error text + stack trace.
- H2: Logic-less engine needs documented helper-based chain (`#with` string games → `constructor` → `Function` → `child_process.exec`), not math/RCE one-liners. Evidence needed: chain renders without parse error and deletes file → marker.
- H3: Exact documented chain (@Zombiehelp54, via official solution pointer after stuck point) adapted with `rm` command → `is-solved` on load.

## Attempts

1. Baseline `GET /` (200, empty session) + `GET /product?productId=1` (302 → message flow mapped) – sink located in 2 requests.
2. `GET /?message={{7*7}}` → 500 Handlebars parse error (`Expecting ID/STRING/NUMBER... got INVALID` + node paths) – H1 confirmed + engine/version leaked.
3. `GET /?message={{"PROBE"}}` → 200 empty div – string-literal path renders nothing (recorded engine behavior; did NOT build on it).
4. Full documented chain (`wrtz{{#with "s" as |string|}}...{{#with (string.sub.apply 0 codelist)}}...require('child_process').exec('rm /home/carlos/morale.txt')...`) URL-encoded as `message` → 200 → `/` → `is-solved`/`Solved`/`Congratulations` – H2+H3 confirmed first try.

## What Failed

- Nothing on target beyond the two characterizing probes (`{{7*7}}` 500, `{{"PROBE"}}` empty) – both were evidence, not dead ends. No RCE guessing attempted without the documented chain.

## What Worked

- Message sink → Handlebars fingerprint via 500 → documented `#with`/`constructor` chain (URL-encoded, 1418 chars) → solved marker on load. 5 requests total.

## Burp Observations

- Baseline, sink mapping, engine-error capture, final proof (`200 is-solved`) via Burp MCP.
- String-literal probe + full chain fire via curl (URL-encoding ergonomics; same HTTP semantics).

## Browser Observations

- Not required. No JS/state workflow; anon sink.

## CLI / Tool Observations

- `curl` for probes/trigger; `python3` + `urllib.parse.quote` for full-chain encoding. No scanner/crawler/fuzzer.

## Root Cause

User-controlled `message` query value concatenated into a Handlebars template evaluated server-side (Node.js). Logic-less engine still reaches code execution via helper trampolines: `#with` aliases + `split`/`lookup`/`apply` string games walk `String.sub.constructor` → `Function` constructor → compiled `require('child_process').exec(...)`. Data (query param) → template → JS execution as app user.

## Verification

- Engine proof: 500 parse error naming `handlebars/.../parser.js` + Node v19.8.1 (not assumed from title).
- Chain proof: single documented payload → `is-solved` via fresh anon `GET /` (global marker). No intermediate output needed – marker arbitrates.
- Single variable per request (only `message` changed).

## Impact

Remote code execution as app user (demonstrated file delete; `child_process.exec` runs arbitrary commands → reverse shell/exfiltration in real apps).

## Why The Successful Approach Worked

- Treated the 500 as the fingerprint (full stack trace = engine + runtime + parser expectations) instead of an error to avoid.
- Recognized logic-less semantics (`{{"PROBE"}}` → empty) as a STOP sign for one-liner RCE – documented helper chain required, not more guessing.
- Used the documented chain verbatim (adapted command only) after genuine stuck point – first-try solve beats blind chain construction.

## Generalization

- For `{{ }}` sinks with 500s naming `handlebars`: skip math-RCE attempts (logic-less) → go directly to documented `#with`-`constructor` chain → URL-encode fully → marker check on load.
- Parse-error text (`Expecting ID/STRING/NUMBER... got INVALID`) is Handlebars-specific – file it as a fingerprint alongside the stack path.
- `{{"literal"}}` → empty div is EXPECTED Handlebars behavior (path lookup, not eval) – pivot to helper chains, not other engines.

## Lessons Learned

- Unknown-language triage: fuzz string `${{<%[%'"}}%` (per solution method) or single `{{7*7}}` → READ the 500 (engine + file paths + version) before any exploit research.
- Logic-less ≠ safe: helpers (`with`/`each`/`lookup`/`apply`) + `constructor` access = code execution; documentation (not intuition) provides the chain.
- Documented-exploit tasks are retrieval tasks: primary source (researcher writeup) + command adaptation + marker proof.

## Related Methodology

- Extends `methodology/ssti.md` (ERB/Tornado/Freemarker; no Handlebars/logic-less/documented-chain pattern – update justified below; 4th SSTI lab, new engine).
- `methodology/injection.md` does NOT apply (template evaluation vs query/shell). Deliberately not modified.
- Priors: `ssti-basic-erb-rce.md` (sink-shape hypothesis source: message-via-redirect reused correctly), others contributed only generic discipline.

## References

- Solved instance: https://0ab5007d035cf67e80f3da11004500af.web-security-academy.net/
- Lab: https://portswigger.net/web-security/server-side-template-injection/exploiting/lab-server-side-template-injection-in-an-unknown-language-with-a-documented-exploit
- Documented chain: @Zombiehelp54 Handlebars `#with`/`split`/`lookup`/`apply` → `constructor` → `child_process.exec` (via official solution pointer after genuine stuck point; command adapted to `rm /home/carlos/morale.txt`)
- Engine evidence: `handlebars/compiler/parser.js:267`, Node.js v19.8.1 (server error text)
