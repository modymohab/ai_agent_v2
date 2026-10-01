---
name: security-impact
description: Evidence-based security impact analysis covering confidentiality, integrity, availability, authentication, authorization, privilege boundaries, and demonstrated versus potential consequences.
compatibility: opencode
metadata:
  domain: impact-analysis
---

# Security Impact Skill

Impact must be derived from evidence.

---

# 1. THREE LEVELS

DEMONSTRATED

Directly proven.

SUPPORTED

Reasonably follows from proven behavior.

POTENTIAL

Possible but not demonstrated.

Never merge these levels.

---

# 2. CONFIDENTIALITY

Analyze:

what data
whose data
sensitivity
quantity demonstrated
authorization context

---

# 3. INTEGRITY

Analyze actual unauthorized changes.

---

# 4. AVAILABILITY

Require meaningful evidence.

Do not infer broad availability impact from minor errors.

---

# 5. AUTHENTICATION

Distinguish:

authentication weakness
session impact
recovery impact
account compromise

Do not claim account takeover without evidence.

---

# 6. AUTHORIZATION

Identify exact crossed boundary:

object
user
tenant
role
administrator

---

# 7. PRIVILEGE

Distinguish narrow privileged operation from complete administrative control.

---

# 8. DATA SCOPE

Do not extrapolate:

one record
→ entire database

without evidence.

---

# 9. OUTPUT

Produce:

impact_summary
demonstrated
supported
potential
security_properties
affected_resources
evidence
