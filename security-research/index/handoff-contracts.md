# Agent Handoff Contracts (H1-H8)

Canonical stack architecture for inter-stage handoffs in the web security
research system. This document materializes the H1-H8 handoff design into an
explicit, persistent contract that mission runs must follow.

Audience: Orchestrator, all stage agents, and mission artifact consumers.

Status: architecture contract. This document creates no mission instance, no
agents, no skills, and no target interaction.

---

## 0. Pipeline Model

Canonical pipeline:

```
SCOPE / AUTHORIZATION
→ PLANNING
  ├── Target Selection
  ├── Application Mapping
  └── Hypothesis Generation
→ RECON
→ HUNTER / SPECIALISTS
→ VERIFICATION
→ TRIAGE
→ IMPACT
→ REPORTING
```

Every arrow is a handoff point. H1-H8 name the upstream/downstream pairs at
those points.

All mission artifacts live under a single root:

```
./security-research/missions/mission-###/
```

with the existing architecture:

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

Paths in this document use `mission-###` as the mission identifier placeholder.
Artifact paths are schema-level; the directories are NOT created by this
document or this batch.

---

## 1. Global Invariants

Every handoff contract below operates under these invariants. They are
non-negotiable and apply to all eight contracts.

### 1.1 Authorization

`mission.yaml` is the authorization/scope truth.

No downstream stage may silently expand scope. Any stage that encounters a
surface outside the authorized scope must record it as an observation and route
it to the Orchestrator; it must not act on it.

`scope.md` is the embodiment of the current scope for a given mission and must
not be silently rewritten by any stage.

### 1.2 Traceability

Every downstream artifact must identify its upstream source.

Use candidate IDs / finding IDs / mission IDs where applicable:

```
mission
→ planning artifact
→ recon evidence
→ hypothesis
→ candidate
→ verification artifact
→ triage artifact
→ impact artifact
→ report artifact
```

Every transition must be traceable. A downstream artifact that cannot name its
upstream source is incomplete.

### 1.3 Evidence priority

Use this precedence:

```
Current-target evidence
>
Mission artifacts
>
Canonical methodology
>
Persistent historical knowledge
```

Historical knowledge must never override current evidence.

Reasoning: canonical methodology and persistent knowledge explain patterns;
they do not establish what the current target does. Only observed evidence from
the current target does.

### 1.4 Ownership

No agent silently takes ownership of another stage.

Examples (non-exhaustive):

- Recon does not own canonical hypothesis generation.
- Hunter does not independently verify.
- Verification does not perform general hunting.
- Triage does not replace Verification.
- Impact does not hunt.
- Reporting does not invent impact.

Each stage is the owner of its own outputs and is the receiver of its
immediate upstream outputs. Cross-stage ownership transfer requires an explicit
handoff.

### 1.5 History preservation

Do not silently delete, overwrite, or replace prior evidence.

Stage outputs must preserve traceability. Updating a record with a new state is
allowed; silently discarding its history is not. Prior evidence remains
referenced even when superseded.

### 1.6 Uncertainty

Unknown, inconclusive, blocked, inferred, and theoretical states must remain
explicit.

Do not convert uncertainty into certainty during handoff.

A handoff that would force certainty out of uncertainty must instead preserve
the uncertain state and communicate it to the receiver.

---

## 2. H1 — Target Selection → Application Mapping

### Purpose

Decide what authorized target/surface should be researched, then begin mapping
its application structure.

### 1. Purpose

Pass the selected authorized target from Target Selection to Application
Mapping so that mapping can start from the correct surface. Target Selection
decides WHAT is in scope to research; Application Mapping produces the
structured application model for that target.

### 2. Sender

Target Selection (planning stage).

### 3. Receiver

Application Mapping (planning stage).

### 4. Required inputs

To Application Mapping:

- selected target identity/designation
- authorized scope references (mission.yaml + scope.md)
- target classification / surface assessment summary
- any known constraints on the surface
- sufficient scope/context for mapping to begin

### 5. Required outputs

From Application Mapping:

- structured application model (surfaces, endpoints, actors, trust boundaries,
  parameters, technologies/signals, scope constraints)
- confirmation that the model corresponds to the selected target

### 6. Artifact paths

- Input: `missions/mission-###/planning/` (target selection output), backed by
  `missions/mission-###/mission.yaml` and `missions/mission-###/scope.md`
- Output: `missions/mission-###/planning/` (application model)

### 7. Completion criteria

- The selected target is identified with enough scope/context for mapping to
  begin.
