# Root Cause — innerHTML sink sourced from location.search

## The vulnerability
The client-side script reads `location.search` and assigns the decoded value directly to
`element.innerHTML`. The value is parsed as HTML fragment children of `#searchMessage`,
so attacker-controlled markup becomes live DOM — including executable event handlers.

## Root cause (framing)
- **Insecure sink API used for untrusted data**: `innerHTML` is a markup-parsing assignment.
  Assigning URL-derived strings to it is equivalent to handing the attacker a fragment of
  the page's DOM. Safe alternatives: `textContent` (renders as inert text), or
  `createElement` + property assignment.
- **Dangerous source read**: `location.search` is attacker-controllable via the URL.
- **Missing boundary**: no sanitization, no allow-list, no `Trusted Types` policy, no CSP
  between the source read and the sink assignment.
- The failed assumption (same as all DOM XSS): *"a JS string stays data when placed into
  the DOM."* The fragment parser re-interprets it as code. The boundary is **entirely
  client-side** — server response is identical for benign and malicious queries, so no
  server control can fix this path.

## Trust boundary model
```
Attacker URL ──► location.search ──► URLSearchParams.get ──► JS string (data)
                                                                    │
              [TRUST BOUNDARY: string(data) → parsed fragment(code)]
                                                                    ▼
                        el.innerHTML = query → fragment parser → live elements
                                                                    │
                                                                    ▼
                                              event-handler execution (victim origin)
```

## The sink-semantics subtlety (core lesson of this lab)
`innerHTML` parses markup but deliberately neuters `<script>` execution, while leaving
event handlers, `<iframe srcdoc>`, `<object>/<embed>`, `<form>`+`formaction`, `<meta
http-equiv=refresh>`, SVG animations (`<animate onbegin=…>`) and similar vectors live.
Therefore:
- "HTML injection" via innerHTML ≠ "script-tag execution". The exploit primitive is the
  **event-handler attribute**, not the script element.
- Defenses that strip only `<script>` (naive regex/WAF) remain bypassable through this
  sink — the fix must be sink-level (textContent / sanitizer / Trusted Types), not
  payload-blacklist-level.

## Enabling conditions (checklist)
1. `innerHTML` (or sibling: `outerHTML`, `insertAdjacentHTML`, jQuery `.html()`)
   assigned a URL-influenced string.
2. Assignment target is element content (no breakout needed) or an interpolated context
   (breakout needed — same rule as other sinks).
3. No sanitizer / DOMPurify / Trusted Types on the path.
4. No CSP blocking inline handlers (`on*` attributes) — absent here, so classic
   `<img src=x onerror=…>` works; under CSP, fall to `javascript:`-free vectors or
   policy gaps (see class notes).