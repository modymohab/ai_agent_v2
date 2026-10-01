# Root Cause — escaper blind to a later decode stage (entity smuggling)

## The vulnerability
The comment `website` is stored after encoding quotes/brackets/backslashes but NOT
ampersands. At render time the value lands in an `onclick` handler string, and the
victim's HTML parser decodes `&apos;` → `'` while computing the attribute value —
AFTER (downstream of) the server escaper. The smuggled quote terminates the JS
string, and `-alert(1)-` executes when any viewer clicks the author link.

## Root cause (framing)
- **Decode-stage ordering failure**: every output encoding is undone by some LATER
  decoder (HTML entities → attribute computation; URL-encoding → URL parsing;
  JS escapes → string evaluation). An escaper is sound ONLY if it neutralizes its
  OWN metachars (`&` first for HTML-encoding!) against every downstream decoder.
  Leaving `&` raw while encoding `'"<>` is defending the alphabet while surrendering
  the escape hatch that reconstitutes it. Iron rule: **encode `&` FIRST, always** —
  the exact dual of the backslash-first rule.
- Failed assumption: *"encoded output stays encoded."* Output passes through the
  victim parser, which decodes entities as its job. The defense must be evaluated
  at the SINK (post-decode JS text), never at the STORE (pre-decode bytes).
- The `href` twin reflection is inert by comparison (URL navigation, no decode-to-code
  path here) — same value, two contexts, one live. Context decides, again.

## Trust boundary model
```
Attacker POST ──► escaper (handles '"<> \, MISSES &) ──► storage: &apos; intact
                                                                              │
              [TRUST BOUNDARY: stored bytes(data) → decoded attribute(code)]
                                                                              ▼
              victim HTML parser: attribute computation DECODES &apos;→'
                                                                              │
                                                                              ▼
                              onclick handler text now contains live quotes
                                                                              │
                                                                         (click gate)
                                                                              ▼
                                                   expression execution (viewer origin)
```

## Enabling conditions (checklist)
1. Stored (or reflected) value rendered into markup with `&` unencoded (test `&apos;`
   / `&#x27;` / `&quot;` survival in the echo — one probe decides).
2. A code-ish sink downstream of entity decoding (event handlers, `javascript:` URIs
   where `&colon;`/`&Tab;` variants decode, `<script>` text is NOT entity-decoded —
   know which contexts decode: attributes YES, script/style raw-text NO).
3. Clickable (or auto-firing) host for the handler.
4. No CSP blocking inline handlers (none here).

## Decode-context matrix (which sinks see decoded entities?)
| Sink position | Entities decoded? | Smuggling viable? |
|---|---|---|
| double/single-quoted attribute value | YES (`&apos;`→`'`) | YES — this lab |
| unquoted attribute value | YES | YES |
| element text | YES | YES (for markup, not code) |
| `<script>` / `<style>` raw text | NO | NO — entities stay literal |
| JS string at runtime | n/a (already parsed) | only via an earlier HTML-decode stage |
| URL bar / location | separate `%`-decoding | different smuggle alphabet (`%27` stays literal in HTML) |