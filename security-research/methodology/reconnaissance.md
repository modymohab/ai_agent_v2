# Reconnaissance Methodology

## Core Concept

Reconnaissance maps the attack surface before testing it: every page, endpoint, parameter, and data flow is inventoried from OBSERVED responses, and each discovery narrows (never widens) the next probe set. Recon answers "what exists?" — hypotheses about "what's broken?" come after.

## Security Boundary

Intended: complete, quiet surface knowledge with zero state change.
Violated when: recon itself mutates state (creates accounts/comments/orders), trips rate limits, or pollutes later evidence (probe comments stored alongside payloads).

## Recognition Patterns

- Shop surfaces: product listings (`/product?productId=N`), filter/search forms, stock-check endpoints (`POST /product/stock`).
- Blog surfaces: post listings, individual posts (`/post?postId=N`), comment forms (`POST /post/comment`).
- Auth surfaces: `/login` (CSRF presence varies per family — probe once), `/my-account`, `/admin`, password-reset and 2FA stage endpoints.
- API-ish surfaces: `/api/...` routes, JWKS endpoints (`/jwks.json`), well-known paths, key/certificate endpoints.
- Framework markers: `labHeader.js`, `stockCheckPayload.js`-style builder files, exploit-server links, email-client links.

## Common Locations

- Homepage link harvest (`href` extraction) for products/posts coverage.
- Form reads: action, method, encoding (`urlencoded` vs JSON vs XML), hidden fields (`csrf`, `postId`), input names.
- Builder JS files (`*Payload.js`): exact request SHAPE (XML body vs `URLSearchParams` form) — shape mismatch wastes first probes.
- Response headers: content-type, cookies/flags, CSP presence, error formats.
- Inbox / access-log endpoints (exploit server `/email`, `/log`) for out-of-band flows.

## Indicators

- Reflected-slot discovery: quote/tag probes reveal error-message reflection before any exploit attempt.
- Endpoint existence oracle: 200-vs-404 plus content-length deltas across candidate paths.
- Method oracle: 405s map allowed verbs per endpoint.
- Builder-file reads decide payload SHAPE (DOCTYPE body vs in-value injection) before the first attack request.

## Testing Methodology

1. Map passively first: homepage → link harvest → one GET per distinct page TYPE (not every ID).
2. Read every form completely (action/method/encoding/hidden fields) before submitting anything.
3. Read builder JS before crafting structured payloads (XML vs form mismatch is the top wasted-probe cause).
4. Probe reflection with benign unique strings (e.g. `PROBEXSS9Z8…`) and record EXACT context (surrounding markup, encoding) — never lead with exploit payloads.
5. Sweep cheap candidate endpoints (robots, well-known, jwks, key paths) with single GETs and 200/404 + size recording.
6. Check headers on every baseline (CSP decides XSS viability; cookie flags decide exfiltration readability; content-type decides body shape).
7. Keep recon read-only: GETs and single benign POSTs only; no scanning bursts on rate-defended surfaces (rapid scans trip IP blocks — learned hard on the timing lab).
8. Record baseline numbers (counts, sizes, timings) — later differentials are measured against THESE, not memory.
9. Git-history extension: where `.git/HEAD` (or config/logs) is retrievable, walk the object graph — `logs/HEAD` for hashes + messages (deletion-marker commits like "Remove X from config" point at the prior commit), fetch commits/trees/blobs via `/.git/objects/XX/YYYYYYYY`, zlib-decompress, parse tree entries programmatically (mode, name, 20-byte SHA — never hand-transcribe hashes). Prioritize deletion commits; use recovered credentials at the main login.

## Verification

- Every mapped endpoint re-requested at least once (rules out transient responses).
- Reflection contexts captured as raw bytes with surrounding markup (not paraphrased).
- Absence claims ("no CSRF", "no CSP", "404") verified with explicit requests, not assumed from templates.

## Common Failure Modes

- Spraying exploit payloads before mapping (wastes the cleanest evidence window; pollutes stored comments).
- Assuming endpoint shapes from prior labs (XML vs form mismatch; CSRF presence varies per family).
- Rapid full-list scans on first contact (IP lockout before any hypothesis — throttle or isolate with XFF from the start).
- Treating 200 status as endpoint-equivalence (compare SIZES and content, not codes).
- Recon actions that change state (logins mint codes/emails; comments persist; orders charge) — track and account for each side effect.

## Impact Considerations

- Recon has no direct impact; its value is measured in later precision (request counts to solve: 7–13 on well-mapped JWT/XXE labs vs hundreds on blind scans).
- Noisy recon risks lockout that blocks the real attack — budget requests per defense family.

## Lessons Learned

- From PortSwigger JWT labs: `/jwks.json` + robots + well-known + kid-path sweeps (6 GETs) routinely decide the whole attack (exposed key vs GCD recovery vs dead end).
- From PortSwigger XXE labs: reading `stockCheckPayload.js` FIRST determines in-value vs body payload shape — one read prevents the classic DOCTYPE-misfire.
- From PortSwigger “Username enumeration via response timing”: a rapid 101-request opening scan IP-locked the lab for 30+ minutes — scan rate is family-dependent, throttle by default.
- From PortSwigger “Offline password cracking” (stalled): benign-probe-first confirmed stored reflection cleanly; payload correctness verified byte-for-byte (domain-prefix bug caught by programmatic diff, not eyeballing).
- From PortSwigger 2FA labs: inbox timestamp/count forensics attributes server-side events (login-mint vs form-view-mint) without guessing.
- From PortSwigger “Information disclosure in version control history”: logs-first reading (deletion-marker commit narrates the secret's location) → object-graph walk (commits→trees→blobs, exact-SHA parsing after an eyeball-hex failure) → `ADMIN_PASSWORD` → administrator login → delete carlos → `is-solved` (~20 requests).

## Related Concepts

- methodology/verification.md (baseline numbers as the comparison datum; absence claims need explicit requests)
- methodology/authentication.md (Academy list sourcing; XFF isolation; throttle discipline)
- tooling/tools.md (tool-per-question selection: curl mapping, Python parsing, Burp precision)

## Sources

- Cross-lab synthesis of solved-note recon sections (JWT shop mapping, XXE builder reads, auth list sourcing, 2FA inbox forensics) in knowledge/portswigger/labs/.
- PortSwigger lab: Information disclosure in version control history (knowledge/portswigger/labs/info-disclosure-version-control-history.md)
