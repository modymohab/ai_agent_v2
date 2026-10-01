# PortSwigger Lab

## Lab

Blind XXE with out-of-band interaction

URL: https://0a150022046019b281de61bf003a0016.web-security-academy.net/

## Vulnerability Class

XXE injection, blind with OOB interaction – external entity with `http://` URL forces server-side request with no reflection; detection via Collaborator interaction attributed to instance → solved marker

## Objective

Trigger server-side outbound interaction to Collaborator via blind XXE entity (detection lab – solved by attribution, no exfil). Established by `is-solved` flip after async wait. Official description not fetched; OOB discipline from stored blind-SSRF/OOB-command lessons.

## Initial Observations

- Shop + XML stock-check (`POST /product/stock`) – same sink shape as 2 prior XXE labs (current evidence from product page + prior loop).
- Baseline (`productId=1,storeId=1`) → 200 `974` (count oracle).
- `file:///etc/passwd` entity → `400 "Invalid product ID"` (GENERIC – no reflection, unlike prior lab's reflected contents). Blindness proven by differential: same payload class, reflected vs generic error.
- Stored `methodology/xxe.md` (in-band file + SSRF-drill patterns; no blind-OOB section) + blind-OOB discipline from SSRF/OS-command lessons (Collaborator-only egress, unique subdomain, 60-90s async wait, marker check, no client polling).

## Hypotheses

- H1: Parser still resolves external entities (generic error ≠ blocked parser – file entity parsed, just unreflected). Evidence: `file://` gives `Invalid product ID` (parsed) – need `http://` test for egress.
- H2: `http://<unique>.burpcollaborator.net` entity fires server-side fetch; interaction attributed to instance → `is-solved` after async window (same as blind-SSRF/OOB-command labs).
- H3: Trigger response (`XML parsing error` vs `Invalid product ID`) does NOT determine success – fetch may fire before/during parse failure; marker after wait arbitrates.

## Attempts

1. Baseline product page + baseline POST (`974`) – sink + shape in 2 requests.
2. `file:///etc/passwd` entity → `400 "Invalid product ID"` (no contents) – blindness confirmed, parser-engagement confirmed (distinct from parse rejection).
3. `http://5idfgqytchyb.burpcollaborator.net` (fresh random 12-char) entity → `400 "XML parsing error"` – different error than H1's (fetch attempted during parse; error text is not the oracle here).
4. Waited 65s → `GET /` → `is-solved`/`Solved`/`Congratulations` – H2+H3 confirmed.

## What Failed

- Nothing material. The `XML parsing error` (vs `Invalid product ID`) looked discouraging for ~65s but was correctly treated as non-oracle (fetch timing vs parse timing unknown) – patience beat a second hypothesis.

## What Worked

- Single OOB entity + unique subdomain + 65s wait + marker check. 5 requests total.

## Burp Observations

- Baseline, blindness probe, OOB trigger, proof – all via Burp MCP. Error-text differentials (`974` vs `Invalid product ID` vs `XML parsing error`) mapped blindly-vs-OOB behavior.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `burp_generate_random_string` (12-char unique subdomain – attribution hygiene); `bash sleep 65` for async window. No scanner/crawler/fuzzer.

## Root Cause

XML parser resolves external entities including `http://` URLs and issues the request server-side during parsing, with no output channel (generic errors only). Attacker DOCTYPE → server-side HTTP to attacker-influenced host → interaction observable only at the receiver (Collaborator) / platform attribution. Blind XXE with OOB detection as the sole signal.

## Verification

- Blindness: `file://` entity parsed (no parse rejection) but unreflected (generic error) – proves blind (not hardened) parser.
- Interaction: unique subdomain isolates attribution; 65s async wait respects receiver timing; `is-solved` flips with no other variable changed (single OOB injection).
- Trigger-status independence: success despite `XML parsing error` (fetch fired regardless of parse outcome) – marker, not trigger response, is the oracle.

## Impact

Server-side request forgery via XXE (demonstrated outbound interaction to arbitrary host; same primitive enables cloud-metadata theft where in-band, OOB exfiltration via parameter entities/DTD where blind, and internal-network probing).

## Why The Successful Approach Worked

- Distinguished three error classes BEFORE acting: count (`974` valid) vs generic (`Invalid product ID` blind-but-parsed) vs parse (`XML parsing error` OOB-attempt) – each mapped to the next step instead of treated as failure.
- Reused blind-OOB discipline verbatim (unique subdomain + Collaborator-only + wait + marker, no polling) from SSRF/OS-command lessons – third vindication of the same cross-class pattern.
- Waited out the async window on a discouraging trigger response – H3 (marker arbitrates) held.

## Generalization

- For blind XXE endpoints: baseline → `file://` probe (parsed-but-generic = blind, proceed; parse-rejection = harden/pivot) → `http://<unique>.burpcollaborator.net` entity → 60-90s wait → marker check. Trigger error text is NOT the oracle.
- Blindness is a spectrum signal: reflected (in-band) vs generic-but-parsed (blind, OOB-capable) vs parse-rejection (blocked) – classify via `file://` probe first.
- Unique-subdomain-per-attempt hygiene isolates attribution across labs/attempts.

## Lessons Learned

- `XML parsing error` on OOB entities can coincide with successful fetch (parse fails AFTER/DURING fetch) – never conclude from trigger response in OOB labs.
- Cross-class OOB discipline compounds: same Collaborator/wait/marker pattern now validated in SSRF-blind, OS-command-blind-OOB, and XXE-blind-OOB – the skill system compounds when layers stay separated.
- Blind-vs-hardened disambiguation costs exactly one `file://` probe.

## Related Methodology

- Extends `methodology/xxe.md` (in-band file + SSRF-drill; no blind-OOB section – update justified below; 3rd XXE lab, new signal class).
- Composes blind-OOB discipline (methodology/ssrf.md blind lessons – applied, not modified).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-external-entity-file-retrieval.md` (endpoint/entity/slot recipe), `xxe-ssrf-metadata-credentials.md` (scheme swap to `http://`), `ssrf-blind-oob-detection.md` + `os-command-injection-blind-oob.md` (OOB discipline).

## References

- Solved instance: https://0a150022046019b281de61bf003a0016.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/blind/lab-xxe-with-out-of-band-interaction
- OOB subdomain (instance-bound): 5idfgqytchyb.burpcollaborator.net (unique, attribution hygiene)
- Deliberately did NOT fetch official solution; OOB pattern from stored blind lessons, validated by marker.
