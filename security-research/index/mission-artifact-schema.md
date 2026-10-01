# Mission Artifact Schema

Authoritative schema for how an authorized web security research mission
stores and tracks its artifacts.

This document defines the architecture/schema only. It is a **template and
contract**, NOT a mission instance. A future mission must instantiate its own
root:

```
./security-research/missions/mission-###/
```

No mission directory is created by this document or this batch. No real
target data, credentials, candidates, or findings populate this schema here.

Canonical mission root (all future instances):

```
./security-research/missions/mission-###/
```

with the artifact layers:

```
mission.yaml
scope.md
planning/
recon/
candidates/
verification/
triage/
impact/
report/
```

Companion to `index/handoff-contracts.md` (the H1-H8 stage handoffs this schema
serves) and `index/canonical-ownership-plan.md`.

---

## 1. `mission.yaml` — Global Mission Schema

Purpose: the machine-readable authorization/scope record for a mission.

Ownership: Target Selection / Orchestrator.

### Required fields

| Field | Meaning |
|---|---|
| `mission_id` | unique mission identifier |
| `created_utc` | creation timestamp (UTC) |
| `target` | authorized target/surface |
| `scope_rules` | what is in scope |
| `exclusions` | what is out of scope |
| `authorized_accounts` | accounts authorized for the mission |
| `program_rules` | program/bug-bounty rules in force |
| `status` | one of allowed lifecycle states |

### Optional fields

`authorization_reference`, `tools_permitted`, `notes`, `lang`.

### Allowed lifecycle

```
planned
scoped
active
complete
aborted
```

### Rules

- `mission.yaml` is the authorization/scope truth.
- Only Target Selection / Orchestrator may mutate authorization-relevant fields.
- Downstream agents MUST NOT silently expand scope.
- Scope changes must remain explicit and traceable.
- Downstream artifacts must NOT override `mission.yaml`.

---

## 2. `scope.md` — Human-Readable Scope Mirror

Purpose: human-readable mirror of `mission.yaml`.

Ownership: Orchestrator / mission governance.

Document:

- target
- scope
- exclusions
- authorized accounts
- program rules
- authorization reference
- operational constraints
- relevant notes

`scope.md` must NOT become an independent authorization authority. When in
conflict, `mission.yaml` is the truth.

---

## 3. `planning/` — Planning Artifact Layer

Purpose: store the canonical planning capabilities' outputs.

Ownership: Planning layer (Target Selection / Application Mapping / Hypothesis
Generation).

Planning represents the three canonical capabilities:

```
planning/target-selection
planning/application-mapping
planning/hypothesis-generation
```

Future artifacts for: selected target/surface, application model, generated
hypotheses, routing metadata.

### Target Selection — conceptual outputs

- selected target/surface
- selection rationale
- scope relationship
- constraints

### Application Mapping — conceptual outputs

- application model
- surfaces
- endpoints
- actors
- trust boundaries
- authentication/context
- relevant technologies/signals
- provenance/confidence

### Hypothesis Generation — conceptual outputs

- `hypothesis_id`
- `category`
- `affected_surface`
- hypothesis statement
- `prerequisites`
- `expected_security_boundary`
- `evidence_basis`
- `routing_destination`
- `confidence`
- `unresolved_assumptions`

### Rules

- Planning does NOT perform vulnerability testing.
- Planning does NOT create verified findings.
- Planning outputs must be traceable into Recon / Hunter / Specialists.

---

## 4. `recon/` — Recon Evidence Layer

Purpose: store discovery evidence and attack-surface signals.

Ownership: Recon.

### Expected artifacts

```
surfaces.md
endpoints.md
parameters.md
```

Optional:

```
subdomains/
apis/
hosts/
probing/
```

### Required conceptual fields

- `asset`
- `endpoint`
- `parameter`
- `method`
- `source`
- `scope_status`
- `auth_requirement`
- `confidence`
- `provenance`

### Optional evidence fields

- `http_status`
- `technology_signals`
- `parameter_role`
- `notes`

### Rules

