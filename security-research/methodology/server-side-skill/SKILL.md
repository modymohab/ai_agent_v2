# Server-Side Skill

> Dedicated capability built from existing project knowledge. Source template `../server-side.md` is a header-only stub; this skill is organized from the server-side knowledge that already exists in this repository (hunting references, the server-side vulnerability class skills, and header/Host-trust knowledge). See `# Source / Derivation`.

## Purpose

Organize and drive server-side security research: attacks whose trust boundary is crossed during **server-side processing** of attacker-controlled input — injection into server components (databases, parsers, templates, deserializers, command interpreters, file systems) and abuses of server trust of client-influenced headers/parameters/locations.

This is a capability layer. It routes to the class skills that hold the tested methodology (`../ssrf-skill/SKILL.md`, `../xxe-skill/SKILL.md`, `../injection-skill/SKILL.md`, `../ssti-skill/SKILL.md`, `../deserialization-skill/SKILL.md`, `../traversal-skill/SKILL.md`, `../file-security-skill/SKILL.md`, `../api-security-skill/SKILL.md`, `../access-control-skill/SKILL.md`) and to server-side hunting references. It must never be treated as a replacement for those skills.

## Scope

In scope (where the knowledge base documents them):

- Server-side request processing and trust of client-influenced inputs: headers (Host, X-Original-URL, Referer, TRACE-disclosed IP headers, X-Forwarded-For), parameters, locations.
- SSRF (server-initiated requests) and XXE; server-side injection families (SQL/NoSQL, command, SSTI); deserialization; path traversal; file upload/processing security.
- API/server trust boundaries (undocumented endpoints, server-side auth/model enforcement).
- Cache-ambiguous request handling where documented (host-header web-cache controversy is covered as host-trust; broader cache poisoning is a coverage boundary).

Out of scope (owned by other skills):

- Client-side execution / DOM sinks / browser controls — `../client-side-skill/SKILL.md`.
- Server-side **authorization decision** trust (role markers, object ownership) — `../access-control-skill/SKILL.md`.
- Identity/session primitives independent of class skills (enumeration, JWT/OAuth token flows) — `../authentication-skill/SKILL.md`, `../jwt-skill/SKILL.md`, `../oauth-sso-skill/SKILL.md`.

## Inputs

- Attack-surface model entries for **server-side functionality** and integrations (from `../reconnaissance-skill/SKILL.md`).
- Discovery outputs: endpoints, parameters (query/body/path/header/cookie), API contracts, file-upload surfaces, server-rendered templates, redirect/navigation logic.
- Baseline request/response pairs and header sets the application honors.
- Server-side hunting reference: `../../../skills/security-hunter/references/server-side.md`.

## Workflow

1. **Map input → server-side component → observable behavior.** For each suspected server-side surface, record which request data reaches which server component and what the observable output is (response body, header, timing, state change). This mapping is the hunting method documented in `../../../skills/security-hunter/references/server-side.md`.
2. **Classify the trust boundary.** Name the boundary an attack would cross: app→database (injection), app→file system (traversal), app→internal network (SSRF), app→parser (XXE), app→template/command interpreter (SSTI/command injection), app→object loader (deserialization), app→storage layer (file security), server-trust-of-header (host/X-Original-URL/IP).
3. **Select the class skill from the boundary**, not from a label — e.g. an endpoint that echoes input into a template selects `../ssti-skill/SKILL.md`; a fetch of a URL parameter selects `../ssrf-skill/SKILL.md`.
4. **Baseline then differential test.** Establish the non-vulnerable baseline first; change one variable; compare behavior — per `../verification-skill/SKILL.md`.
5. **Prefer non-destructive proof.** Per `../../../skills/security-hunter/references/server-side.md`: prefer non-destructive proof, do not access unrelated internal systems or data.
6. **Evidence capture and candidate pass-through** per class skill and `../verification-skill/SKILL.md`.

## Detection / Hypothesis Areas

Only the following areas are documented by the knowledge base; everything else is a coverage boundary (see `# Coverage Boundaries`).

### SSRF — server-initiated requests (detailed, supported)

`../ssrf-skill/SKILL.md` documents the full methodology: server fetch of attacker-influenced URL; filter-bypass chains (open-redirect relay — see `../../knowledge/portswigger/labs/ssrf-open-redirect-chain.md`); whitelist/blacklist bypass, double-decode; blind vs reflected detection. Server-side request behavior is a boundary (app→internal network) per the impact matrix in `../impact-analysis-skill/SKILL.md`.

### XXE — XML parser trust (detailed, supported)

`../xxe-skill/SKILL.md`: external entity resolution; file-read vs internal-SSRF vs OOB exfiltration; stack-dependent protocol handlers; local-DTD repurposing (see `../../knowledge/portswigger/labs/xxe-local-dtd-repurposing.md` if present). RCE only where the stack/handler demonstrably supports it.

### Server-side injection families (detailed, supported)

- SQL / NoSQL and command injection: `../injection-skill/SKILL.md`.
- Server-side template injection: `../ssti-skill/SKILL.md`.
- Applied sink-driven: prove the data reaches the sink before spending effort; never blind-test every class (per `../impact-analysis-skill/SKILL.md` step 7).

### Deserialization (detailed, supported)

`../deserialization-skill/SKILL.md`: object deserialization of attacker-influenced input (e.g. ViewState, pickle-style objects); object-state control instead of flat data.

### Path traversal / arbitrary file access (detailed, supported)

`../traversal-skill/SKILL.md`: sequence stripping / absolute-path / start-of-path validation / extension-null-byte variants; second-order and upload-extraction (zip-slip) write side.

