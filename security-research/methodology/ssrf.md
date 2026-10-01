# SSRF Methodology

## Core Concept

SSRF occurs when the server fetches an attacker-controlled URL and the request inherits the SERVER's network position — reaching loopback-only interfaces (`127.0.0.1`, `localhost`) and internal services that edge controls deny to external clients.

## When a server-side fetch is NOT SSRF

A server that fetches an attacker-supplied URL is only an SSRF **if the fetch
reaches something the attacker could not otherwise reach**. Fetching a public URL
and returning its body is proxy/fetcher behaviour, not a boundary crossing. This
distinction decides severity and is the single most common mis-filing in this
class.

The canonical trap is a **userinfo host-discrepancy**:
`?u=https://<trusted-looking>@<attacker-host>/…`. In URL parsing everything
before `@` is userinfo, so the *displayed* host differs from the *actual* host
fetched. That is a genuine **host-allowlist bypass** and is worth reporting. It
is routinely mis-filed as Critical SSRF. Separate the two claims:

- The **bypass** defeats a filter the application believed it had. Real.
- The **SSRF** is real only if the attacker-chosen destination is *internal* or
  otherwise privileged: loopback, RFC1918, link-local cloud metadata, an
  internal-only admin API.

| How the fetched response is handled | Accurate class |
|---|---|
| Returned to the requester verbatim | SSRF **only if** the destination is internal/privileged; otherwise a public fetcher — often no vulnerability at all |
| Rendered into a page the attacker can view | **XSS** (the fetch is a delivery vector, not a privilege boundary crossing) |
| Parsed and stored server-side, later shown to another user | Stored XSS / cache poisoning — file the class the impact supports |
| Used to authenticate or authorize a server-side decision | Real SSRF if internal; otherwise a logic flaw in the decision |

**Calibration probes before claiming SSRF** (state negative results explicitly in
the report — a report that documents what it *could not* reach is harder to
downgrade):

- `file://` — does the fetcher read local files?
- `gopher://` / `dict://` — can it drive non-HTTP internal services?
- Link-local metadata (`169.254.169.254`, `metadata.google.internal`) — cloud credentials?
- Does it follow redirects? A same-host redirect to `127.0.0.1` is still an
  internal reach and counts.
- Is the target genuinely internal, or a public host that merely *looks* private?

If every probe is negative and the destination was public, do not file SSRF.
File the real bug under its real class.

**Worked example (public triage, paid and fixed).** A search engine's image-proxy
endpoint accepted a URL, resolved the host through a userinfo discrepancy to
bypass an allowlist, and reflected the fetched body into its own origin. Filed as
Critical SSRF; re-triaged as XSS and paid at Medium. The reporter explicitly
conceded that no internal network, no metadata service, and no local file was
reachable, and that the fetching component had nothing internal behind it — which
is precisely why the submission stayed payable instead of collapsing. The bug was
genuine; only the label set the wrong ceiling.

## Parser differentials — validate with the parser that DISPATCHES

A URL allowlist is only as strong as the agreement between the parser that
**validates** and the parser that **sends**. If those two disagree, the check is
decorative. Audit every outbound-request path for this pair explicitly:

| Layer | Typical parser |
|---|---|
| Validation / allowlist code | `urllib.parse.urlparse`, `java.net.URI`, `url.Parse` |
| Actual dispatch | `urllib3.util.parse_url` (via `requests`), `net/http`, Go `net/url` |

Known divergence classes, all of the same shape — *the two parsers disagree about
where the authority ends*:

- **userinfo** — `http://trusted@attacker/`: one parser reads everything before
  `@` as userinfo and takes the host after it; another may take the first token.
