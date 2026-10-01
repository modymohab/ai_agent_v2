# Application Mapping

## Purpose

Build a structured model of an authorized application's attack surface before systematic vulnerability hunting.

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

The map is a research model, not a claim that the entire application has been discovered.

---

# 1. Mapping Principles

Application mapping must be:

* Scope-aware
* Evidence-driven
* Incremental
* Non-destructive
* Rate-limit-aware
* Reproducible
* Explicit about unknowns

Do not claim complete coverage based on a homepage crawl.

Do not assume that visible UI represents the entire application.

Do not assume that an API endpoint is authorized merely because the UI hides it.

Do not assume that an endpoint is vulnerable merely because it is reachable.

---

# 2. Mapping Sources

Use authorized sources such as:

### Browser

Observe:

* Pages
* Navigation
* Forms
* Network requests
* API calls
* Authentication transitions
* State changes

### HTTP Proxy

Use authorized proxy history to identify:

* Methods
* Paths
* Parameters
* Headers
* Cookies
* Tokens
* Request bodies
* Response patterns

### Documentation

Review:

* API documentation
* Application documentation
* Help pages
* Developer documentation
* Feature documentation

### Authorized Reconnaissance

Use only reconnaissance permitted by the program.

Respect:

* Scope
* Rate limits
* Automation restrictions
* Program rules

---

# 3. Host Mapping

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

* Production
* Staging
* Development
* API
* Documentation
* Authentication
* Administration
* Static content
* CDN
* Other

Do not test an environment merely because it appears related.

Verify scope independently.

---

# 4. Route Mapping

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

* Authentication
* Account
* Profile
* Organization
* Team
* Projects
* Files
* Documents
* Settings
* Administration
* Billing
* Integrations
* API
* Search
* Import/export

The category should reflect observed application behavior.

---

# 5. API Mapping

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

* Object identifiers
* User identifiers
* Organization identifiers
* Resource IDs
* Role parameters
* Ownership fields
* State parameters
* Hidden API operations
* Alternate HTTP methods

Do not assume an API weakness from parameter names alone.

---

# 6. Authentication Mapping

Document:

* Login
* Logout
* Session establishment
* Session expiration
* Password changes
* Account recovery
* MFA
* Email verification
* Role assignment
* Account switching
* Authentication state transitions

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

---

# 7. Role Mapping

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

---

# 8. Resource Mapping

Identify important application objects.

Examples:

* User
* Organization
* Team
* Project
* Document
* File
* Invoice
* Transaction
* API key
* Integration
* Configuration

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

---

# 9. Object Identifier Mapping

For important objects, document how the application identifies them.

Examples:

* Numeric ID
* UUID
* Slug
* Username
* Email
* Composite identifier
* Token
* Opaque reference

Record:

```yaml
identifiers:
  - resource:
    identifier_type:
    location:
    observed_behavior:
```

Identifier predictability alone is not evidence of IDOR.

The relevant question is whether authorization is correctly enforced around the object.

---

# 10. Workflow Mapping

Identify multi-step workflows.

Examples:

* Account creation
* Invitation
* Organization creation
* Resource sharing
* Permission changes
* Ownership transfer
* File upload
* Import/export
* Integration setup
* Account recovery
* Administrative changes

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

Do not reduce a multi-step workflow to isolated endpoints when state transitions matter.

---

# 11. State Mapping

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

* Multiple roles participate.
* Approval is required.
* Ownership changes.
* Actions become irreversible.
* Security-sensitive operations occur.

---

# 12. Trust-Boundary Mapping

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

---

# 13. Sensitive Functions

Identify functions where authorization or business rules matter significantly.

Examples:

* Change email
* Change password
* Reset credentials
* Add administrator
* Invite member
* Remove member
* Change ownership
* Export data
* Access private resource
* Modify security settings
* Create API credentials
* Configure integrations

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

---

# 14. Attack-Surface Model

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

# 15. Mapping vs Testing

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

# 16. Evidence Requirements

Every important map entry should have supporting evidence where practical.

Useful evidence includes:

* HTTP request
* HTTP response
* Browser observation
* API documentation
* Application behavior
* Program documentation
* Existing mission artifact

Avoid recording assumptions as facts.

Use:

```text
observed
inferred
unknown
```

when useful.

---

# 17. Unknowns

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

# 18. Application Map Artifact

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

---

# 19. Handoff to Hypothesis Generation

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

---

# Completion Criteria

Application mapping is sufficiently complete when:

* Major hosts are identified.
* Major application areas are identified.
* Authentication boundaries are understood.
* Relevant roles are identified.
* Important resources are identified.
* Ownership relationships are documented where known.
* Important APIs are mapped.
* Sensitive workflows are identified.
* Meaningful state transitions are documented.
* Major trust boundaries are identified.
* Unknowns are explicitly recorded.

"Mapped" does not mean "secure."

It means the research team has a structured model from which hypotheses can be generated.
