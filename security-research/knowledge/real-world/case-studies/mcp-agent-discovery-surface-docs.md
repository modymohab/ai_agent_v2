# Case Study — MCP / Agent discovery surface (.well-known) on docs platforms

Date: 2026-09-19 | Origin: mission arc-bbp-fullspectrum-2026-09-19 (Arc docs, Mintlify-hosted)
Status: reusable pattern (educational, sanitized — no target secrets)

## Surface
Documentation platforms (Mintlify, others) advertise structured discovery endpoints via a
`Link` header and `/.well-known/*`:

- `/.well-known/api-catalog`
- `/.well-known/mcp/server-card.json`
- `/.well-known/agent-card.json`
- `/.well-known/agent-skills/index.json`
- `/.well-known/agent-skills/<skill>/skill.md`
- `/llms.txt`, `/llms-full.txt`

## Generalizable observations / hypotheses to check (bounded, read-only)
1. The `server-card.json` for an MCP endpoint may disclose a **backend/hosting routing host**
   (`url` field) that differs from the public host. Check whether that host is in scope
   before probing it; treat it as reconnaissance output, otherwise as an out-of-scope lead.
2. **Discovery metadata may understate the live toolset**: compare the tool list in
   `server-card.json` against a live `tools/list` MCP call. A mismatch (extra write tools
   live that metadata omits) matters only if demonstrable abuse follows; a docs-accuracy
   mismatch is informational.
3. **Advertised capabilities vs reality**: `capabilities.resources:true` should be probed
   with a single read-only `resources/list`. Often it maps to one public resource (negative
   result, not a finding).
4. Skills indexes publish sha256 digests of skill definitions — content-integrity metadata;
   check the skill content for references to new hosts before treating them as in-scope.
5. CORS asymmetry within a host: public metadata JSON may carry `access-control-allow-origin: *`
   while the actual POST endpoint (`/mcp`, APIs) sends none. Do not generalize one path's CORS
   policy to the whole host.

## Repeatable technique
- Enumerate `/.well-known/*` once (single GET per path, no recursion).
- Fetch `/llms.txt` and `/llms-full.txt` to enumerate the full doc tree quickly.
- Diff discovery-metadata tool/resource lists against one live introspection call.
- Record hostnames discovered (public, backend) and classify each in/out of scope.

## Evidence quality notes
- Never invoke write tools surfaced in tool inventories during recon/hunting; record them and
  gate a single authorized benign invocation on an impact-demonstration phase.
- A toolset mismatch without a demonstrated impact is a rejection at triage, not a finding.