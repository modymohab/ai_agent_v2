---
name: security-business-logic
description: Deep business-logic methodology for workflow modeling, state transitions, invariants, replay, transaction abuse, invitation and approval flows, and controlled race-condition research.
compatibility: opencode
metadata:
  domain: business-logic
---

# Business Logic Security Skill

Business logic research begins by understanding how the application is supposed to work.

---

# 1. WORKFLOW

Model:

state
→ action
→ state

---

# 2. INVARIANTS

Identify rules that should always remain true.

Examples:

ownership
authorization
payment requirement
approval requirement
identity binding
transaction uniqueness

Only use invariants supported by application behavior.

---

# 3. WORKFLOW BYPASS

Investigate:

skipped step
reordered step
repeated step
direct endpoint invocation
missing validation

A bypass matters only if it violates a meaningful security or business property.

---

# 4. STATE TRANSITIONS

Map:

initial
→ intermediate
→ final

Look for unexpected transitions.

---

# 5. REPLAY

Analyze whether sensitive operations can be repeated.

Use safe test objects.

Avoid destructive repetition.

---

# 6. TRANSACTION ABUSE

Where applicable analyze:

quantity
price
discount
credits
ownership
approval
limits

Only within authorized testing.

---

# 7. INVITATIONS

Model:

creator
recipient
organization
token/state
acceptance
resulting permissions

Focus on identity and authorization boundaries.

---

# 8. APPROVALS

Model:

requester
reviewer
approver
executor

Look for missing actor requirements.

---

# 9. RACE CONDITIONS

Only investigate when there is a plausible concurrency-sensitive invariant.

Use controlled, rate-limit-aware testing.

Do not attempt to bypass infrastructure rate limits.

---

# 10. PORTSWIGGER

Use:

./security-research/index/portswigger.md

to identify known workflow patterns.

---

# 11. EVIDENCE

Preserve:

initial state
normal sequence
tested sequence
resulting state
violated invariant

---

# 12. HANDOFF

Candidate
→ security-verification
