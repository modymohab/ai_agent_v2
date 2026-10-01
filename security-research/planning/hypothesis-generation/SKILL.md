# Hypothesis Generation Skill

> Provenance: canonicalized from
> `skills/web-security-research/references/hypothesis-generation.md` (809 lines,
> classified UNIQUE by `index/parallel-knowledge-audit.md` §2.1 and confirmed by
> `index/canonical-ownership-plan.md`). Migrated in Batch 1B-3 (planning-layer
> canonicalization). Original source retained as a derived/reference copy;
> content preserved, restructured into the standard skill layout.

## Canonical owner

```text
security-research/planning/hypothesis-generation/SKILL.md
```

---

# 1. Purpose

Convert application observations and security boundaries into explicit,
testable security hypotheses.

The objective is to transform:

```text
Application Map
+
Security Model
+
Observed Behavior
```

into:

```text
Testable Security Hypotheses
```

A hypothesis is not a vulnerability.

A hypothesis becomes a candidate only after evidence indicates that the
expected security property may not hold.

A candidate becomes a finding only after appropriate verification and triage.

---

# 2. Scope

This skill owns the planning-layer capability of turning a mapped application
and its security context into explicit, testable security hypotheses.

It covers:

- hypothesis construction and required fields
- security-property framing
- hypothesis categories grounded in the actual application
- observation → hypothesis → test transformation
- prioritization and test design
- candidate creation, negative results, false-positive defense,
  duplicate prevention, and lifecycle
- handoff to verification and to specialized research capabilities

It does NOT cover:

- selecting the target (owned by `planning/target-selection`)
- mapping the application (owned by `planning/application-mapping`)
- reconnaissance, hunting, or other discovery
- vulnerability testing, exploitation, verification, triage, impact, or
  reporting execution

Separation of responsibilities:

```text
Target selection:    choosing what should be researched.
Application mapping: understanding and modeling the selected application's
                     structure.
Hypothesis generation: turning the mapped application/security context into
                     explicit, testable security hypotheses.
```

This skill does NOT become a testing or exploitation guide. It defines the
questions, not the attack.

---

# 3. Inputs

- Application map artifact (from `planning/application-mapping`): hosts,
  routes, APIs, authentication, roles, resources, identifiers, ownership,
  workflows, state transitions, trust boundaries, sensitive functions,
  unknowns, evidence
- Target-selection artifact and program scope/rules
- Observed application behavior (authorized)
- Security model of the application (boundaries, actors, protected resources)
- Existing hypotheses, candidates, findings, mission artifacts, and persistent
  knowledge base (for duplicate prevention)

---

# 4. Hypothesis Generation Workflow

## 4.1 Core research model

Use:

```text
Observation
    ↓
Security Boundary
    ↓
Expected Secure Behavior
    ↓
Hypothesis
    ↓
Minimal Test
    ↓
Evidence
    ↓
Verification
    ↓
Triage
    ↓
Impact
    ↓
Finding
```

Never skip directly from:

```text
Observation
```

to:

```text
Finding
```

## 4.2 Observation → Hypothesis pattern

Use this pattern:

```text
OBSERVATION:
What did we actually observe?

BOUNDARY:
What security boundary is involved?

EXPECTED:
What should a secure implementation do?

HYPOTHESIS:
What specific failure could violate that property?

TEST:
What is the smallest authorized test that can distinguish
secure behavior from the hypothesized failure?
```

## 4.3 Hypothesis quality gate

Before testing, ask:

1. Is there an actual observed feature?
2. Is there a defined security boundary?
3. Is the expected secure behavior clear?
4. Is the failure condition specific?
5. Is the test authorized?
6. Can the hypothesis be tested with minimal impact?
7. Is the required evidence defined?
8. Is this different from an existing hypothesis?

If several answers are "no", improve the hypothesis before testing.

## 4.4 Prioritization

Do not use bounty size or vulnerability popularity as the sole prioritization
mechanism.

Prioritize hypotheses using observable research value:

### Strong security boundary

Examples:

- Owner vs non-owner
- Member vs administrator
- User vs organization
- Authenticated vs unauthenticated

### Sensitive resource

Examples:

- Private data
- Credentials
- Security settings
- Administrative configuration
- Organization resources

### Sensitive action

Examples:

- Modify
- Delete
- Transfer ownership
- Grant permissions
- Export
- Change security settings

