# File Security Methodology

## Core Concept

File-upload flaws occur when user-supplied files are stored without extension/MIME/content validation and served from a predictable web path with script execution enabled — a `.php` avatar becomes OS command execution as the app user.

## Security Boundary

Intended: uploads are inert data (images) served safely.
Violated when: `avatar=<shell.php>` stores executably → `GET /files/avatars/shell.php?cmd=id` returns `uid=…`.

## Recognition Patterns

- Avatar/attachment forms (`multipart/form-data`, file + user + csrf fields).
- Upload responses disclosing storage paths (`The file avatars/<name> has been uploaded.`).
- Server stack headers (Apache/PHP) implying script execution.
- Submission oracles (`POST /submitSolution`, `{"correct":true}`) for exfiltrated secrets.
- 403 naming allowed types (`Only image/jpeg and image/png are allowed`) — header-only validation signal; extension may be unrestricted.
- 403 naming blocked concepts (`php files are not allowed`, `only JPG & PNG`) — read wording: allowlist → spoof type; blocklist → matrix unlisted-but-executable extensions.
- 403 naming VALIDITY (`file is not a valid image`) — content-inspection signal; magic-byte polyglot required.
- Stored-but-static shells (source returned, not executed) + preserved `../` in echoed relpath (`avatars/../marker.php`) — traversal-to-executing-parent setup.
- Synchronous 403s across ALL payload families with no async-deletion evidence on compliant files — suspect STORE-THEN-DELETE race (rejection message describes intent, not mechanism).

## Common Locations

- `POST /my-account/avatar` (upload), `GET /files/avatars/<name>?cmd=` (execution).
- Secrets: `/home/<user>/secret`; recon: `pwd`, `ls -la`, `cat`.

## Indicators

- Upload message names the stored path verbatim (path oracle).
- `?cmd=id` returns `uid=…` (execution proof, not page render).
- Secret file listed + exfiltrated; submission returns `{"correct":true}` + `is-solved`.

## Testing Methodology

