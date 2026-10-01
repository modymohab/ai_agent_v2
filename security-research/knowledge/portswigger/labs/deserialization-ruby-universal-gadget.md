# PortSwigger Lab

## Lab

Exploiting Ruby deserialization using a documented gadget chain

URL: https://0a37007c0338e4a684666492007c00f0.web-security-academy.net/

## Vulnerability Class

Deserialization – Ruby `Marshal.load` on unsigned base64 session cookie with universal default-gem gadget chain (`Gem::Requirement→TarReader→TarHeader→BufferedIO→WriteAdapter→RequestSet→Kernel.system`) → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via malicious marshalled session object. Established by lab description objective (documented-exploit task); payload from vakzz universal gadget (hypothesis source – see References), command adapted, execution verified by server trace + solved marker.

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty session, shop (integer productIds) + `/my-account`.
- `POST /login wiener:peter` → 302 + `session=BAhvOglVc2VyBzoOQHVzZXJuYW1lSSILd2llbmVyBjoGRUY6EkBhY2Nlc3NfdG9rZW5JIiVldDR4dWljbXVjejU0end2amZpY2Jnb3d0OGczMWV6NAY7B0YK` → decoded `\x04\x08o:\tUser...@username="wiener" @access_token=...` – Ruby Marshal v4.8 (`BAhv` = `04 08`), first Ruby runtime in this KB (priors: PHP `Tzo0`, Java `rO0A`).
- Stored methodology `methodology/deserialization.md` (read – PHP flag/path, Java CC4, PHP/Java custom gadgets; no Ruby section). No prior Ruby labs. Local Ruby 3.3.8 present with rubygems.
- Genuinely stuck on gadget selection (no Ruby gadget knowledge in repo) → consulted official solution pointer (vakzz universal gadget) + primary source (devcraft.io article) as hypothesis source per stuck-clause.

## Hypotheses

- H1: Session bytes are `Marshal.load`ed unsafely; universal default-gem chain fires on load: `Requirement#marshal_load→TarReader#each→TarHeader.from→BufferedIO#read→LOG→WriteAdapter#<<→RequestSet#resolve→Kernel.system(cmd)`.
- H2: Server Ruby is ≤3.0.2 (gadget patched later; local 3.3 already differs – `WriteAdapter#initialize` arity 1). Evidence needed: server trace naming `net/protocol.rb` + `system` + `sh: reading: not found` first-call artifact.
- H3: Payload = `Marshal.dump([SpecFetcher, Installer, requirement])` (autoload pragmas) → strict-Base64 → URL-encode → session cookie on any authenticated request → `is-solved`.

## Attempts

1. Baseline `GET /` + `POST /login` → Marshal session captured, runtime identified by `BAhv` magic (not assumed from title).
2. Fetched vakzz article (correct date 2021-01-07 after 404 on wrong date; search-resolved) – full chain + final script captured.
3. Adapted script (`/tmp/opencode/ruby_gadget.rb`, outside repo): `CMD` param, `require net/protocol + rubygems/package`, `allocate+instance_variable_set` for `WriteAdapter` (local 3.3 arity compat), `strict_encode64` (newline-free cookies; Ruby `decode64` tolerates either).
4. Local generation smoke test with echo marker → exit 0, 336B Marshal, contains `Gem::RequestSet` (structure proof; local fire impossible – patched 3.3 – NOT treated as success).
5. Real payload `rm /home/carlos/morale.txt` (334B, cmd embedded – verified by decode) → `GET /my-account?id=wiener` as session via curl → `HTTP/2 500`.
6. Trigger body: `sh: 1: reading: not found` + `/usr/lib/ruby/2.7.0/net/protocol.rb:458:in 'system'` – server Ruby 2.7.0 (vulnerable range), chain reached `Kernel.system` (H1+H2 confirmed).
7. Anon `GET /` → `is-solved` ×2 + Burp `GET /` → `is-solved`/`Solved`/`Congratulations` – side-effect proof (H3 confirmed).

## What Failed

- Wrong-date article URL → 404 (resolved via search, not guessing).
- Local `Net::WriteAdapter.new(Kernel, :system)` → arity error on Ruby 3.3 (confirmed patched-range divergence) – fixed with `allocate` + ivar sets; generation decoupled from execution.
- Nothing on target failed; first trigger solved.

