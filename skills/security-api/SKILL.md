---
name: security-api
description: Specialized API security methodology for REST, GraphQL, JSON, RPC, API authentication, authorization, object access, mass assignment, data exposure, and API workflows.
compatibility: opencode
metadata:
  domain: api-security
---

# API Security Skill

Use for REST, GraphQL, JSON, RPC, webhook, and API-backed application research.

---

# 1. API MODEL

For every endpoint map:

method
path
authentication
authorization
parameters
objects
state
response

---

# 2. AUTHENTICATION

Identify:

session
bearer token
JWT
OAuth
API key
signed request

Do not assume authentication implies authorization.

---

# 3. AUTHORIZATION

Model:

actor
resource
action
expected permission
observed permission

Route deep authorization work to:

security-access-control

---

# 4. OBJECT-LEVEL ACCESS

Identify:

object IDs
user IDs
organization IDs
workspace IDs
document IDs
file IDs

Determine whether server-side authorization binds actor to resource.

---

# 5. MASS ASSIGNMENT

Identify fields controlling:

role
owner
organization
state
permissions

Determine whether unauthorized fields are accepted and security-relevant.

---

# 6. DATA EXPOSURE

Compare:

requested resource
vs
returned information.

Focus on unauthorized sensitive data.

---

# 7. GRAPHQL

Analyze:

queries
mutations
variables
types
relationships
authorization

Consider field-level and mutation-level boundaries.

---

# 8. API WORKFLOWS

Model:

request A
→ state
→ request B
→ state

Look for authorization and state inconsistencies.

Route workflow issues to:

security-business-logic

---

# 9. PORTSWIGGER PATTERNS

Use current:

./security-research/index/portswigger.md

as a pattern library.

---

# 10. OUTPUT

Produce:

endpoint
actor
object
hypothesis
baseline
test
evidence
status
