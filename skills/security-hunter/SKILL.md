---
name: security-hunter
description: General web application vulnerability research methodology covering input analysis, injection, XSS, CSRF, SSRF, traversal, file security, authentication, JWT, OAuth, server-side and client-side vulnerability patterns.
compatibility: opencode
metadata:
  domain: vulnerability-research
---

# Security Hunter Skill

Use this skill for broad web application vulnerability research.

The objective is intelligent hypothesis generation followed by controlled verification.

---

# 1. HUNTING LOOP

OBSERVE
→ CLASSIFY
→ MODEL
→ HYPOTHESIZE
→ TEST
→ ANALYZE
→ VERIFY

---

# 2. INPUT ANALYSIS

For every interesting input determine:

What does it control?

Possible roles:

reflection
database query
file path
URL
redirect
template
object
user
role
state
transaction

Then select relevant vulnerability classes.

---

# 3. INJECTION

Consider injection when:

user-controlled input
→ reaches an interpreter/parser
→ without adequate separation or validation.

Possible contexts:

SQL
NoSQL
command
template
expression
LDAP
XML

Do not assume injection merely because special characters produce errors.

---

# 4. XSS

Model:

source
→ processing
→ sink
→ browser context

Identify:

reflected
stored
DOM-based

Understand the actual rendering context before forming a conclusion.

---

# 5. CSRF

Ask:

Does a state-changing operation exist?

Does the application rely on ambient authentication?

Is an anti-CSRF defense present?

Is cross-origin triggering actually possible?

Do not report a CSRF issue solely because a POST request exists.

---

# 6. SSRF

Look for server-side URL fetching behavior.

Identify:

user-controlled URL
→ server-side request
→ security-sensitive destination

Verify actual server-side behavior.

---

# 7. TRAVERSAL

Identify file/path inputs.

Model:

user input
→ path construction
→ file operation

Do not assume a path parameter is vulnerable without demonstrating unauthorized file access.

---

# 8. FILE SECURITY

Analyze:

upload
download
processing
preview
conversion
storage
deletion

Consider:

type validation
content validation
authorization
path handling
storage isolation

---

# 9. AUTHENTICATION

Analyze:

login
registration
password reset
email verification
session lifecycle
account recovery

Focus on security boundaries and observable behavior.

---

# 10. JWT

Understand:

header
payload
signature
algorithm
key handling
validation

Do not assume JWT presence implies a vulnerability.

---

# 11. OAUTH / SSO

Model:

authorization request
redirect
callback
state
identity binding
account linking

Test only where the flow and scope permit.

---

# 12. SERVER-SIDE

Consider relevant server-side classes based on observed behavior:

request processing
deserialization
template processing
file handling
URL fetching
parser behavior

---

# 13. CLIENT-SIDE

Consider:

DOM sinks
client-side routing
postMessage
storage
browser trust boundaries

Focus on security consequences rather than unusual JavaScript.

---

# 14. PORTSWIGGER

Use:

./security-research/index/portswigger.md

to retrieve relevant patterns.

Never treat educational examples as current-target evidence.

---

# 15. CANDIDATES

Create candidates only when:

target behavior
+
security hypothesis
+
meaningful test
+
observable evidence

exist.

---

# 16. HANDOFF

Specialized API behavior
→ security-api

Authorization
→ security-access-control

Workflow
→ security-business-logic

Evidence requiring confirmation
→ security-verification
