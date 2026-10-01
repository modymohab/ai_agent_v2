# PortSwigger Lab

## Lab

2FA broken logic (instance `0a17001e034a440080aabc8000820053`)

URL: https://0a17001e034a440080aabc8000820053.web-security-academy.net/

## Vulnerability Class

Authentication — 2FA verification logic flaw (code issuance keyed on attacker-controlled `verify` cookie; session unvalidated at verification; short emailed code brute-forced)

## Objective

Access `carlos`'s account page using only low-priv `wiener:peter` + wiener's inbox. Solved when authenticated homepage flips to `is-solved`.

## Initial Observations

- CURRENT EVIDENCE (Burp): `POST wiener:peter` → 302 `/login2` + `verify=wiener` cookie + session (stage-1 shape as prior instance).
- CURRENT EVIDENCE: `GET /login2` → 200 form `POST mfa-code` (4-digit).
- CURRENT EVIDENCE: wiener's emailed code read from exploit-server inbox (e.g. 1414, then 0102, 0725, ... — codes rotate).
- STORED KNOWLEDGE (prior instance `...280054` → code `1402`): query-mint (`GET /login2?verify=carlos`) then threaded brute-force. Used as hypotheses H1–H4, NOT assumed.

## Hypotheses

- H1: Stage-1 + swap falsification behaves as prior (swap + wiener code → 200).
- H2: `GET /login2?verify=carlos` mints carlos a code; unthrottled 0000–9999 scan finds one 302.
- H3 (formed after H2 failed 3×): issuance may key on the `verify` COOKIE rather than the query — `GET /login2` with `Cookie: verify=carlos` mints carlos's code.
- H4: Session may be unvalidated at verification (test: garbage session + valid code).

## Attempts

