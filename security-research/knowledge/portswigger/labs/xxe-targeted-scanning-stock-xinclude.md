# PortSwigger Lab

## Lab

Discovering vulnerabilities quickly with targeted scanning

URL: https://0a70000404241a8082ef20fb00a700ee.web-security-academy.net/

## Vulnerability Class

XXE via XInclude injection in the `productId` stock-check parameter → arbitrary file read (`/etc/passwd`)

## Objective

Retrieve `/etc/passwd` within 10 minutes (scanner-lab framing: use targeted intuition instead of full-site scan). Solved by the file read itself (`is-solved` flips on retrieval).

## Initial Observations

- CURRENT EVIDENCE: shop with 20 products; product page has `POST /product/stock` form (`productId` hidden + `storeId` select, form-encoded).
- CURRENT EVIDENCE: baseline `productId=1&storeId=1` → bare-number stock count; `productId=1'` → `Invalid product ID: 1'` (value reflected in error slot).
- CURRENT EVIDENCE: `<script>alert(1)</script>` in productId → reflected as `alert(1)` (tags stripped — naive XSS dead, not pursued).
- STORED KNOWLEDGE (not evidence): `xxe-xinclude-file-retrieval.md` + `methodology/xxe.md` XInclude section — identical endpoint shape (form-encoded stock check, reflected-slot value) in a prior lab.

## Hypotheses

- H1: backend wraps form values into server-side XML with XInclude enabled → in-value `xi:include file:///etc/passwd` returns file text in the `Invalid product ID` slot (transferred shape, to verify).
- H2 (explored, abandoned): `storeId` numeric oracle suggests SQLi — boolean-differential responses observed but irrelevant to the file-read objective; dropped after H1 confirmed (see What Failed).

## Attempts

1. Shop mapping (homepage links) + product page form read + baseline POST.
2. Reflection probes: quote (reflected), script tags (stripped) — mapped the error slot, ruled out naive XSS.
3. `storeId` numeric probing: `1→939, 2→296, 1 AND 1=1→608, 1 AND 1=2→19`, deterministic repeats — boolean-differential behavior noted but NOT pursued (wrong vulnerability class for the objective; possible rabbit hole or second vuln, out of scope).
4. XInclude payload (URL-encoded form value): `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>` → **400 `Invalid product ID: root:x:0:0...` (FULL passwd)**. H1 CONFIRMED first try.
5. `GET /` → `is-solved` ×2. SOLVED (~12 requests total).

## What Failed

- Naive `<script>` XSS (tags stripped) — 1 probe, correctly abandoned (error-slot reflection ≠ script execution context).
- `storeId` SQLi-looking oracle chase (several probes) — interesting but off-objective; stopping rule applied once H1 (the file-read primitive) was available. Recorded so future scanners don't re-chase it on this endpoint shape.

## What Worked

In-value XInclude in `productId` → file bytes in reflected error → solved marker.

## Burp Observations

- Form inspection, reflection probes, numeric-oracle probes, and XInclude proof all via Burp MCP (`burp_send_http1_request`) with full request/response evidence. No Burp Scanner available in this toolset — manual targeted probing substituted (shop → stock endpoint intuition, same time-box logic).

## Browser Observations

- Not required. Pure HTTP flow. Browser Control MCP correctly unused.

## CLI / Tool Observations

- curl for mapping/counting; Python for exact reflection-context extraction. No wordlists, no scanners, no fuzzers — targeted single-payload exploit after slot mapping.

## Root Cause

The stock-check backend interpolates the form-encoded `productId` value into server-side XML parsed WITH XInclude processing enabled: attacker-supplied `xi:include` elements resolve `file://` URLs and their content lands in the reflected `Invalid product ID` error. No DOCTYPE needed — bypasses DOCTYPE-focused defenses by construction.

## Verification

- Full `/etc/passwd` bytes (root through system accounts + lab users peter/carlos) in a single 400 response — content proof, not status.
- `GET /` → `is-solved` ×2 immediately after. Deterministic end-to-end.

## Impact

Arbitrary server file read via unauthenticated stock endpoint (passwd demonstrated; same primitive reaches app configs/secrets within file permissions).

## Why The Successful Approach Worked

- Stored XInclude shape (form-value, URL-encoded, reflected-slot) transferred exactly — prior lab's builder-shape lesson (`URLSearchParams` form, never DOCTYPE bodies) applied without re-derivation.
- Rabbit-hole discipline: `storeId` numerics abandoned once the file-read primitive confirmed, despite being genuinely curious.

## Generalization

NONE new — technique, shape, slot, and proof are all already in `methodology/xxe.md` (XInclude section) and the prior lab note. Only lab-specific framing differs (10-minute scanner time-box → targeted endpoint intuition).

## Lessons Learned

- Scanner-lab framing is a recon lesson, not a new vuln class: map shop → stock endpoint → error-slot reflection → known XXE shape in ~12 requests, well inside the time-box without any scanner.
- Off-objective oracles (`storeId` numerics) get recorded, not chased, when the objective primitive is already in hand.

## Related Methodology

- methodology/xxe.md (XInclude section — fully covers this; NO update justified)
- methodology/verification.md (content proof + solved marker)
- methodology/injection.md does NOT apply (storeId numerics unclassified by design — deliberately not promoted without a worked exploit). Deliberately not modified.

## References

- Lab description: objective (read `/etc/passwd` in 10 min) + community writeups confirming the XInclude vector for this slug (used as hypothesis source after independent slot mapping; payload shape from stored XXE knowledge)
- Prior related (shape source): knowledge/portswigger/labs/xxe-xinclude-file-retrieval.md
- Solved instance: https://0a70000404241a8082ef20fb00a700ee.web-security-academy.net/ with in-value XInclude in `productId`