- **backslash as separator** — `http://169.254.169.254\@127.0.0.1:8000/`: stdlib
  treats the backslash as part of userinfo and resolves the host to the
  post-`@` segment, while urllib3 treats `\` as a path separator and resolves the
  host to the *first* token. Validation sees the legitimate host; dispatch goes
  to the attacker host.
- **whitespace/control chars, redundant schemes, decimal vs hex vs octal IPs**,
  and trailing-dot or mixed-case host forms.

**How to verify a parser-differential claim properly.** Do not stop at the
library. Progressively close the gap until you are at the dispatch layer:

1. Both raw parsers, side by side, on the same input string.
2. The framework's prepared/normalized request object (e.g. `requests.PreparedRequest`).
3. The resolved connection target (pool host/port) from that prepared request.
4. Only then a live observation on the wire.

Report which rung you reached, and label the gap if you stop short. A
component-level differential is a real finding; saying plainly "not yet verified
end-to-end, reviewer steps included" is what keeps it payable instead of
overclaimed.

**When a multi-field check is the gate, attack the weakest field.** A check
comparing `(scheme, hostname, port)` invites the objection "the port won't match."
Verify **each** element independently against the permissive parser and show that
all of them resolve to the attacker-favourable value. Port, scheme, and case
normalization each have their own divergence modes.

**Remediation, strongest first:** (1) validate with the *same* parser that
dispatches; (2) cross-check that both parsers agree on the resolved host, or
reject when they disagree; (3) deny-by-default — allow only the exact configured
host rather than an origin tuple; (4) additionally block private, loopback and
link-local ranges unless the configured target is itself there. (1) alone fixes
this instance; (3) and (4) are defence in depth against the next differential.

## Client-side SSRF (confused deputy)

The framing above — "the *server* fetches" — is only half the class. In the
client-side variant the untrusted party is the **server** and the **victim's
client** executes the request. The impact analysis inverts:

- The reachable targets are the **client's** network position, not the server's.
- The asset at risk is whatever the victim's machine can reach but the internet
  cannot: internal services, admin panels, and especially **cloud instance
  metadata** (`169.254.169.254`, `metadata.google.internal`) which can yield IAM
  credentials.
- The bypass usually defeats a control the client **explicitly implemented** for
  this exact purpose. An origin/host allowlist in a CLI or SDK is a stated
  security boundary, so defeating it is a genuine authorization finding, not a
  hardening nit.
- Typical sink: a client that **follows pagination or redirect `next`/`Location`
  values** returned by the untrusted server, with no re-validation against its own
  allowlist. This is why the finding is reachable at all.

Calibrate the precondition honestly — and check it in both directions, because
reports tend to state it in whichever direction flatters the finding:

- *"Attacker must compromise a server instance"* sounds like a high bar.
- *"User points the client at an untrusted server URL"* is often trivial, because
  the target is a URL the user is told to configure.

State which is actually required. If the client takes an arbitrary operator-
supplied URL, the practical bar is low; if it only ever talks to a
hardcoded/pinned host, the class may not apply at all. Get this right in **both**
directions — an understated precondition and an overstated impact are the same
error.

## Security Boundary

Intended: server-side fetches constrained to approved external hosts.
Violated when: `stockApi=http://127.0.0.1/admin…` returns internal content and executes internal actions.

## Recognition Patterns

- Forms carrying full URLs for server-side fetching (stock-check `stockApi`, webhooks, previews, PDF generators, image proxies).
- Baseline responses reflecting fetched bodies (stock counts, content snippets).
- Admin surfaces linked publicly but denied externally — candidates for loopback reachability.
- Fetched URLs already referencing private ranges (`http://192.168.0.1:8080/…`) — port + path convention given; sweep the /24 for a second backend.
- Block-message oracle (`400 External stock check blocked…`) revealing a blacklist: host and path filtered as INDEPENDENT string matches (loopback literals blocked; short-form/encoded/case variants may pass).
- Strict parsed-host whitelist (`host must be stock.weliketoshop.net`) + distinct parse-error (`Illegal character in authority`) and fetch-error (`Could not connect…`) messages: validator robust on single decode — suspect DECODE-COUNT gaps (`%2523`) and redirect-following next.
- RELATIVE-path fetch input (`stockApi=/product/stock/check?...`, absolute rejected as `Invalid URL`) combined with an open redirector accepting absolute targets (`/product/nextProduct?…&path=<absolute>`): relative-only SSRF converts to arbitrary-destination SSRF when the fetcher follows redirects.
- NO reflected surface at all (no forms/stock/API/account) + analytics-style fetching: blind SSRF via request HEADERS (Referer/Origin/UA), fetched asynchronously, observable only out-of-band.

## Common Locations

- `POST /product/stock` (`stockApi` URL param).
- Any endpoint accepting URLs, hostnames, or IPs that the server resolves/fetches.

## Indicators

- External baseline (stock count `54`) vs loopback (`http://127.0.0.1/` → reflected homepage HTML) — server-side fetch proven.
- Loopback `/admin` renders privileged UI (`Users … Delete` links) denied to direct external access.
- Post-delete panel re-read (`User deleted successfully!`, victim absent) + `is-solved`.

## Testing Methodology

1. Baseline the legitimate fetch (external URL → recorded oracle shape).
2. Swap destination to loopback root (`http://127.0.0.1/`) — reflected internal content = SSRF confirmed.
3. Escalate loopback targets stepwise: `/` → `/admin` → state-changing paths (`/admin/delete?username=<victim>`); fully URL-encode nested URLs; one variable per request.
4. Re-read internal state after each mutation (panel re-read, not status alone); confirm via solved marker.
5. Backend-range extension: when forms reference `192.168.0.x:<port>`, sweep the /24 on that port for `/admin` (threads + timeouts, per-host bodies); uniform refusal (e.g. 500/2454B) vs one admin page (200 + `delete?username=`) = the finding; then steps 3–4 through the hit host.
6. Blacklist-bypass extension: on 400-block, matrix host equivalents (`127.1`, `localhost`, trailing-dot, decimal/hex/octal, userinfo, whitespace, scheme-case) × path evasions (case, percent-encoding, dot-segments, `//`) INDEPENDENTLY; 400-block vs 200-content splits map each filter dimension. 200-wrong-page proves host bypass — then attack path separately. Per-target output files; check sizes before reading.
7. Whitelist double-decode extension: when single-decode tricks + redirect hunt both eliminate with evidence, test decode-count gaps in userinfo position with LOOPBACK-FIRST ordering (`http://<loopback>:<port>%2523@<whitelisted>/<path>`): validator sees userinfo (host ✓), fetcher re-decodes `#` and re-roots to loopback. Send RAW bodies (`--data`, never urlencoding helpers) and verify wire bytes — `%2523` vs `%252523` is 500-vs-302.
8. Open-redirect chain extension: when fetch input is path-constrained (absolute rejected), hunt redirectors taking absolute targets (`nextProduct?path=`, `redir`, `returnUrl`); prove follow-behavior with a BENIGN target first (product HTML via chain), then pivot to internal targets (loopback variants, then /24 sweep through the redirector on form-provided ports). Trichotomy per target: fetch-error (500) vs absent (404) vs content (200) maps liveness; topology differs per instance — probe, don't port conclusions.
9. Blind-OOB extension: with no reflected surface, build + HEALTH-CHECK the OOB receiver first (selftest hit); probe header vectors (Referer/Origin/UA) on content pages; wait out async windows (minutes) before concluding; treat zero-hits as ambiguous (wrong vector vs blocked receiver vs too early) and control each variable. Platform firewalls may restrict receivers (Collaborator-only) — use the imposed receiver; solve attribution may be by instance source (unique subdomain, no client session needed).

