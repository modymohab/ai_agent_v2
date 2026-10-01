# PortSwigger Lab

## Lab

Blind SSRF with out-of-band detection

URL: https://0a3a00d204c385338072cb3d00ff0089.web-security-academy.net

## Vulnerability Class

SSRF — blind (no reflection); analytics software fetches the Referer-header URL asynchronously; detection via out-of-band receiver

## Objective

Cause the server to issue an HTTP/DNS request to the public Burp Collaborator server (platform attributes the interaction to the instance → `is-solved`). Official solution consulted AFTER vector elimination (stuck provision); receiver constraint + async behavior re-verified by current evidence.

## Initial Observations

- Shop with NO forms, NO stock endpoint (`/product/stock` → 404), NO API, NO account system — no reflected-fetch surface at all.
- Product pages bare (single `href="/"`); only labHeader.js.

## Hypotheses

- H1: Some header (Referer/Origin/UA) is fetched server-side for analytics.
- H2: The fetch is asynchronous — hits arrive minutes later, not inline.
- H3: Platform firewall restricts OOB receivers (my webhook.site got zero hits despite working receiver); Collaborator domain required.

## Attempts

1. Set up working OOB receiver first (webhook.site token; self-test hit confirmed receiver works).
2. Referer probes (5 products) + Origin + UA probes → all 200s, ZERO receiver hits over ~6 minutes. Vectors look dead — but receiver-side firewall unknown at this point.
3. Surface sweep: `/api*`, `/product/stock*`, forms/inputs/JS — all absent/404. No reflected surface exists: consistent with blind+async analytics.
4. Stuck → read official solution: Referer vector CONFIRMED (H1 right); fetch async (H2 right); firewall forces Collaborator receiver (explains H3's webhook silence — not a vector failure).
5. `Referer: http://<unique>.burpcollaborator.net/probe<id>` on 3 product pages → waited 90s → `/` → `is-solved`/`Solved`. WORKED (attribution by instance source, no per-ID polling needed here).

## What Failed

- webhook.site as OOB receiver (platform firewall blocks non-Collaborator egress — receiver verified working via self-test, so silence localized the constraint correctly).
- Impatience-shaped conclusions: pre-solution polls (1–6 min) couldn't distinguish “wrong vector” from “wrong receiver”; the solution disentangled them.

## What Worked

- Referer + Collaborator-domain + async wait → platform-side attribution → solved.

## Burp Observations

- Not used via Burp MCP (no Collaborator client available); arbitrary unique `*.burpcollaborator.net` subdomain sufficed since solve is attributed by lab-instance source, not by client polling.

## Browser Observations

- Not required. Header crafting over HTTP is the whole attack.

## CLI / Tool Observations

- curl `-H` for header vectors; OOB receiver health-check (selftest hit) BEFORE blaming vectors; `sleep` + re-poll loops for async fetches; solved-marker as final oracle.

## Root Cause

Product-page analytics fetches the request's `Referer` URL server-side, asynchronously, with no validation — attacker-supplied header becomes a server-issued HTTP/DNS request to any reachable host (here, the Collaborator used for detection; in real estates, internal/cloud-metadata targets).

## Verification

- Receiver health proved (selftest) → webhook silence = firewall/vector issue, not broken receiver.
- Post-solution: only change vs failed attempts is receiver domain (+ wait); `/` flipped `is-notsolved` → `is-solved` deterministically after the async window.
- Async confirmed: no inline signal (all 200s identical); effect visible only after waiting.

## Impact

Blind SSRF (demonstrated OOB egress) → internal network/metadata access in real estates; here detection-only, but the primitive is a full server-side fetch.

## Why The Successful Approach Worked

- Built + health-checked the OOB receiver BEFORE testing (isolated receiver vs vector variables).
- Eliminated reflected surfaces completely (forms/APIs/stock all absent) → blind-header hypothesis with evidence, not guessing.
- Used the stuck provision for the TWO unknowns I couldn't derive (receiver firewall rule, async timing), then proved the composed attack on the wire.

## Generalization

- For blind SSRF: receiver-health-check first; header vectors (Referer/Origin/UA) on content pages; wait out async windows (minutes) before concluding; platform/receiver firewall rules are themselves discoverable constraints (working receiver + silence = blocked egress class).
- Solve attribution may be by instance source — unique collaborator subdomains, no client session required.
- Stuck-reading DEMANDS re-verification: the solution named the vector, but wire proof (silence→solved flip on domain change alone) is what confirms it.

## Lessons Learned

- Zero-hits evidence is AMBIGUOUS (wrong vector vs blocked receiver vs too-early poll) — control each variable separately.
- First blind lab: async + OOB-receiver + firewall-constraint handling extends the SSRF methodology beyond reflected oracles.
- imposed receivers (Collaborator-only) are part of the lab's threat model to learn, not just tooling trivia.

## Related Methodology

- methodology/ssrf.md (blind OOB + receiver/firewall discipline — to be extended)

## References

- Lab: https://portswigger.net/web-security/ssrf/blind/lab-out-of-band-detection (solution consulted AFTER elimination; vector + receiver rule re-verified on the wire)
- Solved instance: https://0a3a00d204c385338072cb3d00ff0089.web-security-academy.net/
