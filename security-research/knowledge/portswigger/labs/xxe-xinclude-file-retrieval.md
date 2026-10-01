# PortSwigger Lab

## Lab

Exploiting XInclude to retrieve files

URL: https://0a8300a104e826c58108b6bc0098008a.web-security-academy.net/

## Vulnerability Class

XInclude injection – form-encoded stock-check backend builds XML server-side with XInclude processing enabled; `xi:include` element in `productId` value pulls `file://` content into reflected error → arbitrary file read (no DOCTYPE needed)

## Objective

Retrieve server files via XInclude (demonstration lab – solved by `/etc/passwd` retrieval itself). Established by `is-solved` flip immediately after the passwd read. Official description not fetched; XInclude shape from XML knowledge, validated by error.

## Initial Observations

- Shop (integer productIds) + no account links. Product page stock form posts `application/x-www-form-urlencoded` (`stockCheckPayload.js` builds `URLSearchParams`, NOT XML – differs from prior XXE labs' `application/xml`).
- `POST /product/stock productId=1&storeId=1` → 200 `711` (count oracle).
- Stored `methodology/xxe.md` (5 shapes: DOCTYPE entities, SSRF-drill, blind-OOB ×2, SVG-upload; no XInclude section). No prior XInclude labs.

## Hypotheses

- H1: Backend wraps form values into server-side XML parsed with XInclude enabled. Evidence needed: `<foo xmlns:xi="...XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>` in `productId` returns file text (no DOCTYPE required).
- H2: Same reflected-error slot (`Invalid product ID`) carries content. Evidence needed: passwd bytes in 400.

## Attempts

1. Baseline product page + `stockCheckPayload.js` read (format: form-encoded, NOT XML – one read prevented DOCTYPE-in-body misfire) + baseline POST (`711`).
2. XInclude `file:///etc/passwd` in `productId` (URL-encoded, `storeId=1` constant) → `400 Invalid product ID: root:x:0:0...` (FULL passwd incl. `carlos:x:12002`) – H1+H2 confirmed first try.
3. `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Nothing. No dead ends; 4 requests total.

## What Worked

- Single XInclude element (no DOCTYPE) → contents in error → solved marker.

## Burp Observations

- All HTTP via Burp MCP (page, JS, baseline, XInclude probe with hand-computed `Content-Length: 139`, proof). Form-encoding of `<>"`/`:`/`/` in the element is load-bearing.

## Browser Observations

- Not required. No JS/state workflow (JS file only read as format documentation).

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known endpoint).

## Root Cause

Backend constructs XML server-side embedding raw `productId` value, then parses with XInclude processing enabled: `xi:include` with `file://` href is resolved during inclusion, and the lookup-failure error echoes substituted content. No DOCTYPE/entity surface needed – inclusion happens at XInclude layer, bypassing DOCTYPE-focused defenses conceptually.

## Verification

- Baseline-vs-XInclude differential (`711` vs passwd bytes) on same endpoint/session; only `productId` changed.
- Impact proof: global `is-solved` via fresh anon `GET /`. Full file (40+ lines) rules out partial-render artifacts.

## Impact

Unauthenticated arbitrary file read (demonstrated full `/etc/passwd`). Same primitive reads any `file://` path; `http://` hrefs extend to SSRF where egress permits.

## Why The Successful Approach Worked

- Read the payload builder FIRST (`stockCheckPayload.js`): form-encoded (not XML) dictated an in-VALUE XInclude element instead of a DOCTYPE body – one read prevented a wrong-shape attempt.
- No DOCTYPE gambit needed: XInclude needs no DTD, so the minimal element sufficed first try.

## Generalization

- For form-encoded endpoints that build XML server-side: skip DOCTYPE bodies; inject `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>` as the reflected-slot VALUE (URL-encoded).
- Client JS builders dictate request shape (XML vs form) – read before crafting; shape mismatch wastes the first probe.
- `parse="text"` for text files; reflected-error slots (`Invalid product ID`) exfiltrate on 400 as usual.

## Lessons Learned

- XInclude is the no-DTD XXE variant: one element, no DOCTYPE, same file impact – try it wherever DOCTYPEs are filtered.
- Builder-file reading (`*Payload.js`) is a standing pre-step for stockCheck-family endpoints – XML vs form shapes differ per lab.

## Related Methodology

- Extends `methodology/xxe.md` (no XInclude pattern – update justified below; 6th XXE lab, new vector shape).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: all XXE notes (reflected-error-slot + passwd-first + length discipline reused; shape adapted from builder evidence).

## References

- Solved instance: https://0a8300a104e826c58108b6bc0098008a.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/lab-xinclude-attack
- Format source (current evidence): `/resources/js/stockCheckPayload.js` (form-encoded, NOT XML)
- Deliberately did NOT fetch official solution; XInclude shape from XML knowledge, validated by error.
