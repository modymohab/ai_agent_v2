# PortSwigger Lab

## Lab

User ID controlled by request parameter, with unpredictable user IDs

URL: https://0ab0007b0413d6eb8086e57b00840088.web-security-academy.net

## Vulnerability Class

Access control — horizontal IDOR (insecure direct object reference) with GUID identifiers; victim GUID leaked via blog author links

## Objective

Retrieve `carlos`'s API key and submit via the lab's `POST /submitSolution` mechanism (`is-solved` on success; official description not read).

## Initial Observations

- Blog app with `Submit solution` header button (`POST /submitSolution`, param `answer`, per `submitSolution.js` — 200 + `{"correct":true}` oracle).
- Login `wiener:peter` → 302 `/my-account?id=29548ef2-247b-4902-92c5-32bc7ca6c128` (GUID-keyed accounts); own page shows `Your API Key is: …`.
- GUIDs unpredictable — direct guessing infeasible; leak required.

## Hypotheses

- H1: Victim GUID is leaked in reachable content (blog author links).
- H2: `/my-account?id=<victim-guid>` lacks ownership check → renders victim API key to any authenticated session.
- H3: Submitted key returns `{"correct":true}` → solved.

## Attempts

1. Login + own GUID shape + API-key-on-page baseline (wiener).
2. Fetched 10 blog posts; grepped `carlos` + author/account/id links → `/blogs?userId=0e64066f-849a-4c96-8438-11a0ebaebaf7` on carlos's posts. H1 confirmed — leak, not guess.
3. `GET /my-account?id=0e64066f-849a-4c96-8438-11a0ebaebaf7` as wiener → 200 `Your username is: carlos Your API Key is: kW8CLBi6DrbCWlXk19c3V18Cp42ZipH4`. H2 confirmed.
4. `POST /submitSolution answer=<key>` → `{"correct":true}` 200; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; first-attempt chain succeeded because leak discovery preceded access testing (no guessing, no brute-force).

## What Worked

- Author-link GUID extraction → direct IDOR → key submission → solved (4 logical steps, ~15 requests).

## Burp Observations

- Not used via Burp MCP; curl + grep sufficed. Repeater equivalent for id-swap.

## Browser Observations

- Not required. No session/JS-dependent behavior.

## CLI / Tool Observations

- curl session jar; grep over fetched posts for victim identifier; `submitSolution.js` read to learn the submission contract (method/path/param/oracle) instead of guessing it.

## Root Cause

Object-level authorization missing on `/my-account?id=`: any authenticated user can substitute an arbitrary account GUID and read that account's data (username + API key). Unpredictable IDs raise the bar from guessing to leaking — but the application itself leaks victim GUIDs in public blog author links, collapsing the protection.

## Verification

- Own-vs-victim differential: same session, own GUID → wiener key; victim GUID → carlos key — one variable (id value) explains disclosure.
- Key validity proved by submission oracle `{"correct":true}` + `/` `is-solved` (not merely by page render).
- Deterministic across re-requests.

## Impact

Horizontal account-data disclosure for any user whose GUID is discoverable (authored content, shared links, logs): API keys enable full account impersonation at downstream services.

## Why The Successful Approach Worked

- Established the ID shape + key-on-page facts on MY account first (baseline before attack).
- Hunted the leak (content grep) instead of guessing unguessable IDs.
- Read the submission contract (`submitSolution.js`) rather than assuming endpoint/param shape.

## Generalization

- GUID-keyed objects: first prove self-access + data-on-page, then hunt victim IDs in authored content, shared URLs, sitemaps, JS, and API responses — then swap.
- Read client submission code (button attrs + JS) for method/path/param/oracle before submitting.
- 200 + victim data + oracle-true is the proof chain for IDOR (render alone is step one).

## Lessons Learned

- First horizontal lab: A-vs-B with two controlled observations (own key vs victim key) replaces escalation proof (solved marker still required).
- “Unpredictable” ≠ “unreachable” — the app that mints unguessable IDs often leaks them in its own UI; grep there first.
- Submission oracles (`{"correct":true}`) double as key-validity checks — no separate verification step needed.

## Related Methodology

- methodology/access-control.md (horizontal IDOR — to be extended; currently vertical-only)

## References

- Solved instance: https://0ab0007b0413d6eb8086e57b00840088.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
