---
name: security-access-control
description: Deep authorization methodology for IDOR, BOLA, horizontal and vertical privilege escalation, tenant isolation, ownership, forced browsing, and function-level authorization.
compatibility: opencode
metadata:
  domain: authorization
---

# Access Control Security Skill

Authorization research is fundamentally boundary modeling.

---

# 1. CORE MODEL

ACTOR
+
RESOURCE
+
ACTION
+
EXPECTED PERMISSION
+
OBSERVED PERMISSION

---

# 2. ACTORS

Model only evidenced actors:

anonymous
user
owner
same tenant
different tenant
privileged role
administrator

---

# 3. RESOURCES

Map:

user
document
project
file
message
organization
workspace
invoice
integration
API object

---

# 4. HORIZONTAL

Same privilege level.

User A
→ Resource A

User B
→ Resource B

Question:

Can B access A's protected resource?

---

# 5. VERTICAL

Different privilege levels.

Normal user
vs
privileged user

Test sensitive functions where justified.

---

# 6. TENANT ISOLATION

Model:

Tenant A
Tenant B

Identify tenant-bound identifiers.

Look for server-side enforcement.

---

# 7. OWNERSHIP

Determine:

who owns the object?

what operation is allowed?

where is ownership checked?

---

# 8. FUNCTION AUTHORIZATION

Sensitive operations include:

role changes
account management
organization administration
security settings
integrations

Check server-side authorization.

---

# 9. FORCED BROWSING

A hidden UI element is not a security boundary.

Test server-side authorization where meaningful.

---

# 10. METHOD DIFFERENTIALS

Only test method differences when justified by observed application behavior.

---

# 11. EVIDENCE

Strong evidence demonstrates:

unauthorized actor
+
protected resource/function
+
successful unauthorized action

---

# 12. FALSE POSITIVES

Reject or investigate:

public resources
intentional sharing
legitimate delegation
authorized cross-user access
non-security-relevant response differences

---

# 13. PORTSWIGGER

Use:

./security-research/index/portswigger.md

for authorization patterns.

Never assume IDOR from an identifier alone.

---

# 14. OUTPUT

Produce:

actor
resource
action
expected permission
observed behavior
security boundary
evidence
status
