# Pattern: ASP.NET ViewState MAC-disabled detection (differential, no payload)

Source: henkel-vdp-2026-09-19 mission (henkeleconomato.es) — verified 2026-09-19.
Class: Insecure deserialization configuration — ASP.NET WebForms ViewState (CWE-502 / CWE-353).

## Pattern

ASP.NET WebForms pages render hidden fields `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, and
`__EVENTVALIDATION`. `__VIEWSTATEGENERATOR` is a per-page hash that participates in the
ViewState MAC computation (introduced in .NET 2.0 to prevent cross-page ViewState reuse).
If MAC validation is enabled, tampering the generator MUST produce
"Validation of viewstate MAC failed" (HTTP 500). If the server accepts a postback with a
tampered generator and processes it normally (HTTP 200, page re-rendered, fresh per-request
session/security cookie), MAC validation is disabled.

## Preconditions

- Target is ASP.NET WebForms (fingerprint: `X-AspNet-Version` header, `__VIEWSTATE` fields).
- Anonymous reachability of at least one page that accepts postbacks (login forms are ideal).
- No payload delivery required — the test is a pure integrity-check probe.

## Observable indicators

- `Server: Microsoft-IIS/8.5` + `X-AspNet-Version: 4.0.30319` (legacy .NET 4.x stack).
- `__VIEWSTATEGENERATOR` present and stable per page (e.g., `CA0B0334`).
- Tampered generator (`DEADBEEF`) → 200 with re-render + fresh session cookie (MAC disabled).
- Byte-altered `__VIEWSTATE` (valid base64) → 500 generic runtime error (ViewState IS processed).
- `__EVENTVALIDATION` tampering → 500 (EventValidation is a separate mechanism; its presence
  does NOT protect ViewState deserialization).
- Fresh per-request session/security cookie on the tampered postback proves genuine server
  processing, not cache.

## Verification concept

Differential, one variable at a time, same session:
1. `GET /` → capture `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, `__EVENTVALIDATION`, cookies.
2. `POST /` with `__VIEWSTATEGENERATOR=DEADBEEF` (all else valid) → 200 + fresh cookie = MAC disabled.
3. `POST /` with byte-altered `__VIEWSTATE` (valid base64, original generator) → 500 = ViewState processed.
4. Repeat on a second page (different generator value) to prove app-wide configuration, not a page quirk.
5. Repeat the tampered-generator POST once more to confirm determinism.

## False positives / caveats

- A generic 500 on a tampered ViewState does NOT by itself prove MAC enabled/disabled — the
  tamper may fail deserialization before the MAC check. The generator-tamper test is the
  decisive one (generator is checked only by the MAC path).
- A 200 on tampered generator could theoretically be a cache; disprove with the fresh
  per-request cookie and a changed `__VIEWSTATE` in the response.
- Non-standard ViewState serialization headers (not `ff 01` LosFormatter, not gzip `1f 8b`)
  indicate a custom scheme — payload acceptance for RCE is then UNPROVEN even with MAC disabled.
- Do not ship ysoserial.net payloads without explicit program authorization; report the
  primitive and let the vendor validate the RCE path internally.

## Lessons learned

- The generator-tamper probe is the cheapest, most decisive MAC-disabled test — no payload,
  no machine key, no decryption needed.
- Confirming on two pages with different generators turns a page-quirk hypothesis into an
  app-wide configuration finding.
- EventValidation enforcement is orthogonal: it 500s on its own tamper but does not protect
  ViewState deserialization — do not be misled by its presence.
- Severity honesty: MAC-disabled is a confirmed configuration weakness (Low by itself);
  RCE is a plausible-but-unverified escalation that must be reported as potential impact.