## Verification

- Fetch differential (external vs loopback) isolates server-side behavior.
- Impact proof is internal state change (victim absent, success message) + solved marker — deterministic, session-independent (anon here).

## Common Failure Modes

- Jumping to the delete URL before confirming reflection (uninterpretable results).
- Under-encoding nested `?`/`&` (use `--data-urlencode`).
- Trusting the mutation response status without re-reading internal state.

## Impact Considerations

- Internal admin compromise unauthenticated (demonstrated deletion); same primitive reaches metadata/internal APIs in real estates.

## Lessons Learned

- From PortSwigger “Basic SSRF against the local server”: stockApi external → `54`; loopback root → homepage HTML; `/admin` → delete links; delete-URL → 302; re-read → `User deleted successfully!` + `is-solved`. Five requests, all anon.
- From PortSwigger “Basic SSRF against another back-end system”: form URLs reference `192.168.0.1:8080`; /24 sweep (25 threads) → 254× uniform 500/2454B refusals vs `192.168.0.170:8080/admin` 200/3245B admin page; delete-URL through it → 302 → re-read success + `is-solved`. Adopt form-provided port/path; content (not status) oracles.
- From PortSwigger “SSRF with blacklist-based input filter”: `127.0.0.1` → 400-block; host matrix → only `127.1` passes (200 homepage); `/admin` path also filtered → case matrix → `/Admin`/`/ADMIN`/encoded pass (200 panel); delete-URL → 302 → re-read success + `is-solved`. Matrix host × path independently; router case-insensitive vs filter case-sensitive.

- From PortSwigger “SSRF with whitelist-based input filter”: strict parsed-host whitelist (host + parse-error + fetch-error tetrad mapped; ~30 single-decode/redirect probes eliminated) → double-decode `http://localhost:80%2523@stock…/admin/delete?username=carlos` RAW → 302 → re-read success + `is-solved`. Loopback-first ordering; `--data-urlencode` re-encoding (`%252523`) fails — verify wire bytes.
- From PortSwigger “SSRF with filter bypass via open redirection”: relative-only stockApi + open `nextProduct?path=` redirector (302 to arbitrary confirmed directly) → benign-follow control (product HTML via chain) → loopback:80 absent (404s) → /24 sweep via redirector → single hit `192.168.0.12:8080/admin` → delete-URL → re-read (victim absent) + `is-solved`. Benign-control-then-payload order.
- From PortSwigger “Blind SSRF with out-of-band detection”: no forms/stock/API/account surface; Referer/Origin/UA probes → identical 200s, zero hits on working webhook receiver over ~6 min (receiver health proved by selftest) → solution: Referer IS the vector, fetch async, firewall mandates Collaborator receiver → `Referer: http://<unique>.burpcollaborator.net/…` + 90s wait → `is-solved` by instance attribution. Disambiguate silence (vector vs receiver vs timing) with separate controls.

## Related Concepts

- Loopback trust boundaries (edge-deny vs server-reachable)
- methodology/verification.md (differential testing + state re-read)

## Sources

- PortSwigger lab: Basic SSRF against the local server (knowledge/portswigger/labs/ssrf-basic-local-server.md)
- PortSwigger lab: Basic SSRF against another back-end system (knowledge/portswigger/labs/ssrf-basic-backend-system.md)
- PortSwigger lab: SSRF with blacklist-based input filter (knowledge/portswigger/labs/ssrf-blacklist-filter-bypass.md)
- PortSwigger lab: SSRF with whitelist-based input filter (knowledge/portswigger/labs/ssrf-whitelist-double-decode.md)
- PortSwigger lab: SSRF with filter bypass via open redirection (knowledge/portswigger/labs/ssrf-open-redirect-chain.md)
- PortSwigger lab: Blind SSRF with out-of-band detection (knowledge/portswigger/labs/ssrf-blind-oob-detection.md)
