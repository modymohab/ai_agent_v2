# PortSwigger Lab

## Lab

Exploiting XXE using external entities to retrieve files

URL: https://0a9d006a0408884983724b3b0072004f.web-security-academy.net/

## Vulnerability Class

XXE injection – XML stock-check endpoint resolves external entities (`file://`) with contents reflected in error text → arbitrary file read

## Objective

Retrieve server files via external entities (demonstration lab – solved by `/etc/passwd` retrieval itself). Established by `is-solved` flip immediately after the passwd read. Official description not fetched; DOCTYPE/entity shape from XML-handling knowledge, validated by errors.

## Initial Observations

- Shop (integer productIds) + no account links. `GET /product?productId=1` → 200 product page with `Check stock` form (`POST /product/stock`) + `xmlStockCheckPayload.js` building `<?xml...?><stockCheck><productId>..<storeId>..</stockCheck>` as `application/xml`.
- `POST /product/stock` baseline (`productId=1,storeId=1`) → 200 `551` (stock count oracle shape).
- No XXE methodology exists in repo (no `xxe.md`; `injection.md` grep-confirmed zero XXE content – only coincidental `system-table` hits). No prior XXE labs.

## Hypotheses

- H1: `/product/stock` XML parser resolves DOCTYPE/external entities. Evidence needed: `<!ENTITY xxe SYSTEM "file:///etc/passwd">` referenced in `productId` returns file text.
- H2: Error text reflects entity content (`Invalid product ID: <contents>`), making even failed lookups an exfil oracle. Evidence needed: passwd bytes in 400 body.
- H3: Other sensitive paths readable the same way (e.g. `/home/carlos/secret`). Evidence needed per-path (success vs `FileNotFoundException` distinguishes).

## Attempts

1. Baseline product page + JS format read + baseline POST (`551`) – sink + shape mapped in 3 requests.
2. XXE `file:///etc/passwd` in `productId` → `400 Invalid product ID: root:x:0:0...` (FULL passwd, 40+ lines incl. `carlos:x:12002`) – H1+H2 confirmed first try.
3. XXE `file:///home/carlos/secret` → `400 FileNotFoundException: /home/carlos/secret (No such file or directory)` – H3 answered negatively for that path (distinguishes missing-file from blocked-parser: parser clearly resolves `file://`, file simply absent).
4. `GET /` → `is-solved`/`Solved`/`Congratulations` – passwd retrieval itself satisfied the objective.

## What Failed

- `/home/carlos/secret` guess – absent file (informative negative: `FileNotFoundException` proves `file://` resolution works generally; no parser hardening).

## What Worked

- Single DOCTYPE entity (`<!ENTITY xxe SYSTEM "file:///etc/passwd">` + `&xxe;` in `productId`) → contents in `Invalid product ID` error → solved marker. 5 requests total.

## Burp Observations

- All HTTP via Burp MCP (page, JS, baseline, both XXE probes, proof). `Content-Length` recomputed per body (107/205/213) – length math is load-bearing for raw HTTP/1.1.

## Browser Observations

- Not required. No JS/state workflow (JS file only read as format documentation).

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known endpoint, no discovery needed).

## Root Cause

XML parser on `/product/stock` processes inline DTD with external entities enabled and no allowlist: attacker DOCTYPE defines `file://` entity, referenced value is substituted into `productId`, and the lookup-failure error echoes substituted content. Data (XML) → parser directive (entity) → filesystem read → reflected error.

## Verification

- Baseline `551` (valid shape) vs entity `400` + passwd bytes (only variable: DOCTYPE + `&xxe;`).
- Negative control (`secret` → `FileNotFoundException`, not parser rejection) proves generality of `file://` resolution.
- Impact proof: global `is-solved` via fresh anon `GET /` – retrieval demonstration satisfied the lab.

## Impact

Authenticated-not-required arbitrary file read (demonstrated full `/etc/passwd` incl. service users, UIDs, home dirs, shells – recon gold). Same primitive yields source/config/key theft (`/proc`, app files, `.ssh/`) where paths exist.

## Why The Successful Approach Worked

- Read the client-side payload builder (`xmlStockCheckPayload.js`) as format documentation – exact element names, no guessing.
- Chose the reflected-error slot (`productId` in `Invalid product ID`) for the entity reference – exfil needs no valid lookup.
- Used `/etc/passwd` (guaranteed path) before instance-specific guesses – universal proof first, targeted paths second.

## Generalization

- For XML endpoints with reflected errors: baseline valid shape → read any client-side builders → DOCTYPE `<!ENTITY x FILE "file:///etc/passwd">` + `&x;` in the reflected slot → file bytes in error (even on 400) → escalate to targeted paths; `FileNotFoundException` (vs parser rejection) means resolution works, path wrong.
- `Content-Length` recompute per raw body; `application/xml` content type required.
- Passwd content doubles as recon (users/homes/shells inform next paths).

## Lessons Learned

- Reflected-error slots turn failed XXE lookups into exfil oracles – 400s carry the file.
- Missing-file errors (`FileNotFoundException`) vs parser rejections distinguish “wrong path” from “hardened parser” – read the exception class.
- JS payload builders are free format specs – read before crafting.

## Related Methodology

- New `methodology/xxe.md` created (no XXE methodology existed; `injection.md` grep-verified zero XXE content – dedicated file, not an injection.md append; 1st XXE lab).
- `methodology/injection.md` does NOT apply (XML parser directives vs query/shell). Deliberately not modified.
- No prior XXE labs; generic discipline only (single-variable, marker proof, JS-as-docs habit from API lab).

## References

- Solved instance: https://0a9d006a0408884983724b3b0072004f.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/lab-exploiting-xxe-to-retrieve-files
- Format source (current evidence): `/resources/js/xmlStockCheckPayload.js`
- Deliberately did NOT fetch official solution; entity shape from XML knowledge, validated by errors.
