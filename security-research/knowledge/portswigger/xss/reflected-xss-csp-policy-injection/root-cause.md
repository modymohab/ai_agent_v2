# Root Cause — delimiter-naive policy construction (CSP injection)

## The vulnerability
The application builds its `Content-Security-Policy` response header by string-
interpolating the attacker-controlled `token` query parameter into the `report-uri`
directive value without sanitizing the policy delimiter (`;`). Browsers split CSP
headers into directives on `;` before interpreting values, so attacker syntax escapes
the value context and becomes live policy — here a forged `script-src-elem
'unsafe-inline'` that re-permits the inline script the policy was deployed to stop.

## Root cause (framing)
- **Injection at a new layer**: all prior KB injections targeted HTML/JS/URL/CSS
  parsers; this one targets the CSP POLICY parser — same primitive (delimiter
  breakout: `;` plays the role `'"<>` played elsewhere), new grammar. Any
  attacker-influenced header bytes must be treated as an injection surface with the
  header's OWN delimiter set.
- **Value-context naivety**: `report-uri <url>` looks like a safe sink for arbitrary
  strings (it's "just a URL"), but CSP has no quoting/escaping mechanism for
  directive values — a `;` (or `,` in some positions) ALWAYS terminates the value.
  There is no safe way to embed attacker data in a CSP header except strict
  allow-listing (e.g., hex tokens) — the token here is unbounded.
- Failed assumption: *"header values are data."* True only until a delimiter the
  downstream parser honors. The policy parser honors `;` unconditionally.
- Bitter irony, precisely stated: the defense designed to CONTAIN the reflected XSS
  is itself constructed from the same untrusted input, so one payload defeats both
  layers at once (`search` beats the page, `token` beats the policy).

## Trust boundary model
```
Attacker URL ──► token param ──► header string concat (data?)
                                                        │
              [TRUST BOUNDARY: header value(data) → policy directive(code)]
                                                        ▼
                    report-uri …token= ; script-src-elem 'unsafe-inline'
                                          ▲ split here (policy parser)
                                                        │
                                                        ▼
                              forged directive permits inline <script>
                                                        │
                                                        ▼
                                              echo executes (page origin)
```

## Enabling conditions (checklist)
1. Attacker-influenced bytes in a CSP header (report-uri tokens/URLs, nonce values
   reflected, policy endpoints echoing params, `Report-To` JSON endpoints).
2. Delimiter (`;`, sometimes `,`) surviving into the header (no allow-listing).
3. A smuggleable directive that changes enforcement for YOUR sink
   (`script-src-elem`/`script-src` + `unsafe-inline` for inline scripts;
   `object-src`/`frame-src`/`form-action`/`base-uri`/`navigate-to` for others;
   `report-uri` itself is inert for execution).
4. Browser support for the forged directive (Chrome-only here — verify per engine).

## Fix shape (recognition = know the fix)
Strict allow-list token formats (hex/alphanumeric, fixed length) or drop attacker
data from the policy entirely (server-side token store keyed by session). Never
interpolate request data into security headers without delimiter-stripping.