- Recon owns discovery evidence.
- Recon does NOT own canonical hypothesis generation.
- Recon may record signals, observations, discovery evidence, emerging patterns.
- Canonical hypotheses come from Planning (H3 routing).

---

## 5. `candidates/` — Candidate Artifact Layer

Purpose: store hunting candidates awaiting independent evaluation.

Ownership: Hunter / Specialists.

### Artifacts

```
candidates.md          (index)
<candidate-id>.yaml    (authoritative candidate record)
```

The candidate YAML is the authoritative candidate record.

### Required fields

| Field | Meaning |
|---|---|
| `candidate_id` | unique candidate identifier |
| `category` | security category |
| `target` | target |
| `endpoint` | endpoint |
| `method` | HTTP method |
| `parameter` | parameter (if any) |
| `actor` | actor/context |
| `hypothesis` | hypothesis being tested |
| `prerequisites` | prerequisites |
| `test_plan` | planned test |
| `baseline` | baseline state |
| `test_result` | result |
| `evidence` | evidence |
| `confidence` | confidence |
| `status` | candidate status (initial: `candidate`) |
| `next_action` | next action |

### Initial status

```
candidate
```

### Rules

Candidate artifacts must preserve:

- provenance
- evidence
- history
- uncertainty
- upstream hypothesis reference
- relevant recon references

A candidate must NOT be treated as verified merely because it exists.

---

## 6. `verification/` — Verification Artifact Layer

Purpose: store independent verification results.

Ownership: Verification.

### Artifact

```
<candidate-id>.md
```

### Required fields

- `candidate_id`
- `verification_status`
- `baseline`
- `test`
- `differential_comparison`
- `reproduction`
- `evidence`
- `reasoning`
- `remaining_uncertainty`

### Allowed verification status

```
confirmed
rejected
inconclusive
```

### Rules

- Verification independently evaluates the candidate.
- Verification is an evidence gate.
- Verification does not own hunting.
- Verification does not own severity.
- Verification does not decide reportability.
- Verification does not invent impact.
- Verification output must preserve candidate identity and traceability.
- The candidate record retains its history and receives the verification
  state/result.

---

## 7. `triage/` — Triage Artifact Layer

Purpose: store triage reviews of verified-state candidates.

Ownership: Triage.

### Artifacts

```
<candidate-id>.md   (per-candidate review)
index.md            (triage index)
```

### Required fields

- `candidate_id`
- `verification_status`
- `verdict`
- `duplicate_candidate`
- `scope_status`
- `evidence_review`
- `reason`

### Optional

- `authorization_check`
- `expected_behavior_note`
- `report_readiness_gates`

### Preserve the designed triage vocabulary

```
false_positive
informational
duplicate
insufficiently_evidenced
potentially_reportable
```

Do NOT redesign the taxonomy in this batch.

### Rules

- Triage is downstream of Verification.
- Triage does not rerun Verification as its primary role.
- Triage does not perform Impact Analysis.

---

## 8. `impact/` — Impact Artifact Layer

Purpose: store evidence-backed impact analysis.

Ownership: Impact.

### Artifact

```
<finding-id>.md
```

### Required fields

- `finding_id`
- `affected_resources`
- `affected_actors`
- `evidence_references`
- `impact_classification`
- `coverage_check`
- `demonstrated_impact`

### Optional

- `impact_chain`
- `severity_notes`

### Preserve the designed impact vocabulary

```
CONFIRMED
PLAUSIBLE-but-unverified
INAPPLICABLE
```

Do NOT reconcile this vocabulary with Triage or Verification vocabularies in
this batch. The mismatch is an explicit future architecture item.

### Rules

- Impact must be evidence-backed.
- Impact does not hunt.

---

## 9. `report/` — Reporting Artifact Layer

Purpose: store reports built from verified, evidence-backed impact.

Ownership: Reporting.

### Artifacts

```
<finding-id>.md   (per-finding report)
index.md          (report index)
```

### Required report sections

- Title
- Summary
- Reproduction steps
- VERIFIED EVIDENCE
- Impact
- Root cause / remediation if supported
- Quality checklist

### Rules

