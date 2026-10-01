# Authentication Methodology

## Core Concept

Authentication fails when login responses distinguish valid from invalid usernames (enumeration) or allow unbounded password guessing (brute-force). The difference can be a single byte — e.g. `Invalid username or password.` (period) for unknown users vs `Invalid username or password ` (trailing space) for a real user. It can also be overt — e.g. `Invalid username` vs `Incorrect password` — needing no byte-forensics at all.

## Security Boundary

Intended: login failures reveal nothing about account existence.
Violated when: any response attribute (message bytes, headers, timing, lockout state) varies with username validity, enabling enumerate-then-brute-force → account takeover.

## Recognition Patterns

- Same visible message for all failures — suspect byte-level differences (trailing space, punctuation, NBSP, line endings). NEVER trust normalized/whitespace-collapsed comparisons.
- OVERTLY different messages (`Invalid username` vs `Incorrect password`) — match effort to overtness: exact-message compare suffices, byte-forensics unnecessary (but keep raw bytes anyway).
- Intermittent markup across responses (e.g. random `<!-- -->`) signals multi-backend noise — partition by variant before concluding.
- Seeded creds from other environments failing indicates a different account base; do not anchor on them.
- Staged login (password stage → code stage) where stage-2 identity follows a REQUEST PARAMETER (`verify` query/body/cookie): point it at the victim to mint them a code without their password.
- Staged login with NO stage gate: stage-1 session serves gated pages directly (`GET /my-account?id=<stage-1-user>` → 200 without touching `/login2`) – test the skip FIRST (one request) before any code games; victim stage-1 still needs victim password (often description-given: `carlos:montoya`).
- Password-reset binding: where the reset form carries token + identity as SEPARATE fields (`temp-forgot-password-token` + `username`), the token may validate without binding – mint OWN token, submit with VICTIM username + attacker password, verify by victim LOGIN (302 + session + redirect), not by reset acceptance alone.

## Common Locations

- `POST /login` (`username`+`password`; CSRF may be absent here unlike other labs).
- Provided candidate wordlists (lab-specific; use from /tmp, do not import into repo wordlists without justification).
- Academy candidate lists (`auth-lab-usernames` ~101, `auth-lab-passwords` ~100): parse the `<code class="code-scrollable">` block (meta/body extracts truncate with `...`); count-check completeness before scanning.

## Indicators

- Population scan over a username wordlist with a fixed wrong password: N−1 identical failures + exactly one byte-different message = enumerated user.
- Password scan for that user: all 200 except one 302 (+ session cookie + redirect naming the user) = cracked password.
- Account page rendering the username + `is-solved` marker = proof.

## Indicators

- Population scan over a username wordlist with a fixed wrong password: N−1 identical failures + exactly one byte-different message = enumerated user.
- Password scan for that user: all 200 except one 302 (+ session cookie + redirect naming the user) = cracked password.
- Account page rendering the username + `is-solved` marker = proof. NOTE: marker may flip on authenticated HOMEPAGE visit, not the account page – verify both surfaces.
- Common-name anchoring fails per-instance (`administrator`/`wiener`/`carlos` invalid where `agenda` valid) – population scan beats memory; rule out assumed accounts first.

## Testing Methodology

