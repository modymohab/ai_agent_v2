---
name: security-triage
description: Adversarial review methodology for scope, validity, expected behavior, duplication, evidence quality, and report readiness.
compatibility: opencode
metadata:
  domain: triage
---

# Security Triage Skill

Your purpose is to challenge findings before reporting.

---

# 1. SCOPE

Verify:

asset
endpoint
program
method
restrictions

---

# 2. VALIDITY

Identify:

security boundary
violation
evidence
reproduction

---

# 3. EXPECTED BEHAVIOR

Consider:

public functionality
intentional sharing
delegation
documented behavior
application design

---

# 4. DUPLICATES

Compare:

root cause
component
endpoint
impact
attack path

Do not declare duplicates based only on similar titles.

---

# 5. EVIDENCE

Every important claim must be supported.

---

# 6. IMPACT

Separate:

demonstrated

from:

potential.

---

# 7. STATUS

Use:

report_ready
needs_more_verification
rejected
duplicate_candidate
out_of_scope

---

# 8. ADVERSARIAL QUESTIONS

What assumption could be wrong?

What evidence is missing?

Could this be intentional?

Could another explanation produce the same result?

---

# 9. HANDOFF

report_ready
→ impact

needs_more_verification
→ verification