1. Baseline via Burp MCP: stage-1 login, `/login2` form, wiener code 1414 from inbox.
2. Swap falsification (single explicit headers): `verify=carlos` + 1414 → 200 `Incorrect security code`. H1 holds.
3. Query-mint + control: `GET /login2?verify=carlos` → 200; `verify=wiener` + fresh code 0102 → 302 (control proves session/code mechanics healthy; codes rotate — 1414 died).
4. Throttle probe: 20 rapid carlos wrongs → all 200, no block. Brute-force viable in principle.
5. THREE full 0000–9999 sweeps (10–20 threads, NoRedir 302 detection, fresh mint + fresh session each) → zero hits. First sweep additionally had a redirect-following bug (302s invisible); fixed for sweeps 2–3. Still zero.
6. Mint forensics via inbox timestamps/counts (CLI): login POST alone mints NOTHING (count 14→14 over 90s); each `GET /login2` mints exactly one code (+1 per GET); verification POSTs mint none. All 14 emails `To: wiener` — carlos's code never visible.
7. Ownership test: code minted by `?verify=carlos` GET (1768) submitted as carlos → 200; as wiener → 302. So query-mint refreshes the SESSION user only — H2's mint mechanism falsified for this instance.
8. Channel test: garbage session (`PLACEHOLDER_SESS8`) + valid 1768 as wiener → 302. Session UNVALIDATED at verification (H4 confirmed). Wrong code + garbage session → 200 (code still checked).
9. Cookie-mint test: `GET /login2` with `Cookie: verify=carlos` → inbox count UNCHANGED (+0, i.e. no wiener email — consistent with invisible carlos issuance). H3 supported.
10. Immediate sessionless brute-force (verify=carlos, static garbage session, 10 threads, 302 + NO-WARNING logging): **`0048`** flagged in 17s (512 tries) → Burp verify `verify=carlos` + 0048 → 302 `Location: /my-account?id=carlos` + fresh session. SOLVED.
11. Verification: `GET /my-account?id=carlos` → 200 `Your username is: carlos` (`is-notsolved` there) → `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Three full sweeps on query-minted sessions (30k+ requests): wrong mint key meant carlos never had a code during those scans. Most expensive failure; caused by copying the prior instance's mint vector instead of verifying issuance per instance.
- Redirect-following bug in sweep 1 (plain `urlopen` follows 302 → hits invisible). Fixed from sweep 2 on.
- 40-thread attempt: server choked (all threads starved, command timed out, buffered output lost). 10–20 threads optimal; `-u` unbuffered logging mandatory.
- Repeated status polling while IP-blocked on the EARLIER timing lab (different lab) — each probe plausibly extended the window; unrelated to this solve but recorded as discipline lesson.
- Browser MCP: lab-domain tab permission never granted by user; browser path unused (pure HTTP flow needed nothing browser-side).

## What Worked

Cookie-keyed mint (`GET /login2` + `Cookie: verify=carlos`) → sessionless brute-force → `0048` → 302 carlos session → identity render → homepage `is-solved`.

## Burp Observations

- Stage-1, swap falsification, generation probes, channel/garbage-session tests, final 302 proof — all via Burp MCP (`burp_send_http1_request`), full request/response evidence. Created Repeater tab `timing-baseline-test` earlier (different lab, untouched here).
- Bulk scans via CLI Python (threading + per-variant cookies), the smaller appropriate toolset; 150+ Burp calls would add nothing.

## Browser Observations

- Tab 101 opened for the lab; content unreadable (permission dialog pending user action). Not required — no JS/state workflow. Browser Control MCP correctly unused beyond the open attempt.

## CLI / Tool Observations

- Python `urllib` NoRedir opener for 302 detection; `threading` 10–20 workers; `re` warning-message oracle (`Incorrect security code` vs NO-WARNING); inbox forensics with `grep`/timestamp tables to attribute mint events (login vs GET vs POST).
- Unbuffered (`-u`) logging essential for killed-scan forensics.

## Root Cause

Two compounding flaws: (1) 2FA code issuance keys on the attacker-controlled `verify` COOKIE — any unauthenticated holder of a low-priv session can mint a victim code (`GET /login2` with `verify=carlos`); the `?verify=` query is ignored for issuance on this instance. (2) Verification checks only (`verify`, code) — session unvalidated (garbage sessions accepted), 4-digit space unthrottled. Attacker mints + guesses (`0048`) → victim session without password or inbox.

## Verification

- Mint attribution: inbox deltas (+0 for carlos-cookie mint vs +1 per wiener-cookie GET; login POST +0 over 90s) isolate issuance triggers.
- Hit: `verify=carlos` + `0048` → 302 + `Set-Cookie: session` + `Location: /my-account?id=carlos` (Burp, static garbage session — session-irrelevance proven simultaneously).
- Identity: account page renders `Your username is: carlos`.
- Solved: authenticated `/` returns `is-solved` (account page alone `is-notsolved` — both checked).

## Impact

Full account takeover of `carlos` with only low-priv credentials — 2FA reduced to a mintable, unthrottled 10k guess with no valid session required at guess time.

## Why The Successful Approach Worked

- Stopped re-running the prior's mint vector after 3 falsifying sweeps and asked "was anything ever minted?" — inbox forensics answered issuance mechanics instead of assuming them.
- Ownership test (fresh code as carlos-then-wiener) killed the query-mint theory in 2 requests.
- Garbage-session accident revealed session-irrelevance, removing session management from the attack (static session scan).

## Generalization

- In staged logins, verify the MINT vector per instance (query vs cookie vs body) using a visible-oracle principal (own inbox delta) before spending brute-force budget — prior-instance vectors do not transfer by assumption.
- Mailbox timestamp/count forensics attributes issuance triggers (login vs form-view vs verify) cheaply and exactly.
- Test session binding with garbage-session + valid-code: 302 proves verification is sessionless, simplifying scans to static headers.
- Log BOTH 302 and warning-absence anomalies in oracle scans; fixed-302-only matching blinds alternative hit shapes.

## Lessons Learned

- Prior-instance recipe (query-mint) cost 30k+ requests here because issuance keyed differently; per-instance mint verification (2 inbox reads) precedes any scan.
- Only-latest-code-valid + silent supersession explains "valid code rejected" mysteries — always use the newest email.
- Threading sweet spot 10–20; 40 chokes this backend; unbuffered logging or results die with the command.

## Related Methodology

- methodology/authentication.md (2FA mint-vector verification + mailbox forensics + session-binding test — new reusable patterns; update justified, applied separately)
- methodology/verification.md (paired ±XFF-style probes adapted to ±identity probes; dual-session proof)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description (objective only; solution not consulted — mint mechanics derived from inbox evidence): https://portswigger.net/web-security/authentication/multi-factor/lab-2fa-broken-logic
- Prior related (hypothesis sources, vectors NOT transferred): knowledge/portswigger/labs/authentication-2fa-broken-logic.md (`...280054` → `1402` via query-mint)
- Solved instance: https://0a17001e034a440080aabc8000820053.web-security-academy.net/ with `verify=carlos` + `0048` (mint: `GET /login2` + `Cookie: verify=carlos`)