1. Baseline: invalid login → record RAW failure bytes (no stripping/collapsing; shell `$(...)` destroys trailing whitespace — use Python/xxd).
2. Eliminate oracle families in order: exact bytes → headers → timing (statistics, n≥20, trimmed means) → lockout (≥15 rapid failures) → param edge cases (empty/missing) → backend-version split (partition by intermittent markers).
3. Enumerate: scan the username wordlist with a fixed wrong password, byte-exact message compare → odd-one-out is the user.
4. Brute-force ONLY that user over the password wordlist → 302 + session = password.
5. Login → account page → verify identity render + solved marker. Enumerate-first (~N+M requests) beats cluster bomb (~N×M).
6. 2FA-logic extension: map stage handoff (which parameter carries identity into stage 2 — query/body/cookie?). Test generation (`GET /login2?verify=<victim>` → 200/no-error = minted), then throttle-probe (20 rapid guesses), then exhaustive short-code search on the 302-oracle. NEVER mix cookie jars with explicit `Cookie` headers in identity tests — duplicates are undefined; single explicit headers only. Verify the MINT vector per instance before scanning: mint key may be query, cookie, or body — confirm issuance with a visible oracle (own-inbox email delta: login POST vs form-view GET vs verify-carrying GET each tested in isolation with counts/timestamps) rather than assuming the prior instance's vector. Test session binding with garbage-session + known-valid code: 302 proves verification is sessionless (static headers suffice for scans). Only the newest emailed code stays valid; superseded codes fail.
7. 2FA-skip extension: with a fresh stage-1 session (never visited `/login2`), `GET` a gated page for the stage-1 user directly — 200 full content = missing stage gate (no code needed at all). Then obtain victim stage-1 (description-given creds common in this family; brute-force only after ruling that out) and repeat for the victim identity. Verify-vector matrix (cookie/query/body × valid code) eliminates confusion flaws in 3 requests: ignored = absent vector; 500 = binding breakage, not bypass.
8. Password-reset extension: map the flow (request form → token email → reset form fields) → mint OWN token via own reset request → read the reset form for separate token/identity fields → POST own token + VICTIM username + attacker password → verify by VICTIM LOGIN (302 + `Set-Cookie` + redirect naming victim), never by reset acceptance alone → identity render → homepage marker check (not just account page).
13. Reset-poisoning extension: test whether the emailed link host follows client headers — Host spoof first (SNI must stay on the lab or front-routing eats it; use http.client SNI/Host splits when tooling routes by Host), then forwarding-header matrix (each verified via own-inbox link inspection). For victim tokens: spoofed reset for the victim → poll the exploit ACCESS LOG (not email) for bot clicks (filter victim UA from self traffic) → transplant the token into a genuine reset URL → submit + login within ~60s (tokens expire in minutes; stale failures mimic broken submits — control age first). Verify baseline credentials BEFORE testing (never assume seeded passwords).
7. If all families eliminate with evidence, use the stuck provision (read writeup), then re-verify every claim by current evidence.
9. Brute-force-protection-bypass extension: if failures are counter-gated (e.g. IP block after N consecutive failures), test whether ANY successful login (even as a different low-priv user) resets the counter — one fail-batch plus one known-valid login, then re-probe. If reset is confirmed, cycle (N-1) victim guesses + 1 valid login, strictly single-threaded to preserve fail/reset order, until the password list is exhausted. Counter state is per-IP, not per-session, so stateless requests suffice; 302 + session + redirect naming the victim remains the password oracle. Caveat: if the counter honors a client-controlled IP header (`X-Forwarded-For`), rotating it per request partitions the counter — test with ONE paired probe (same creds ± XFF: block message vs normal message) rather than polling the block.
10. Timing-enumeration extension: when messages/headers are identical, amplify before measuring — use a LONG password (~128 chars) so the server's hash work (done only for valid users) dominates noise. Rank median-of-3 delays across the username wordlist (unique XFF per request where counters apply, light spacing), then confirm the single outlier with 6 samples plus 2 controls. Short passwords show no delta; single samples are not evidence.
11. Persistent-login-token extension: when a `stay-logged-in`/`remember-me` cookie exists, decode it first (base64/hex), identify the hash (length/charset), and recompute against a KNOWN credential to confirm the construction before touching the victim. If the token is an unsigned deterministic function of public values (e.g. `base64(username:md5(password))`), forge offline per password wordlist and test with read-only requests matching on identity render — never brute-force the login form when the token is self-validating. GET-only scans avoid failed-login counters entirely.
12. Symmetric-cookie-oracle extension: when an encrypted session/token cookie coexists with an error path that encrypts attacker input into a cookie AND decrypts cookie values into displayed messages, treat the pair as encrypt/decrypt oracles — capture Set-Cookie values with redirects DISABLED (followers silently eat them). Learn the format by decrypting own token (`username:timestamp` shape); forge with block-aligned padding (pad attacker prefix so the removable prefix is a multiple of 16); verify every forgery by decryption BEFORE use; authenticate sessionless (drop the session cookie) to prove token sufficiency.