1. Baseline benign upload (PNG) → record exact stored/served path convention.
2. Upload minimal shell (`.php` first on Apache/PHP stacks; polyglots only if blocked), one variable at a time.
3. Prove execution with `?cmd=id` (GET vs POST per shell construction — 405 means wrong verb).
4. Discover the served path (`/files/…` vs `/avatars/…`) by status+body probing.
5. Walk filesystem to objective (`/home/<user>/secret`); submit contents; verify oracle + solved marker.
6. Content-Type-bypass extension: on 403 naming allowed types, resubmit IDENTICAL bytes with each allowed `Content-Type` (`-F "avatar=@shell.php;type=image/png"`); stored-path message = header-only validation. Extract csrf from the SAME form render (cross-form tokens 400-mislead). Then steps 3–5 unchanged.
7. Path-traversal extension: when stored shells serve STATIC (source, not output), tamper the multipart FILENAME (`../`, `..%2f`, `..%252f`, `....//`) with UNIQUE marker names; read the echoed relpath as storage oracle; normalize against the served prefix (`/files/avatars/../x` → `/files/x`) and prove execution there (`uid=`). Stored-200 ≠ vuln; executed output = vuln.
8. Null-byte extension: after eliminating case/alt-ext/double-ext/semicolon/dot/htaccess with evidence, test `filename=shell.php%00.png` vs `%2500` with HAND-BUILT multipart (curl `-F` can't control these bytes); stored-TRUNCATED name (`avatars/shell.php`) = bypass, stored-LITERAL = no-decode. Then steps 3–5 unchanged.
9. Blacklist-gap extension: on concept-blocklist 403s, matrix unlisted-but-executable-per-stack extensions (`.phar`, `.pht`, `.phtml`, `.php5/7`, `.htaccess`, case variants) AND prove EXECUTION per candidate (`?cmd=id` → `uid=` vs source). Acceptance ≠ exploitability (`.pht` stores yet serves static). Stop at first executor.
10. Polyglot extension: on validity-gate 403s, prepend format magic (`GIF89a`, PNG `\x89…`, JPEG `FFD8`) to the payload, keep executable extension, verify stored → execute; prologue bytes emit verbatim — STRIP framing (`xxd`, prefix-strip) before submitting exfiltrated secrets (`false` after RCE = contamination until proven otherwise).
11. Race-window extension: when synchronous families eliminate cleanly, test TIME — upload + N parallel executions per round (N=10–15, randomized filenames, shared output file); ANY `uid=` hit among 404s proves store-before-scan. Then race exfiltration the same way and dedupe repeats. Serial retests cannot see millisecond windows; parallelism is mandatory.

## Verification

- Chain: stored-path message → command output → secret bytes → `{"correct":true}` + `is-solved`. Each link deterministic; note the RCE user.

## Common Failure Modes

- Exotic polyglots before trying plain `.php` (cheapest test first).
- POSTing commands to a `$_GET` shell (405) — match invocation to construction.
- Assuming served path from stored path (probe variants; 404/302 vs 200+output).

## Impact Considerations

- RCE as app user → file disclosure (demonstrated), backdooring, lateral movement.

## Lessons Learned

- From PortSwigger “Remote code execution via web shell upload”: PNG baseline → `avatars/t.png`; `shell.php` unblocked → `/files/avatars/shell.php?cmd=id` → `uid=12002(carlos)` → `/home/carlos/secret` → submit → `{"correct":true}` + `is-solved`.
- From PortSwigger “Web shell upload via Content-Type restriction bypass”: plain `.php` (octet-stream) → 403 naming `image/jpeg|image/png`; identical bytes as `image/png` → stored executable → same RCE chain → `{"correct":true}` + `is-solved`. Per-form csrf (login token 400s on avatar form).
- From PortSwigger “Web shell upload via path traversal”: no extension/MIME block, but `avatars/` serves static (source leak); `filename=..%2fmarker.php` echoes `avatars/../marker.php` → `/files/marker.php?cmd=id` → `uid=12002(carlos)` → secret → `{"correct":true}` + `is-solved`. Placement decides execution; fresh markers per variant.
- From PortSwigger “Web shell upload via obfuscated file extension”: 7 extension variants → identical 403; `shell.php%00.png` (hand multipart) → stored TRUNCATED as `shell.php` (vs `%2500` literal) → same RCE chain → `{"correct":true}` + `is-solved`. Exactly-one-decode gap; per-form csrf.
- From PortSwigger “Web shell upload via extension blacklist bypass”: `Sorry, php files are not allowed`; `.phtml` blocked but `.phar`+`.pht` upload; only `.phar` EXECUTES (`uid=…`, `.pht` serves source) → secret → `{"correct":true}` + `is-solved`. Unlisted-executable gap; prove execution per candidate.
- From PortSwigger “Remote code execution via polyglot web shell upload”: plain PHP → 403 `not a valid image`; `GIF89a`+PHP → stored + executes (`uid=…` beside verbatim prologue); unstripped secret → `{"correct":false}`, stripped 32-char → `{"correct":true}` + `is-solved`. Magic-byte-only check; frame-strip exfiltration.
- From PortSwigger “Web shell upload via race condition”: all sync families 403 (even TOCTOU pairs 404); upload + 10 parallel GETs × 6 rounds → 49 `uid=` hits among 404s (403 lies — stored then async-deleted); raced `cat secret` → repeated token → `{"correct":true}` + `is-solved`. Time-parallelism; randomized names per round.

### Prefix-limited content scanning is a bypass, not a defence
Where an application scans uploaded content, establish **how much** it reads before
you conclude anything. A scanner that inspects only a fixed-size prefix of the file
is not a weaker comprehensive scanner; it is a *specific* tool, and content placed
beyond its window is invisible to it by construction. This is trivially bypassed and
almost never noticed, because the natural test — put a known-bad string in the file
and see whether it is rejected — is defeated by padding.

- **Test the boundary, not just the payload.** Upload a payload that is *only*
  padding-then-payload, with the payload beginning immediately after the scan
  window, and confirm the same payload is rejected at the start of the file. One
  accepted, one rejected, identical payload = the scan window is the control, and
  the control is trivially defeated. Use a distinctive, comment-legal filler
  (repeated characters inside a comment) so the file remains valid and parses.
- **Record the window size from source, then confirm it from behaviour.** A literal
  read length in the validator is a precise, greppable artifact — and reading it
  also tells you what the control was *for*, which is the next and more important
  question (see the control-purpose rule in `verification-skill/SKILL.md`). A
  short prefix is frequently *correct* for a narrow threat such as legacy browser
  MIME sniffing, which reads only the header. Reporting "the scanner failed" when
  the scanner was never assigned your threat is a category error that hands the
  triager a confident rebuttal, and the remediation you propose — scanning the whole
  file — solves a problem the control was not given.
- **The real finding is usually a missing control, not a broken one.** Establish
  which threat model has *no* coverage at all, and report that. A defence-in-depth
  layer is only worth reporting as a bypass if something actually depends on it;
  otherwise the honest report is "this threat is uncovered" plus the hardening you
  would accept, which is a smaller, correctable ask.
- **Keyword blocklists for markup are a losing game; say so with an example.**
  Enumerating disallowed tag names cannot be complete, because event-handler
  attributes (`onload`, `onbegin`, and every other `on*` attribute) are valid on
  elements that are perfectly legitimate, and because SVG, MathML and HTML all
  provide distinct element and attribute vocabularies. Demonstrate one element and
  one event handler that are obviously reasonable to a reviewer and absent from the
  list, and recommend contextual output encoding at the render point instead of
  enumeration. This is a stronger report and a more useful remediation, and it is
  what makes the finding survive a maintainer who intends to push back on the fix.

### Serving an active document type inline converts a stored file into stored script
The upload control and the serving control are independent, and the vulnerability
usually lives in the *second* one. A stored file becomes executable when the
application later serves it with a content type the browser renders as an active
document **and** a disposition that invites rendering rather than download.

- **The decisive pair is `Content-Type` + `Content-Disposition`.** An
  image-family content type served `inline` renders as a document; the same file
  served `attachment` downloads harmlessly. Establish both, from response headers,
  before claiming anything — and treat the disposition as the finding's real subject,
  because the type is often legitimate.
- **Which file types are active documents:** SVG is the canonical case, and it is
  routinely treated as an "image" by both users and product teams while being a
  full XML document that can carry script, event handlers, and external references.
  Treat any upload-allowed type in this class (SVG, and by the same logic other XML
  and markup document types) as a stored-XSS candidate the moment it can be served
  inline. Note the trap in configuration-driven checks: a validator that confirms
  the file *is* a valid image of its declared type may reject the very payload you
  need while permitting the vulnerability in configurations where it does not run,
  so the vulnerable path may be the one that *looks* misconfigured.
- **Check whether application logic overrides the administrator's own setting.**
  The strongest version of this finding is not "an admin could misconfigure it" but
  "the application serves inline **despite** the global setting that says do not
  serve inline." That is a code defect rather than a deployment mistake, and it is
  what moves a finding out of the shoot-yourself-in-the-foot bucket. Read the
  serving code for a hardcoded disposition decision that never consults the
  configuration, and if you find one, that is the root cause — quote the branch.
- **A regression is a different finding from a long-standing gap.** Compare the
  serving logic against the previous stable branch. If inline serving was
  deliberately removed for a newer major line, the finding is a *regression
  introduced by a refactor*, which is both more accurate and considerably more
  likely to be treated seriously than "this was always possible."
- **When demonstrating propagation, show the topology rather than asserting
  self-propagation.** A "worm" claim is credible when you identify the
  user-controlled field that renders for *other* users and propagate one hop: a
  persistent profile field that appears under every post the victim has ever
  written reaches every thread containing those posts, so one infected account
  exposes every reader of them. Demonstrate the mutation, then state the resulting
  reach. Also report the **near-miss controls** you found while building the chain —
  a credential-change field requiring the current password, `HttpOnly` session
  cookies that defeat cookie theft, CSRF tokens correctly enforced. These are what
  distinguish a bounded finding from a maximal one, and stating them up front is
  what makes the parts you *are* claiming credible.
- **Do not let configuration preconditions inflate the classification.** Required
  non-default settings are a legitimate precondition; report them plainly in the
  preconditions section and let severity be scored against them. This is a
  recognised and frequently decisive scoring factor rather than something to argue
  about after triage — see the disposition guidance in `reporting-skill/SKILL.md`.

## Related Concepts

- Unrestricted upload → RCE (extension/MIME/content validation gaps)
- methodology/verification.md (command-output + oracle proof)

## Sources

- PortSwigger lab: Remote code execution via web shell upload (knowledge/portswigger/labs/file-upload-webshell-rce.md)
- PortSwigger lab: Web shell upload via Content-Type restriction bypass (knowledge/portswigger/labs/file-upload-content-type-bypass.md)
- PortSwigger lab: Web shell upload via path traversal (knowledge/portswigger/labs/file-upload-path-traversal.md)
- PortSwigger lab: Web shell upload via obfuscated file extension (knowledge/portswigger/labs/file-upload-obfuscated-extension.md)
- PortSwigger lab: Web shell upload via extension blacklist bypass (knowledge/portswigger/labs/file-upload-extension-blacklist-bypass.md)
- PortSwigger lab: Remote code execution via polyglot web shell upload (knowledge/portswigger/labs/file-upload-polyglot-rce.md)
- PortSwigger lab: Web shell upload via race condition (knowledge/portswigger/labs/file-upload-race-condition.md)
