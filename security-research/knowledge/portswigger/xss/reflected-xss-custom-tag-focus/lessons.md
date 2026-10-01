# Lessons — Generalizable pattern from this lab

## Reusable pattern
> **When a filter blocks standard tags, test unknown/custom elements with handlers
> FIRST (`<xss autofocus onfocus=…>` — one request characterizes tag-vs-handler
> filtering). Unknown ≠ inert: custom elements take global attributes, event
> handlers, `id`, and `tabindex` — and `#id` fragment navigation auto-focuses them
> on load, giving a zero-interaction trigger shippable inside an ordinary link. Read
> the objective for the signal type (`alert(document.cookie)` = prove data access;
> victim vs self decides delivery).**

Coupled rules:
1. **Filter-shape before payload-shape**: one probe (`<xss autofocus onfocus=X>`)
   distinguishes tag-only filtering (this lab) from tag+handler filtering (prior
   lab). The shape dictates everything downstream — never port the sibling's
   assumptions.
2. **Custom elements are fully capable hosts**: `on*` handlers fire, `id` anchors,
   `tabindex` confers focusability, CSS applies. Audit them exactly like standard
   tags wherever a filter passes them through.
3. **Fragment-focus is the cheapest zero-interaction trigger**: no iframe, no second
   navigation, no style mutation — `#id` + `tabindex` + `onfocus` in a single URL.
   Prefer it over manufactured-event chains whenever the host is focusable.
4. **Signal-type discipline**: `alert(1)` proves execution; `alert(document.cookie)`
   proves data access; victim vs self proves delivery. Match the proof to the
   objective — over-proving wastes cycles, under-proving misses the grade.

## Recon indicators (how to find this class again)
- Reflected echoes + tag-400s + custom-tag-200s (two requests to characterize).
- Exploit-server / victim-interaction objectives with cookie-reading signals.
- `tabindex` + `id` + fragment in any payload context = focus-trigger design.
- Real-world analogues: WAFs with tag allow/block lists, CMS "safe HTML" modes that
  strip known tags but pass unknown ones, email HTML sanitizers with the same gap.

## Verification techniques (reusable)
1. **Single characterizing probe** (custom tag + autofocus + handler) before any
   mapping campaign.
2. **Headless fragment-load proof** (title side-effect) — validates the full
   focus chain without victim infrastructure.
3. **Self-fire control** (own-browser execution → banner must NOT flip) to confirm
   victim-gating before spending delivery cycles.
4. **Byte-verified STORE + log-watched DELIVER** (prior labs' discipline, unchanged).
5. **Delivery-latency bookkeeping** (this lab: minutes + re-delivery; prior: similar)
   — re-deliver on silence, never re-edit a working exploit mid-wait.

## Common mistakes that miss this
- **Assuming custom tags can't execute** (the filter author's exact error — and the
  finding).
- **Porting the sibling lab's handler-block assumption** instead of the one-probe
  re-map (here `onfocus` passes; there it 400s).
- **Overlooking `tabindex`** (custom elements aren't focusable by default — the
  trigger silently fails without it; `autofocus` alone on a non-focusable host also
  fails).
- **Designing iframe-resize chains** when fragment-focus does it in one URL
  (trigger matched to objective, cheapest sufficient mechanism).
- **Firing `alert(1)`** when the objective demands `alert(document.cookie)`
  (signal mismatch — execution proof ≠ data-access proof).
- **Treating delivery silence as exploit failure** (check the log for visits first;
  re-deliver; don't mutate working payloads).
- **Forgetting transport encoding** of `#` (must be literal in the delivered URL —
  `%23` would NOT act as a fragment; encode everything EXCEPT the `#`).

## Cross-cutting
- Trigger-design trilogy now complete across the victim-delivery labs: manufactured
  viewport event (iframe resize → `onresize`), manufactured fragment change (iframe
  src append → `hashchange`), intrinsic fragment focus (`#id` → `onfocus`). Same
  delivery template (lure page → victim browser → platform signal), three trigger
  physics — select by constraint (no-interaction? which handler survives?).
- The invariant method holds for filter-shaped targets: characterize filter (2
  probes) → oracle-map only what the characterization leaves open → compose
  surviving set → local proof → victim proof. Fifteen labs; the method is unchanged
  since lab one, only the tables grow.