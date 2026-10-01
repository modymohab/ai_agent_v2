# PortSwigger Lab

## Lab

Scanning non-standard data structures

URL: https://0ac8006103d46c3982619c5600750007.web-security-academy.net/

## Vulnerability Class

Stored XSS in the username half of a colon-split session cookie (`user:token`), exploited blindly — victim-side `fetch` performs the state change, no exfiltration receiver needed → admin deletes carlos

## Objective

Delete user `carlos`. Solved when the homepage flips to `is-solved` (solution text provided by user mid-session; insertion-point idea attributed to it, all verification below is current evidence).

## Initial Observations

- CURRENT EVIDENCE: `POST /login` without csrf → 400 `Missing parameter 'csrf'` — and the 400's own `Set-Cookie: session=%3a<token>` leaks the structure (EMPTY username + token).
- CURRENT EVIDENCE: CSRF-bound `POST wiener:peter` → 302 + `session=wiener%3a<token>` — colon-split `user:token` confirmed.
- CURRENT EVIDENCE: unmodified cookie → 200 + `Your username is: wiener`; tampered username (`PROBEUSER123:TOKEN`) → 500 `Integrity violation detected` — token binds username, tampering fails closed for the attacker.

## Hypotheses

- H1: Tampered-cookie requests still STORE the username part server-side (error page ≠ no storage) — supported by the official scanner finding (collaborator interaction from a stored payload).
- H2: Without any exfil receiver, a stored `<script>fetch('/admin/delete?username=carlos')</script>` executes in the ADMIN's session when viewed → victim-side deletion, no cookie theft needed.

## Attempts

1. CSRF-bound baseline login (Burp) → session structure + identity render.
2. Benign tamper probe → 500 integrity violation (recorded the closed-for-attacker behavior; did not stop — H1 distinguishes storage from session validity).
3. No exploit server exists on this lab; webhook.site provisioning returned garbage (blocked) — abandoned receivers entirely (H2 needs none).
4. Stored blind payload (Burp, cookie username part, own token preserved): `<script>fetch('/admin/delete?username=carlos')</script>` → 500 (expected — storage, not session use).
5. Waited 120s → `GET /` → `is-solved` ×2 (was `is-notsolved`). SOLVED.
6. Rigor check: `carlos:montoya` login → `Invalid username or password.` — INCONCLUSIVE (password unknown; generic message either way). Recorded honestly; the flipped solved marker is the authoritative proof.

## What Failed

- Receiver provisioning (webhook.site garbage response) — rendered moot by the blind-action design.
- Direct tampered-session use (500 integrity) — expected; the attack never uses the tampered session as the attacker.

## What Worked

Blind stored XSS: admin bot viewed the stored username part → same-origin `fetch` deleted carlos under the admin's authority → solved marker.

## Burp Observations

- Login/structure probes, tamper probe, baseline render, and blind payload delivery all via Burp MCP (`burp_send_http1_request`) with full request/response evidence. No Scanner/Collaborator tools exist in this toolset — manual equivalents throughout.

## Browser Observations

- Lab-domain tab permission never granted by user; browser path unused. Pure HTTP flow sufficed (storage + victim-side execution need no attacker browser).

## CLI / Tool Observations

- curl for marker polling; Python for CSRF-bound flows. No wordlists, no cracking, no brute-force — 8 requests total.

## Root Cause

Two compounding flaws: (1) the username half of the session cookie is stored server-side (logging/audit surface) without output encoding → stored XSS; (2) a privileged bot/user views that surface with full admin authority, so injected script executes as admin. Integrity protection on the SESSION does not cover the STORED copy — validation happens at use time, storage happens before it.

## Verification

- Solved marker flipped `is-notsolved` → `is-solved` with no other intervening actions (120s wait only).
- Tamper→500 vs blind→solved contrast proves the victim-side (not attacker-side) execution path.
- carlos-login check honestly inconclusive; marker stands as the lab-defined proof.

## Impact

Unauthenticated persistent XSS-to-admin-action: any visitor action that stores the username part (here: merely presenting a tampered cookie) becomes arbitrary admin function execution (user deletion demonstrated).

## Why The Successful Approach Worked

- Separated STORAGE from SESSION VALIDITY: the 500 closed the front door (attacker's session) while the stored copy opened the back door (victim's session).
- Receiverless design: victim-side `fetch` performs the impact directly — no collaborator, exploit server, or webhook needed.

## Generalization

- For stored-XSS-with-privileged-viewer: prefer victim-side state-changing `fetch` (same-origin = victim credentials automatic) over cookie exfiltration — fewer moving parts, no receiver infrastructure, works where exfiltration is blocked.
- Integrity errors on tampered input do NOT imply the input wasn't stored — test the stored surface independently.

## Lessons Learned

- First XSS-family solved evidence in the KB (xss.md was an empty stub); methodology update justified for the receiverless pattern + storage-vs-validity distinction.
- Solution texts are insertion-point hints only: the scanner/collaborator steps were replaced wholesale with manual equivalents, and the exfil-then-swap chain with a direct blind action.

## Related Methodology

- methodology/xss.md (first content — stored-cookie-XSS + receiverless victim-side action; update justified, applied separately)
- methodology/verification.md (marker as lab-defined proof; honest inconclusive secondary check)
- methodology/injection.md does NOT apply. Deliberately not modified.

## References

- Lab description: https://portswigger.net/web-security/essential-skills/using-burp-scanner-during-manual-testing/lab-scanning-non-standard-data-structures (objective only)
- Official solution text (provided by user mid-session): insertion-point idea (username half of colon-split cookie) + collaborator exfil chain — PARTIALLY followed (insertion point verified independently; exfil chain REPLACED with blind victim-side action; scanner steps replaced with manual Burp/CLI equivalents)
- Solved instance: https://0ac8006103d46c3982619c5600750007.web-security-academy.net/ via blind `<script>fetch('/admin/delete?username=carlos')</script>` in cookie username part
