# PortSwigger Lab

## Lab

Exploiting a mass assignment vulnerability — https://0a2c002b0407214f8116523c00b5002d.web-security-academy.net/ (PortSwigger Web Security Academy, API testing). Creds wiener:peter.

## Vulnerability Class

Mass assignment: hidden API parameter (`chosen_discount.percentage`) bound server-side without authorization/validation. NOT injection.

## Objective

Buy the Lightweight L33t Leather Jacket (no admin/delete objective in this lab).

## Initial Observations

- Shop checkout goes through JSON API `GET/POST /api/checkout` (not form `/cart/checkout` as in prior shop labs — assumed wrongly at first).
- `GET /api/checkout` returns `{"chosen_discount":{"percentage":0},"chosen_products":[]}` — the discount object is absent from any client POST shape.
- `/api/v1/...` version-gated paths, change-email role guessing (13 names), full API wordlist (295, all 404), docs sweep — all dead ends (~45 probes) before reading the checkout contract.

## Hypotheses

- H1: undisclosed `chosen_discount` is server-processed (not ignored). Confirmed: `0` accepted silently, `"x"` → `Key percentage: string is not a number`.
- H2: `percentage: 100` zeroes the order. Confirmed: 201 + confirmation + solved.

## Attempts

1. Login → assumed form checkout (prior-lab habit, unverified) → probed change-email mass assignment (13 role names × values), API version hunting (v0–v100, headers, query, methods, bodies), 295-entry wordlist (all 404), cart price override (400), method overrides — all correctly negative, one wrong assumption (checkout shape) cost the most time.
2. Post-nudge (stuck clause): `GET /api/checkout` contract read → baseline POST (0) → `"x"` error probe → `100` → 201 + `is-solved`.

## What Failed

- ~45 probes on wrong surfaces (role names, API versions, hidden endpoints) — failure mode: assumed prior labs' checkout shape instead of intercepting this lab's actual checkout traffic first.

## What Worked

Contract-diffing GET vs POST JSON shapes; hidden-param validation probe (benign → type-error → exploit value); single exploit request.

## Burp Observations

Not used (curl sufficed; Proxy history would have shown the /api/checkout traffic immediately — the lesson).

## Browser Observations

Mapping only.

## CLI / Tool Observations

- curl + jar; JSON bodies; error-message oracles (`string is not a number` proves processing).

## Root Cause

Checkout binds the full JSON object including the client-undisclosed `chosen_discount.percentage` with no authorization or sane-range validation — any session sets arbitrary discount percent.

## Verification

- Benign (0) → silent accept; wrong-type ("x") → processing error; 100 → 201 + `Location: /cart/order-confirmation` + `is-solved` marker. Three-point differential, not a single shot.

## Impact

Any authenticated user buys any item at any discount up to 100% free (demonstrated jacket).

## Why The Successful Approach Worked

Compared the server's own GET shape against what the client sends — the difference IS the hidden attack surface; the type-error probe confirmed live processing before committing to the exploit value.

## Generalization

For JSON APIs: GET/POST shape-diff every state-changing endpoint; add each GET-only field to POST with benign value (no error?), wrong-type value (processing error?), then exploit value; verify via marker/state.

## Lessons Learned

- Intercept THIS lab's checkout traffic first — never assume prior labs' endpoint shapes (costliest mistake here).
- GET-vs-POST JSON diff is the fastest hidden-parameter oracle.
- Wrong-type probe ("x") distinguishes ignored vs processed params before exploit values.
- 201 + Location (not 200) can be the success signal — read status + marker, not body presence (empty 201 body).

## Related Methodology

- methodology/api-security.md (mass-assignment pattern added below)
- methodology/verification.md (three-point differential + marker)
- methodology/injection.md — compared, NOT applicable (no interpreter; binding flaw; no touch)

## References

- Lab description: https://portswigger.net/web-security/api-testing/lab-exploiting-mass-assignment-vulnerability
