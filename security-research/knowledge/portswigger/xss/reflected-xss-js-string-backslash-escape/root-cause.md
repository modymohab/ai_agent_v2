# Root Cause — escaper ordering failure (backslash must be escaped first)

## The vulnerability
The search term is echoed into a single-quoted JavaScript string by an escaper that
neutralizes `'` (→`\'`) and `<>` (→entities) but passes `\` through raw. A leading
backslash in attacker input collapses with the escaper's own escape backslash
(`\\` → one literal), freeing the following `'` to terminate the string — the
escaper manufactures the very terminator it was built to suppress.

## Root cause (framing)
- **Escaping-order violation**: the iron rule of string escapers is ESCAPE THE
  ESCAPE CHARACTER FIRST (`\` → `\\`, THEN `'` → `\'`). This escaper handles quotes
  (and brackets) while skipping backslashes — precisely backwards. Any correct
  implementation order closes the hole completely; any other order is bypassable by
  construction, not by cleverness.
- Failed assumption: *"`'`-escaping makes string echoes safe."* Only when the
  escape character itself is neutralized. The single most common server-side XSS
  filter bug in this KB's experience set (third appearance: eval-JSON sibling,
  asymmetric h1-doubling here proving the author KNEW how — the h1 doubles `\`
  while the script passes it raw).
- Contrast the trilogy: quotes-raw (no shift needed), quotes-escaped+`\`-raw in
  OBJECT position (shift + grammar surgery), quotes-escaped+`\`-raw in STATEMENT
  position (shift only — this lab, minimal shape). Same escaper defect, three
  template difficulties.

## Trust boundary model
```
Attacker URL ──► GET param ──► server template into '…' (data?)
                                                                     │
              [TRUST BOUNDARY: template text(data) → script source(code)]
                                                                     ▼
                    '\\';alert(1);//';  →  string, terminator, statement
                                                                     │
                                                                     ▼
                                              statement execution (page origin)
```

## Enabling conditions (checklist)
1. Request data echoed into JS string literals with quote-escaping but raw `\`
   (test `\"`-shapes: does the escaper double backslashes? `xxd` decides).
2. Statement (or closable-construct) position after the breakout point.
3. A tail-neutralizer (`//`, or balanced continuation) for the template suffix.
4. No CSP blocking inline scripts (none here).