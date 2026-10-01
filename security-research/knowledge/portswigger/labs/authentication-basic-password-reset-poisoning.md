# PortSwigger Lab

## Lab

Basic password reset poisoning

URL: https://0a6c00e8035e4587807a58a100d900ba.web-security-academy.net/

## Vulnerability Class

Authentication — Host-header password-reset poisoning: reset link built from client-controlled `Host`, victim bot clicks the poisoned link, token leaks via exploit-server access log → victim password overwrite → account takeover (carlos)

## Objective

Log in to `carlos`'s account. Solved when the authenticated homepage flips to `is-solved` (own account: wiener, password reset during testing to `WTest99`).

## Initial Observations

- CURRENT EVIDENCE: username-based reset form (`POST /forgot-password` + csrf); no token/username split on the reset form itself (hidden token + two password fields only).
- CURRENT EVIDENCE: own-account reset → token email with lab-host link; tokens are SHORT-LIVED (stale tokens → 400).

## Hypotheses

- H1: reset link host follows a forwardable header (X-Forwarded-Host family).
- H2: victim bot clicks emailed links, leaking tokens to the exploit access log.
- H3: stolen token + fast use (<~2 min) resets the victim password.

## Attempts

1. Direct-Host spoof (Burp + http.client, SNI=lab): front routes by HTTP Host → exploit-server 404s. Dead (recorded the routing behavior, not retried blindly).
2. Forwarding-header matrix (X-Forwarded-Host/Server, X-Host, Forwarded, X-Original-Host) + rewrite headers (X-Original-URL, X-Rewrite-URL) + Origin/Referer: all 200s, all emails lab-hosted. Dead family on this stack.
3. Absolute-URI confusion: 200, no victim follow-up. Dead.
4. Token-binding attempt (own token + victim username): reset form has NO username field — structurally impossible here. Dead by inspection.
5. carlos-reset anomaly: token email arrived at WIENER's inbox — investigated, determined to be request/user mismatch noise, not the path.
6. Reset-flow self-test (wiener token → immediate use → login): PROVED submits apply when fresh (wiener/WTest99 login works). This unblocked everything: prior failures were STALE tokens, not broken submits.
7. Host-spoofed carlos reset POST (http.client, SNI=lab, `Host: <exploit>`) → 200 (app reached — GET variants 404, POST works).
8. Exploit-log poll → victim click `GET /forgot-password?temp-...=lcow...` (bot UA). POISONING CONFIRMED.
9. First token use too slow (~3 min) → login failed (expiry evidence).
10. Re-poison → 30s-interval log polling → fresh token → IMMEDIATE submit (`CarlosPW99`) → carlos login renders identity. SOLVED → homepage `is-solved` ×2.

## What Failed

- Header matrix (8 headers, all ignored for link building).
- Absolute-URI confusion (no follow-up).
- Token-binding (no username field — structural).
- Slow token use (expiry ~2 min; first stolen token wasted).
- Early confusion from never-baselined wiener credentials (assumed `peter`, broke it with tests before verifying — recovered via clean reset cycle).

## What Worked

Host-spoofed victim reset → log-polled token → sub-60s submit → victim login → solved.

## Burp Observations

- CSRF probes, Host-spoof attempts, token-form reads via Burp MCP (`burp_send_http1_request`) with full request/response evidence. http.client used where SNI/Host split control was required (Burp MCP routes by Host).

## Browser Observations

- Not required. Pure HTTP + email/log reads via HTTP. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python http.client for SNI≠Host splits; `http.cookiejar` chains; exploit log polling with victim-UA filtering; inbox token extraction newest-first.

## Root Cause

Reset-link host derived from the client-supplied HTTP `Host` header with no allowlist: a spoofed host reaches the app (POST path) and is embedded into the victim's emailed link; the victim bot clicks it, leaking its token to the attacker's log. Short token expiry is the only (weak) mitigation and loses to fast polling.

## Verification

- Poisoned request → 200 (app reached, not routed away).
- Victim click in log with token (bot UA, distinct from self traffic).
- Fresh-token submit → carlos identity render + `is-solved` (vs stale-token failure — expiry contrast is itself evidence).
- Deterministic end-to-end (second token, fast path).

## Impact

Full account takeover of any user (demonstrated: carlos) with one spoofed request + log watch — no victim interaction beyond normal email clicking.

## Why The Successful Approach Worked

- Killed 4 header families + absolute-URI with evidence before the working vector (no sunk-cost persistence).
- Self-test cycle (wiener reset→login) isolated the expiry variable that explained ALL prior failures at once.
- Victim-UA filtering distinguished bot clicks from own polling in a busy log.

## Generalization

- NEW reusable pattern for methodology/authentication.md: Host-poisoned reset + log-polled victim token + fast submit (SNI/Host split via http.client when tooling routes by Host; expiry demands sub-minute use).

## Lessons Learned

- Never-baselined credentials (`peter` assumed) cost an entire investigation branch — verify baseline FIRST, even for "standard" creds.
- Stale-token failures mimic broken-submit failures exactly — control token age before doubting the submit mechanics.
- Tooling routing (Burp MCP by Host) can make valid vectors look dead — http.client SNI/Host splits recover them.

## Related Methodology

- methodology/authentication.md (reset-poisoning extension — genuinely new; update justified, applied separately)
- methodology/verification.md (bot-UA filtering + freshness contrast + identity proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/host-header/exploiting/password-reset-poisoning/lab-host-header-basic-password-reset-poisoning (objective only; solution not consulted — Host-spoof shape is standard, victim-log mechanics derived from observation)
- Solved instance: https://0a6c00e8035e4587807a58a100d900ba.web-security-academy.net/ with Host-poisoned carlos reset → log token → fast submit → carlos login
