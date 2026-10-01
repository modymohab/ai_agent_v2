# Pattern: Unrestricted Google Maps API key in a public client bundle enables billed web-service API abuse

Source: mission eternal-2026-09-22, finding C-02 (bistro.blinkit.com). Generalizable pattern; no target-specific secrets beyond the pattern description.

## Pattern

A Google Maps Platform API key embedded in a public client bundle (config.js / JS bundle) that has **no application restriction** (no HTTP-referrer restriction, no IP restriction) can be used by anyone to call **billed web-service APIs** (e.g. Geocoding) from any origin or from no origin. Each successful call is billed to the key owner's Google Cloud project and counts against its quota.

Browser keys are public by design; the security control is the **restriction set**, not the key value. Referer restrictions are the only authorization control for Maps web-service APIs — a referer-restricted key is rejected for web-service use.

## Preconditions

- Target serves a public client bundle containing a Google Maps API key.
- The key has no application restriction (or only an API restriction that still permits a billed web-service API).
- The key's project has at least one billed web-service API enabled (Geocoding, Places, Static Maps, Directions, Distance Matrix, etc.).

## Observable indicators

- `config.js` / bundle contains `googleMapsJsApiKey` / `googleMapsApiKey` / `mapsApiKey` fields.
- A Geocoding call (`maps.googleapis.com/maps/api/geocode/json?address=...&key=<key>`) returns `"status":"OK"` with a foreign `Referer` or with no `Referer`.
- Sibling keys on the same organization return `REQUEST_DENIED` with "API keys with referer restrictions cannot be used with this API" — strong discriminator proving the target key is the misconfiguration outlier.
- The Maps JS bootstrap (`/maps/api/js?key=...`) returning 200 is NOT a restriction signal (client loader behavior) — do not use it as evidence.

## Verification concept

1. Extract key from public bundle.
2. One low-volume Geocoding call with a foreign referer → expect `OK` (vulnerable) or `REQUEST_DENIED` (restricted).
3. One call with no Referer header → `OK` proves no origin binding.
4. Control: same call with a sibling key from the same org → `REQUEST_DENIED` proves methodology sound and the target key misconfigured.
5. Blast-radius: probe Directions/Distance Matrix with the same key to bound exposure (REQUEST_DENIED = not enabled). Do not exhaustively enumerate all Maps APIs at volume.

## False positives / caveats

- Referer-restricted keys correctly return `REQUEST_DENIED` for web-service APIs — that is expected, not a finding.
- Keys restricted to Maps JavaScript API only are fine for browser use; the finding requires a billed web-service API to be callable.
- The Maps JS bootstrap 200 is not a restriction signal.
- Do not frame as DoS/service disruption; sustained quota exhaustion is potential impact, usually out of scope for programs, and was not demonstrated.
- Severity ceiling is Low/informational (P4/P5): no data exposure (public reference data), no integrity impact, no account impact. Financial/quota abuse is the demonstrated capability.

## Lessons learned

- Always test the key against a billed web-service API, not just the JS loader.
- The sibling-key contrast is the strongest proof of misconfiguration — same org, same API, different restriction outcome.
- Keep validation to one request per key (minimal-impact rule); a single successful call is accepted industry proof of abuse capability for this class.
- Remediation guidance: rotate the key; referer-restrict browser keys (which also disables web-service use — desired) or use a separate IP-restricted server-side key; set quota caps and billing alerts; audit other bundles for the same issue.