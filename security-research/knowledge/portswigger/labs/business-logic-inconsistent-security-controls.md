# PortSwigger Lab

## Lab

Inconsistent security controls

URL: https://0a6c00e6040e481380b22172008500df.web-security-academy.net

## Vulnerability Class

Business logic — inconsistent validation between parallel endpoints (registration verifies email + gates role on domain; profile email-change applies domain role with no verification)

## Objective

Delete user `carlos` (established by evidence: admin panel exposes delete links; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Shop + `/register` (username/email/password + csrf) with hint: “If you work for DontWannaCry, please use your @dontwannacry.com email address” — domain-gated role signal.
- Registration is VERIFIED: POST → 200 “Please check your emails for your account registration link”; emailed `temp-registration-token` link activates; only then does login 302. Attacker inbox `attacker@exploit-…` receives mail.
- `POST /my-account/change-email` (csrf) exists on account pages.

## Hypotheses

- H1: Registration and email-change enforce different rules — change-email skips verification and still triggers domain-based role assignment.
- H2: Changing a normal account's email to `@dontwannacry.com` grants the employee/admin role (Admin panel link appears).
- H3: Admin panel permits deleting carlos → solved.

## Attempts

1. Registered with unreachable email (`@evil.com`) → verification-required state (login 200-fail, not 302). Baseline: registration gate works.
2. Re-registered with attacker inbox address → token email → visited link → login 302 → active account. Legitimate baseline E2E.
3. `POST /my-account/change-email` → `rat@dontwannacry.com` → 302, NO verification email/step; account page immediately shows new email AND a new **Admin panel** link. H1+H2 confirmed — the inconsistency.
4. `GET /admin` → 200 `Users wiener - Delete carlos - Delete <me> - Delete`, still `is-notsolved`.
5. `GET /admin/delete?username=carlos` → 302; panel `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; the unreachable-email registration usefully proved the registration-side control before the change-email side violated it (paired-endpoint differential).

## What Worked

- Legitimate verified registration → unverified domain-email change → role upgrade → admin delete → solved.

## Burp Observations

- Not used via Burp MCP; curl sufficed. Repeater equivalent for the change-email POST.

## Browser Observations

- Not required. Email client read via HTTP fetch; all flows curl-reproducible.

## CLI / Tool Observations

- curl session jar across register→verify→login→change→admin→delete (csrf+session binding preserved per form); inbox fetch for token; account HTML as email+role oracle.

## Root Cause

Two endpoints implement the same domain-based trust with different controls: registration requires mailbox proof (token link) before the address — and its role — take effect, while profile email-change applies the new address AND its domain role immediately with no verification. Attacker registers honestly, then self-assigns the privileged domain and inherits its admin panel.

## Verification

- Paired-endpoint differential on one account: register-with-unverified-address (inactive, login fails) vs change-to-unverified-address (active immediately + role). Same address class, opposite enforcement.
- Role proof: Admin panel link absent before change, present + 200 with user table after; no other variable changed.
- Impact proof: `User deleted successfully!` + carlos absent + `/` `is-solved`. Deterministic.

## Impact

Any self-registered user self-promotes to administrator (demonstrated) and deletes arbitrary accounts — full admin compromise from a standard account, no mailbox proof required.

## Why The Successful Approach Worked

- Read the domain hint as a ROLE rule, then tested BOTH endpoints that write email state instead of attacking one.
- Established the verified-registration baseline first, making the change-email gap a clean one-variable inconsistency.
- Solved-state attribution: only the email change separates normal account from admin panel.

## Generalization

- For every validated write path (register, update, reset, invite), test its PARALLEL writers with identical hostile input: verified-vs-unverified, admin-vs-self, create-vs-update. Divergence is the flaw class.
- Role-implying domains/flags (`@…`, `role=`, `isEmployee`) are first-class test values on EVERY writer, not just the obvious one.
- Prove inconsistency with paired same-input/different-endpoint evidence, then exploit the weaker writer and confirm via role UI + solved marker.

## Lessons Learned

- Hints about privileged domains name the ROLE rule — immediately map all writers of that attribute.
- Verification emails prove nothing about sibling endpoints; the token flow's existence made the missing check findable by contrast.
- First inconsistent-controls lab: parallel-endpoint differential replaces single-endpoint tampering as the core technique.

## Related Methodology

- methodology/business-logic.md (inconsistent parallel validation — to be extended)

## References

- Solved instance: https://0a6c00e6040e481380b22172008500df.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
