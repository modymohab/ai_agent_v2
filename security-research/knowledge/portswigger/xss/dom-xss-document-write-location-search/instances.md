# Instances — re-confirmations of this lab pattern on fresh targets

This lab's pattern (DOM XSS: `location.search` → `document.write` attribute-context
sink) is deterministic per lab build. Each fresh instance below was independently
reconnoitered (sink code re-read, SSR reflection re-mapped) and re-exploited rather
than assumed identical from the title.

## Instance 1 (canonical workup)
- Target: `https://0a7700dc03d3367d805303aa005b00ca.web-security-academy.net/`
- Date: 2026-09-19 — SOLVED
- Full workup in: `metadata.md`, `attack-chain.md`, `root-cause.md`,
  `verification.md`, `impact.md`, `lessons.md`.
- Vectors CONFIRMED here: tag-close (`"><script>…`) AND attribute event-handler
  (`" autofocus onfocus=…`).
- Edge semantics mapped here: browser `%25`→`%` normalization, `URLSearchParams`
  single-decode, SSR `<h1>` fully encoded.

## Instance 2 (pattern re-confirmation)
- Target: `https://0ac1003a04ee9e4e803512b7009300b2.web-security-academy.net/`
- Date: 2026-09-19 — SOLVED (`is-solved`, 4/4 polls)
- Recon (not assumed): sink code byte-identical in structure
  (`trackSearch` / `URLSearchParams(...).get('search')` / `document.write('<img
  src="…tracker.gif?searchTerms='+query+'">')`); SSR `<h1>` re-checked with
  `ssrCHK</h1>"'` → `ssrCHK&lt;/h1&gt;&quot;&apos;` (encoded, not a sink).
- Execution proof: `/?search=%22%3E%3Cscript%3Edocument.title%3D'DOMXSSFIRED_LAB3'%3C/script%3E`
  → `<title>DOMXSSFIRED_LAB3</title>` in headless dump; written img
  `<img src="…searchTerms=">` confirms the `">` breakout shape.
- Lab acceptance: real-browser navigation to `?search=%22%3E%3Cscript%3Ealert(1)%3C/script%3E`
  → alert fired → `is-solved`.
- Attribute event-handler vector on THIS instance: PLAUSIBLE by code identity
  (same sink bytes as Instance 1 where it was CONFIRMED); not re-fired here since
  the script vector already satisfied lab acceptance.

## Takeaway for future agents
When the same lab/vuln-class recurs on a new target, the transferable artifact is the
**context→primitive rule** (`"` + `>` breakout in a double-quoted document.write
attribute), not the literal URL. Re-verify the sink code on each new target — one
`grep` of the inline script — then re-apply the rule. That single check is what
separates pattern reuse from blind copying.