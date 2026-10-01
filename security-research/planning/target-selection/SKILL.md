# Target Selection Skill

> Provenance: canonicalized from
> `skills/web-security-research/references/target-selection.md` (411 lines,
> classified UNIQUE by `index/parallel-knowledge-audit.md`, confirmed by
> `index/canonical-ownership-plan.md`). Migrated in Batch 1B-1 (planning-layer
> canonicalization). Original source retained as a derived/reference copy;
> content preserved, restructured into the standard skill layout.

## Canonical owner

```text
security-research/planning/target-selection/SKILL.md
```

---

# 1. Purpose

Select an authorized research target that provides a meaningful and
sufficiently testable web security surface.

Target selection is a research-planning step.

It is NOT vulnerability prediction.

The existence of a large bounty, a popular target, a complex application, a
previous vulnerability, or a specific technology does not establish that a
target is vulnerable.

The objective is to identify an in-scope target where systematic security
research can be performed safely, efficiently, and with measurable coverage.

---

# 2. Scope

This skill covers the decision stage that precedes application mapping, recon,
and hunting.

It decides:

- whether a target may enter active research at all (authorization gate)
- which candidate is selected and why
- what constraints and unknowns are recorded before mapping begins

It does NOT cover:

- application mapping (future canonical capability, see §8)
- reconnaissance or attack-surface discovery
- vulnerability hypothesis generation
- testing, verification, triage, impact, or reporting

Target selection does not establish security posture. It establishes the
authorized starting point for research.

---

# 3. Inputs

- Official program policy (authoritative, current)
- Program scope: exact in-scope assets, exclusions, protocols
- Program-provided assets and documentation
- Existing authorized reconnaissance and mission knowledge
- Candidate list built from authorized sources (§4)
- Operational constraints (rate limits, permitted methods, prohibited actions)

Prefer the program's current authoritative policy over third-party scope
databases.

---

# 4. Workflow

## Step 1 — Authorization gate

No target may enter active research until authorization has been established.

Verify:

- Program identity
- Official program policy
- Exact in-scope asset
- Protocol
- Hostname/domain
- Path restrictions, if any
- Authentication requirements
- Account requirements
- Testing restrictions
- Rate limits
- Prohibited actions
- Program-specific exclusions
- Disclosure requirements

Record:

```yaml
authorization:
  verified: true|false
  source:
  checked_at:
  notes:
```

If authorization cannot be established:

```text
STOP
```

Do not perform active testing against the unresolved target.

## Step 2 — Candidate discovery

Build the candidate list from authorized sources.

Possible sources include:

- Official program scope
- Official documentation
- Program-provided assets
- Existing authorized reconnaissance
- Existing mission knowledge
- Application documentation
- Previously mapped assets that remain in scope

Do not expand the scope merely because an apparently related hostname or
service exists.

Every candidate must be mapped back to an explicitly authorized asset where
possible.

## Step 3 — Target classification

For each candidate, classify the research surface.

Record:

```yaml
asset:
  hostname:
  protocol:
  type:
  scope_status:

application:
  type:
  authentication:
  api:
  user_roles:
  organizations:
  resources:
  workflows:
  integrations:
```

Useful application types include:

- Web application
- API
- SaaS platform
- Administrative portal
- Customer portal
- Developer platform
- Authentication service
- Documentation platform
- Dashboard
- Marketplace
- Integration platform

Do not assume that the application type implies a vulnerability class.

## Step 4 — Research-surface assessment

Evaluate whether the target provides meaningful security boundaries.

Look for observable characteristics such as:

### Identity

- Authentication
- Multiple accounts
- Session management
- Account recovery
- Role assignment

### Authorization

- Multiple roles
- Resource ownership
- Organization boundaries
- Team membership
- Administrative permissions
- Sharing

### Resources

- User-owned objects
- Organization-owned objects
- Files
- Projects
- Documents
- Transactions
- Configurations
- API resources

### Workflows

- Invitations
- Permission changes
- Ownership changes
- Account changes
- State transitions
- Administrative actions
- Integrations

### APIs

- REST
- GraphQL
- RPC
- Internal APIs exposed to the browser
- State-changing endpoints

### Trust boundaries

- User → application
- User → organization
- User → administrator
- Application → third-party service
- Browser → API
- Service → service

These are indicators of research surface, not evidence of vulnerabilities.

## Step 5 — Suitability assessment

Determine whether the target is suitable for systematic testing.

Document factual reasons such as:

```yaml
suitability:
  interactive_application: true|false
  authenticated_surface: true|false
  multiple_roles: true|false
  resource_ownership: true|false
  api_surface: true|false
  stateful_workflows: true|false
  integrations: true|false
  administrative_surface: true|false

reasons:
  - ...
```

Do not assign a numeric score.

Do not call a target "best" or "worst."

Do not predict whether a target will produce findings.

## Step 6 — Constraints assessment

Before selection, record operational constraints.

Examples:

- Rate limits
- Low request volume requirements
- No automated scanning
- No denial-of-service testing
- No destructive testing
- No social engineering
- No third-party testing
- No production data modification
- Required test accounts
- Required headers
- Required identification
- Geographic restrictions

Example:

```yaml
constraints:
  rate_limit:
  automation:
  destructive_testing:
  authentication:
  test_accounts:
  prohibited_actions:
```

The strictest applicable restriction must be respected.

## Step 7 — Selection decision

Select a target only when:

1. Authorization is verified.
2. The asset is explicitly in scope.
3. Operational restrictions are understood.
4. The application can be meaningfully mapped.
5. The research surface is sufficiently understood to begin application mapping.

Selection does not mean:

```text
"This target is vulnerable."
```

Selection means:

```text
"This target is authorized and provides a suitable surface for systematic research."
```

## Step 8 — Target selection output

