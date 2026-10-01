# Impact — SVG animateTransform/onbegin filter gap

## Applicability reasoning
The input (`search`) is echoed into page markup; the filter rejects listed tags and
common handlers (400) but passes the unlisted SVG pair, whose SMIL begin-event
executes attacker JS in the victim's browser on the application origin at page load.
Relevant categories: **client-side, filter-gapped, link-delivered, interaction-free**.
No storage, no state change, no non-HTML consumer.

## CONFIRMED
- **Load-time code execution at the application origin** on crafted-URL visit, zero
  interaction (title-mutation proof; real `alert(1)` + acceptance).
- **Filter bypass without evasion tricks**: no case/separator/encoding games — the
  payload is plain, well-formed SVG that the filter simply doesn't list. Bypass by
  ontology gap, not by obfuscation.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** (cookies, tokens, storage, page secrets;
  authenticated actions as victim).
- **Admin compromise** via crafted search link (tickets, shared links).
- **Sibling SMIL handlers** (`onend`, `onrepeat` — same unlisted family, untested;
  likely identical bypass value).
- **Sibling unlisted SVG elements** as alternate hosts (the 9 passing tags each take
  `onbegin` where the event model allows).
- **Keylogging / credential capture / phishing overlays** (standard post-execution set).

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| Listed tags/handlers as vectors | NOT APPLICABLE (disproven ~40 probes) | 400 matrix |
| `<image src=x onerror>` shortcut | NOT APPLICABLE (disproven) | `onerror` listed (tag was innocent) |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | echo only |
| Stored/persistent delivery | NOT APPLICABLE | per-request echo |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | side-effect-free GET |
| Click/hover-gating | NOT APPLICABLE | SMIL-begin fires at load |

## NOT TESTED
- `onend`/`onrepeat` and other SMIL-event spellings (same family as `onbegin`;
  highly likely unlisted — flagged, unfired).
- Full SVG/MathML element boundary (25 tags mapped; exotic remainder unmapped).
- Other params/endpoints under the same filter (only `search` mapped).
- CSP interplay (no CSP here).

## What would increase impact in a real application
- **Authenticated app + shareable search URLs** (help centers, docs, support portals
  echoing queries) → organic victim flow to crafted links.
- **SVG-accepting rich content** (avatars, diagrams, pasted markup with SVG allowed)
  under the same list philosophy → stored variants of this gap.
- **Verbose 400-vs-200 differentials** (the oracle that makes mapping cheap — silent
  strip-filters slow attackers but don't stop them).
- **HTML-centric filter culture** (audits covering `<script>/<img>/<svg>` + `onload/
  onerror` while SMIL/MathML/custom-element vocabularies go unreviewed).
- **Missing HttpOnly** → trivial cookie read (here HttpOnly present → in-context
  actions instead).

## Lab-scoped confirmed impact
`alert()` via search-term SVG/SMIL vector — accepted first poll.