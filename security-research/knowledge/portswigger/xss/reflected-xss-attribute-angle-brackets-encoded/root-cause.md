# Root Cause — partial output encoding (quotes left raw in attribute)

## The vulnerability
The server reflects the `search` parameter into a double-quoted `value` attribute while
encoding only angle brackets (`<`→`&lt;`, `>`→`&gt;`). Double (and single) quotes pass
through raw, so an attacker terminates the attribute and injects event-handler
attributes that execute on page load via `autofocus`.

## Root cause (framing)
- **Incomplete context-aware output encoding**: the template encodes for a TEXT context
  (`<>` neutralization stops tag injection) but the value actually sits in an ATTRIBUTE
  context, which additionally requires quote encoding (`"`→`&quot;`). Encoding for the
  wrong context = no encoding at all for the operative breakout character.
- Note the asymmetry that proves the point: the sibling `<h1>` reflection encodes
  `" ' < > &` fully (safe), while the `value` reflection encodes only `<>`. Same
  developer, same template, per-location inconsistency — the exact coverage-gap pattern
  seen in the stored-XSS lab, now server-side.
- Failed assumption: *"`<`/`>` filtering makes reflections safe."* It makes TAG
  injection safe; attribute-breakout with event handlers never uses angle brackets.

## Trust boundary model
```
Attacker URL ──► GET param ──► server template concat (data)
                                              │
        [TRUST BOUNDARY: template text(data) → response markup(code)]
                                              ▼
              value="ATTACKER" autofocus onfocus="…"  →  victim parser
                                              │
                                              ▼
                        autofocus → focus event → handler (app origin)
```

## The general rule this lab exists to teach
Output encoding must match the SINK CONTEXT, and every reflection point needs its own
check:
| Reflection context | Must encode | If only `<>` encoded, breakout with |
|---|---|---|
| element text (`<p>`, `<h1>`) | `& < >` (+ quotes harmless to add) | (nothing — need `<` for tags) |
| double-quoted attribute | `& " < >` | `"` + event handler |
| single-quoted attribute | `& ' < >` | `'` + event handler |
| unquoted attribute | everything incl. whitespace, `=`, backtick | space / `/` + handler |
| JS string | `\ ' " < > & /` + line breaks | `'`, `</script>`, `\` |

## Enabling conditions (checklist)
1. Server reflection of request data into markup (any param, header, path — here `search`).
2. At least one reflection whose encoding omits the context's breakout set.
3. A load-time trigger available without angle brackets (`autofocus`, `onfocus` on
   `<body>`/focusable, `<details open ontoggle>`, `<marquee loop=1 behavior=slide …>`
   variants where permitted, or plain user-interaction handlers for lower conversion).
4. No CSP blocking inline handlers (none here).