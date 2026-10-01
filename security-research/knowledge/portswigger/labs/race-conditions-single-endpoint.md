# PortSwigger Lab

## Lab

Single-endpoint race conditions — https://0a1a003e036f684981a87bd900fc0060.web-security-academy.net/ (PortSwigger Web Security Academy, Race conditions). Creds wiener:peter (email initially wiener@exploit-domain). Invite pending for carlos@ginandjuice.shop → whoever claims it inherits admin.

## Vulnerability Class

Race condition on a single endpoint: email-send task vs DB-read template render (`POST /my-account/change-email`). NOT injection.

## Objective

Claim carlos@ginandjuice.shop via raced confirmation → admin panel → delete carlos.

## Initial Observations

- Account page: email display + change-email form only (no password/reset endpoints; /forgot-password etc. 404).
- Baseline change to probe1@exploit-domain → 302 → confirmation email with token link → click → address updated (normal flow proven).
- Only one pending address stored (edit-not-append per design docs; verified implicitly by race outcome).

## Hypotheses

- H1: send-task addressed from request input while template renders pending address from DB — a parallel swap mid-window misdirects the token email (To: mine, body: victim's).
- H2: winning email = To my address + body naming carlos@ + live token; clicking binds victim address to my session.

## Attempts

1. Baseline single change + confirm (probe1@) — normal flow, address updated.
2. Barrier-paired POSTs [r1@exploit-domain + carlos@ginandjuice.shop] round 1 → inbox: email To r1@ with body "confirm your email change to carlos@ginandjuice.shop" + fresh token. Hit first try.
3. Clicked token → `Your email is: carlos@ginandjuice.shop` + Admin panel link → `GET /admin` 200 → `GET /admin/delete?username=carlos` 302 → re-read `is-solved` ×2 + `User deleted successfully!`.

## What Failed

Nothing material; no reset loop needed. (Adjacent caution from file-upload lessons — stale csrf variables — avoided by explicit re-read.)

## What Worked

Two-thread barrier on one endpoint with distinct values; inbox adjudication (To-mine + body-victim); token click; admin delete.

## Burp Observations

Not used (curl + threads sufficed; Repeater parallel group is the GUI equivalent).

## Browser Observations

Mapping only (homepage, banner links).

## CLI / Tool Observations

- curl jars; csrf re-read per phase (change-email csrf stable within session here).
- Exploit-server `/email` inbox as the oracle (recipient vs body mismatch is the signal).
- Thread barrier (2 parties) adequate — no h2 needed for a 2-request window.

## Root Cause

Change-email stores a single pending address (overwrite) while confirmation sending is split-phase: envelope recipient resolved from the request input, template body from a later DB read. A concurrent second change swaps the DB value between the two phases, so the token for the victim address is delivered to the attacker's inbox.

## Verification

- Misdirected email: To r1@(mine) + body carlos@ + fresh token (vs baseline To==body).
- Click → account renders victim address + Admin panel link (privilege proof, not just text).
- Delete 302 → re-read `is-solved` + success string + carlos absent.

## Impact

Arbitrary email claim → admin inheritance (demonstrated) → victim deletion; same primitive hijacks any invite-gated identity.

## Why The Successful Approach Worked

Raced the two phases of one endpoint against each other with values that make the mix-up observable (own inbox vs foreign address), then used the attacker's own receipt as the oracle — no blind guessing.

## Generalization

Wherever a single endpoint both triggers a message and renders it from re-read state (email/SMS/push confirmations, receipts): pair self-address + victim-value concurrently; adjudicate on recipient/body mismatch in the attacker-visible channel.

## Lessons Learned

- Single-endpoint races need only 2 threads + a barrier — don't over-build (h2 reserved for wide gates like 30-password bursts).
- Make the two raced values distinguishable in YOUR observable channel (own inbox), not the victim's.
- Inbox polling replaces response reading for async sends; token from the mismatched email is live — click promptly.

## Related Methodology

- methodology/race-conditions.md (fourth pattern added below: single-endpoint send/render split)
- methodology/verification.md (To/body mismatch oracle, privilege + state proof)
- methodology/injection.md — compared, NOT applicable (no interpreter; phase-ordering flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/race-conditions/lab-race-conditions-single-endpoint