## Verification

- Oracle determinism: re-request the odd-one-out; message difference must reproduce byte-exact.
- Password proof is the 302 + `Set-Cookie: session` + redirect target naming the user — not a body change.
- Identity proof is the account page rendering the username; solved marker confirms.

## Common Failure Modes

- Normalizing responses before comparing (strip/collapse/`$(...)`) — destroys single-byte oracles; produces false “identical” conclusions.
- Comparing assumed-valid vs invalid without a KNOWN-valid reference — switch to whole-wordlist population scan.
- Chasing intermittent markup/timing jitter as signal — quantify rates across names; abandon when uniform.
- Anchoring on other labs' seeded creds or payloads.
- Contaminated identity tests (jar + explicit `Cookie` doubles) — conclusions undefined until redone with single headers.
- Falsified swap ≠ dead end: ask how victim-side state (code issuance) is created — generation precedes guessing.

## Impact Considerations

- Account takeover of the enumerated user; stepping stone to privilege escalation if the account is administrative.
- Do not claim compromise without authenticated session + identity render (per skill authentication reference).

## Lessons Learned

- From PortSwigger “Username enumeration via subtly different responses”: 101-username scan → only `americas` returned `…password ` (space); 100-password scan → only `moon` returned 302; login → `/my-account?id=americas` 200 + `is-solved`. Normalized diffs, 20-sample timing, 15× lockout, headers, seeded creds all eliminated with evidence first.
- From PortSwigger “Username enumeration via different responses”: 101-username scan → only `agenda` returned `Incorrect password` (100× `Invalid username`, incl. administrator); 100-password scan → only `princess` returned 302; login → identity render + `is-solved` on authenticated homepage visit (account page alone still showed `is-notsolved`). Overt oracle: exact-message compare, no forensics; 201 requests total.
- From PortSwigger “2FA broken logic”: `verify` parameter mints victim codes — `GET /login2?verify=carlos` → 200, then threaded 0000–9999 with `verify=carlos` → exactly one 302 (`1402`) → `/my-account?id=carlos` + `is-solved`. Naive cookie swap fails (code binds to parameter identity; generation must precede guessing); duplicate-cookie order is last-wins (no bypass); no throttle (20-burst clean).
- From PortSwigger “2FA broken logic” second instance: query-mint refreshed only the session user (fresh code worked as wiener, never as carlos; 3 full sweeps empty) — cookie-keyed mint (`GET /login2` + `Cookie: verify=carlos`, inbox delta +0 for wiener) then sessionless brute-force → `0048` → 302. Verification ignores session entirely (garbage session + valid code → 302). Per-instance mint verification via mailbox forensics precedes any scan; log 302 AND warning-absence anomalies.
- From PortSwigger “Brute-forcing a stay-logged-in cookie”: cookie decoded to `wiener:md5(peter)` (recomputed match) → forged `carlos:md5(pw)` per 100-list → single identity render (`george`) → `is-solved` on the proof request. GET-only scan: zero failed logins, zero counters. Unsigned deterministic tokens are eternal forgery primitives (expiry year 3000).
- From PortSwigger “2FA simple bypass”: fresh wiener stage-1 session → `GET /my-account?id=wiener` 200 WITHOUT visiting `/login2` (no gate); `?id=carlos` on same session → 302 (ownership enforced, stage not); `verify` cookie/query ignored, body breaks binding (500) — no confusion vector; 100-password carlos scan all-200 (given-creds family); description creds `carlos:montoya` → stage-1 → victim page 200 + `/` `is-solved`. Skip-first beats code games.
- From PortSwigger “Password reset broken logic”: own reset mints token (email link `/forgot-password?temp-forgot-password-token=...`); reset form splits token + `username` (hidden, attacker-editable) → POST own token + `username=carlos` + attacker password → 302 → victim login 302 + session + redirect → identity render + `/` `is-solved`. Token validity ≠ token binding; reset-302 proves acceptance, login-302 proves effect.
- From PortSwigger “Broken brute-force protection, IP block”: 3-strike IP counter reset by ANY successful login — cycled 2× `carlos` guesses + 1× `wiener:peter` single-threaded over 100 passwords (50/50 resets 302, zero blocks) → single carlos 302 (`ranger`) → identity render + `/` `is-solved`. Keep consecutive failures below threshold; concurrency scrambles fail/reset order.
- From PortSwigger “Username enumeration via response timing”: 128-char password timing oracle — 100 users at 0.276–0.366s vs exactly one outlier `apache` 0.918s (confirmed 6-sample median 0.877s vs controls 0.288s) → password scan → single 302 (`dragon`) → identity render + `/` `is-solved`. Same lab family honors `X-Forwarded-For`: one paired probe (±XFF) proved counter partitioning, enabling unique-XFF-per-request operation with zero blocks. Never poll a block to check expiry — silence or identity-switch instead; rapid message-scan habits do not transfer to rate-defended logins.
- From PortSwigger “Authentication bypass via encryption oracle”: ECB cookie (block-1 constant across logins) + comment error path that encrypts email into `notification` and decrypts it for display — decrypt own cookie → `username:timestamp` → encrypt `9×pad+administrator:<ts>`, excise 32 prefix bytes (23+9), decrypt-verify → sessionless admin login → delete carlos → `is-solved`. NoRedirect capture mandatory (followers eat Set-Cookie oracles); verify forgeries by decryption before use.
- From PortSwigger “Basic password reset poisoning”: forwarding-header matrix all ignored + absolute-URI no follow-up + no username field (binding structurally impossible) — Host-spoofed victim reset (SNI/Host split) → victim bot click in access log → fresh-token fast submit → carlos identity + `/` `is-solved`. Tokens expire in ~2 min (stale failures mimic broken submits); baseline credentials verified first (assumed `peter` cost a branch).

