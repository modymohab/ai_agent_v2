# PortSwigger Lab

## Lab

CSRF vulnerability with no defenses — https://0ab7002c04415f0a82f4101000a40055.web-security-academy.net/ (PortSwigger Web Security Academy, CSRF). Creds wiener:peter. Exploit server: https://exploit-0ae7008804115f3b82810f39012100cc.exploit-server.net.

## Vulnerability Class

Cross-site request forgery: state-changing action with no token, no SameSite protection, no Referer check. First CSRF lab in KB.

## Objective

Craft HTML CSRF changing the viewer's email; upload to exploit server (victim bot reviews → solved).

## Initial Observations

- Login csrf fetch failed (markup variant) yet empty-csrf login still 302'd — login token unenforced or optional (not the target; noted, not pursued).
- Change-email form: email field ONLY, no csrf input. Session cookie `Secure; HttpOnly; SameSite=None` — cross-site sends allowed by design.
- `POST /my-account/change-email` with email alone → 302 → email changed (verified on re-read).

## Hypotheses

- H1: action has zero CSRF defenses (no token + SameSite=None) → bare cross-origin POST succeeds. Confirmed on own session first.
- H2: auto-submit exploit + victim visit → victim email changes → solved marker. Confirmed (slow cycle).

## Attempts

1. Bare-POST proof on own session (email → csrf-test@example.com, verified re-read).
2. Exploit stored at `/exploit` (auto-submit form + script), verified bytes live, DELIVER_TO_VICTIM ×2.
3. Polls at ~2/6/10 min: no victim, marker `is-notsolved`. At ~15 min: victim UA hit + `is-solved`. No exploit changes between polls — pure victim-cycle latency.

## What Failed

- Impatience risk: nearly rewrote a working exploit at 10 min; the only fault was polling too early. Victim cycles vary (4–15 min observed across labs).

## What Worked

Minimal auto-submit form; store → verify bytes → deliver (with real body — deliver re-stores posted fields, so never deliver placeholder bodies) → poll log for `Mozilla/5.0 (Victim)` → marker.

## Burp Observations

Not used (curl sufficed).

## Browser Observations

Mapping only (permission dialog blocked automation).

## CLI / Tool Observations

- Exploit-server form API: responseFile/responseHead/responseBody/urlIsHttps + formAction (STORE/DELIVER_TO_VICTIM/ACCESS_LOG→`/log`); deliver POST must carry the REAL body (it re-stores).
- Victim identification: `Mozilla/5.0 (Victim)…Chrome/151` vs curl in `/log`.

## Root Cause

State-changing email update bound to cookie session only: no per-request token, `SameSite=None` cookies, no origin/Referer validation — any cross-site page can submit it with victim credentials attached automatically.

## Verification

- Self-proof: tokenless POST changed own email (302 + re-read).
- Victim proof: `/log` shows victim hit on `/exploit/` + Lab `is-solved` (no other state change explains the marker flip).

## Impact

Arbitrary account-attribute overwrite for any victim lured to attacker content (demonstrated email; same primitive hits any undefended action).

## Why The Successful Approach Worked

Removed every variable except the victim visit: proven action + proven cookie behavior + byte-verified exploit — so the only remaining unknown was timing, which polling resolved.

## Generalization

For suspected CSRF: (1) prove tokenless success on own session; (2) check cookie flags (`SameSite=None` = green light, `Lax` = GET/top-level only, `Strict` = dead); (3) minimal auto-submit page; (4) store → verify → deliver with real body → poll victim UA + marker; (5) allow 15+ min before reworking.

## Lessons Learned

- SameSite flag on the session cookie predicts CSRF viability before any exploit is built.
- DELIVER re-stores posted fields — always deliver the real body (learned hard on the cache lab; applied here).
- Victim cycles vary widely; time-box re-polls, don't rewrite working exploits early.
- Empty-csrf login succeeding is worth noting but out of scope — stay on the target action.

## Related Methodology

- methodology/csrf.md (NEW — first CSRF content, created below)
- methodology/verification.md (self-proof then victim-proof, marker arbitration)
- methodology/injection.md — compared, NOT applicable (no interpreter; trust-boundary flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/csrf/lab-csrf-vulnerability-with-no-defenses
