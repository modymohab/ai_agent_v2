# Hypothesis Generation

## Purpose

Convert application observations and security boundaries into explicit, testable security hypotheses.

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

A hypothesis becomes a candidate only after evidence indicates that the expected security property may not hold.

A candidate becomes a finding only after appropriate verification and triage.

---

# 1. Core Research Model

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

---

# 2. What Is a Good Hypothesis?

A good hypothesis is:

* Specific
* Testable
* Evidence-based
* Connected to an actual application feature
* Connected to a security boundary
* Reproducible
* Scoped to an authorized target

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

* Actor
* Resource
* Boundary
* Action
* Failure condition

---

# 3. Required Hypothesis Fields

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

---

# 4. Security Properties

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

---

# 5. Hypothesis Categories

Use categories supported by the actual application.

## Authentication

Possible hypothesis areas:

* Authentication state transitions
* Session boundaries
* Logout/session invalidation
* Recovery workflows
* Verification flows
* Account switching
* MFA state transitions
* Role assignment

Do not assume a weakness merely because a feature exists.

---

## Access Control

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

---

## API Security

Consider:

* Object-level authorization
* Function-level authorization
* Method-specific authorization
* API/UI authorization differences
* Resource ownership
* State-changing endpoints
* Hidden or undocumented API functionality
* Alternate representations

Do not classify an API as vulnerable simply because an endpoint is undocumented.

---

## Business Logic

Consider:

* Workflow assumptions
* State transitions
* Permission changes
* Ownership changes
* Invitation flows
* Resource sharing
* Conflicting operations
* Duplicate operations
* Trust assumptions
* Sequence dependencies

The hypothesis must describe the expected business rule.

---

## Input Handling

Where the application accepts user-controlled input, identify relevant trust boundaries.

Possible areas:

* HTML rendering
* Database queries
* Template processing
* XML parsing
* Serialization
* File processing
* Command execution
* URL fetching

Only generate a hypothesis when the application's behavior provides a reason to investigate the relevant boundary.

Do not blindly spray payloads across every input.

---

## Integrations

Consider:

* Identity mapping
* Permission propagation
* Callback authorization
* External resource ownership
* Trust relationships
* Integration configuration
* Cross-service authorization

---

# 6. Observation → Hypothesis

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

Example:

```yaml
id: AC-001

category: access-control

feature: project_api

observation:
  authenticated users receive project objects containing project_id

security_boundary:
  project_owner_to_non_owner

actor:
  non_owner_authenticated_user

protected_resource:
  project

expected_behavior:
  non_owner_cannot_read_project

hypothesized_failure:
  project authorization may not be enforced when requesting
  another user's project identifier

test_method:
  compare equivalent authorized and unauthorized requests

required_context:
  - owner_account
  - non_owner_account
  - two distinct project identifiers

evidence_required:
  - baseline_owner_request
  - non_owner_request
  - response_comparison

constraints:
  preserve_non_destructive_testing

status: untested
```

---

# 7. Hypothesis Quality Gate

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

---

# 8. Prioritization

Do not use bounty size or vulnerability popularity as the sole prioritization mechanism.

Prioritize hypotheses using observable research value:

### Strong security boundary

Examples:

* Owner vs non-owner
* Member vs administrator
* User vs organization
* Authenticated vs unauthenticated

### Sensitive resource

Examples:

* Private data
* Credentials
* Security settings
* Administrative configuration
* Organization resources

### Sensitive action

Examples:

* Modify
* Delete
* Transfer ownership
* Grant permissions
* Export
* Change security settings

### Multiple actors

Hypotheses involving multiple roles or accounts may provide stronger opportunities to test authorization boundaries.

### Observable behavior

Prefer hypotheses where the application already provides enough evidence to define a meaningful test.

Do not assign arbitrary scores unless the mission system explicitly requires them.

---

# 9. Test Design

Tests should be:

* Minimal
* Targeted
* Reproducible
* Non-destructive
* Rate-limit-aware

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

Do not perform broad mutation when a single controlled comparison can answer the question.

---

# 10. Account and Role Comparisons

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

The exact test depends on the application's authorization model and program rules.

Do not access unrelated real-user data.

Use authorized test accounts/resources whenever possible.

---

# 11. Candidate Creation

A hypothesis becomes a candidate only when testing produces evidence suggesting that the expected security property may fail.

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

---

# 12. Negative Results

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

---

# 13. False Positives

A candidate may appear interesting because:

* Response status differs
* Error messages differ
* Object exists but remains inaccessible
* UI behavior is inconsistent
* Client-side data is visible but server-side authorization holds
* Endpoint is reachable but action is denied
* Data is intentionally public
* Behavior is documented

These are not automatically vulnerabilities.

Send ambiguous candidates to verification/triage.

---

# 14. Duplicate Prevention

Before creating a hypothesis:

Check:

* Existing hypotheses
* Existing candidates
* Existing verified findings
* Mission artifacts
* Persistent knowledge base
* Known application behavior

If the same security property is already being tested, extend the existing hypothesis instead of creating a duplicate.

---

# 15. Hypothesis Lifecycle

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

# 16. Handoff to Verification

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

Verification must determine whether the evidence demonstrates an actual security failure.

---

# 17. Handoff to Specialized Agents

The Orchestrator should route hypotheses according to their category.

```text
Access Control hypothesis
→ access-control agent

API hypothesis
→ api agent

Business Logic hypothesis
→ business-logic agent

Authentication hypothesis
→ relevant authentication-capable workflow/agent

General candidate
→ hunter
```

Specialists should not regenerate the entire application map unless necessary.

They should consume the relevant mission artifacts and return structured results.

---

# 18. Hypothesis Artifact

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

---

# 19. Research Discipline

Never generate hypotheses merely to increase the hypothesis count.

Ten meaningful hypotheses are more useful than one hundred arbitrary payload attempts.

Every hypothesis should answer:

```text
What security property are we testing?
Why does this application feature create that boundary?
What exact behavior would demonstrate a failure?
What evidence would be sufficient?
```

---

# 20. Completion Criteria

Hypothesis generation is sufficiently complete when:

* Important security boundaries have been considered.
* Major mapped features have relevant hypotheses where appropriate.
* Duplicate hypotheses have been removed or merged.
* Each hypothesis has a clear test.
* Required evidence is defined.
* Required account/role context is defined.
* Constraints are documented.
* Every hypothesis has an initial status.
* Hypotheses are ready for specialized testing.

Hypothesis generation does not establish the existence of vulnerabilities.

It establishes a disciplined set of questions that the research team can test.
