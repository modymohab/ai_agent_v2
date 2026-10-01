# PortSwigger Lab

## Lab

Exploiting XXE to retrieve data by repurposing a local DTD

URL: https://0add008703ed911a80f767e0007800c6.web-security-academy.net/

## Vulnerability Class

XXE injection, blind error-based exfiltration via repurposed LOCAL DTD – no exploit server; `docbookx.dtd`'s `%ISOamso;` reference hijacked by internal redefinition carrying nested file/eval/error entities → `FileNotFoundException` embeds file content

## Objective

Retrieve `/etc/passwd` via local-DTD error (demonstration lab – solved by error content itself). Established by `is-solved` flip immediately after the repurposed-DTD trigger. Official solution consulted for exact entity name/shape only after genuine stuck point (see Attempts).

## Initial Observations

- Shop + XML stock-check (`POST /product/stock`) – same sink shape as 8 prior XXE labs (current evidence from product page).
- Baseline (`productId=1,storeId=1`) → 200 `20` (count oracle).
- General file entity (`&xxe;` in body) → `400 "Invalid product ID"` generic (parsed, blind – no block message here, unlike parameter-entities lab).
- No exploit-server link on page (only Home) – external DTD impossible; local DTD repurposing REQUIRED (title direction).
- Stored `methodology/xxe.md` (8 shapes; no local-DTD section). No prior local-DTD labs.

## Hypotheses

- H1: `file:///usr/share/yelp/dtd/docbookx.dtd` exists and its `%ISOamso;`-style reference can be hijacked by internal redefinition. Evidence needed: include alone parses (200/FileNotFound, not syntax error).
- H2: Redefinition value carrying nested file/eval/error entities (all `%` escaped) expands in external context → content-embedding error. Evidence needed: passwd bytes in error.
- H3: Exact entity NAME matters (`ISOamso` vs lookalikes) – wrong names silently change behavior.

## Attempts

1. Baseline product page + baseline POST (`20`) – sink + shape in 2 requests.
2. General-entity blindness probe → generic `Invalid product ID` – blind parser confirmed (no hardening message).
3. Local-DTD include alone (`% local_dtd` spaced decl+ref) → 200 – DTD exists + parses (later understood: length luck; discipline fixed below).
4. ISOamsa (WRONG NAME, `amsa` vs `amso`) redefinition attempts → confusing col-72/159/252/304/324 errors – root cause unrecognized at the time (name wrong, so docbookx behavior never engaged; errors misattributed to spacing/syntax).
5. Spacing matrix (spaced vs unspaced decls/refs) + P1/P2 bisection + name sweep (`eval`, `eee`, `my_ent`, `abcdefghi`, `local_dtd2`) – mapped a PHANTOM name-dependence (`local_dtd`-only works) that was actually an artifact of hand-counted `Content-Length` mismatches (218 vs true 213 etc.) compounded by the wrong entity name. Valuable negatively: proved length discipline + exact-name discipline by failure.
6. Consulted official solution (genuinely stuck: ~15 requests, contradictory parser behavior) → corrections: entity is `ISOamso`, full nested chain lives INSIDE its value with `&#x25;`/`&#x27;` escapes, `<!DOCTYPE message` + newlines shape.
7. Fixed transcription (`&#x27;` both quotes, not `&#27;` control char – caught via `invalid XML character` error) → `FileNotFoundException: /nonexistent/root:x:0:0...` (FULL passwd) – H1+H2 confirmed.
8. `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- `ISOamsa` (wrong name) + hand-counted lengths + unescaped nesting – a triple confound that produced phantom parser rules (name-dependence, space-dependence). Each was individually plausible; combined they were undebuggable until the documented shape reset the experiment.
- `% xxe;`-style spacing superstition carried from parameter-entities lab – irrelevant here (documented shape uses spaced decls, works).

## What Worked

- Documented repurposing shape (exact names/escapes/newlines, machine-measured length 416) → content error → solved marker. One clean request after reset.

## Burp Observations

- Baseline, blindness probe, include probe, iterative variants, final trigger, proof – all via Burp MCP. Error-column forensics (`col 72/159/...`, `&#27 invalid character`) guided each fix once lengths were trusted.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `python3` for machine-measured `Content-Length` (the fix for hand-count poisoning) + payload file generation. No crawler/fuzzer (single known endpoint).

## Root Cause

Parser resolves local `file://` DTDs and honors internal-subset redefinition of entities the DTD references (`%ISOamso;`): attacker value smuggles nested file/eval/error entity definitions (all `%` escaped for internal-subset legality) that expand in external-subset context → file content embedded in `FileNotFoundException` path. No network, no exploit server – pure local composition.

## Verification

- Include-alone probe (DTD exists/parses) → redefinition probe (behavior change proves the reference is live) → content error (full passwd, not partial) → global `is-solved` via fresh anon `GET /`.
- Each stage distinguished: existence (200) vs engagement (behavior change on redefine) vs exfiltration (content in error).

## Impact

Blind arbitrary file read without any network egress or reflection channel (demonstrated full `/etc/passwd`). Defeats external-DTD blocks and air-gap assumptions – only local DTD presence required. Same primitive reads any `file://` path by editing one line.

## Why The Successful Approach Worked

- Reset to the documented shape after recognizing confounded debugging (wrong name + wrong lengths + superstition = phantom rules).
- Fixed transcription precisely (`&#x27;` vs `&#27` via `invalid XML character` error) instead of reshaping blindly.
- Machine-measured every length after discovering hand-count poisoning – removed an entire error class.

## Generalization

- For repurposed-local-DTD labs: include-alone probe (existence) → redefine the DOCUMENTED entity name EXACTLY (`ISOamso` ≠ `ISOamsa` – one letter kills the chain silently) → nest the ENTIRE exfil chain inside its value with `&#x25;`/`&#x27;` escapes → machine-measure lengths → content error → marker.
- When parser behavior seems self-contradictory (name/space superstitions), suspect confounded variables (lengths, names) and reset to a known-good documented shape rather than theorizing new parser rules.
- `invalid XML character` errors name the exact bad reference – fix transcription, not structure.

## Lessons Learned

- Exactness compounds in nested-DTD payloads: name (one letter), escapes (`&#x27;` vs `&#27;`), lengths (machine-measured) – three independent exactness axes, each silently fatal.
- Confounded debugging produces phantom rules (name-dependence, space-dependence); the cure is a documented-shape reset + single-variable retest, not more theory.
- Stuck-clause consultation is a tool: ~15 requests of contradictory evidence justified reading the solution's exact bytes (then still verified independently).

## Related Methodology

- Extends `methodology/xxe.md` (no local-DTD repurposing pattern – update justified below; 9th XXE lab, new no-network exfil primitive).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: `xxe-blind-error-based-exfiltration.md` (file/eval/exfil trio concept reused; external→local adaptation), all XXE notes (endpoint/slot/length recipe; length discipline upgraded to machine-measured).

## References

- Solved instance: https://0add008703ed911a80f767e0007800c6.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/blind/lab-xxe-trigger-error-message-by-repurposing-local-dtd
- Key shape (verified): `docbookx.dtd` + `ISOamso` redefinition + nested `&#x25;`/`&#x27;`-escaped chain + `<!DOCTYPE message` + newlines + exact length (416 here)
- Deliberately shaped final payload from official solution's exact bytes after genuine stuck point (phantom-rule debugging); verified by content error + marker.