### Multiple actors

Hypotheses involving multiple roles or accounts may provide stronger
opportunities to test authorization boundaries.

### Observable behavior

Prefer hypotheses where the application already provides enough evidence to
define a meaningful test.

Do not assign arbitrary scores unless the mission system explicitly requires
them.

## 4.5 Research discipline

Never generate hypotheses merely to increase the hypothesis count.

Ten meaningful hypotheses are more useful than one hundred arbitrary payload
attempts.

Every hypothesis should answer:

```text
What security property are we testing?
Why does this application feature create that boundary?
What exact behavior would demonstrate a failure?
What evidence would be sufficient?
```

---

# 5. Hypothesis Construction Criteria

## 5.1 What is a good hypothesis?

A good hypothesis is:

- Specific
- Testable
- Evidence-based
- Connected to an actual application feature
- Connected to a security boundary
- Reproducible
- Scoped to an authorized target

Bad hypothesis:

```text
"This endpoint probably has IDOR."
```

Better:

```text
"A non-owner account may be able to retrieve another user's project
by changing the project identifier in the authenticated API request."
```

The second statement defines:

- Actor
- Resource
- Boundary
- Action
- Failure condition

## 5.2 Required hypothesis fields

Every hypothesis must contain:

```yaml
id:
category:
feature:
target:

observation:

security_boundary:

actor:

protected_resource:

expected_behavior:

hypothesized_failure:

test_method:

required_context:

evidence_required:

constraints:

status:
```

Initial status:

```text
untested
```

## 5.3 Security properties

Generate hypotheses around security properties rather than payloads.

Examples:

### Confidentiality

```text
Can an unauthorized actor read protected data?
```

### Integrity

```text
Can an unauthorized actor modify protected data?
```

### Authorization

```text
Can an actor perform an action outside their role?
```

### Ownership

```text
Can an actor interact with an object they do not own?
```

### Authentication

```text
Can a protected action be performed without the required authentication state?
```

### State Integrity

```text
Can an actor force an invalid or unauthorized state transition?
```

### Business Rule Integrity

```text
Can an actor bypass an important application rule?
```

### Trust Boundary Integrity

```text
Can untrusted input influence a security-sensitive decision?
```

## 5.4 Hypothesis categories

Use categories supported by the actual application.

### Authentication

Possible hypothesis areas:

- Authentication state transitions
- Session boundaries
- Logout/session invalidation
- Recovery workflows
- Verification flows
- Account switching
- MFA state transitions
- Role assignment

Do not assume a weakness merely because a feature exists.

### Access Control

Possible hypothesis areas:

### Horizontal Authorization

```text
User A
→ Resource owned by User B
```

### Vertical Authorization

```text
Low-privilege role
→ Administrator-only action
```

### Organization Boundaries

```text
Organization A
→ Resource belonging to Organization B
```

### Ownership

```text
Non-owner
→ Owner-only action
```

### Administrative Functions

```text
Member
→ Administrator operation
```

Each hypothesis must identify the actual boundary.

### API Security

Consider:

- Object-level authorization
- Function-level authorization
- Method-specific authorization
- API/UI authorization differences
- Resource ownership
- State-changing endpoints
- Hidden or undocumented API functionality
- Alternate representations

Do not classify an API as vulnerable simply because an endpoint is
undocumented.

### Business Logic

Consider:

- Workflow assumptions
- State transitions
- Permission changes
- Ownership changes
- Invitation flows
- Resource sharing
- Conflicting operations
- Duplicate operations
- Trust assumptions
- Sequence dependencies

The hypothesis must describe the expected business rule.

### Input Handling

Where the application accepts user-controlled input, identify relevant trust
boundaries.

Possible areas:

- HTML rendering
- Database queries
- Template processing
- XML parsing
- Serialization
- File processing
- Command execution
- URL fetching

Only generate a hypothesis when the application's behavior provides a reason to
investigate the relevant boundary.

Do not blindly spray payloads across every input.

### Integrations

Consider:

- Identity mapping
- Permission propagation
- Callback authorization
- External resource ownership
- Trust relationships
- Integration configuration
- Cross-service authorization

---

# 6. Evidence / Confidence

## 6.1 Test design

Tests should be:

- Minimal
- Targeted
- Reproducible
- Non-destructive
- Rate-limit-aware

