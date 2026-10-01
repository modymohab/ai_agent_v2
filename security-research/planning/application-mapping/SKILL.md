# Application Mapping Skill

> Provenance: canonicalized from
> `skills/web-security-research/references/application-mapping.md` (712 lines,
> classified UNIQUE by `index/parallel-knowledge-audit.md` §2.1 / Special Area B,
> confirmed by `index/canonical-ownership-plan.md`). Migrated in Batch 1B-2
> (planning-layer canonicalization). Original source retained as a
> derived/reference copy; content preserved, restructured into the standard
> skill layout.

## Canonical owner

```text
security-research/planning/application-mapping/SKILL.md
```

---

# 1. Purpose

Build a structured model of an authorized application's attack surface before
systematic vulnerability hunting.

Application mapping converts an application from:

```text
Unknown application
```

into:

```text
Hosts
→ Routes
→ APIs
→ Authentication
→ Roles
→ Resources
→ Ownership
→ Workflows
→ State transitions
→ Trust boundaries
```

The map is a research model, not a claim that the entire application has been
discovered.

---

# 2. Scope

This skill owns the planning-layer capability of decomposing and mapping the
structure and attack surface of an already-selected authorized application.

It covers:

- host, route, API, authentication, role, resource, object-identifier,
  workflow, state, trust-boundary, and sensitive-function mapping
- mapping principles and decomposition criteria
- evidence requirements for map entries
- map output artifacts and handoff
- explicit handling of unknowns

It does NOT cover:

- choosing which target to research (owned by `planning/target-selection`)
- hypothesis generation (future planning capability; see §11)
- reconnaissance or attack-surface discovery execution
- vulnerability testing, hunting, verification, triage, impact, or reporting

Application mapping answers:

```text
"What exists?"
"Who can interact with it?"
"What resource does it affect?"
"What security boundary surrounds it?"
```

Vulnerability testing answers:

```text
"Does the security boundary fail?"
```

Do not confuse the two.

---

# 3. Inputs

- Authorized target plus target-selection artifact (from
  `planning/target-selection`): target, scope, authorization evidence,
  constraints, known application characteristics
- Program scope and rules
- Authorized mapping sources (§4)
- Existing mission artifacts
- Known unknowns carried forward from target selection

---

# 4. Application Mapping Workflow

Mapping sources (§4.1) and principles (§4.2) apply throughout. Proceed through
the mapping stages in dependency order where practical.

## 4.1 Mapping Sources

Use authorized sources such as:

### Browser

Observe:

- Pages
- Navigation
- Forms
- Network requests
- API calls
- Authentication transitions
- State changes

### HTTP Proxy

Use authorized proxy history to identify:

- Methods
- Paths
- Parameters
- Headers
- Cookies
- Tokens
- Request bodies
- Response patterns

### Documentation

Review:

- API documentation
- Application documentation
- Help pages
- Developer documentation
- Feature documentation

### Authorized Reconnaissance

Use only reconnaissance permitted by the program.

Respect:

- Scope
- Rate limits
- Automation restrictions
- Program rules

## 4.2 Mapping Principles

Application mapping must be:

- Scope-aware
- Evidence-driven
- Incremental
- Non-destructive
- Rate-limit-aware
- Reproducible
- Explicit about unknowns

Do not claim complete coverage based on a homepage crawl.

Do not assume that visible UI represents the entire application.

Do not assume that an API endpoint is authorized merely because the UI hides it.

Do not assume that an endpoint is vulnerable merely because it is reachable.

## 4.3 Stage 1 — Host Mapping

Identify known hosts.

Example:

```yaml
hosts:
  - hostname:
    protocol:
    purpose:
    environment:
    scope:
    evidence:
```

Possible classifications:

- Production
- Staging
- Development
- API
- Documentation
- Authentication
- Administration
- Static content
- CDN
- Other

Do not test an environment merely because it appears related.

Verify scope independently.

## 4.4 Stage 2 — Route Mapping

Map application routes.

Record:

```yaml
routes:
  - method:
    path:
    feature:
    authentication_required:
    role_context:
    resource:
    state_changing:
    evidence:
```

Examples of useful route categories:

- Authentication
- Account
- Profile
- Organization
- Team
- Projects
- Files
- Documents
- Settings
- Administration
- Billing
- Integrations
- API
- Search
- Import/export

The category should reflect observed application behavior.

## 4.5 Stage 3 — API Mapping

Identify APIs exposed through normal application functionality.

Record:

```yaml
apis:
  - method:
    path:
    api_type:
    function:
    authentication:
    role_context:
    resource:
    object_identifier:
    state_changing:
    evidence:
```

Pay attention to:

- Object identifiers
- User identifiers
- Organization identifiers
- Resource IDs
- Role parameters
- Ownership fields
- State parameters
- Hidden API operations
- Alternate HTTP methods

Do not assume an API weakness from parameter names alone.

## 4.6 Stage 4 — Authentication Mapping

Document:

- Login
- Logout
- Session establishment
- Session expiration
- Password changes
- Account recovery
- MFA
- Email verification
- Role assignment
- Account switching
- Authentication state transitions

Record:

```yaml
authentication:
  mechanism:
  session_type:
  login:
  logout:
  recovery:
  mfa:
  verification:
  role_assignment:
  account_switching:
  unknowns:
```

Do not conduct credential attacks unless explicitly authorized.

## 4.7 Stage 5 — Role Mapping

Identify distinct roles and their observed capabilities.

Example:

```yaml
roles:
  - name:
    capabilities:
      view:
      create:
      modify:
      delete:
      administer:
    evidence:
```

For each role, distinguish:

```text
What can the role see?
What can the role create?
What can the role modify?
What can the role delete?
What can the role administer?
```

Do not infer permissions solely from role names.

## 4.8 Stage 6 — Resource Mapping

Identify important application objects.

Examples:

- User
- Organization
- Team
- Project
- Document
- File
- Invoice
- Transaction
- API key
- Integration
- Configuration

Record:

```yaml
resources:
  - name:
    identifier:
    creator:
    owner:
    readers:
    writers:
    administrators:
    lifecycle:
    evidence:
```

The goal is to understand ownership and authority boundaries.

## 4.9 Stage 7 — Object Identifier Mapping

For important objects, document how the application identifies them.

Examples:

- Numeric ID
- UUID
- Slug
- Username
- Email
- Composite identifier
- Token
- Opaque reference

Record:

```yaml
identifiers:
  - resource:
    identifier_type:
    location:
    observed_behavior:
```

Identifier predictability alone is not evidence of IDOR.

The relevant question is whether authorization is correctly enforced around the
object.

## 4.10 Stage 8 — Workflow Mapping

Identify multi-step workflows.

Examples:

- Account creation
- Invitation
- Organization creation
- Resource sharing
- Permission changes
- Ownership transfer
- File upload
- Import/export
- Integration setup
- Account recovery
- Administrative changes

Record:

```yaml
workflows:
  - name:
    actors:
    prerequisites:
    steps:
    state_changes:
    sensitive_actions:
    trust_boundaries:
    evidence:
```

Do not reduce a multi-step workflow to isolated endpoints when state
transitions matter.

## 4.11 Stage 9 — State Mapping

Identify meaningful states and transitions.

Example:

```text
Draft
  ↓
Submitted
  ↓
Approved
  ↓
Completed
```

Record:

```yaml
state_transitions:
  - workflow:
    from_state:
    action:
    to_state:
    actor:
    authorization:
    evidence:
```

State transitions are particularly important when:

- Multiple roles participate.
- Approval is required.
- Ownership changes.
- Actions become irreversible.
- Security-sensitive operations occur.

## 4.12 Stage 10 — Trust-Boundary Mapping

Identify where authority changes.

Common boundaries:

```text
User
 ↓
Application

User
 ↓
Organization

Member
 ↓
Administrator

Browser
 ↓
API

Application
 ↓
Third-party integration

Service A
 ↓
Service B
```