## Related Concepts

- Brute-force attacks (enumerate-then-guess vs cluster bomb economics)
- methodology/verification.md (raw-byte differential + fresh-session proof)
- SQLi login-bypass lab (credential-form CSRF+session binding, session-state verification — contrasting form shape)

## Sources

- PortSwigger lab: Username enumeration via subtly different responses (knowledge/portswigger/labs/authentication-username-enumeration-subtle-responses.md)
- PortSwigger lab: Username enumeration via different responses (knowledge/portswigger/labs/authentication-username-enumeration-different-responses.md)
- PortSwigger lab: 2FA broken logic (knowledge/portswigger/labs/authentication-2fa-broken-logic.md)
- PortSwigger lab: 2FA broken logic, cookie-mint instance (knowledge/portswigger/labs/authentication-2fa-broken-logic-0a17001e.md)
- PortSwigger lab: Brute-forcing a stay-logged-in cookie (knowledge/portswigger/labs/authentication-bruteforcing-stay-logged-in-cookie.md)
- PortSwigger lab: 2FA simple bypass (knowledge/portswigger/labs/authentication-2fa-simple-bypass.md)
- PortSwigger lab: Password reset broken logic (knowledge/portswigger/labs/authentication-password-reset-broken-logic.md)
- PortSwigger lab: Broken brute-force protection, IP block (knowledge/portswigger/labs/authentication-broken-bruteforce-protection-ip-block.md)
- PortSwigger lab: Username enumeration via response timing (knowledge/portswigger/labs/authentication-username-enumeration-response-timing.md)
- PortSwigger lab: Authentication bypass via encryption oracle (knowledge/portswigger/labs/authentication-bypass-encryption-oracle.md)
- PortSwigger lab: Basic password reset poisoning (knowledge/portswigger/labs/authentication-basic-password-reset-poisoning.md)
