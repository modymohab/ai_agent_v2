---
name: security-verification
description: Evidence-first methodology for reproducing, comparing, confirming, rejecting, and documenting web security vulnerability candidates.
compatibility: opencode
metadata:
  domain: verification
---

# Security Verification Skill

This skill is the evidence gate.

---

# 1. CLAIM

Define:

what is claimed
where
by whom
against what
with what effect

---

# 2. BASELINE

Capture normal behavior before testing the candidate.

---

# 3. CONTROLLED TEST

Change one meaningful variable at a time.

Prefer minimal tests.

---

# 4. DIFFERENTIAL ANALYSIS

Compare:

baseline
vs
test

Compare:

status
body
headers
state
authorization
resource
side effects

---

# 5. REPRODUCTION

Repeat enough to determine:

deterministic
intermittent
environmental
non-reproducible

---

# 6. CAUSALITY

Determine whether the candidate actually caused the result.

Investigate alternative explanations.

---

# 7. FALSE POSITIVE

Check:

expected behavior
public resource
authorized actor
cache
client state
redirect
stale state
missing context

---

# 8. RESULT

confirmed
rejected
inconclusive

---

# 9. EVIDENCE

Preserve:

request
response
actor
resource
baseline
test
result
reproduction

Never fabricate evidence.

---

# 10. HANDOFF

confirmed
→ triage

rejected
→ close

inconclusive
→ orchestrator


## Failure Isolation and Queue Continuity

Verification is a queue of independent candidate tasks.

The verification phase MUST NOT terminate because one candidate,
tool call, subagent, or output stream becomes stuck, corrupted,
unavailable, or repeatedly fails.

For every candidate:

1. Start verification independently.
2. Establish baseline.
3. Perform only the bounded verification required for that candidate.
4. Record the result:
   - CONFIRMED
   - REJECTED
   - INCONCLUSIVE
5. If execution becomes stuck, corrupted, unavailable, or repeatedly
   fails:
   - immediately stop the CURRENT candidate
   - mark it INCONCLUSIVE
   - record the exact blocker
   - continue with the NEXT candidate

Never wait indefinitely for a candidate.

Never:
- restart the entire mission
- restart recon
- restart the verification phase
- retry the same failing tool call indefinitely
- let one candidate block the remaining queue

Required execution model:

candidate_01 -> result -> candidate_02 -> result -> candidate_03 -> result

NOT:

candidate_01 -> stuck -> wait -> wait -> stop entire verification phase

The orchestrator must maintain explicit queue state:

verification_queue:
  pending:
  active:
  completed:
  inconclusive:

If the active candidate fails, move it from `active` to
`inconclusive`, then immediately promote the next candidate from
`pending` to `active`.

A verification phase is complete only when:
`pending == empty` AND `active == empty`.

A candidate marked INCONCLUSIVE is NOT a phase failure.
It is a candidate-level result.

## Subagent Failure Isolation

If verification is delegated to a subagent:

- The subagent failure applies only to that candidate/task.
- The orchestrator must regain control and continue the queue.
- Do not treat subagent silence or malformed output as mission completion.
- Do not wait indefinitely for a silent/stuck subagent.
- Preserve all completed candidate results before moving on.

If the execution mechanism cannot recover control from a stuck
subagent, record the candidate as INCONCLUSIVE and continue with
any verification tasks that can still be executed independently.
