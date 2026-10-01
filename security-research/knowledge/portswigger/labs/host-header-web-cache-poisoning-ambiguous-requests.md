# PortSwigger Lab

## Status

NOT SOLVED — blocked. This note records an attempted lab plus the verified failure of its published solution on this stack. It is intentionally NOT listed in index/portswigger.md (solved-lab index) and taught NO methodology change.

## Lab

Web cache poisoning via ambiguous requests — https://0aca005f0472e16b80bb03f200250060.h1-web-security-academy.net/ (PortSwigger Web Security Academy, Host header attacks; h1-stack host). Lab banner `Not solved` at start and end.

## Vulnerability Class

Web cache poisoning via Host-header ambiguity (intended). Cache/host-trust family. Not injection.

## Objective

Poison the cache so the home page executes `alert(document.cookie)` in a victim's browser (victim regularly visits `/`).

## Initial Observations

- Homepage shop, `My account`, `Go to exploit server` (https://exploit-0af900790488e1b080fa02ef01cb00f8.exploit-server.net), lab banner.
- `GET /` → 200, `Cache-Control: max-age=30`, `Age`, `X-Cache: miss→hit`. Query fully keyed (new value miss, repeat hit, incl. utm_*). No `Vary`.
- Only Host reflection in any body: `<script src="//HOST/resources/js/tracking.js">` (protocol-relative). `/resources/js/tracking.js` itself is static 70B (`document.write tracker.gif`), cached 30s.
- Exploit server: Craft-a-response form (responseFile/responseHead/responseBody/formAction=STORE); `responseFile=/` refused (`footgun detected`).

## Hypotheses

- H1 (published): duplicate Host (lab first, evil second) — validator uses first, renderer reflects second, cache stores under first's key.
- H2: override headers (X-Forwarded-Host/X-Host/Forwarded/X-Original-Host/X-Forwarded-Server/X-Original-URL/X-Rewrite-URL).
- H3: absolute-URI ambiguity (evil URI + lab Host and reverse; userinfo; encoded @; http scheme; no-Host).
- H4: Host-format differentials (case, port, trailing dot, leading/trailing OWS, obs-fold, comma, semicolon, slash, quote, NUL, %00, LF-only framing).
- H5: unkeyed query/header reflection elsewhere (canary sweep UA/Referer/XFF/Lang/Cookie/query on `/` and `/product`).
- H6 (late): smuggling-shape CL.TE desync delivering a dup-Host inner request past the edge.
- H7 (late): R1 routing desync + crafted exploit response entering the lab cache.

## Attempts

~57 probes total via raw TLS sockets (SNI=lab; ground truth), curl (real-SNI control), browser (mapping + exploit server), Burp MCP (partial — see tool notes). Families and results:

1. Baselines: `/` miss→hit; `/?cb` keying confirmed. (4 reqs)
2. XFH/header matrix (6 headers × miss renders): all ignored, tracking=lab. (6)
3. Absolute-URI shapes (evil/lab × origin/absolute/userinfo/encoded/scheme/no-Host): backend always uses strict Host; missing/invalid Host → 403. (9)
4. Duplicate Host exact (lab+evil, both orders, via socket): evil-first → 421; lab-first → 400 `{"error":"Duplicate header names are not allowed"}`; identical lab+lab → 200 deduped. HTTP/1.0 dup → same 400. Lowercase `host:` → same 400. (≈6)
5. Near-duplicates: case → 400; comma → 403; obs-fold space/tab → 400; `Host :`/`Host\t:` space/tab names → 200 but backend ignores the malformed line (lab page). (8)
6. Value tricks: `lab:443` → 200 reflected WITH port (11050B); trailing space/tab → 403; `;` `/` inner-tab quotes `@` `%00` NUL → 403; unknown host → 403; real exploit host → 200 exploit app (suffix routing). (12)
7. Reflection sweeps: headers + query canaries → 0 hits; `:443`-suffix sweep over `/ /product /login /my-account` → same single tracking sink (302 on my-account). (4)
8. Cache-key test (PORT): prime `/?P` with `Host: lab:443` (miss, `:443` body) → re-request with canonical Host → **HIT with `:443` body** — Host unkeyed in cache. (2)
9. R1 desync: `Host : lab` + `Host: <exploit>` → 200 exploit-server page (edge trims names for validation; backend routes on strict Host). Reversed → lab page. Exploit-origin responses carry no cache headers; repeats show no X-Cache; canonical `/` untouched (hit, lab content) — exploit route bypasses cache. (6)
10. Crafted exploit `/resources/js/tracking.js` = `alert(document.cookie);` + `max-age=30` (stored, verified live) → delivered via R1 (200, 23B, headers survive) → canonical re-read → miss, original 70B. Not stored. Control (malformed-lab shape) → hit — cache engages malformed framing, exclusion is origin-based. (5)
11. Smuggling probe (CL.TE `POST /` + inner `GET` evil-Host, keep-alive): outer `404 "Not Found"`, server closed connection, follow-up 0 bytes — no desync. (1 conn)

## What Failed

Everything that could produce attacker content from the lab backend: H1 (400), H2 (ignored), H3 (Host wins / 403), H4 (403/400/421 except lab-equivalent values, all harmless — any lab-resolving reflection loads Academy JS), H5 (no reflection), H6 (no desync), H7 (delivered to wire, never cached).

## What Worked (partials, no exploit)

- Unkeyed-Host cache proof (Attempt 8).
- R1 trim/strict desync characterization + full exploit-server drive via curl (STORE with custom Head incl. `Cache-Control`; footgun guard on `/` mapped).
- Exact edge/backend/cache model (below).

## Posted-Solution Verification (executed literally)

- Steps 1–4 (browser Home, repeater study, Host validation 403, cache headers + `?cb=123` miss): REPRODUCED.
- Step 5 (second Host arbitrary → ignored for validation, reflected in tracking.js): FAILED — `400 {"error":"Duplicate header names are not allowed"}` (socket, ×3 across sessions; Burp MCP hangs 30s on this shape instead of sending).
- Step 6 (remove dup, same buster → still injected): FAILED (control) — same buster returns `miss`, clean lab body; nothing was ever stored.
- Step 7 (exploit file): DONE — `/resources/js/tracking.js` = `alert(document.cookie);` live on exploit origin.
- Steps 8–10 (dup with exploit domain → hit with reflection → strip buster → victim): BLOCKED at step 8 — `400`, verified for HTTP/1.1 and 1.0 just now.
- Correction to an interim claim: single `Host: <real-exploit-domain>` returns 200 exploit UI (recognized-host routing), NOT 403 — earlier 403s used a nonexistent domain. Lab render still requires lab Host.

## Burp Observations

- Burp MCP `send` timed out 4× on this host (normal requests OK); proxy-history reads fine. Dup-Host sends hang in MCP (socket ground truth used instead).
- Status/bytes fingerprint table: 200 lab (11046, cached, X-Frame + _lab cookie) / 200 lab:443 (11050) / 200 exploit (5497→5552 after storing a file, NO cache headers, `Server: Academy Exploit Server`) / 403 (109B, unknown host) / 400 dup (50B JSON) / 400 parse (16B `Protocol error`) / 421 (12B, SNI/first-Host mismatch incl. `Invalid host`).

## Browser Observations

- Lab homepage mapping (products, links, `Not solved`); exploit-server Craft form inspected (field names Enabled curl-driven STORE).
- No victim simulation possible (no poison exists to serve).

## CLI / Tool Observations

- curl: SNI-correct control (trailing-dot/case questions untestable via pinned-SNI sockets); header matrix; keying tests.
- Raw Python TLS sockets: primary evidence harness (exact bytes, SNI pinned to lab).
- Burp MCP: flaky here (dup-send hangs); socket evidence preferred and noted as such.

## Root Cause (of the block, not of a vuln)

Stack mismatch: the published solution assumes an edge that forwards duplicate Host headers with first-wins validation and second-wins rendering. This `h1-*` edge instead rejects duplicate names (case-insensitive JSON 400), pins SNI==first-Host (421), exact-matches Host values (403), and routes `*.exploit-server.net` to an uncached origin. No vulnerability was reached, so no vuln root cause is claimed.

## Verification (of negative claims)

- Dup-400 reproduced across sessions, HTTP/1.0+1.1, case variants, both orders, socket and (attempted) Burp — deterministic.
- Cache exclusion of exploit route: before/after canonical reads + R1 repeats without cache headers + malformed-lab control hitting — deterministic.
- Unkeyed-Host: two-key (port) test with re-read hit — deterministic.

## Impact

None demonstrated. No authenticated session, no state change on lab, no victim impact. Exploit-server artifact is origin-local and harmless.

## Why The Successful Approach Worked

N/A — no successful approach. The R1 delivery reached the wire with cacheable headers but the front does not store exploit-origin responses.

## Generalization

None verified — deliberately no methodology change. One CANDIDATE technique (unconfirmed, needs a second instance): port-variant cache-key test (`Host: lab:443` prime → canonical re-read; hit-with-port-body proves Host unkeyed).

## Lessons Learned

- Fingerprint the edge first: 50B JSON dup-error vs 16B parse-error vs 109B validation-403 vs 12B 421 names four layers before any exploit attempt.
- Pinned-SNI harnesses cannot test SNI==Host variants — pair every raw-socket finding with a curl (real-SNI) control.
- A reflection + an unkeyed cache are jointly necessary; either alone (here: unkeyed Host proven, reflection ungated never achieved) is not exploitable — verify composition, not parts.
- Published solutions are instance-bound: `web-security-academy.net` behavior ≠ `h1-web-security-academy.net` behavior; re-verify the primitive (here step 5) before building on it.
- Stale static strings (banner exploit-link) pollute substring checks — assert on the sink line (`tracking`), not domain counts.

## Related Methodology

- methodology/reconnaissance.md (cache-header mapping, key tests — referenced, unmodified)
- methodology/verification.md (hit/miss discipline, re-read rule — referenced, unmodified)
- methodology/access-control.md (Host-trust family — referenced, unmodified: no new reusable variant proven)
- methodology/injection.md (compared — not applicable, unmodified)

## References

- Lab description/solution: https://portswigger.net/web-security/host-header/exploiting/lab-host-header-web-cache-poisoning-via-ambiguous-requests
- Lab instance: https://0aca005f0472e16b80bb03f200250060.h1-web-security-academy.net/
- Exploit origin: https://exploit-0af900790488e1b080fa02ef01cb00f8.exploit-server.net/ (staged `/resources/js/tracking.js` = `alert(document.cookie);`, harmless origin-local)
- Sibling note (technique precedent only): knowledge/portswigger/labs/host-header-authentication-bypass.md
