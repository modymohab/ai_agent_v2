# PortSwigger Lab

## Lab

Basic server-side template injection (code context)

URL: https://0a5100d90421bc13815af3040016000d.web-security-academy.net/

## Vulnerability Class

Server-side template injection, code context – stored preferred-name (`POST /my-account/change-blog-post-author-display`) evaluated as Python/Tornado template expression on blog comment author display → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via code-context template injection. Established by SSTI-lab pattern + `is-solved` flip after `system()`-equivalent trigger. Official description not fetched; engine and context derived from probes + error forensics.

## Initial Observations

- Blog + `/my-account` (wiener:peter, csrf-bound login). One early request used a stale Host header (old lab) – caught immediately (wrong-lab title in response), redone correctly; no state harmed.
- `/my-account?id=wiener` → `change-blog-post-author-display` form (`user.name` / `user.first_name` / `user.nickname` options) – stored preference rendered as blog author display name (current evidence from form label; sink location unknown until tested).
- Stored `methodology/ssti.md` (read – reflected-`message` ERB recipe: syntax matrix, math proof, RCE). No code-context or Tornado knowledge. No prior stored-preference SSTI labs.

## Hypotheses

- H1: Preference value flows into a template evaluated on comment display (stored SSTI). Evidence needed: distinctive submitted value reappears transformed on a post page.
- H2: Engine/family unknown – Twig-first per prior lab, ERB second, Tornado/Python third. Evidence needed: per-family math rendering.
- H3: Code context (value inside executable template code, not output slot) – breakout/bare-expression shape needed, not `{{ }}` wrapping.

## Attempts

1. Baseline `GET /login` (csrf) + `POST /login` → session; `GET /my-account` → preference form mapped (sink candidate, not yet proven).
2. `POST change-blog-post-author-display {{7*7}}` → 302 → posted `probemarker` comment on post 1 → author displayed `{{49}}` – H1 confirmed (stored value evaluated: `7*7`→`49`, braces retained – code-context signature, NOT plain `{{ }}` output slot).
3. `POST` Twig RCE `{{_self.env...exec...}}` (habit from prior labs, unadapted to context) → post page became 500 error page, `is-notsolved` – USEFUL failure: error leaked engine: `tornado/template.py`, Python 2.7, `NameError: _self` (proves Tornado/Python evaluation of our input; Twig assumed wrong).
4. `POST` bare `7*7` → author renders `49` – context mapped: value sits directly as template EXPRESSION (no breakout delimiters needed; braces in attempt 2 were evaluated as Python set literal, explaining `{{49}}`).
5. `POST __import__('os').system('rm /home/carlos/morale.txt')` → author renders `0` (`system()` exit 0 = ran) → `/` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Twig `{{7*7}}` habit (prior-lab shape) – evaluated oddly (`{{49}}`) instead of cleanly; correctly read as context evidence, not pursued with Twig RCE chains.
- Unadapted Twig `_self` RCE – 500, but error forensics named Tornado/Python 2.7 (failure converted to engine fingerprint).

## What Worked

- Stored preference → comment → author-display readback loop (3 requests per cycle); bare-expression math proof (`49`); bare-expression RCE (`0` + solved marker). 8 requests total.

## Burp Observations

- Baseline, login (302 + session), preference form mapping, final proof (`200 is-solved`) via Burp MCP.
- Preference POSTs + comment posting/reading via curl (form ergonomics; same HTTP semantics). Error page captured via curl + text extraction.

## Browser Observations

- Not required. No JS/state workflow; stored value + comment readback suffices.

## CLI / Tool Observations

- `curl --data-urlencode` for preference/comment forms (csrf-bound); `python3` + regex for stripping tags from error/comment pages. No scanner/crawler/fuzzer.

## Root Cause

Stored preference value concatenated into Tornado template executable code (expression slot), evaluated on every render of the author's comments. Attacker string becomes template expression → arbitrary Python (`__import__('os').system(...)`) with app privileges. Stored input + code-context evaluation = SSTI with persistence.

## Verification

- Stored-flow proof: submitted value reappears transformed on a DIFFERENT page (preference POST → post page author line).
- Engine proof: Twig syntax mis-evaluates (`{{49}}` artifact) + error names `tornado/template.py` + bare `7*7`→`49`.
- Execution proof: `system()` renders `0` (exit status) in author line.
- Impact proof: global `is-solved` via fresh anon `GET /`. One variable per cycle (only preference value).

## Impact

Remote code execution as app user (demonstrated file delete; `os.system` runs arbitrary commands). Stored nature widens impact: every viewer of the author's comments triggers evaluation (here self-read suffices for RCE at render).

## Why The Successful Approach Worked

- Proved STORED flow first (distinctive value → readback page) before any exploit syntax.
- Read evaluation artifacts literally (`{{49}}` = set-literal evaluation) instead of forcing prior-lab shapes.
- Converted the 500 into engine forensics (Tornado 2.7) rather than retrying Twig chains.
- Tested bare expression (`7*7`→`49`) to map the exact slot before RCE – one probe defined the payload shape (no delimiters).

## Generalization

- For profile-preference → display-name flows: submit distinctive value → find readback page (comments/posts) → check transformation (literal vs evaluated vs error) → on evaluation, test bare math → on `49`, RCE with engine-native exec (`__import__('os').system` for Tornado/Python).
- `{{49}}`-style artifacts mean set/dict-literal evaluation inside retained braces – submit WITHOUT braces next.
- 500s on template sinks are forensics gold: read framework path/version/name errors before choosing chains.

## Lessons Learned

- Code context inverts the basic-lab recipe: no `{{ }}` wrapping needed – the slot IS the expression. Prior `ssti.md` reflected-message workflow extends with a context-mapping step.
- Stored SSTI needs a write→read loop (preference POST + comment view); each cycle is one hypothesis test.
- Engine families multiply: Twig/ERB matrix now needs a Tornado/Python row (`7*7` bare vs `{{ }}` vs `<%= %>`).

## Related Methodology

- Extends `methodology/ssti.md` (reflected-ERB only – code-context + Tornado + stored-loop pattern missing; update justified below; 2nd SSTI lab, new sub-technique).
- `methodology/injection.md` does NOT apply (template evaluation vs query/shell). Deliberately not modified.
- Priors: `ssti-basic-erb-rce.md` (syntax-matrix + math-proof + marker-proof discipline reused; payload shapes NOT reused – correctly, different engine/context).

## References

- Solved instance: https://0a5100d90421bc13815af3040016000d.web-security-academy.net/
- Lab: https://portswigger.net/web-security/server-side-template-injection/exploiting/lab-server-side-template-injection-basic-code-context
- Deliberately did NOT fetch official solution; engine/context from artifacts + error forensics.