Start with baseline behavior.

Then introduce only the change necessary to test the hypothesis.

Examples:

```text
Baseline request
        ↓
Controlled change
        ↓
Compare result
```

Do not perform broad mutation when a single controlled comparison can answer
the question.

## 6.2 Account and role comparisons

For authorization hypotheses, prefer controlled comparisons.

Example:

```text
Account A
→ owns Resource A

Account B
→ owns Resource B

Compare:

A → Resource A
A → Resource B
B → Resource B
B → Resource A
```

The exact test depends on the application's authorization model and program
rules.

Do not access unrelated real-user data.

Use authorized test accounts/resources whenever possible.

## 6.3 Negative results

Negative results are useful.

If testing shows:

```text
Expected secure behavior observed.
```

record:

```yaml
status: not-confirmed
evidence:
reason:
```

Do not repeatedly test the same hypothesis without new evidence.

## 6.4 False positives

A candidate may appear interesting because:

- Response status differs
- Error messages differ
- Object exists but remains inaccessible
- UI behavior is inconsistent
- Client-side data is visible but server-side authorization holds
- Endpoint is reachable but action is denied
- Data is intentionally public
- Behavior is documented

These are not automatically vulnerabilities.

Send ambiguous candidates to verification/triage.

## 6.5 Duplicate prevention

Before creating a hypothesis:

Check:

- Existing hypotheses
- Existing candidates
- Existing verified findings
- Mission artifacts
- Persistent knowledge base
- Known application behavior

If the same security property is already being tested, extend the existing
hypothesis instead of creating a duplicate.

---

# 7. Outputs / Artifacts

## 7.1 Hypothesis artifact

Recommended location:

```text
mission-###/hypotheses/
```

Possible structure:

```text
hypotheses/
├── AC-001.yaml
├── API-001.yaml
├── BL-001.yaml
└── AUTH-001.yaml
```

Example:

```yaml
id: AC-001
category: access-control

feature:
target:

observation:

actor:
security_boundary:
protected_resource:

expected_behavior:

hypothesized_failure:

test_method:

required_context:

evidence_required:

constraints:

status: untested
```

## 7.2 Candidate creation

A hypothesis becomes a candidate only when testing produces evidence suggesting
that the expected security property may fail.

Candidate structure:

```yaml
candidate_id:
hypothesis_id:

observation:

expected_behavior:

observed_behavior:

security_boundary:

evidence:

reproduction_status:

next_stage: verification
```

Do not label it:

```text
confirmed vulnerability
```

at this stage.

## 7.3 Hypothesis lifecycle

Use exactly one current status:

```text
untested
testing
needs-evidence
verified
not-confirmed
false-positive
```

Recommended lifecycle:

```text
untested
   ↓
testing
   ↓
needs-evidence
   ↓
verified
   ↓
triage
   ↓
impact
   ↓
report
```

Alternative:

```text
testing
   ↓
not-confirmed
```

or:

```text
testing
   ↓
false-positive
```

Do not silently discard a hypothesis.

---

# 8. Handoff

## 8.1 Handoff to verification

When a candidate requires verification, provide:

```text
CANDIDATE ID
HYPOTHESIS ID
TARGET
FEATURE
ACTOR
SECURITY BOUNDARY
BASELINE REQUEST
TEST REQUEST
OBSERVED RESPONSE
EXPECTED RESPONSE
EVIDENCE
REPRODUCTION STEPS
KNOWN LIMITATIONS
```

Verification must determine whether the evidence demonstrates an actual
security failure.

## 8.2 Handoff to specialized capabilities

Hypotheses are routed according to their category:

```text
Access Control hypothesis
→ access-control capability

API hypothesis
→ api capability

Business Logic hypothesis
→ business-logic capability

Authentication hypothesis
→ authentication-capable workflow/capability

General candidate
→ hunter
```

Specialists should not regenerate the entire application map unless necessary.

They should consume the relevant mission artifacts and return structured
results.

(This skill defines the category-based routing contract; the executing agent
registry and dispatch are owned by the agent layer.)

---

# 9. Completion Criteria

Hypothesis generation is sufficiently complete when:

- Important security boundaries have been considered.
- Major mapped features have relevant hypotheses where appropriate.
- Duplicate hypotheses have been removed or merged.
- Each hypothesis has a clear test.
- Required evidence is defined.
- Required account/role context is defined.
- Constraints are documented.
- Every hypothesis has an initial status.
- Hypotheses are ready for specialized testing.