- Application Mapping has produced an application model for the selected
  target, or has recorded why mapping could not proceed.

### 8. Failure / blocked semantics

- Missing authorization → stop. Do not map.
- Missing scope → stop. Do not map.
- Incomplete mapping → return/block at the planning boundary; do not forward a
  half-model downstream as if it were complete.

### 9. Uncertainty handling

If the selected target's surface is uncertain, record the uncertainty
explicitly in the application model; do not guess a surface into the model.

### 10. Ownership boundary

- Target Selection owns the selection decision.
- Application Mapping owns the application model.
- Application Mapping must not reinterpret authorization. It maps what was
  authorized; it does not re-decide scope.

### 11. What the receiver MUST NOT assume

- That the application model implies authorization to test any surface found
  during mapping.
- That mapping toggles scope.

### 12. What the sender MUST NOT silently do

- Expand scope beyond `mission.yaml`/`scope.md`.
- Forward a selection without providing enough context for mapping to begin.

### 13. Traceability requirements

- The application model records the selected target and the scope references
  that authorize it.

---

## 3. H2 — Application Mapping → Hypothesis Generation

### Purpose

Feed the structured application model into hypothesis generation to derive
explicit, testable hypotheses.

### 1. Purpose

Convert the mapped application structure into explicit, testable security
hypotheses. Application Mapping provides the model; Hypothesis Generation
derives the hypotheses. Hypothesis Generation must not perform vulnerability
testing.

### 2. Sender

Application Mapping (planning stage).

### 3. Receiver

Hypothesis Generation (planning stage).

### 4. Required inputs

To Hypothesis Generation:

- mapped surfaces
- endpoints
- actors
- authentication/context
- trust boundaries
- parameters
- technologies/signals
- relevant behavioral observations
- scope constraints

### 5. Required outputs

From Hypothesis Generation:

- explicit, testable hypotheses
- for each hypothesis: the security property it targets, the surface/actor it
  applies to, and any prerequisites

### 6. Artifact paths

- Input: `missions/mission-###/planning/` (application model)
- Output: `missions/mission-###/planning/` (hypotheses)

### 7. Completion criteria

- The application model is available.
- Hypotheses are derived from the model (or the model was returned for
  completion).

### 8. Failure / blocked semantics

- Insufficient hypothesis context (missing surfaces/actors/endpoints) → return
  to Application Mapping.
- Model is incomplete → block; do not generate hypotheses from invented
  structure.

### 9. Uncertainty handling

An unverified structural assumption (e.g., a parameter whose reachability is
unknown) is recorded as such on the hypothesis; it must not be converted into a
testable claim.

### 10. Ownership boundary

- Application Mapping owns the application model.
- Hypothesis Generation owns the hypotheses.
- Hypothesis Generation does not own vulnerability testing.

### 11. What the receiver MUST NOT assume

- That a hypothesis is a vulnerability.
- That the model authorizes testing beyond the recorded scope.

### 12. What the sender MUST NOT silently do

- Include out-of-scope structure as if in-scope.
- Present unverified structural assumptions as fact.

### 13. Traceability requirements

- Each hypothesis references its originating application-model element and the
  scope constraints in force.

---

## 4. H3 — Hypothesis Generation → Orchestrator → Recon / Hunter / Specialists

### Purpose

Route canonical hypotheses from the planning layer to the stages that consume
them.

### 1. Purpose

Hypothesis Generation provides canonical hypotheses. The Orchestrator owns
routing, and routes each hypothesis (and its discovery prerequisites) to Recon
or directly to Hunter/Specialists.

### 2. Sender

Hypothesis Generation (planning stage), via the Orchestrator.

### 3. Receiver

The Orchestrator (routing), then Recon / Hunter / Specialists.

### 4. Required inputs

To the Orchestrator:

- canonical hypotheses
- per hypothesis: security category, affected surface, actor/context,
  prerequisites, required discovery evidence, specialist ownership

### 5. Required outputs

From the Orchestrator:

- routed tasks to Recon (discovery tasks / prerequisite evidence) 
- routed hypotheses to Hunter / Specialists

### 6. Artifact paths

- Input: `missions/mission-###/planning/` (hypotheses)
- Output: routed instructions into `missions/mission-###/recon/` and
  into `missions/mission-###/candidates/` preparation or specialist handoff

### 7. Completion criteria

- Each hypothesis is routed to the correct consumer, or explicitly held with a
  recorded reason.
- Routing decisions are traceable to the hypothesis.

### 8. Failure / blocked semantics

