# PortSwigger Lab

## Lab

Basic SSRF against another back-end system

URL: https://0a180094031b915c80f1767100ad00ce.web-security-academy.net

## Vulnerability Class

SSRF — server-side request forgery via stock-check URL reaching a second internal backend (private-range scan → admin interface on 192.168.0.170:8080)

## Objective

Delete user `carlos` via the internal backend's admin interface (established by evidence; deletion flips `is-solved`). Official description not read.

## Initial Observations

- Shop; stock-check form `POST /product/stock` with `stockApi` URLs already pointing at `http://192.168.0.1:8080/…` (internal range referenced directly).
- External-shape baseline from sibling lab applies as principle only; here baseline `573` bytes.

## Hypotheses

- H1: `stockApi` is fetched server-side with no private-range restriction (loopback-lab lesson as source).
- H2: A second backend host in `192.168.0.0/24:8080` serves `/admin` (closed hosts error distinctively).
- H3: SSRF delete through that host removes carlos → solved.

## Attempts

1. Baseline external-shaped request (573B) — oracle shape.
2. Parallel sweep `stockApi=http://192.168.0.1-254:8080/admin` (25 threads, 12s timeout): 254/255 → 500/2454B (connection-refused error page, uniform); exactly one outlier **`192.168.0.170` → 200/3245B with `Admin panel` + `delete?username=` links**. H2 confirmed — open-vs-closed differential.
3. `stockApi=http://192.168.0.170:8080/admin/delete?username=carlos` → 302; re-read panel → `User deleted successfully!`, carlos gone; `/` → `is-solved`/`Solved`. WORKED.

## What Failed

- Nothing material; the sweep's uniformity (identical 500/2454B) made the single outlier unambiguous — no ambiguous hosts needed follow-up.

## What Worked

- Baseline → /24 sweep on `:8080/admin` with content oracle → single hit → delete → re-read + solved check.

## Burp Observations

- Not used via Burp MCP; curl + Python threads sufficed. Intruder equivalent for the backend sweep (pitchfork/sniper over octets, grep on admin markers).

## Browser Observations

- Not required. All anon HTTP.

## CLI / Tool Observations

- Python `threading` (25 workers) + per-host response files; discriminator 500/2454B-refused vs 200/3245B-admin; `delete?username=` grep as hit criterion.

## Root Cause

Same unrestricted server-side fetch as the loopback lab, extended to the private network: `stockApi` reaches any `192.168.0.0/24:8080` host, and a second backend there exposes its admin interface without authentication. Probing internal hosts through the parameter finds `.170`; its delete action executes in the server's network position.

## Verification

- Sweep differential: 254 identical refusals vs 1 admin page — single variable (octet) explains the outlier.
- Delete 302 + panel re-read (success message, victim absent) + `/` `is-solved` — deterministic server-side effect.

## Impact

Unauthenticated internal-network pivot + admin compromise on a second backend (demonstrated deletion); same primitive enumerates/reaches any internal HTTP service.

## Why The Successful Approach Worked

- Reused the loopback lab's oracle discipline (baseline shape → destination swap → re-read) with the range as the only new dimension.
- Uniform refusal signature turned a 254-host sweep into a one-outlier decision — no per-host judgment calls.
- Port fixed at `:8080` from the form's own URLs (no port sweep needed).

## Generalization

- When fetched URLs already reference `192.168.0.x:port`, sweep the /24 on that port for `/admin` with content (not status) oracles; refused-vs-open differentials carry the scan.
- Parallelize boring sweeps (threads + timeouts); log response bodies per host for post-hoc greps.
- Step up: loopback first (cheap), then adjacent private range; re-read state after mutation; solved marker confirms.

## Lessons Learned

- Form-provided internal URLs define port + path convention — adopt them instead of guessing.
- Uniform-error sweeps are self-validating: one outlier IS the finding; investigate it, don't re-sweep.
- Second SSRF lab, same 5-step shape (baseline → target → admin → delete → re-read) with range-scan inserted — methodology extends, not rewrites.

## Related Methodology

- methodology/ssrf.md (private-range backend discovery — to be extended)

## References

- Solved instance: https://0a180094031b915c80f1767100ad00ce.web-security-academy.net/
- Deliberately did NOT read the official solution/writeup for this lab.
