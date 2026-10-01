# Target Selection

## Purpose

Select an authorized research target that provides a meaningful and sufficiently testable web security surface.

Target selection is a research-planning step.

It is NOT vulnerability prediction.

The existence of a large bounty, a popular target, a complex application, a previous vulnerability, or a specific technology does not establish that a target is vulnerable.

The objective is to identify an in-scope target where systematic security research can be performed safely, efficiently, and with measurable coverage.

---

# 1. Authorization Gate

No target may enter active research until authorization has been established.

Verify:

* Program identity
* Official program policy
* Exact in-scope asset
* Protocol
* Hostname/domain
* Path restrictions, if any
* Authentication requirements
* Account requirements
* Testing restrictions
* Rate limits
* Prohibited actions
* Program-specific exclusions
* Disclosure requirements

Prefer the program's current authoritative policy over third-party scope databases.

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

---

# 2. Candidate Discovery

Build the candidate list from authorized sources.

Possible sources include:

* Official program scope
* Official documentation
* Program-provided assets
* Existing authorized reconnaissance
* Existing mission knowledge
* Application documentation
* Previously mapped assets that remain in scope

Do not expand the scope merely because an apparently related hostname or service exists.

Every candidate must be mapped back to an explicitly authorized asset where possible.

---

# 3. Target Classification

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

* Web application
* API
* SaaS platform
* Administrative portal
* Customer portal
* Developer platform
* Authentication service
* Documentation platform
* Dashboard
* Marketplace
* Integration platform

Do not assume that the application type implies a vulnerability class.

---

# 4. Research-Surface Assessment

Evaluate whether the target provides meaningful security boundaries.

Look for observable characteristics such as:

### Identity

* Authentication
* Multiple accounts
* Session management
* Account recovery
* Role assignment

### Authorization

* Multiple roles
* Resource ownership
* Organization boundaries
* Team membership
* Administrative permissions
* Sharing

### Resources

* User-owned objects
* Organization-owned objects
* Files
* Projects
* Documents
* Transactions
* Configurations
* API resources

### Workflows

* Invitations
* Permission changes
* Ownership changes
* Account changes
* State transitions
* Administrative actions
* Integrations

### APIs

* REST
* GraphQL
* RPC
* Internal APIs exposed to the browser
* State-changing endpoints

### Trust Boundaries

* User → application
* User → organization
* User → administrator
* Application → third-party service
* Browser → API
* Service → service

These are indicators of research surface, not evidence of vulnerabilities.

---

# 5. Target Suitability

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

---

# 6. Constraints Assessment

Before selection, record operational constraints.

Examples:

* Rate limits
* Low request volume requirements
* No automated scanning
* No denial-of-service testing
* No destructive testing
* No social engineering
* No third-party testing
* No production data modification
* Required test accounts
* Required headers
* Required identification
* Geographic restrictions

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

---

# 7. Target Selection Decision

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

---

# 8. Target Selection Output

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

# 9. Handoff to Application Mapping

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

The purpose of the next stage is to discover and structure the application's actual attack surface.

---

# 10. Failure Conditions

Target selection must stop or return to scope review when:

* Authorization is unclear.
* The asset is outside scope.
* Scope changed and has not been revalidated.
* Testing restrictions prohibit the intended activity.
* The required account or permission context is unavailable.
* The target cannot be distinguished from an out-of-scope asset.
* The requested testing would require prohibited activity.

Never bypass an authorization problem by continuing with passive assumptions.

---

# 11. Anti-Bias Rules

Do not select targets because:

* Another researcher found a bug there.
* A writeup exists.
* The bounty is large.
* The technology is fashionable.
* The target looks complex.
* A vulnerability class is historically common.
* A scanner produced an interesting result.
* The target "feels vulnerable."

Use documented application characteristics and authorized scope instead.

---

# Completion Criteria

Target selection is complete when:

* Authorization is verified.
* Scope is documented.
* Restrictions are documented.
* One research target is established.
* Known application characteristics are recorded.
* Unknowns are explicitly recorded.
* The target-selection artifact exists.
* Application mapping can begin.

Target selection does not establish security posture.

It only establishes the authorized starting point for research.
