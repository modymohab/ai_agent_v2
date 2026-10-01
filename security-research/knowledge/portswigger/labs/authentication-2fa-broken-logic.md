# PortSwigger Lab

## Lab

2FA broken logic

URL: https://0adc00e70405d63b80789a4100280054.web-security-academy.net

## Vulnerability Class

Authentication — 2FA verification logic flaw (attacker-influenced identity selects the victim whose short emailed code is then brute-forced; no rate limiting)

## Objective

Access `carlos`'s account page. Attacker resources: `wiener:peter` + wiener's email inbox. Official solution consulted AFTER extensive elimination (stuck provision); every step below re-verified by current evidence.

## Initial Observations

- Blog; `POST /login` (username+password, no CSRF) → valid `wiener:peter` → 302 `/login2` + `verify=wiener` cookie + session; `carlos:montoya` + 4 commons → 200 fail.
- `GET /login2` → 200 form `POST mfa-code` (4-digit); wrong code → 200 re-render; correct emailed code (`0601`, reusable across sessions) → 302 `/my-account?id=wiener`.
- Email client shows only wiener's code; carlos never logs in (hint-confirmed).
- No typo-enumeration oracle here (all `password.<`), timing uniform, `/my-account` → 302 `/login` pre-2FA (no skip), no IDOR (`?id=carlos` as authed wiener → 302 `/login`).

## Hypotheses

- H1: `verify` cookie binds code-check identity; swapping to `carlos` + wiener's code logs in as carlos.
- H2 (after H1 failed cleanly): the code-check identity follows the `verify` REQUEST PARAMETER; issuing (`GET /login2?verify=carlos`) mints carlos a code without his password, then his 4-digit code is brute-forceable (no throttling observed).
- H3: `verify=carlos` + cracked code → 302 `?id=carlos` → account page → solved.

## Attempts

1. Baseline legitimate flows (wiener full login, wrong-code fail) — mapped 302/200 oracles.
2. `verify=carlos` (explicit single Cookie header, no jar contamination) + wiener's code `0601` → 200 fail; control `verify=wiener` + same → 302. Clean single-variable proof H1 false — code binds to cookie identity. (Earlier jar+`--cookie` runs risked DUPLICATE cookies; redone explicitly.)
3. Duplicate-cookie order matrix: `verify=carlos; verify=wiener` → 302 as WIENER; reverse → 200. Last-wins parsing, no bypass — documented, abandoned.
4. Empty/missing code (400/200), missing cookie (500 crash), garbage/SQLi cookie (200), case/pad/truncate codes (200), `username` override param (ignored → wiener), GET-query code, PUT (405), Referer/Origin, seeded passwords, common/null-ish codes (`0000…`, `None`, `null`, `0`, …) as carlos → all fail. Each eliminated with evidence.
5. Throttle probe: 20 rapid carlos guesses → all 200, no block. Brute-force viable.
6. Generation: `GET /login2?verify=carlos` on stage-1 session → 200 (no error) — mints carlos's code server-side (solution-guided, evidence-confirmed by what follows).
7. Threaded brute-force (15 workers) `verify=carlos` × `mfa-code` 0000–9999 → exactly one 302: **`1402`**. H2 confirmed.
8. `verify=carlos` + `1402` → 302 `/my-account?id=carlos` + session → account page 200 `Your username is: carlos`; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Naive cookie swap (H1) — the cookie IS honored for identity; without a minted carlos code there is nothing to match. Lesson: generation must precede guessing.
- Duplicate-cookie tricks — parser takes last value consistently; no confusion.
- ~40 single-shot logic probes (skip/IDOR/override/verb/SQLi/padding/case/null-codes) — all correctly negative; bounded the search and justified the stuck-provision read.
- Contaminated early runs (jar + explicit `--cookie` doubles) — redone with single explicit headers before concluding.

## What Worked

- `GET /login2?verify=carlos` (generate) → brute-force 4-digit `mfa-code` with `verify=carlos` (15 threads, 302-oracle) → `1402` → login as carlos → solved.

## Burp Observations

- Not used via Burp MCP; curl + Python threads replaced Intruder (sniper on `mfa-code`, 302-oracle) minimally. Repeater equivalent for the generation request.

## Browser Observations

- Not required. Email client read via HTTP fetch; all auth over curl.

## CLI / Tool Observations

- curl explicit `-H "Cookie: …"` (never jar+string mixes) for cookie-identity tests; `%{http_code}` oracles (200 fail / 302 hit / 400 validation / 500 crash).
- Python `threading` (15 workers) for 10k code space; full scan completed in minutes with zero throttling.

## Root Cause

Two compounding flaws: (1) the `verify` request parameter lets any stage-1-authenticated attacker mint a 2FA code for an ARBITRARY user (`carlos`) without that user's password; (2) the 4-digit code space has no rate limiting, so the victim's emailed code is brute-forceable. Attacker never needs carlos's password or inbox — wiener's session + `verify=carlos` + guessed `1402` yields carlos's authenticated session.

## Verification

- Generation necessity: pre-generation carlos guesses (≈30 across sessions) all 200; post-generation brute-force hit 302 — same identity, same channel, only code value varies.
- Hit uniqueness: exactly one 302 in 0000–9999; neighboring codes 200.
- Identity proof: 302 `Location: /my-account?id=carlos` + fresh session + account page rendering `carlos` + `/` `is-solved`. Deterministic.

## Impact

Full account takeover of `carlos` (read/update identity, email, act as victim) with only low-priv attacker credentials — 2FA reduced to a 10k unthrottled guess against an attacker-chosen identity.

## Why The Successful Approach Worked

- Stopped forcing H1 after the CLEAN single-header test falsified it (instead of re-running contaminated variants).
- The stuck-provision read supplied the missing primitive (parameter-driven code generation); evidence (post-generation 302) confirmed it rather than assumed it.
- Unthrottled 4-digit space + 302-oracle + threading made exhaustive search cheaper than further theorizing.

## Generalization

- In staged logins, test whether stage-2 identity comes from a REQUEST PARAMETER (query/body/cookie) rather than the stage-1 session — if so, point it at the victim (generation oracle: 200/no-error = minted).
- Missing-code (500) vs wrong-code (200) vs hit (302) is a three-way oracle; map all three before attacking.
- Never mix cookie jars with explicit `Cookie` headers in identity tests — duplicates make results undefined; single explicit headers only.
- 4-digit + no-throttle (verify with a 20-burst first) = brute-forceable; parallelize and match on 302+redirect-target.

## Lessons Learned

- My “cookie-swap fails → binding solid → need carlos's code” reasoning was right but incomplete: the missing step was MINTING his code via the same parameter. Falsified H1 should have prompted “how is victim state created?” sooner.
- Contaminated cookie runs cost an entire investigation branch; methodology now mandates single-header identity tests.
- Brute-force is justified only after (a) throttle probe passes, (b) generation primitive confirmed — not as an opener.

## Related Methodology

- methodology/authentication.md (2FA logic — to be extended)
- methodology/verification.md (single-header isolation + fresh-session proof)

## References

- Lab: https://portswigger.net/web-security/authentication/multi-factor/lab-2fa-broken-logic (solution consulted AFTER elimination of ~40 probes; all findings re-verified by current evidence)
- Solved instance: https://0adc00e70405d63b80789a4100280054.web-security-academy.net/