### File upload / processing security (detailed, supported)

`../file-security-skill/SKILL.md`: malicious file processing, storage-then-serve trust, path-traversal-write in archive extraction.

### API / server trust boundaries (detailed, supported)

`../api-security-skill/SKILL.md`: undocumented endpoints, excessive data exposure, mass assignment, object authorization; server-side enforcement vs documented contracts (OpenAPI `security` arrays are documentation, not enforcement — see the worked example in the reporting skill's artifact checklist).

### Server trust of client-influenced headers (detailed, supported across skills)

- **Host header trust:** locality/interface checks that compare the Host string rather than the connection source → `../access-control-skill/SKILL.md` (Host-header auth bypass); host-header web-cache ambiguity note: `../../knowledge/portswigger/labs/host-header-web-cache-poisoning-ambiguous-requests.md`.
- **Rewrite-header trust (URL filtering desync):** `X-Original-URL`/`X-Rewrite-URL` filter-vs-router desync → `../access-control-skill/SKILL.md`.
- **IP-header trust:** `TRACE`-disclosed `X-Custom-IP-Authorization` loopback forgery → `../access-control-skill/SKILL.md`; counters honoring `X-Forwarded-For` value → `../authentication-skill/SKILL.md`.
- **Referer-gated mutations:** trust of `Referer` for authorization → `../access-control-skill/SKILL.md`.

## Verification

- Differential, single-variable testing with a preserved baseline; state re-read (re-request the affected object/state after the test), not status-code-only conclusions.
- Oracles: reflected file bytes in an error (exfiltration proof), 401-vs-content boundaries (auth-layer proof), timing only with statistics + controls.
- Never certify from the discovery request alone — independently re-perform per the meta-rule in `../verification-skill/SKILL.md`.
- For host/header trust: keep the connection target (SNI) identical; change only the header being tested; 302 alone is not proof — re-read state.

## Evidence

Preserve the baseline and the differential observation (request, response, decoded sink operand where relevant, before/after state). Safety-first per `../../../skills/security-hunter/references/server-side.md`: no access to unrelated internal systems or data; minimal necessary requests. Record failed candidates (encoded/neutralized reflections, wrong breakout, unreachable sinks) — defense shape is actionable intelligence.

## Handoff

- Candidates → `../verification-skill/SKILL.md`; verified primitives → `../impact-analysis-skill/SKILL.md` (impact matrix rows for SSRF/XXE/injection/traversal/etc., escalation chains).
- Composite surfaces (e.g. an API whose parsing differs from its docs) → `../api-security-skill/SKILL.md`.
- Header-trust findings that also move authorization → `../access-control-skill/SKILL.md` for the authorization boundary analysis.
- Generalized patterns → `../../knowledge/` class knowledge per AGENTS.md feedback rules.

## Related Skills

- `../ssrf-skill/SKILL.md`, `../xxe-skill/SKILL.md`, `../injection-skill/SKILL.md`, `../ssti-skill/SKILL.md`, `../deserialization-skill/SKILL.md`, `../traversal-skill/SKILL.md`, `../file-security-skill/SKILL.md`, `../api-security-skill/SKILL.md` — the class skills this capability dispatches to.
- `../access-control-skill/SKILL.md` — header/Host/IP-trust authorization mechanics.
- `../authentication-skill/SKILL.md` — X-Forwarded-For counter partitioning context.
- `../verification-skill/SKILL.md` — differential/baseline proof standards.
- `../impact-analysis-skill/SKILL.md` — class impact matrix (boundary → hypotheses → escalation paths → lab refs).
- `../client-side-skill/SKILL.md` — the complementary client-side capability.
- `../../../skills/security-hunter/references/server-side.md` — the hunting-layer server-side signal reference this skill is organized around.

## Source / Derivation

- **Directly derived:** the hunting method (map input → server-side component → observable behavior; safety: non-destructive proof, no unrelated internal access) and coverage list from `../../../skills/security-hunter/references/server-side.md`.
- **Cross-referenced (organized, not re-derived):** each server-side class skill listed above (`../ssrf-skill/SKILL.md`, `../xxe-skill/SKILL.md`, `../injection-skill/SKILL.md`, `../ssti-skill/SKILL.md`, `../deserialization-skill/SKILL.md`, `../traversal-skill/SKILL.md`, `../file-security-skill/SKILL.md`, `../api-security-skill/SKILL.md`), whose tested lab-derived methodology remains authoritative.
- **Header-trust content** is a cross-reference of `../access-control-skill/SKILL.md` and `../authentication-skill/SKILL.md` knowledge.
- **Source template:** `../../methodology/server-side.md` was an empty header-only stub; no verbatim body existed to migrate.

## Coverage Boundaries

The current knowledge base does not yet contain a dedicated methodology for:

- **HTTP request smuggling** (only cited as a boundary in `../impact-analysis-skill/SKILL.md` step 2, no class skill or lab knowledge). Closest existing skill: `../injection-skill/SKILL.md` / `../api-security-skill/SKILL.md` — treat smuggling hypotheses as unverified until researched.
- **General web-cache poisoning** (only the host-header cache-poisoning lab note exists). Closest: `../access-control-skill/SKILL.md` Host-trust section.
- **CORS misconfiguration as a server-side class** (referenced in orchestration only, no repository methodology). Closest: `../api-security-skill/SKILL.md`.
- **Mass URL-based request mutation / parameter-polution server parsing** beyond the documented traversal/encoding families.
- **Server-side request-mutation classes not covered by the class skills above** (e.g. request-smuggling-driven caching, protocol-level splitting).

Within the *documented* areas above, this skill provides organization and dispatch; the class skills are the detailed methodology.