## What Worked

- Single malicious Marshal session cookie → 500 trigger with execution trace → global solved marker.

## Burp Observations

- Baseline, login (302 + Marshal session), final proof (`200 is-solved`) via Burp MCP.
- Trigger via curl (449B cookie – CLI pragmatism). Trigger error body carried the decisive trace (Ruby path + version + `system` frame).

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `ruby` 3.3.8 for payload generation (with compat shim); `curl -sk -i` for trigger; `grep` for marker/trace; `python3` for base64/URL round-trip checks. No scanner/crawler/fuzzer.

## Root Cause

Unsafe `Marshal.load` of client-controlled session bytes with default gems loaded. Attacker object graph abuses `marshal_load`/`each`/`read`/`LOG` trampolines to steer a `WriteAdapter` method call into `RequestSet#resolve` with controlled `@git_set`, ending in `Kernel.system(cmd)`. Data (cookie) → object graph → trampoline calls → arbitrary method with controlled arg → RCE. No integrity check, no class allowlist.

## Verification

- Generation proof (local structure) kept separate from execution proof (server trace + marker) – never conflated.
- Server trace proves chain execution on target (`2.7.0`, `system` frame, `sh: reading` artifact of uncontrolled first call).
- Global `is-solved` via anon + Burp – state proof, not status-alone. Single variable (session bytes only).

## Impact

Remote code execution as app user (demonstrated file delete; trace shows `system` sink – any command). Highest impact class in this KB so far.

## Why The Successful Approach Worked

- Identified runtime from bytes (`BAhv`), not title – routed to Ruby gadget research instead of reusing PHP/Java payloads (all inapplicable).
- Used the DOCUMENTED universal chain (default gems only) rather than inventing app-specific gadgets – correct for Rails/plain-Ruby session sink.
- Decoupled generation (local, with version shims) from execution proof (server trace + marker) – patched-local did not block vulnerable-remote.
- Read the trigger error as evidence (`sh: reading` = documented first-call artifact, not failure).

## Generalization

- For `BAhv` (`04 08`) session cookies: login → confirm Marshal → find documented chain matching server Ruby range (≤3.0.2: vakzz universal; newer: Round-Two/Git-S3 variant) → adapt command → strict-Base64 → URL-encode → replay as session → expect 500 + `sh: reading` + `system` frame → check global marker.
- `sh: 1: reading: not found` in trigger response is a SUCCESS indicator for this chain (first uncontrolled call), not an error to fix.
- Local Ruby version ≠ server version: build with `allocate` shims; prove on target.

## Lessons Learned

- New runtime = new research: `BAhv`/`Tzo0`/`rO0A` magic triage first; payloads never cross runtimes, only discipline does.
- Documented-gadget tasks are source tasks: primary article + version-range check, then adapt-test-prove.
- Trigger-error forensics (`net/protocol.rb:458`, Ruby 2.7.0) doubles as version fingerprint + execution proof.

## Related Methodology

- Extends `methodology/deserialization.md` (no Ruby section – update justified below; 6th deserialization lab, first Ruby runtime).
- `methodology/injection.md` does NOT apply (no SQL/query sink). Deliberately not modified.
- Priors: all deserialization notes (unsigned-cookie discipline, 500-trigger oracle, source-driven graphing); none contributed payload bytes.

## References

- Solved instance: https://0a37007c0338e4a684666492007c00f0.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-exploiting-ruby-deserialization-using-a-documented-gadget-chain
- Primary: vakzz “Universal Deserialisation Gadget for Ruby 2.x-3.x” (devcraft.io, 2021-01-07) – chain `Requirement→TarReader→TarHeader→BufferedIO→WriteAdapter→RequestSet→Kernel.system`, `SpecFetcher`/`Installer` autoload pragmas
- Version-range note: patched >3.0.2 (Round-Two article exists); server 2.7.0 confirmed vulnerable-range via trace
- Generator: `/tmp/opencode/ruby_gadget.rb` (work artifact, outside repo)
- Consulted official solution pointer only after genuine stuck point (no Ruby gadget in repo); payload adapted + independently verified.
