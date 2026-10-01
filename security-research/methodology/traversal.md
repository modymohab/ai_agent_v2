# Traversal Methodology

## Core Concept

Path traversal (file read) occurs when a file-returning parameter is resolved against a base directory without normalization: `/image?filename=..%2f..%2f..%2fetc%2fpasswd` escapes the web root and returns `/etc/passwd`. Distinct from upload-side traversal (placement) — this is READ disclosure.

## Security Boundary

Intended: file reads confined to the asset directory.
Violated when: `filename=<../-sequence>` returns files outside it (e.g. `/etc/passwd` with 200).

## Recognition Patterns

- File-returning params (`/image?filename=<N>.jpg`, download/preview endpoints).
- Baseline oracle shape (200 + content-type + size, e.g. 179KB jpeg).
- No login/submit surface — solved-on-display labs.
- Sequence-block oracle (400 `No such file` on `../`) implying absolute-path hole.
- Sequence-STRIP oracle (same 400, but defense removes rather than rejects): nested `....//` survives one pass as `../`.
- Legitimate values already ABSOLUTE with a fixed prefix (`/var/www/images/...`): start-of-path allowlist — preserve prefix, append escape.
- Extension-gate oracle (bare `/etc/passwd` → 400): allowlist (`.jpg`/`.png`) + null-byte truncation (`%00.jpg`) + traversal depth.

## Common Locations

- `/image?filename=`, `/download?file=`, `/preview?path=`, static-asset handlers.

## Indicators

- Content + size + type differential: baseline image vs `root:x:0:0…` text (2316B) on one variable.
- Solved marker flips on display (`is-notsolved` → `is-solved`).

## Testing Methodology