Hypothesis generation does not establish the existence of vulnerabilities.

It establishes a disciplined set of questions that the research team can test.

---

# 10. Failure Conditions / Boundaries

- Premature conclusion: treating a hypothesis as a vulnerability, or a candidate
  as a confirmed finding, before evidence/verification/triage. The core model
  (§4.1) must not be skipped.
- Assumption errors: assuming a weakness because a feature or phrase exists
  (e.g., undocumented API → vulnerable; parameter name → weakness).
- Unanchored hypotheses: hypotheses not connected to an actual observed
  feature, an identified boundary, expected behavior, and a specific failure
  condition. Improve at the quality gate rather than testing blindly.
- Noise: blindly spraying payloads; generating hypotheses merely to increase
  count.
- Hazard/scope violations: tests that are not minimal, non-destructive, and
  rate-limit-aware; accessing unrelated real-user data. Use authorized test
  accounts/resources.
- Boundary violation: if the work becomes testing/exploitation guidance or
  executes vulnerability verification, it has left the planning layer.

---

# 11. Related Capabilities

```text
target-selection (existing canonical)
    ↓
application-mapping (existing canonical)
    ↓
hypothesis-generation (this skill)
    ↓
execution layer (hunting / specialists / verification)
```

Existing canonical capabilities:

- `planning/target-selection/SKILL.md` — chooses the authorized research target
  and records its characteristics.
- `planning/application-mapping/SKILL.md` — builds the structured model of the
  selected application; its output is this skill's primary input.

Execution-layer relationships (do not duplicate their bodies):

- Reconnaissance: `methodology/reconnaissance-skill/SKILL.md`
- Hunting: `skills/security-hunter/SKILL.md` and the class methodology skills
  under `methodology/`
- Verification: `methodology/verification-skill/SKILL.md`
- Orchestrator: `agents/orchestrator.md` (routes hypotheses by category to
  specialized capabilities)

Conceptual chain preserved by this migration (selection → mapping → hypothesis):

```text
choosing what should be researched
→ understanding/modeling the selected application
→ turning the mapped security context into explicit, testable hypotheses
```

---

# 12. Source / Derivation

- Original source: `skills/web-security-research/references/hypothesis-generation.md`
  (809 lines; classified UNIQUE in `index/parallel-knowledge-audit.md` §2.1 and
  Special Area C; listed as additional unique knowledge in
  `index/methodology.md`; identified as feeding the hunter layer).
- Audit classification: UNIQUE — no canonical counterpart.
- Canonical ownership decision: promote the UNIQUE hypothesis-generation
  capability to a standalone canonical planning skill under
  `security-research/planning/`; NOT a vulnerability methodology (not placed
  under `methodology/`); NOT merged into hunter or recon. The
  hypothesis-generation vs vulnerability-methodology distinction is preserved:
  generation builds PLANNING artifacts (hypotheses/candidates); methodology
  skills explain how classes manifest and are tested.
- Migration purpose: Batch 1B-3 of the controlled migration sequence, following
  the canonical ownership design (`index/canonical-ownership-plan.md`), to give
  the planning tier a single canonical owner per capability.
- What was preserved: all 20 source sections (core research model, good
  hypothesis, required fields, security properties, categories, observation→
  hypothesis, quality gate, prioritization, test design, account/role
  comparisons, candidate creation, negative results, false positives, duplicate
  prevention, lifecycle, handoffs, artifact, research discipline, completion
  criteria) with their YAML schemas retained verbatim.
- What was intentionally excluded: no operational/tool-specific content required
  exclusion. The source names no tools. The §17 agent names are preserved as
  routing context (§8.2), with dispatch ownership noted as agent-layer.
- Unresolved content: none.

---

# 13. Coverage / Preservation Notes

- This skill owns the full hypothesis-generation capability identified by the
  audit; nothing substantive is left in the source that is not represented here.
- No operational/tool-specific material required exclusion: the source contains
  no tool commands or agent-execution instructions; its category-based routing
  guidance is preserved as the handoff contract.
- The original source is retained unchanged as the derived/reference copy and
  remains authoritative for provenance.
- Coverage boundary: this skill generates and defines testable hypotheses; it
  does not select targets, map applications, or execute tests/verification.