Record:

```yaml
trust_boundaries:
  - boundary:
    actors:
    trusted_input:
    security_decision:
    protected_resource:
    evidence:
```

The existence of a trust boundary does not imply that it is broken.

## 4.13 Stage 11 — Sensitive Functions

Identify functions where authorization or business rules matter significantly.

Examples:

- Change email
- Change password
- Reset credentials
- Add administrator
- Invite member
- Remove member
- Change ownership
- Export data
- Access private resource
- Modify security settings
- Create API credentials
- Configure integrations

Record:

```yaml
sensitive_functions:
  - function:
    actor:
    required_role:
    protected_resource:
    security_boundary:
    evidence:
```

## 4.14 Stage 12 — Attack-Surface Model

The application map should eventually produce:

```text
Application
│
├── Authentication
│
├── Account Management
│
├── Authorization
│   ├── User
│   ├── Organization
│   ├── Resource
│   └── Administrative
│
├── APIs
│
├── Resources
│
├── Workflows
│
├── State Transitions
│
├── Integrations
│
└── Administrative Functions
```

Only include branches supported by evidence.

---

# 5. Mapping / Decomposition Criteria

Decompose the application into the documented dimensions and record each entry
against the schemas in §4:

- Hosts (scope-verified individually)
- Routes (categorized by observed behavior)
- APIs (with object identifiers, role fields, state parameters)
- Authentication (mechanism, transitions, recovery, MFA)
- Roles (observed capabilities, not name inferences)
- Resources (ownership and authority boundaries)
- Object identifiers (location and observed behavior)
- Workflows (actors, prerequisites, steps, state changes, boundaries)
- State transitions (when security- or ownership-relevant)
- Trust boundaries (where authority changes)
- Sensitive functions (authorization/business-rule significance)

Criteria:

- Record only what is observed or explicitly inferred; mark the distinction.
- Do not claim complete coverage from a homepage crawl or visible UI alone.
- Do not treat an endpoint's existence as authorization or as a weakness.
- Verify host scope independently; do not test look-alike environments.
- Keep the map incremental, evidence-driven, and rate-limit-aware.

---

# 6. Evidence Requirements

Every important map entry should have supporting evidence where practical.

Useful evidence includes:

- HTTP request
- HTTP response
- Browser observation
- API documentation
- Application behavior
- Program documentation
- Existing mission artifact

Avoid recording assumptions as facts.

Use:

```text
observed
inferred
unknown
```

when useful.

---

# 7. Outputs / Artifacts

## Application Map Artifact

Recommended location:

```text
mission-###/application-map.yaml
```

Example:

```yaml
application:
  name:
  type:

hosts:
  - ...

routes:
  - ...

apis:
  - ...

authentication:
  ...

roles:
  - ...

resources:
  - ...

identifiers:
  - ...

workflows:
  - ...

state_transitions:
  - ...

trust_boundaries:
  - ...

sensitive_functions:
  - ...

unknowns:
  - ...

mapping_status:
  partial|substantial
```

Record the structured map as the persistent artifact. Conversation output alone
is not the map.

## Unknowns

Explicitly record unknown areas.

Example:

```yaml
unknowns:
  - undocumented_api_routes
  - second_role_behavior
  - organization_boundary
  - integration_permissions
```

Unknown does not mean vulnerable.

Unknown means additional research may be required.

---

# 8. Handoff

Application Mapping hands the following to the next stage:

```text
HOSTS
ROUTES
APIs
AUTHENTICATION
ROLES
RESOURCES
IDENTIFIERS
OWNERSHIP
WORKFLOWS
STATE TRANSITIONS
TRUST BOUNDARIES
SENSITIVE FUNCTIONS
UNKNOWNS
EVIDENCE
```

The next stage converts these observations into explicit security hypotheses.

The next stage must not assume that the application is fully mapped; it receives
a structured model, not a finished inventory.

---

# 9. Completion Criteria

Application mapping is sufficiently complete when:

- Major hosts are identified.
- Major application areas are identified.
- Authentication boundaries are understood.
- Relevant roles are identified.
- Important resources are identified.
- Ownership relationships are documented where known.
- Important APIs are mapped.
- Sensitive workflows are identified.
- Meaningful state transitions are documented.
- Major trust boundaries are identified.
- Unknowns are explicitly recorded.

"Mapped" does not mean "secure."

It means the research team has a structured model from which hypotheses can be
generated.

---

# 10. Failure Conditions / Boundaries

- Scope violation: mapping an unverified host or environment merely because it
  appears related is a failure. Verify scope independently for each host.
- Premature completion: claiming complete coverage based on a homepage crawl or
  visible UI. The map is incremental and evidence-driven.
- Assumption errors: treating an endpoint's existence as authorization, or an
  API parameter name as evidence of weakness. Record observed vs inferred vs
  unknown.
- Destruction / abuse: mapping must be non-destructive, rate-limit-aware, and
  restricted to program-permitted reconnaissance and observations.
- Boundary violation: application mapping produces a research model; if the
  work crosses into security-boundary testing (asking "does the boundary
  fail?"), it has left the planning layer.

---

# 11. Related Capabilities

```text
target-selection (existing canonical)
    ↓
application-mapping (this skill)
    ↓
hypothesis-generation (future/planned canonical capability)
    ↓
reconnaissance / hunting (execution layers)
```

Existing canonical capabilities:

- `planning/target-selection/SKILL.md` — chooses an authorized research target
  and records its characteristics. This skill decomposes the selected
  application. Selection and mapping are distinct: selection picks a suitable
  surface; mapping builds the structured model.

Future / planned canonical capabilities (do not treat as existing files):

- `planning/hypothesis-generation/SKILL.md` — PLANNED. Will consume this
  skill's map output to produce explicit security hypotheses. It does not exist
  yet; referenced here only as planned architecture.
- Prior to its creation, the parallel reference
  `skills/web-security-research/references/hypothesis-generation.md` remains the
  source of hypothesis-generation knowledge.

Execution-layer relationships (do not duplicate their bodies):

- Reconnaissance: `methodology/reconnaissance-skill/SKILL.md`
- Orchestrator: `agents/orchestrator.md` (consumes the map for coverage
  planning)

---

# 12. Source / Derivation

- Original source: `skills/web-security-research/references/application-mapping.md`
  (712 lines; classified UNIQUE in `index/parallel-knowledge-audit.md` §2.1 and
  Special Area B; listed as additional unique knowledge in
  `index/methodology.md`).
- Canonical ownership decision: promote the UNIQUE mapping capability to a
  standalone canonical planning skill under `security-research/planning/`;
  NOT a vulnerability methodology (not placed under `methodology/`); NOT merged
  into reconnaissance, hunter, or foundation.
- Migration context: Batch 1B-2 of the controlled migration sequence, following
  the canonical ownership design (`index/canonical-ownership-plan.md`).
- What was preserved: all 19 source sections (mapping principles, mapping
  sources, host/route/API/auth/role/resource/identifier/workflow/state/
  trust-boundary/sensitive-function mapping, attack-surface model, mapping-vs-
  testing, evidence requirements, unknowns, map artifact, handoff, completion
  criteria) with their YAML schemas retained verbatim.
- What was intentionally excluded: no substantive content was excluded.
  Recording requirements already documented in the source are preserved.
- Unresolved content: none.

---

# 13. Coverage / Preservation Notes

- This skill owns the full application-mapping capability identified by the
  audit; nothing substantive is left in the source that is not represented here.
- No operational/tool-specific material required exclusion: the source's
  "Authorized Reconnaissance" subsection names no tools and imposes only
  program-rule constraints; it is preserved as evidence/source taxonomy, not as
  tool instructions.
- The original source is retained unchanged as the derived/reference copy and
  remains authoritative for provenance.
- Coverage boundary: this skill does not generate hypotheses, does not select
  targets, and does not test security boundaries.