- Insufficient hypothesis context → return to the appropriate upstream
  planning stage.
- Routing is ambiguous → hold at the Orchestrator; do not guess a destination.

### 9. Uncertainty handling

A hypothesis whose destination is uncertain is held and its uncertainty
recorded; it is not pushed to a stage that would have to invent the 
hypothesis-generation role.

### 10. Ownership boundary

- Hypothesis Generation owns canonical hypothesis generation.
- The Orchestrator owns routing.
- Recon and Hunter must not silently replace the canonical hypothesis-generation
  capability. They consume routed hypotheses/tasks; they do not re-own
  generation.

### 11. What the receiver MUST NOT assume

- That receiving a hypothesis authorizes broadening the attack surface.
- That routing implies ownership of the canonical hypothesis-generation
  capability.

### 12. What the sender MUST NOT silently do

- Skip routing and push hypotheses directly without coordination context.
- Let a consumer re-own generation by not stating the ownership boundary.

### 13. Traceability requirements

- Every routed hypothesis records its source hypothesis ID and its routing
  destination.
- Downstream artifacts created from a routed hypothesis reference it.

---

## 5. H4 — Recon → Hunter / Specialists

### Purpose

Deliver discovery evidence and attack-surface signals from Recon to
Hunter/Specialists so hypotheses can be pursued on an authorized, mapped
surface.

### 1. Purpose

Recon provides the discovery evidence and attack-surface signals that hunting
needs. Hunter/Specialists pursue hypotheses against the surfaces Recon
documents.

### 2. Sender

Recon.

### 3. Receiver

Hunter / Specialists.

### 4. Required inputs

From Recon to Hunter/Specialists (required examples):

- surfaces
- endpoints
- parameters
- authentication/context
- technology signals
- scope status
- provenance
- confidence
- relevant observations

### 5. Required outputs

From Hunter/Specialists:

- candidates for surface behavior that may be security-relevant, each grounded
  in Recon evidence and, where applicable, routed hypotheses

### 6. Artifact paths

- Input: `missions/mission-###/recon/` (discovery evidence and attack-surface
  signals)
- Output: `missions/mission-###/candidates/` (candidate records)

### 7. Completion criteria

- Recon evidence is indexed under `missions/mission-###/recon/` with
  provenance and confidence.
- Hunter/Specialists have what they need to pursue assigned hypotheses, or
  missing evidence has been explicitly requested.

### 8. Failure / blocked semantics

- Insufficient discovery evidence → remain unresolved at Recon; a hypothesis
  needing that evidence stays un-pursued until the evidence exists.
- Missing evidence for an assigned hypothesis → request from Recon; do not
  fabricate evidence.

### 9. Uncertainty handling

Recon confidence levels propagate with the evidence. A low-confidence signal is
labeled as such; Hunter must not upgrade it during receipt.

### 10. Ownership boundary

- Recon owns discovery evidence and attack-surface signals.
- Hunter/Specialists own hypothesis pursuit (for the hypotheses routed to them).
- Recon may identify signals; Recon does not own canonical hypothesis generation.

### 11. What the receiver MUST NOT assume

- That a Recon signal is a confirmed issue (it is an observation).
- That a low-confidence signal may be silently promoted to certainty.

### 12. What the sender MUST NOT silently do

- Present signal-level observations as confirmed findings.
- Omit provenance or confidence from evidence it hands off.

### 13. Traceability requirements

- Every candidate references the Recon evidence (and routed hypothesis) it
  comes from.

---

## 6. H5 — Hunter / Specialists → Verification

### Purpose

Deliver a candidate for independent verification.

### 1. Purpose

Hunter/Specialists provide a candidate. Verification independently evaluates
whether the evidence supports the candidate claim. The sender passes a
candidate, not a verified finding.

### 2. Sender

Hunter / Specialists (hunting layer).

### 3. Receiver

Verification.

### 4. Required inputs

To Verification:

- candidate identity
- target
- endpoint
- method
- parameter
- actor/context
- hypothesis
- prerequisites
- test plan
- baseline
- existing evidence

### 5. Required outputs

From Verification:

- verification outcome via `verification/<candidate-id>.md` (candidate_id,
  verification_status, baseline, test, differential_comparison, reproduction,
  evidence, reasoning, remaining_uncertainty)
- verification status: confirmed / rejected / inconclusive

### 6. Artifact paths

- Input: `missions/mission-###/candidates/<candidate-id>.yaml` (the candidate
  record; authoritative)
