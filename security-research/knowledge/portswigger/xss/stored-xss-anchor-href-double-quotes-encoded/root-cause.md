# Root Cause — quote-encoding without URI-scheme validation on href

## The vulnerability
The comment `website` field is persisted and rendered as an anchor `href` with only
`"` entity-encoded. No validation restricts the URI scheme, so the stored value can be
a complete `javascript:` URI that executes whenever any post viewer clicks the author
name.

## Root cause (framing)
- **Right encoding, wrong threat model**: `"`→`&quot;` correctly kills
  ATTRIBUTE-BREAKOUT — then the code stops defending. But `href` has TWO attacker
  degrees of freedom (break OUT of the value vs. BE the value), and only the first was
  closed. Defenses must cover the sink's full semantics, not just its delimiters.
- **Missing boundary**: no allow-list (`http(s)` + relative), no scheme blocklist
  (`javascript:`/`data:`/`vbscript:`), at input or render time. The client form in this
  build doesn't even carry the `pattern="(http:|https:).+"` hint the earlier build had
  (which was client-only anyway).
- Failed assumption: *"encoded quotes make an href safe."* True only against breakout;
  meaningless against whole-value scheme abuse. The general form: **encoding delimiters
  never substitutes for validating values in scheme-interpreting sinks**.

## Trust boundary model
```
Attacker POST ──► validation: presence-only ──► storage (data at rest)
                                                            │
                        [TRUST BOUNDARY: stored string(data) → link target(code)]
                                                            ▼
                        <a href="javascript:…"> rendered to every viewer
                                                            │  (click gate)
                                                            ▼
                                              navigation → execution (viewer origin)
```

## Why this is worse than its DOM cousin (jQuery-href lab)
Same payload family and same click gate — but STORAGE upgrades delivery: no crafted
link per victim, no luring off-site. Victims arrive organically (blog readers) and the
lure is native page UI (an author name). One store → all future viewers, indefinitely.
Stored × navigation is the highest-conversion link-free XSS shape in this KB.

## Enabling conditions (checklist)
1. User-controlled string persisted and rendered into `href`/`src`/`action`/`location`.
2. Delimiter encoding present but scheme validation absent (the signature gap).
3. A clickable rendering (author name, avatar link, "source" link) — interaction gate
   with native-trust lure.
4. No CSP `navigate-to` / scheme controls (none here).