0. **Blanket file-surface probe (do this FIRST, before committing to any single param's deeper methodology).** Enumerate every file-returning or file-referencing surface recon found — not just obvious `?filename=`/`?file=`/`?path=` params, but also upload-preview/download endpoints, template/theme/language-selector params, log-viewer or export/report-generation features, archive-extraction endpoints, avatar/attachment serving paths, and any JWT `kid`-style header that names a file. Fire a fast, low-cost baseline traversal probe (`../../../../etc/passwd` plain, `..%2f` ×3, and one absolute-path attempt) at EACH surface as a quick sweep, before working any single surface through the full depth/encoding/null-byte matrix below. Record per surface: blocked (400 "No such file" — candidate for step 5), stripped (silently ignored/collapsed — candidate for step 6), gate/extension-rejected (candidate for step 8), no visible traversal effect (still worth a manual look — see the leakage note below), or immediate hit. This first pass triages where the deeper matrix (steps 2–8) is worth spending effort; it does not itself replace that matrix or constitute a finding on its own.
   - **Don't narrow the objective to `/etc/passwd` alone.** That file is the standard PROOF target because its content is unambiguous, but the actual security-relevant leakage on a real target is just as often: application source files, `.env`/config files, credentials or API keys in config, log files containing other users' data, backup files (`.bak`, `~`, `.old`), or internal-only documents. Once a traversal primitive is confirmed via `/etc/passwd` (or an equivalent unambiguous low-sensitivity file), widen the read to check for these — that's where the actual impact usually lives, not in reading `/etc/passwd` itself. Note this doesn't relax the Verification section's rule below about not reading production PII/credentials for the PROOF step — proof uses the low-sensitivity file; the impact write-up is what documents what else was reachable, per `impact-analysis-skill/SKILL.md`'s demonstrated-vs-potential distinction.
1. Baseline legitimate file (record status/type/size).
2. Build traversal URLs LITERALLY (single param — `--data-urlencode` on URLs already carrying the key creates duplicates that mimic filters).
3. Matrix depths (`../` ×N) and encodings (`..%2f`, `..%2F`, `....//`, absolute `/etc/passwd`); target `/etc/passwd` first.
4. Verify content (`root:`) + solved marker; deterministic re-request.
5. Sequence-block extension: on `../`-rejection oracle (400 `No such file`), try ABSOLUTE path first (needs no sequences), then nested/encoded variants only if absolute fails. Map the three-way oracle (baseline/blocked/bypass).
6. Non-recursive-strip extension: on strip-behavior evidence, try NESTED `....//` (and `..././`) first — one pass collapses them into live `../`. Absolute path remains a parallel option; test both, keep the hit.
7. Start-of-path extension: when legitimate values carry a fixed prefix, preserve it verbatim and append `/../` escapes (`/var/www/images/../../../etc/passwd`) — satisfy-then-escape, often first-try.
8. Extension + null-byte extension: on extension-gate 400s, combine traversal depth × null-suffixed extensions (`..%2f..%2f..%2fetc%2fpasswd%00.jpg`, both `.jpg`/`.png`); absolute and relative are INDEPENDENT axes (absolute may fail where relative+depth succeeds and vice versa); escalate depth before abandoning the technique (depth-400 vs gate-400 look identical).

## Verification

- Prove with file CONTENT (passwd lines), not status alone; rule out tooling contamination by comparing failing shapes against the baseline oracle.
- Solved-on-display needs no submission — marker is the oracle.

## Common Failure Modes

- Duplicate query params from helper flags (`--data-urlencode` over a URL already holding the key) — false 404s mistaken for filters.
- Assuming traversal depth — escalate N until content appears.
- Conflating with upload-side traversal (different class, different methodology file).

## Impact Considerations

- Arbitrary local file read (demonstrated `/etc/passwd`); configs/keys/source in real estates.
- **The same-party exception (calibrate before filing).** Traversal only carries
  impact when it reaches a party the attacker cannot already reach. If the
  untrusted party is *also* the content-serving party — a malicious or MITM'd
  server, a hostile directory listing, an attacker-controlled index — it can
  already return arbitrary content for the path the client legitimately requests.
  Forcing the client down a different path first grants no new capability.
  Such findings close as **Informative** ("a bug to fix") even when the code
  analysis is exact, and the project may still ship a fix.
- **Where it *is* reportable:** the destination is a *different* trust domain from
  the requester — a jailed/chrooted directory on a shared host, another tenant's
  path, a local file the client could not otherwise name, or an allowlist/prefix
  check the traversal defeats. The distinguishing test is
  **"who controls the bytes at the traversed destination?"**
- Real, low-severity-by-default class: escaping a `prefix + path` validation while
  the destination is still a legitimately-served file. That is a containment
  defect, not a disclosure, unless the contained area was meant to be private.

## Lessons Learned

- From PortSwigger “File path traversal, simple case”: clean `..%2f`×3 → 200 `root:x:0…` (2316B) + `is-solved`; 5 early 404s were self-inflicted duplicate params, not a filter.
- From PortSwigger “File path traversal, traversal sequences blocked with absolute path bypass”: `..%2f`×3 → 400 `No such file`; absolute `/etc/passwd` → 200 `root:x:0…` (2316B) + `is-solved` in 4 requests. Read bypass off the block message.
- From PortSwigger “File path traversal, traversal sequences stripped non-recursively”: `..%2f`×3 → 400 `No such file` (strip, not block); nested `....%2f%2f`×3 → 200 `root:x:0…` (2316B) + `is-solved` in 4 requests. Sanitizer behavior dictates bypass shape.
- From PortSwigger “File path traversal, validation of start of path”: legitimate absolute `/var/www/images/20.jpg` (184KB jpeg); prefix + `/../../../etc/passwd` → 200 `root:x:0…` + `is-solved` in 3 requests. Satisfy-then-escape.
- From PortSwigger “File path traversal, validation of file extension with null byte bypass”: bare `/etc/passwd` → 400 (extension gate); absolute+null → 400 (relative required); `..%2f`×3 + `etc%2fpasswd%00.jpg/.png` → 200 `root:x:0…` + `is-solved`. Compose null-byte with depth; absolute and relative are independent axes.
- **Calibration, public triage (volunteer-OSS project, closed Informative).** A
  precise analysis of a wildcard-FTP path-traversal defect — an `escape()` then
  `urldecode()` round-trip that reconstructs `../` because `.` survives
  percent-encoding, with no `..` filtering in the path parser — was dismissed on a
  single sentence: a malicious server that can return bad filenames can already
  serve anything it wants on the path the client requested, so redirecting the
  client first grants no new capability. The reporter agreed, re-verified which
  releases were actually affected, and accepted the classification. A fix shipped
  anyway. Lesson: the diagnosis can be flawless and the finding still be
  non-vulnerable — demonstrated capability outranks mechanism severity. That
  project also carries **no monetary rewards at all** and publishes every report,
  which is worth checking *before* investing effort, not after. See
  `impact-analysis-skill/SKILL.md` Step 11 (Calibration case A).

## Related Concepts

- Upload-side traversal placement (methodology/file-security.md — WRITE class, contrast)
- methodology/verification.md (baseline-shape comparison + contamination checks)

## Sources

- PortSwigger lab: File path traversal, simple case (knowledge/portswigger/labs/traversal-simple-case.md)
- PortSwigger lab: File path traversal, traversal sequences blocked with absolute path bypass (knowledge/portswigger/labs/traversal-absolute-path-bypass.md)
- PortSwigger lab: File path traversal, traversal sequences stripped non-recursively (knowledge/portswigger/labs/traversal-sequences-stripped-nonrecursively.md)
- PortSwigger lab: File path traversal, validation of start of path (knowledge/portswigger/labs/traversal-validate-start-of-path.md)
- PortSwigger lab: File path traversal, validation of file extension with null byte bypass (knowledge/portswigger/labs/traversal-extension-null-byte.md)
