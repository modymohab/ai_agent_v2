---
name: web-security-research
description: Core methodology for authorized web application security research, including scope validation, attack-surface analysis, vulnerability hypothesis generation, verification, evidence handling, triage, impact analysis, and reporting.
compatibility: opencode
metadata:
  domain: web-security
  role: core-methodology
---

# Web Security Research Core

This is the foundational methodology for all web security research agents.

All specialized security agents should use this skill as their common research framework.

---

## 1. RESEARCH PRINCIPLES

Security research is evidence-driven.

Always distinguish:

FACT
OBSERVATION
HYPOTHESIS
CANDIDATE
VERIFIED FINDING
IMPACT
CONCLUSION

Never collapse these categories.

A hypothesis is not a vulnerability.

A suspicious response is not proof.

A PortSwigger lab pattern is not proof.

A writeup is not proof.

Only current-target evidence can establish a current-target finding.

---

## 2. SCOPE FIRST

Before testing:

1. Identify the program.
2. Identify in-scope assets.
3. Identify excluded assets.
4. Identify allowed testing methods.
5. Identify account requirements.
6. Identify rate limits.
7. Identify prohibited actions.
8. Identify data-handling restrictions.

Never infer authorization.

---

## 3. RESEARCH LOOP

Use:

OBSERVE
↓
MODEL
↓
HYPOTHESIZE
↓
TEST
↓
COMPARE
↓
VERIFY
↓
DOCUMENT
↓
REVIEW
↓
REPORT

---

## 4. ATTACK SURFACE

Build an attack-surface model containing:

hosts
applications
technologies
authentication
authorization
APIs
parameters
files
uploads
downloads
workflows
administrative functions
integrations
client-side functionality
server-side functionality

---

## 5. KNOWLEDGE USAGE

Persistent knowledge exists to improve hypotheses.

Priority:

current scope
>
current evidence
>
current verification
>
methodology
>
persistent knowledge
>
PortSwigger patterns
>
historical writeups

Never allow historical knowledge to override current evidence.

---

## 6. PORTSWIGGER PATTERN ENGINE

Use:

./security-research/index/portswigger.md

as the primary PortSwigger-derived pattern library.

Process:

Observed behavior
→ vulnerability class
→ relevant pattern
→ prerequisites
→ hypothesis
→ current-target test
→ verification

Do not copy exploit conclusions from labs.

---

## 7. REAL-WORLD WRITEUPS

Writeups can provide:

- attack patterns
- methodology
- indicators
- edge cases
- common mistakes
- verification approaches

They cannot prove that the current target has the same issue.

---

## 8. EVIDENCE

Evidence should preserve:

target
endpoint
method
actor
authorization context
request
response
state
observed effect
reproduction

Never fabricate missing evidence.

---

## 9. MINIMAL TESTING

Prefer the smallest test that can answer the security question.

Avoid:

- unnecessary requests
- duplicate scans
- uncontrolled automation
- destructive actions
- excessive concurrency

---

## 10. RATE-LIMIT-AWARE OPERATION

Use:

- deduplication
- caching
- bounded concurrency
- backoff
- incremental discovery
- targeted testing

Do not attempt to defeat service-side rate limits.

---

## 11. CANDIDATE FORMAT

Every candidate should contain:

candidate_id
category
target
endpoint
method
actor
hypothesis
expected_behavior
observed_behavior
evidence
status

---

## 12. VERIFICATION

Use:

baseline
→ controlled test
→ comparison
→ reproduction
→ evidence
→ result

Result:

confirmed
rejected
inconclusive

---

## 13. IMPACT

Separate:

demonstrated impact

from:

potential impact.

Never exaggerate.

---

## 14. REPORTING

A report must contain only:

verified facts
verified reproduction
supported impact
relevant remediation

---

## 15. KNOWLEDGE FEEDBACK

Reusable findings may be converted into:

./security-research/knowledge/

Preserve:

pattern
preconditions
indicators
testing idea
false positives
lessons learned

Never store unnecessary secrets.
