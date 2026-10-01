# PortSwigger Lab

## Lab

Exploiting XXE to perform SSRF attacks

URL: https://0aec00ba033c4ad2815c702d00b40058.web-security-academy.net/

## Vulnerability Class

XXE injection → SSRF – external entity with `http://` URL forces server-side request to cloud metadata; response reflected in error text → credential exfiltration (XXE × SSRF composition)

## Objective

Exfiltrate EC2 IAM credentials via XXE-driven SSRF (in-band, reflected in `Invalid product ID` errors). Established by lab title + `is-solved` flip after credentials retrieval. Official description not fetched; metadata path drill-down from cloud-SSRF knowledge, validated per rung.

## Initial Observations

- Shop (integer productIds) + no account links; product page has XML stock-check (`POST /product/stock`) – same sink shape as prior XXE lab (current evidence from page HTML).
- `POST /product/stock` baseline (`productId=1,storeId=1`) → 200 `600` (count oracle, same as prior lab).
- Stored `methodology/xxe.md` (file-entity recipe: DOCTYPE + reflected-error slot + passwd-first) and `methodology/ssrf.md` (metadata targets, in-band vs blind discipline). No prior XXE→SSRF labs.

## Hypotheses

- H1: Same parser accepts `http://` entities (not just `file://`). Evidence needed: `http://169.254.169.254/` returns metadata listing in error.
- H2: Standard metadata drill path (`latest/` → `meta-data/` → `iam/` → `security-credentials/` → role → JSON) reflects in-band per rung. Evidence needed at each rung.
- H3: Retrieved admin credentials satisfy the objective → `is-solved` (no submit mechanism observed – retrieval demonstration).

## Attempts

1. Baseline product page + baseline POST (`600`) – sink + shape confirmed in 2 requests (reused prior XXE loop verbatim).
2. Entity `http://169.254.169.254/` → `400 Invalid product ID: latest` – H1 confirmed (server-side request fired, listing reflected).
3. `.../latest/meta-data/` → `iam`; `.../meta-data/iam/` → `security-credentials`; `.../security-credentials/` → `admin` – H2 per-rung (each listing is the next path segment; 3 requests, no guessing).
4. `.../security-credentials/admin` → full JSON (`AccessKeyId gpUEXpCHiIEzglv9Se4I`, `SecretAccessKey RnP5...`, Token, Expiration 2032) – credential objective met.
5. `GET /` → `is-solved`/`Solved`/`Congratulations` – H3 confirmed.

## What Failed

- Nothing. No dead ends; each rung's output dictated the next path (listing-driven, never guessed).

## What Worked

- `file://` recipe transferred to `http://` scheme (only the entity URL changed) + metadata path drill-down + reflected-error exfil. 7 requests total.

## Burp Observations

- All HTTP via Burp MCP (page, baseline, 5 entity probes, proof). `Content-Length` recomputed per body (107/207/228/232/253/258) – length math load-bearing.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known endpoint).

## Root Cause

XML parser resolves external entities for ANY URI scheme including `http://`, and the application issues the request server-side, then echoes the response body into the lookup-failure error. Attacker XML → server-side HTTP to link-local metadata → credential JSON in error text. XXE primitive with SSRF impact; in-band reflection removes need for OOB.

## Verification

- Baseline-vs-entity differential (`600` vs per-rung listings) on same endpoint/session.
- Each listing consumed as the next path (chain integrity: `latest`→`iam`→`security-credentials`→`admin`→JSON with `Code:Success` + key material).
- Impact proof: global `is-solved` via fresh anon `GET /`. Credentials recorded as evidence (instance-bound, expiring 2032 – dead with lab).

## Impact

Cloud IAM credential theft (AccessKeyId + SecretAccessKey + session Token) – full cloud identity compromise in real environments (privilege escalation to AWS APIs, lateral movement). Demonstrated in-band; blind variants would need OOB (cf. SSRF blind discipline).

## Why The Successful Approach Worked

- Transferred ONLY the stable parts of prior XXE lab (endpoint shape, entity syntax, reflected-error slot, length discipline); swapped ONLY the scheme + target per the SSRF objective.
- Let each listing dictate the next rung (no path guessing, no metadata brute force).
- Read `latest`→`iam` chain literally – even minimal one-word listings compose into full paths.

## Generalization

- For XXE-capable endpoints with reflected errors: verify `file://` first (passwd), then switch scheme to `http://169.254.169.254/` for SSRF; drill `latest/meta-data/iam/security-credentials/<role>` rung-by-rung, consuming listings.
- XXE × SSRF composition: entity syntax from XXE methodology, target selection + in-band-vs-blind reasoning from SSRF methodology – cross-file composition beats either alone.
- Minimal listings (`latest`, `iam`, `admin`) are complete – one word per rung is the normal metadata shape; do not over-fetch.

## Lessons Learned

- Scheme swap is a one-variable change: proven `file://` parser + new `http://` objective = same payload family, new impact class.
- Composition across methodology files (xxe.md syntax + ssrf.md targets) solves hybrid labs faster than re-deriving either.
- Credential JSON in errors is impact-complete – record keys as evidence, then marker-check (no submit needed here).

## Related Methodology

- Extends `methodology/xxe.md` (file-entity only – SSRF-via-entity pattern missing; update justified below; 2nd XXE lab, new scheme + target class).
- Composes `methodology/ssrf.md` (metadata drill path, in-band reflection reasoning – applied, not modified; SSRF file covers HTTP/Collaborator mechanics already).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-external-entity-file-retrieval.md` (endpoint/entity/slot/length recipe reused verbatim).

## References

- Solved instance: https://0aec00ba033c4ad2815c702d00b40058.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/lab-exploiting-xxe-to-perform-ssrf
- Exfiltrated (instance-bound, recorded as evidence): AccessKeyId `gpUEXpCHiIEzglv9Se4I` (SecretAccessKey/Token captured in full response; expired with lab)
- Deliberately did NOT fetch official solution; drill path from cloud-SSRF knowledge, validated per rung.
