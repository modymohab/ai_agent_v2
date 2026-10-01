# PortSwigger Lab

## Lab

Inconsistent security controls (instance `0aa100c3037db47a81eb9d8000ed00b9`)

URL: https://0aa100c3037db47a81eb9d8000ed00b9.web-security-academy.net/

## Vulnerability Class

Business logic — registration verifies mailbox before role effect, but profile email-change to a privileged domain applies immediately with no verification → administrator → user deletion

## Objective

Access the admin panel and delete `carlos`. Solved when the panel flips to `is-solved` with carlos absent.

## Initial Observations

- CURRENT EVIDENCE: `/register` (username/email/password + csrf) + `@dontwannacry.com` employee hint — byte-identical shape to the prior instance.
- CURRENT EVIDENCE: seeded `wiener:peter` REJECTED (`Invalid username or password.`, jar-correct flow, twice). Per methodology, different account base — no seeded account on this instance; registration path required instead.

## Hypotheses

- H1: self-registered account (exploit-server email + token verification) can change email to `@dontwannacry.com` with no verification.
- H2: changed identity gains Admin panel → delete carlos → `is-solved`.

## Attempts

1. `wiener:peter` login ×2 → invalid (seeded-creds anchoring falsified immediately; switched to registration instead of guessing further).
2. Register `attackerx1` + exploit-server email → "registration link" message → inbox token → `GET /register?temp-registration-token=...` → login → `Your username is: attackerx1`. Verified account.
3. `POST /my-account/change-email` (`attackerx1@dontwannacry.com`, csrf-bound) → account page gains Admin link; `GET /admin` → 200 roster (wiener, carlos, attackerx1). H1 CONFIRMED.
4. `GET /admin/delete?username=carlos` → re-read `/admin` → `is-solved` ×2, roster (wiener, attackerx1), carlos gone. H2 CONFIRMED. SOLVED.

## What Failed

- Seeded-credential anchoring (2 attempts) — stopped after evidence instead of guessing; the lab's intended path is registration (confirmed by description research + email-client flow).
- One scripting bug (tuple unpack in helper) — fixed, no conclusion drawn from it.

## What Worked

Register → verify → login → unverified privileged-domain email change → admin → delete → solved.

## Burp Observations

- Structure probes via Burp MCP (register/login forms, session-cookie leak shape). Multi-step jar flows via CLI (registration→verification→login→change→admin→delete continuity).

## Browser Observations

- Not required. Pure HTTP + email-client reads via HTTP. Browser Control MCP correctly unused.

## CLI / Tool Observations

- Python `http.cookiejar` single-session chains; exploit-server inbox parsing (table rows, token extraction); regex oracles on identity/roster/marker.

## Root Cause

Role-implying attribute (email domain) written by two endpoints with different verification: registration gates role on mailbox-token proof; profile email-change applies it instantly with none.

## Verification

- Paired evidence: registered (verified) address vs changed (unverified) privileged address on the same account — divergence proves the inconsistency.
- Admin roster + `is-solved` + victim absence. Victim state change confirmed.

## Impact

Any self-registered user becomes administrator (roster + deletion demonstrated on carlos).

## Why The Successful Approach Worked

- Quit seeded creds after 2 failures (evidence: invalid message ×2 with correct binding) and sourced the lab-published registration flow instead — same economics as Academy-list sourcing in enumeration labs.
- Paired same-input/different-endpoint reasoning from methodology variant 3 applied without re-derivation.

## Generalization

NONE new — identical variant to the existing note (only the account source differs: self-registered here vs seeded there; the vulnerable transition is the same).

## Lessons Learned

- Instance confirmation only: seeded accounts are per-instance — verify, never anchor. Registration+verification flow worked first try when treated as the primary path.

## Related Methodology

- methodology/business-logic.md (variant 3 — fully applies; NO update justified)
- methodology/verification.md (paired proof + marker + victim absence)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description research (objective + registration/email-client flow; solution steps used as hypothesis source after seeded-cred falsification)
- Prior same-slug instance: knowledge/portswigger/labs/business-logic-inconsistent-security-controls.md
- Solved instance: https://0aa100c3037db47a81eb9d8000ed00b9.web-security-academy.net/ with self-registered `attackerx1` → `attackerx1@dontwannacry.com` → delete carlos
