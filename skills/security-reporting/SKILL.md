---
name: security-reporting
description: Professional vulnerability-reporting methodology for converting verified security evidence into reproducible, precise, scope-aware reports with impact and remediation.
compatibility: opencode
metadata:
  domain: reporting
---

# Security Reporting Skill

A report is a representation of verified evidence.

---

# 1. STRUCTURE

Use:

Title
Summary
Affected Asset
Endpoint
Prerequisites
Steps
Expected Behavior
Actual Behavior
Impact
Evidence
Root Cause
Remediation

Adapt to program-specific requirements.

---

# 2. TITLE

Describe:

vulnerability
+
function
+
demonstrated consequence

Avoid sensational wording.

---

# 3. REPRODUCTION

Only include actions actually performed.

Steps must be deterministic and clear.

---

# 4. EVIDENCE

Include only verified evidence.

Remove unnecessary secrets.

---

# 5. EXPECTED VS ACTUAL

Make the security boundary explicit.

---

# 6. IMPACT

Use verified impact analysis.

Do not exaggerate.

---

# 7. ROOT CAUSE

Only state root cause when supported.

Otherwise say it is not conclusively established.

---

# 8. REMEDIATION

Tie recommendations to the actual failure.

---

# 9. QUALITY CHECK

Verify:

scope
reproduction
evidence
impact
root cause
remediation
sensitive-data handling

---

# 10. KNOWLEDGE FEEDBACK

If a reusable pattern was discovered:

save a sanitized knowledge artifact under:

./security-research/knowledge/
