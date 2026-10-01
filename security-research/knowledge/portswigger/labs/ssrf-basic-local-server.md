# PortSwigger Lab

## Lab

Basic SSRF against the local server

URL: https://0a9a00fe04c0daa3803f8f5b00ef0001.web-security-academy.net

## Vulnerability Class

SSRF — server-side request forgery via stock-check URL parameter reaching loopback admin interface

## Objective

Delete user `carlos` via the loopback-only admin interface (established by evidence: internal panel exposes delete links; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Shop; product page has stock-check form `POST /product/stock` with `stockApi` URL select (external `http://stock.weliketoshop.net:8080/…` values) — server-fetched input (H-source, not proof).
- Baseline external submit → `54` (stock count rendered).

## Hypotheses

- H1: `stockApi` is fetched server-side with no loopback restriction → `http://127.0.0.1/` content reflected.
- H2: Internal admin lives on loopback (`/admin`) unreachable externally but reachable via SSRF.
- H3: SSRF `GET`-equivalent to `/admin/delete?username=carlos` executes deletion → solved.

## Attempts

1. External baseline → `54`. Oracle shape established (fetched body reflected).
2. `stockApi=http://127.0.0.1/` → 200 homepage HTML (incl. Admin panel link). H1 confirmed — loopback reachable, content reflected.
3. `stockApi=http://127.0.0.1/admin` → 200 `Users wiener - Delete carlos - Delete`. H2 confirmed.
4. `stockApi=http://127.0.0.1/admin/delete?username=carlos` → 302; re-read panel → `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; each step confirmed before the next (no blind jumps).

## What Worked

- Baseline → loopback-root → loopback-admin → loopback-delete → panel re-read + solved check (5 requests).

## Burp Observations

- Not used via Burp MCP; curl URL-swap sufficed. Repeater equivalent for stockApi tampering.

## Browser Observations

- Not required. No session/JS-dependent behavior (all anon).

## CLI / Tool Observations

- curl `--data-urlencode` for URL-valued params (correct encoding of inner `?`/`&`); fetched-body grep for delete links; panel re-read as state proof.

## Root Cause

The stock-check feature fetches an attacker-controlled URL server-side and reflects the body, with no restriction against loopback destinations. The admin interface, blocked at the network edge for external clients, is reachable from the server itself — so SSRF to `http://127.0.0.1/admin…` executes privileged actions in the server's network position.

## Verification

- External-vs-loopback differential (stock count vs reflected HTML) on one param isolates server-side fetching.
- Delete executed (302) + panel re-read (`User deleted successfully!`, carlos absent) + `/` `is-solved` — server-side state effect, deterministic.

## Impact

Internal admin compromise from an unauthenticated request (demonstrated user deletion); same primitive reaches any loopback-only service (admin panels, metadata, internal APIs).

## Why The Successful Approach Worked

- Established the reflection oracle on the benign external URL first, so loopback output was interpretable.
- Escalated loopback targets stepwise (root → admin → delete) instead of jumping to the delete.
- Re-read the panel after deletion rather than trusting the 302 alone.

## Generalization

- Any server-fetched URL param: baseline legitimate → loopback root (reflection?) → loopback admin paths → state-changing internal URLs → re-read + solved marker.
- URL-encode nested URLs fully; one variable (destination host/path) per request.
- 200-with-reflected-internal-HTML is the SSRF proof; victim absence + solved marker is the impact proof.

## Lessons Learned

- Stock-check / webhook / preview / PDF-fetch features are SSRF-first test points — read their forms before anything else.
- First SSRF lab: api-security reference (endpoints/params) + differential discipline transfer directly.
- No auth needed here — SSRF inherits the SERVER's network position, not the attacker's session.

## Related Methodology

- methodology/ssrf.md (loopback SSRF via fetched-URL param — to be created from stub)

## References

- Solved instance: https://0a9a00fe04c0daa3803f8f5b00ef0001.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