- Output: `missions/mission-###/verification/<candidate-id>.md`

Candidate status starts as `candidate`. The sender must not mark it verified or
reportable.

### 7. Completion criteria

- A candidate record exists for the candidate identity.
- Verification has produced an artifact and an explicit status, or has recorded
  why verification could not complete.

### 8. Failure / blocked semantics

- Candidate cannot be independently reproduced → `rejected` or `inconclusive`
  (per evidence).
- Missing candidate identity or evidence → return to the sender with the gap.

### 9. Uncertainty handling

Inconclusive is a valid, explicit outcome. Verification does not coerce
inconclusive results into confirmed/rejected.

### 10. Ownership boundary

- Hunter/Specialists own candidate creation.
- Verification owns the verification decision.
- Verification does not perform general hunting.
- The sender must not pre-verify its own candidate.

### 11. What the receiver MUST NOT assume

- That a candidate is a vulnerability (a candidate is not a confirmed finding).
- That the sender's framing of evidence is final.

### 12. What the sender MUST NOT silently do

- Mark a candidate verified or reportable before Verification runs.
- Withhold existing evidence from the candidate record.

### 13. Traceability requirements

- The candidate record and the verification artifact both carry the same
  candidate ID.
- The verification artifact references the candidate record and the evidence
  used.

---

## 7. H6 — Verification → Triage

### Purpose

Hand verified-state candidates to Triage as the next independent review stage.

### 1. Purpose

Verification provides its outcome and evidence to Triage, which independently
reviews the candidate. "confirmed" does NOT mean "reportable"; Triage remains a
separate review stage.

### 2. Sender

Verification.

### 3. Receiver

Triage.

### 4. Required inputs

To Triage (required):

- candidate_id
- verification_status
- verification artifact
- evidence references
- reasoning
- remaining uncertainty

### 5. Required outputs

From Triage:

- a triage decision per its downstream handoff conditions (see H7)

### 6. Artifact paths

- Input: `missions/mission-###/verification/<candidate-id>.md`
- Output: `missions/mission-###/triage/` (triage artifact)

### 7. Completion criteria

- `confirmed` candidates proceed to Triage with complete verification evidence.
- `rejected` candidates are closed with the candidate record updated in place.
- `inconclusive` candidates return to the Orchestrator with missing evidence.

### 8. Failure / blocked semantics

- Verification cannot independently reproduce → `rejected` or `inconclusive`;
  do not promote.
- Triage is not reachable (queue blocked) → hold at Verification per queue
  continuity; do not silently drop candidates.

### 9. Uncertainty handling

Remaining uncertainty is passed to Triage explicitly; Triage evaluates it as
part of evidence review. Uncertainty is not converted to certainty at this edge.

### 10. Ownership boundary

- Verification owns the verification decision.
- Triage owns the review/verdict.
- Triage does not replace Verification; Verification does not decide
  reportability.

### 11. What the receiver MUST NOT assume

- That `confirmed` implies reportable.
- That the verification artifact is the final word on the issue (Triage reviews
  it).

### 12. What the sender MUST NOT silently do

- Convert `confirmed` into a recommendation for reporting.
- Drop remaining uncertainty before handoff.

### 13. Traceability requirements

- The triage artifact references the verification artifact and the candidate ID.

---

## 8. H7 — Triage → Impact

### Purpose

Pass triaged candidates (those meeting triage handoff conditions) to Impact for
impact analysis.

### 1. Purpose

Triage provides only candidates that satisfy its own downstream handoff
conditions. Impact analyzes demonstrated impact for those candidates. Triage
does not perform impact analysis.

### 2. Sender

Triage.

### 3. Receiver

Impact.

### 4. Required inputs

To Impact, Triage communicates:

- candidate/finding identity
- triage verdict
- duplicate state where applicable
- scope status
- evidence review
- reason
- report-readiness information where applicable

### 5. Required outputs

From Impact:

- impact analysis per H8

### 6. Artifact paths

- Input: `missions/mission-###/triage/` (triage artifact)
- Output: `missions/mission-###/impact/` (impact artifact)

### 7. Completion criteria

- Only triaged candidates meeting handoff conditions reach Impact.
- Impact has produced an impact artifact, or has recorded why analysis was
  blocked.

### 8. Failure / blocked semantics

- Triage identifies insufficient evidence → do not promote to Impact.
- Scope is out of scope (verdict) → do not forward.
- Impact cannot demonstrate impact → preserve uncertainty (see H8).

### 9. Uncertainty handling