- evidence-backed only
- no invented facts
- no invented impact
- no unsupported severity claims
- trace back to verification and impact artifacts
- preserve finding identity

---

## 10. Cross-Artifact Traceability

Canonical chain:

```
mission
→ planning
→ recon
→ hypothesis
→ candidate
→ verification
→ triage
→ impact
→ report
```

Every artifact should carry enough identifiers to trace its origin.

At minimum preserve:

- `mission_id`
- `hypothesis_id` where applicable
- `candidate_id` where applicable
- `finding_id` where applicable
- source artifact references
- evidence references

No stage may silently detach an artifact from its upstream source.

---

## 11. Ownership Matrix

| Artifact | Primary owner |
|---|---|
| `mission.yaml` | Target Selection / Orchestrator |
| `scope.md` | Orchestrator / mission governance |
| `planning/` | Planning layer |
| `recon/` | Recon |
| `candidates/` | Hunter / Specialists |
| `verification/` | Verification |
| `triage/` | Triage |
| `impact/` | Impact |
| `report/` | Reporting |

Ownership means authority to produce/update the artifact within its contract.
It does NOT grant authority to override upstream authorization.

---

## 12. Mutation Rules

- No silent deletion.
- No silent replacement of evidence.
- Preserve history.
- Downstream stages may annotate upstream records only where explicitly
  permitted.
- Authorization cannot be changed by downstream agents.
- Verification updates candidate state but does not rewrite the candidate's
  historical evidence.
- Triage does not rewrite verification results.
- Impact does not rewrite triage conclusions.
- Reporting does not rewrite impact evidence.

If a correction is necessary, preserve the previous state and record the
correction.

---

## 13. Status Model

Status vocabularies are stage-local. They must NOT be collapsed into one
universal status enum and must NOT be interpreted as interchangeable.

| Stage | Vocabulary |
|---|---|
| Mission | `planned` / `scoped` / `active` / `complete` / `aborted` |
| Candidate | `candidate` |
| Verification | `confirmed` / `rejected` / `inconclusive` |
| Triage | `false_positive` / `informational` / `duplicate` / `insufficiently_evidenced` / `potentially_reportable` |
| Impact | `CONFIRMED` / `PLAUSIBLE-but-unverified` / `INAPPLICABLE` |

These are stage-local states; moving between stages is governed by the handoff
contracts (H1-H8), not by interpreting another stage's status.

---

## 14. Unknown / Blocked / Partial Work

The schema must support incomplete research.

Represent without forcing into successful states:

- unknown → explicit `unknown` / `Not demonstrated.` values
- blocked → resume-ready blocked record with blocker
- unresolved → stays at its stage; not promoted
- insufficient evidence → `insufficiently_evidenced` (triage) or
  `inconclusive` (verification)
- rejected → `rejected` (verification)
- duplicate → `duplicate` (triage)
- partial coverage → coverage gaps recorded, not silently completed

Incomplete work is a valid stage outcome; do not convert it into a successful
state to make the pipeline appear complete.

---

## 15. Mission Completion Gate

Conceptual completion chain. A finding may proceed toward Reporting only when
the relevant upstream artifacts exist and satisfy their stage contracts:

```
candidate
→ verified result
→ triage result
→ impact analysis
→ report
```

- Do NOT define "confirmed" as automatically reportable.
- Do NOT define a global severity ranking.
- "reportable" resolves only through the stage chain, per the triage and
  reporting contracts.

---

## 16. Schema Is Not a Mission

This document defines the architecture/schema only.

A future mission must instantiate its own:

```
./security-research/missions/mission-###
```

No mission directory should be created by this batch. The root and layer
directories above are templates, not instances.

---

## 17. Security Constraints

This batch is documentation-only. It does NOT include:

- target-specific exploit instructions
- credentials
- real tokens
- real target data
- bypass procedures
- payloads
- network testing instructions

No target interaction occurs; no reconnaissance is performed; no external
system is contacted.

---

*Companion to `index/handoff-contracts.md` and `index/canonical-ownership-plan.md`.
Schema only — no mission instantiated.*