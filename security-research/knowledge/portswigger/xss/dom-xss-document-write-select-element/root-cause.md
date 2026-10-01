# Root Cause — document.write into select/option with parser leniency

## The vulnerability
The stock-check script writes the `storeId` query value into an `<option>` element via
`document.write`, inside a dynamically built `<select>`. The value is parsed as markup
in select/option context — and the operative parser rules are far more permissive than
the content model suggests, admitting three distinct execution paths.

## Root cause (framing, two layers)
1. **Unsanitized URL data into a markup sink** (the known DOM-XSS half):
   `location.search` → `document.write` with no escaping, no validation, no CSP.
   The data→code boundary is crossed at parse time, entirely client-side.
2. **Restrictive-context assumption failure** (the novel half): a tester reasoning
   from the content model ("only `<option>` allowed in `<select>`; scripts/handlers
   won't survive") would predict breakout-necessity. The parser disagrees:
   - `<img>` (and foreign elements generally) parse as `<option>` children and their
     handlers fire — content-model violations tolerated at tokenization.
   - `<script>` in select context is handled per in-head rules and executes.
   - Hence the wrapping context constrains NOTHING for these vectors; only values
     that are pure text remain inert.

## Trust boundary model
```
Attacker URL ──► location.search ──► URLSearchParams.get ──► JS string (data)
                                                                      │
              [TRUST BOUNDARY: string(data) → parsed markup(code), in select ctx]
                                                                      ▼
              document.write → option/select-context parsing → live elements
                                                                      │
                                                                      ▼
                      img-onerror / script execution (app origin, load-time)
```

## Corrected parser-context rules (empirical, Chrome 150)
| Wrapping context | `<script>` | `<img onerror>` (no breakout) | `</select>`-style breakout |
|---|---|---|---|
| body / `<p>` / `<div>` | runs | fires | n/a (already body) |
| `<select>` → `<option>` | RUNS (this lab) | FIRES (this lab + static control) | works, unnecessary |
| `innerHTML`-assigned fragment | inert (spec neuter) | fires | n/a |
The miope rule "exotic contexts neutralize payloads" is false as stated — EACH
(sink × wrapper × payload-shape) triple must be tested; this lab is the exhibit.

## Enabling conditions (checklist)
1. URL-derived string written into markup parsed inside `<select>`/`<option>`
   (stock selectors, country/language pickers, configurable dropdowns).
2. No output escaping on the value (any of `"`/`<>`/nothing encoded still leaves at
   least one of the three vectors viable — here nothing is encoded at all).
3. No CSP (none here) — otherwise event-handler vectors fall first, `<script>` next
   depending on policy.
4. Crafted-URL delivery to the victim (link-based; load-time fire, no interaction).