Triage verdicts carry their reasoning including uncertainty. Impact consumes
that as-is; it does not re-decide the verdict.

### 10. Ownership boundary

- Triage owns the triage verdict.
- Impact owns impact analysis.
- Triage does not perform impact analysis.
- Impact does not hunt.

### 11. What the receiver MUST NOT assume

- That a triage verdict equals an impact classification.
- That report-readiness information is an impact conclusion.

### 12. What the sender MUST NOT silently do

- Forward un-triaged or out-of-scope candidates.
- Withhold evidence review context from Impact.

### 13. Traceability requirements

- The impact artifact references the triage artifact, the verification
  artifact, and the candidate/finding ID.

### Note: taxonomy mismatch

The previously identified taxonomy mismatch between triage verdicts and impact
classifications is intentionally NOT resolved in this batch. Resolving it is an
open architecture item tracked separately. Contract semantics above hold
independent of that resolution.

---

## 9. H8 — Impact → Reporting

### Purpose

Pass evidence-backed impact to Reporting so the report reflects demonstrated
impact only.

### 1. Purpose

Impact provides evidence-backed impact for triaged findings. Reporting converts
that verified, scoped, impact-analyzed evidence into a report. Reporting must
not invent impact.

### 2. Sender

Impact.

### 3. Receiver

Reporting.

### 4. Required inputs

To Reporting, Impact provides:

- finding_id
- affected resources
- affected actors
- evidence references
- impact classification
- coverage status
- demonstrated impact
- supported impact chain where applicable
- severity-related notes only when evidence supports them

### 5. Required outputs

From Reporting:

- the report artifact built solely from the incoming evidence

### 6. Artifact paths

- Input: `missions/mission-###/impact/` (impact artifact)
- Output: `missions/mission-###/report/` (report artifact)

### 7. Completion criteria

- The report covers all reportable findings with evidence-backed impact.
- Unknown or non-demonstrated impact is explicitly marked, not invented.

### 8. Failure / blocked semantics

- Reporting lacks required evidence → do not invent missing facts; record what
  is not demonstrated.
- Impact has not been produced for a finding → do not report it as impact-analyzed.

### 9. Uncertainty handling

Impact-related uncertainty is carried into the report verbatim. Inferred impact
chains are labeled inferred, never upgraded to demonstrated.

### 10. Ownership boundary

- Impact owns impact analysis.
- Reporting owns the report.
- Impact does not hunt; Reporting does not invent impact.

### 11. What the receiver MUST NOT assume

- That severity-related notes are final scoring.
- That an impact classification implies vulnerability certainty beyond evidence.

### 12. What the sender MUST NOT silently do

- Pass unverified or non-demonstrated impact as demonstrated.
- Omit coverage status.

### 13. Traceability requirements

- The report artifact references the impact artifact, the triage artifact, and
  the finding ID for every included item.

---

## 10. Failure Semantics Summary

The pipeline behavior when a handoff cannot be completed:

| Failure | Behavior |
|---|---|
| missing authorization | stop |
| missing scope | stop |
| incomplete mapping | return/block |
| insufficient hypothesis context | return to appropriate upstream stage |
| insufficient discovery evidence | remain unresolved / return to Recon |
| candidate cannot be independently reproduced | rejected or inconclusive |
| triage identifies insufficient evidence | do not promote |
| impact cannot be demonstrated | preserve uncertainty |
| reporting lacks required evidence | do not invent missing facts |

Do not create new status vocabularies unless absolutely required. Prefer the
existing architecture vocabulary (candidate, confirmed, rejected, inconclusive,
and per-stage verdicts/statuses).

---

## 11. Artifact Traceability Chain

```
mission (mission-###)
→ planning artifact (planning/)
→ recon evidence (recon/)
→ hypothesis (hypothesis ID)
→ candidate (candidates/<candidate-id>.yaml)
→ verification artifact (verification/<candidate-id>.md)
→ triage artifact (triage/)
→ impact artifact (impact/)
→ report artifact (report/)
```

Every transition must carry the identifying IDs (candidate / finding / mission)
so any downstream artifact can be traced to its upstream source.

---

## 12. Security Boundaries

This document is a documentation/architecture contract only. It does NOT add:

- exploit payloads
- target-specific testing instructions
- real credentials
- real target data
- network procedures
- bypass instructions

This batch creates no mission instance and performs no target interaction.

---

*Companion to `index/canonical-ownership-plan.md` and the planning layer under
`security-research/planning/` (target-selection, application-mapping,
hypothesis-generation).*