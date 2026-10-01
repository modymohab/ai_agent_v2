# PortSwigger Lab

## Lab

Broken brute-force protection, IP block

URL: https://0a420042038144d48083adff002a00b0.web-security-academy.net/

## Vulnerability Class

Authentication — broken brute-force protection (IP-based failed-login counter reset by any successful login) → password brute-force → account takeover (carlos)

## Objective

Brute-force victim `carlos`' password from lab-provided candidate list, log in, access account page. Solved when authenticated homepage flips to `is-solved`. Own credentials provided: `wiener:peter`.

## Initial Observations

- CURRENT EVIDENCE: `GET /login` → 200 form (`username`+`password`, no CSRF observed).
- CURRENT EVIDENCE: `POST carlos:wrongtest1` → 200 `Incorrect password` — carlos exists (overt; no enumeration needed, victim given by lab).
- CURRENT EVIDENCE: `POST wiener:peter` → 302 `Location: /my-account?id=wiener` + session — valid-login shape confirmed.
- Counter after 1 fail + 1 success presumed 0. Threshold (3) and reset mechanics at this point STORED/secondhand (lab description), not yet verified.

## Hypotheses

- H1: 3 consecutive failures → temporary IP block; any successful login resets the counter.
- H2: Strictly sequential cycling (2× carlos guesses + 1× wiener:peter) keeps the counter sub-threshold across all 100 passwords; exactly one carlos password returns 302.
- H3: carlos login → identity render → `is-solved` (check account page and `/`).

## Attempts

1. Baseline via Burp MCP: GET /login, 1× carlos fail, 1× wiener success (3 reqs, counter clean).
2. Skipped separate 3-strike threshold proof deliberately: it would cost a block episode for no new information — the bypass run verifies the reset mechanism directly.
3. Main run (CLI Python, single-threaded, 0.4s spacing for deterministic order): for each password pair → 2× `POST carlos:pw` + 1× `POST wiener:peter`, no-redirect opener, 302+Location detection. 100 passwords → 50 pairs + 50 resets (+1 warmup reset).
4. Result: 99× 200, exactly one 302 at pair 26: **`carlos:ranger`** → `Location: /my-account?id=carlos`. All 50 resets returned 302 — zero blocks across ~151 requests. H1+H2 confirmed by evidence.
5. Verification logins: Burp `POST carlos:ranger` → 302 + session + carlos Location (independent session 1); curl `POST carlos:ranger` → 302 + session (session 2) → `GET /my-account?id=carlos` → 200 `Your username is: carlos` (banner still `is-notsolved`) → `GET /` → `is-solved`/`Solved`/`Congratulations`. H3 confirmed.

## What Failed

- No brute-force failures: first 302 hit was the password; no false positives.
- Prior-lab failure mode deliberately avoided: rapid 101-burst scanning (which IP-locked the previous timing lab for 30 min) — here replaced by single-threaded ordered cycling with resets from the start.

## What Worked

2-fail + 1-reset cycling → `carlos:ranger` → session → identity render → homepage `is-solved`.

## Burp Observations

- Baseline, failure shape, valid-login shape, and final carlos 302 proof all captured via Burp MCP (`burp_send_http1_request`) — full request/response evidence.
- Bulk cycling done via CLI, not 150 Burp calls: ordering + session-independence made scripted loop the smaller appropriate toolset (per tool-selection rule). Intruder equivalent: pitchfork, positions `username`+`password`, resource pool max 1 request, wiener/peter aligned before every 2 carlos rows.
- Repeater tab `timing-baseline-test` from prior lab left untouched (different lab).

## Browser Observations

- Not required. Pure HTTP flow, no JS/state workflow. Browser Control MCP correctly not used.

## CLI / Tool Observations

- Python `urllib` with no-redirect handler for 302 detection; `curl` with cookie jar for session proof. Password list from existing `/tmp/auth-passwords.txt` (100, count-checked); lab-specific, not added to repo wordlists.

## Root Cause

IP-based brute-force counter blocks after N consecutive failures but **any successful login (even as a different, low-priv user) resets it to zero**. Attacker with own valid account (`wiener:peter`) interleaves 2 victim guesses with 1 own login, keeping the counter permanently sub-threshold and converting a rate-limited endpoint into an unlimited oracle. Combined with predictable password (`ranger`), this yields full takeover of `carlos`.

## Verification

- Reset proof: 50/50 `wiener:peter` logins during run returned 302; zero block responses across ~151 sequential auth attempts.
- Password proof: single `carlos` 302 + `Set-Cookie: session` + `Location: /my-account?id=carlos` among 100× attempts, reproduced in two independent sessions (Burp + curl).
- Identity proof: `/my-account?id=carlos` 200 renders `Your username is: carlos`.
- Solved proof: authenticated `/` returns `is-solved` (account page alone still `is-notsolved` — both surfaces checked, consistent with prior overt-enumeration instance).

## Impact

Full account takeover of `carlos` (authenticated session, act as victim). Same primitive (reset-oracle + known low-priv account) defeats IP-based throttling wherever success resets global counters.

## Why The Successful Approach Worked

- Order discipline: strictly sequential single-threaded cycling — concurrency would scramble fail/reset order and trigger the block.
- Ratio discipline: 2 guesses per reset keeps consecutive failures at 2 < 3 at all times.
- Reset account validity re-verified mid-run on every cycle (each 302 observed, not assumed).

## Generalization

- For IP/rate counters keyed on consecutive failures: test whether ANY successful authentication resets the counter; if so, interleave attacker-known valid logins below the threshold (2:1 for limit-3) single-threaded.
- Counter state is server-side per IP, not per session — stateless requests suffice; no cookie jar needed during cycling.

## Lessons Learned

- First lab of this family in the KB: no prior IP-block note existed (verified via grep); methodology had throttle/lockout mentions but no bypass recipe.
- Description claims treated as hypotheses until the run's 50/50 resets + zero blocks proved them.
- `Incorrect password` (vs `Invalid username`) confirms victim existence for free — no enumeration phase needed when the victim is given.

## Related Methodology

- methodology/authentication.md (brute-force protection bypass — new reusable pattern; methodology update justified, applied separately)
- methodology/verification.md (302+session proof, dual-surface marker check)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description (objective + credentials + candidate-list URL; solution section present but NOT followed blindly — threshold/reset re-verified by current run): https://portswigger.net/web-security/authentication/password-based/lab-broken-bruteforce-protection-ip-block
- Candidate source (lab-published, `/tmp` only): `auth-lab-passwords` (100)
- Solved instance: https://0a420042038144d48083adff002a00b0.web-security-academy.net/ with `carlos:ranger` (own account `wiener:peter` used only for counter resets)
