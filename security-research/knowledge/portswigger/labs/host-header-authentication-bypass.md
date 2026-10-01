# PortSwigger Lab

## Lab

Host header authentication bypass — https://0a24003a04ada3a2804908a6002100bc.web-security-academy.net/ (PortSwigger Web Security Academy, Host header attacks)

## Vulnerability Class

Access control (Host header trust / locality bypass). Not injection.

## Objective

Access the admin panel and delete user `carlos`.

## Initial Observations

- Browser homepage: shop with products, `My account`, lab banner `Not solved`. Lab title `Host header authentication bypass`.
- `GET /robots.txt` (true Host) → 200, body `User-agent: * / Disallow: /admin`. Admin path disclosed.
- `GET /admin` (true Host) → 401, body `Admin interface only available to local users`, `is-notsolved`.

## Hypotheses

- H1 (stored-knowledge-driven): `/admin` gates on client-controlled `Host` equalling a loopback value (`localhost`). Forging `Host: localhost` while keeping the connection (SNI) on the lab host will render the panel. Source: methodology/access-control.md header-trust family (Referer gate, X-Original-URL desync, TRACE-disclosed IP header) + prior lab `infoleak-authentication-bypass-trace-header` (locality message → header spoof).
- H2 (untested alternative): an override header (`X-Forwarded-Host`, `X-Host`, `Forwarded`) may be trusted instead/also. Not tested — H1 succeeded first; minimal-interaction principle stopped further probing.
- Explicit non-hypothesis: no injection point observed (no interpreter, no quote/syntax reflection); `methodology/injection.md` not applicable.

## Attempts

1. `GET /robots.txt` true Host → 200 `/admin` disclosure.
2. `GET /admin` true Host → 401 locality denial (baseline).
3. `GET /admin` with `Host: localhost` → 200 admin panel (Users wiener/carlos + delete links).
4. `GET /admin/delete?username=carlos` with `Host: localhost` → 302 `Location: /admin`.
5. `GET /admin` with `Host: localhost` → 200 `is-solved`, `User deleted successfully!`, only wiener remains.

Total: 5 Burp HTTP/1.1 requests + 1 browser homepage load. No crawling, no wordlists, no brute force.

## What Failed

No failed exploit approaches. Override-header variants (H2) deliberately left untested after H1 proved deterministically with single-variable delta, per smallest-interaction rule.

## What Worked

Single-variable Host swap (`<lab-host>` → `localhost`, same path, no session needed) flipped 401-denial to 200-panel; same forged Host on the delete endpoint removed carlos.

## Burp Observations

- `GET /robots.txt` true Host → `HTTP/2 200`, `Content-Length: 31`, `Disallow: /admin`.
- `GET /admin` true Host → `HTTP/2 401`, `Content-Length: 2658`, denial string `Admin interface only available to local users`.
- `GET /admin` `Host: localhost` → `HTTP/2 200`, `Content-Length: 3193`, nav gains `Admin panel`, body lists `wiener - Delete`, `carlos - Delete`.
- `GET /admin/delete?username=carlos` `Host: localhost` → `HTTP/2 302`, `Location: /admin`, `Content-Length: 0`.
- `GET /admin` `Host: localhost` (re-read) → `HTTP/2 200`, `Content-Length: 6213`, `is-solved`, `Solved`, `User deleted successfully!`, only `wiener - Delete` remains.
- Transport note: HTTP/1.1 raw via Burp MCP against `targetHostname=<lab>` (SNI stays lab) while `Host:` header forged — correct shape for Host-header tests (HTTP/2 `:authority` not used).

## Browser Observations

- Homepage load only: confirmed shop structure, `My account` link, `Not solved` banner, product `?productId=N` links. No login, no form submission, no admin navigation via browser.

## CLI / Tool Observations

None used. No httpx/Nmap/Katana/Gobuster/ffuf/curl/jq — single-endpoint hypothesis needed only Burp precision.

## Root Cause

Server-side authorization checks the client-controllable `Host` header for a loopback value instead of the connection source. Request with the public Host is denied as non-local; identical request with `Host: localhost` is treated as local and served the admin handler. Trust boundary violated: attacker-controlled L7 header → locality decision.

## Verification

- Deterministic single-variable delta: same path/sessionless, true Host 401 vs `localhost` 200 with privileged UI (user roster + delete links).
- Effect proof, not status: delete returned 302 (insufficient alone) → re-read `/admin` with same forged Host showed `User deleted successfully!` + carlos row absent + `is-solved`/`Solved` marker. Caching ruled out by content change tied to the delete request.
- Solved marker on re-read surface (admin panel), consistent with methodology/verification.md (re-read state, victim context, marker arbitrates).

## Impact

Unauthenticated vertical privilege escalation to admin function: any remote client can list users and delete arbitrary accounts (`carlos` demonstrated). Same primitive yields full admin-panel control. No authentication required at any step.

## Why The Successful Approach Worked

Denial message named the gate (`only available to local users`) while the gate read a spoofable header. Forging the loopback value satisfied the string comparison without changing network locality. Minimal, sessionless, one-variable proof.

## Generalization

Where a denial cites locality/network trust, test whether the check reads `Host` (or related forwarding headers) rather than the connection: baseline denial → replay with `Host: localhost`, `127.0.0.1`, and case/port variants, one variable each; confirm via privileged UI + state change + marker, never status alone.

## Lessons Learned

- Locality-gate wording (`only available to local users`) is a header-trust pointer — same family as TRACE-disclosed IP-header bypass, but here the trusted header is `Host` itself.
- `robots.txt` → `/admin` disclosure + denial message = full target map in 2 requests; no crawling needed.
- HTTP/1.1 raw with SNI/Host split is the correct harness for Host tests; HTTP/2 `:authority` conflates routing with the test value.
- 302 after delete is not proof — re-read and check victim-row absence + success string + solved marker.

## Related Methodology

- methodology/access-control.md (header-trust locality family — new Host-header variant; TRACE/X-Original-URL/Referer precedents)
- methodology/verification.md (single-variable delta, re-read state, marker arbitration)
- methodology/reconnaissance.md (robots + denial-message mapping, read-only)
- methodology/injection.md — compared, NOT applicable (no interpreter/data-logic boundary; no update)

## References

- Lab description: https://portswigger.net/web-security/host-header/exploiting/lab-host-header-authentication-bypass
- Prior lab (pattern precedent, not payload source): knowledge/portswigger/labs/infoleak-authentication-bypass-trace-header.md
- Prior lab (Host mechanics precedent): knowledge/portswigger/labs/authentication-basic-password-reset-poisoning.md
