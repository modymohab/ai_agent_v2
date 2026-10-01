# PortSwigger Lab

## Lab

Weak isolation on dual-use endpoint

URL: https://0a0c0044038075be807017b300c8008d.web-security-academy.net

## Vulnerability Class

Business logic — dual-use endpoint with present-vs-absent validation gap (password change enforced only when `current-password` is supplied; dropping it resets anyone's password)

## Objective

Delete user `carlos` (established by evidence: admin panel exposes delete links; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Blog; login `wiener:peter` → 302; account page has change-email + change-password forms.
- Change-password form: `csrf` + EDITABLE `username` (pre-filled wiener) + `current-password` + `new-password-1/2` — target identity is request-controlled (dual-use signal).

## Hypotheses

- H1: The endpoint serves self-change and arbitrary-target change without isolating them; `username` selects the victim.
- H2: The `current-password` check is conditional on the field's presence — omitting it skips verification.
- H3: Take over carlos, then administrator, then admin-delete carlos → solved.

## Attempts

1. `username=carlos` + my `current-password=peter` → 200 `Current password is incorrect` (page re-renders AS carlos — read-side isolation also weak, noted). Check IS evaluated against the named user when present.
2. Self + wrong current → same `incorrect` message (baseline: check works when field present).
3. `username=carlos` + new passwords, `current-password` DROPPED → 200 **`Password changed successfully!`**. H2 confirmed — absent field skips verification.
4. Login `carlos:Hack1234!` → 302 `?id=carlos` (credential valid) — but `/` not solved, `/admin` as carlos → 401. Objective needs administrator; kept climbing instead of stopping.
5. Same drop-field request with `username=administrator` → success message → login → 302 → `GET /admin` → 200 `Users wiener - Delete carlos - Delete`.
6. `GET /admin/delete?username=carlos` → 302; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Supplying MY password for the victim's change (correctly rejected — check binds to named user when present; useful negative defining the exact gap).
- Stopping at carlos-takeover would have missed the objective — solved-marker arbitration again.

## What Worked

- Drop-`current-password` reset for carlos (verify) then administrator (escalate) → admin delete → solved.

## Burp Observations

- Not used via Burp MCP; curl param-drop sufficed. Repeater equivalent for field omission.

## Browser Observations

- Not required. No JS-dependent behavior.

## CLI / Tool Observations

- curl with full vs reduced param sets on one endpoint; message oracles (`Current password is incorrect` vs `Password changed successfully!`); separate jars per taken-over identity.

## Root Cause

The password-change endpoint validates `current-password` only when the parameter is present; omitting it bypasses verification entirely while the request-controlled `username` still selects the target. Any authenticated user resets any account's password (dual-use without isolation between “change own” and “reset another's”).

## Verification

- Present-vs-absent differential on identical bodies: same `username=carlos` + new passwords → `incorrect` WITH field vs `successfully!` WITHOUT — one field explains the bypass.
- Credential validity per victim: 302 + identity-rendered login for carlos AND administrator.
- Chain proof: carlos insufficient (401, unsolved) → administrator panel 200 → delete → victim absent + `is-solved`. Deterministic.

## Impact

Any authenticated user takes over any account including administrator (demonstrated twice) → admin-panel user deletion; full authentication bypass for chosen victims with zero prior knowledge.

## Why The Successful Approach Worked

- Tested the validator's PRESENCE, not just its value (wrong-value vs missing-field are different code paths).
- Escalated through carlos (proof of primitive) to administrator (proof of impact) instead of assuming carlos sufficed.
- Solved-marker arbitration picked the true objective at each rung.

## Generalization

- On dual-use endpoints (self-action + target param), matrix the guard field three ways: correct value, wrong value, ABSENT — absent-skips-check is a recurring flaw shape.
- Takeover chains: prove primitive on low-value victim, then apply to highest-value target; verify each login (302 + identity page).
- 200 + success-message is the mutation oracle; login + role UI + solved marker is the impact proof.

## Lessons Learned

- Editable `username` in account forms is the dual-use tell — immediately test cross-target writes.
- “Check enforced” (wrong→incorrect) does not mean “check unavoidable” — presence-conditional validation is invisible until omission is tested.
- First dual-use lab: guard-presence matrix replaces value-tampering as the core technique.

## Related Methodology

- methodology/business-logic.md (dual-use present-vs-absent validation — to be extended)

## References

- Solved instance: https://0a0c0044038075be807017b300c8008d.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
