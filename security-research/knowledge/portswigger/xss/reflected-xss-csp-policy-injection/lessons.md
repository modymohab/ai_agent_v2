# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a Content-Security-Policy header contains attacker-influenced bytes
> (report-uri tokens/URLs, reflected nonces, echoed policy endpoints), test `;`
> injection: CSP splits directives on `;` BEFORE considering value contexts, so one
> semicolon promotes URL data into live policy. Forge the narrowest directive that
> restores YOUR sink (`script-src-elem 'unsafe-inline'` for inline `<script>`) and
> prove with a blocked-vs-bypassed A/B pair. A bypassable CSP contributes nothing —
> assess impact as unprotected XSS.**

Coupled rules:
1. **Headers are injection surfaces with their own grammars**: map attacker bytes
   in EVERY security header (CSP, Report-To, Permissions-Policy, HSTS,
   Content-Type-Options values) against that header's delimiter set (`;`, `,`, whitespace).
2. **A/B or it didn't happen**: baseline (payload, no injection → blocked) then
   bypass (same payload + injection → fires). Single-variable proof separates
   "CSP was irrelevant" from "CSP was defeated" — the distinction the whole lab
   turns on.
3. **Directive-combination literacy**: injected directives INTERACT with existing
   ones (`script-src-elem` overrides `script-src` for elements; multiple
   `script-src` intersect; first `report-uri` wins). Know which smuggled directive
   actually changes enforcement for your sink — don't assume additive loosening.
4. **Browser-gate awareness**: `script-src-elem` is Chromium-gated (hence
   Chrome-only); test the matrix per engine before claiming generality.

## Recon indicators (how to find this class again)
- CSP headers with query-ish values (`report-uri ...?token=`, `...?id=`, nonces
  that look echoed, `Report-To` JSON containing request data).
- `report-uri`/`report-to` + user-influenced correlation IDs (the classic shape).
- Policies that look TEMPLATE-built (values mirroring request params — diff the
  header across two requests with different param values).
- Reflected XSS + CSP present (the combination that MOTIVATES policy-injection
  hunting — without a sink needing bypass, the primitive is latent).

## Verification techniques (reusable)
1. **Marker-in-header proof** (`token=TOKENMARK` → header grep) before any bypass.
2. **A/B block-vs-execute** with title markers (never dialogs in harnesses).
3. **Injected-bytes header dump** (prove the forged directive survives verbatim).
4. **Real-browser acceptance** to close (alert needs no special casing here).
5. **Sound-clause inventory** (`object-src 'none'` held — record what the policy
   still enforces; bypass ≠ total collapse claims).

## Common mistakes that miss this
- **Treating CSP as a verdict** ("script-src 'self' ⇒ inline dead, move on")
  without checking whether the POLICY ITSELF is attacker-influenced.
- **Fuzzing only the page** (search param) while the second input (`token`) sits
  in the header — two-input vulnerabilities need two-input recon (headers AND body).
- **Forgetting `;` is policy syntax** (encoding alphanumerics while leaving the
  delimiter — the header analogue of forgetting `'` in markup).
- **Assuming additive loosening** (some injected directives do nothing due to
  intersection/first-wins semantics — verify enforcement change, i.e., the A/B).
- **Over-claiming cross-browser** (Chrome-only primitive presented as universal).
- **Missing the sound clauses** (claiming "CSP bypassed" when `object-src` etc.
  still constrain — scope the bypass to what changed).

## Cross-cutting
- Delimiter-breakout trilogy now spans grammars: HTML (`'"<>`), JS/template
  (quotes/backslash/braces), and POLICY (`;`) — same primitive (unlisted delimiter
  in attacker-controlled bytes), three parsers. Future grammars (CSS, JSONP
  callbacks, SVG, MathML, HTTP/2 pseudo-headers?) slot into the identical audit:
  find attacker bytes → list the grammar's delimiters → test each → compose.
- Twenty-two labs; the invariant method extends to headers without modification:
  sweep (params AND headers) → per-context/delimiter map → family-correct payload →
  A/B proof → negatives → knowledge. The method's input domain just widened from
  bodies to headers.