Create a target selection artifact.

Recommended location:

```text
mission-###/target-selection.yaml
```

Recommended structure:

```yaml
mission:
  id:
  program:

target:
  hostname:
  protocol:
  asset_type:

authorization:
  verified:
  source:
  checked_at:

scope:
  in_scope:
  out_of_scope_notes:

application:
  type:
  authentication:
  roles:
  api:
  resources:
  workflows:
  integrations:

research_surface:
  identity:
  authorization:
  resources:
  workflows:
  api:
  trust_boundaries:

constraints:
  rate_limit:
  automation:
  destructive_testing:
  authentication:
  prohibited_actions:

selection_reasons:
  - ...

unknowns:
  - ...

status: selected
```

---

# 5. Decision / Selection Criteria

Selection requires all five conditions from §4 Step 7:

1. Authorization verified
2. Explicitly in scope
3. Operational restrictions understood
4. Application can be meaningfully mapped
5. Research surface sufficiently understood to begin application mapping

### Anti-bias rules

Do not select targets because:

- Another researcher found a bug there.
- A writeup exists.
- The bounty is large.
- The technology is fashionable.
- The target looks complex.
- A vulnerability class is historically common.
- A scanner produced an interesting result.
- The target "feels vulnerable."

Use documented application characteristics and authorized scope instead.

### Failure conditions — stop or return to scope review when:

- Authorization is unclear.
- The asset is outside scope.
- Scope changed and has not been revalidated.
- Testing restrictions prohibit the intended activity.
- The required account or permission context is unavailable.
- The target cannot be distinguished from an out-of-scope asset.
- The requested testing would require prohibited activity.

Never bypass an authorization problem by continuing with passive assumptions.

---

# 6. Evidence

Target selection produces documented, factual evidence:

- Authorization evidence (source, checked_at, verification state)
- Scope evidence (in-scope / out-of-scope notes)
- Application characteristics (type, authentication, roles, APIs, resources,
  workflows, integrations)
- Research-surface indicators (identity, authorization, resources, workflows,
  APIs, trust boundaries)
- Constraints (rate limits, automation, destructive testing, authentication,
  prohibited actions)
- Selection reasons (factual, documented)
- Recorded unknowns

All recorded evidence is descriptive of the authorized target. It is not
evidence of vulnerabilities and is not a substitute for later observation.

---

# 7. Handoff

The target-selection stage hands the following to the application-mapping stage:

```text
TARGET
SCOPE
AUTHORIZATION EVIDENCE
CONSTRAINTS
KNOWN APPLICATION TYPE
KNOWN ROLES
KNOWN APIs
KNOWN RESOURCES
KNOWN WORKFLOWS
KNOWN UNKNOWNs
```

The next agent must not assume that the target is fully mapped.

The purpose of the next stage is to discover and structure the application's
actual attack surface.

### Completion criteria

Target selection is complete when:

- Authorization is verified.
- Scope is documented.
- Restrictions are documented.
- One research target is established.
- Known application characteristics are recorded.
- Unknowns are explicitly recorded.
- The target-selection artifact exists.
- Application mapping can begin.

---

# 8. Related Skills

```text
target-selection
    ↓
application-mapping   (future canonical capability — planned, not yet created)
    ↓
reconnaissance        (security-research/methodology/reconnaissance-skill/SKILL.md)
```

```text
target-selection
    ↓
orchestrator          (agents/orchestrator.md — mission planning consumes the
                       target-selection artifact)
```

Conceptual links (do not copy their bodies):

- **Application mapping** — PLANNED canonical capability
  (`security-research/planning/application-mapping/SKILL.md`). Until then, the
  current source of application-mapping knowledge is
  `skills/web-security-research/references/application-mapping.md`
  (parallel reference).
- **Hypothesis generation** — PLANNED canonical capability
  (`security-research/planning/hypothesis-generation/SKILL.md`). Until then, the
  current source is
  `skills/web-security-research/references/hypothesis-generation.md`
  (parallel reference).
- **Hypothesis generation** feeds the hunter layer; target selection does not
  produce hypotheses itself.
- **Reconnaissance** — canonical
  `security-research/methodology/reconnaissance-skill/SKILL.md`.

---

# 9. Source / Derivation

- Original source: `skills/web-security-research/references/target-selection.md`
  (classified UNIQUE, no canonical counterpart, in `index/parallel-knowledge-audit.md`
  section 2.1 and Special Area A; listed as additional unique knowledge in
  `index/methodology.md`).
- Canonical ownership decision: promote the UNIQUE planning capability to a
  standalone canonical planning skill under `security-research/planning/`; NOT a
  vulnerability methodology (deliberately not placed under `methodology/`);
  NOT merged into reconnaissance; NOT merged into the hunter.
- Migration context: Batch 1B-1 of the controlled migration sequence, following
  the canonical ownership design (`index/canonical-ownership-plan.md`).
- What was migrated: the full substantive target-selection capability (purpose,
  authorization gate, candidate discovery, classification, research-surface
  assessment, suitability, constraints, selection decision, output artifact,
  handoff, failure conditions, anti-bias rules, completion criteria).
- What was intentionally excluded: none substantive. The source contained no
  tool-specific or agent-specific operational instructions to promote or to
  separate.
- Original source status: retained unchanged as a derived/reference copy.

---

# 10. Coverage Boundaries

This skill owns the planning decision of which authorized target enters
research.

It is NOT:

- a vulnerability methodology (no class bodies, no testing procedures)
- reconnaissance or attack-surface discovery
- application mapping (future canonical capability, §8)
- vulnerability prediction or target scoring
- a hunting, verification, triage, impact, or reporting skill

Boundary rule: this skill decides THAT research on an authorized surface may
begin and WHY; it does not decide WHAT will be found there.