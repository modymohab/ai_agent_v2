# Canonical Ownership Plan

Design-only ownership model for every substantive piece of knowledge in the
web security research system. Produced after the read-only
`index/parallel-knowledge-audit.md` (102-file classification) and consistent
with `index/methodology-canonical-map.md`.

**Phase constraint: DESIGN ONLY.** Nothing in this document is applied here.
No file is created, migrated, rewritten, deleted, renamed, or moved. No link is
re-pointed. No target is interacted with. This plan is the decision record that
a future execution phase may act on (per the validated migration order in
Section 10). The single exception to "nothing created" is this plan file itself.

Fixpoint rule applied throughout: ownership must always resolve to exactly one
authoritative owner for each piece of substantive knowledge; derived summaries,
routers, operational checklists, and agent-specific material may remain in
reference/operational layers, but each must declare its owner.

---

## 1. Executive Summary

The system is a two-layer knowledge architecture.

- **Canonical methodology layer** — `security-research/methodology/<topic>-skill/SKILL.md`
  (23 topics). Authoritative owners of vulnerability-class methodology. Frozen
  in this phase; ownership is confirmed, not changed.
- **Parallel layer** — `skills/<domain>/*` (102 files) plus `agents/<domain>.md`.
  Process, planning, foundation, operational, and agent-dispatch content. Holds
  the system's foundation (research process), four planning capabilities
  (workflow, target selection, application mapping, hypothesis generation), the
  entire triage agent capability, recon tool-selection guidance, and the hunter
  pattern-recognition model.

The decisive design choices:

1. **Foundation stays parallel.** The research process
   (`web-security-research/SKILL.md` + `references/workflow.md`) is the
   authoritative owner of process knowledge. It is NOT migrated into the
   methodology topic set. Process knowledge and vulnerability methodology are
   different kinds of knowledge and must not share owners.
2. **Planning tier is a first-class parallel capability.** Target selection,
   application mapping, and hypothesis generation are each retained as standalone
   capabilities with a single owner in `skills/web-security-research/references/`.
   None is folded into recon, hunter, the foundation workflow, or a methodology
   topic (each conflation was examined and rejected — see Sections 5 and 10).
3. **Operational tool/pattern knowledge stays operational.** Recon
   `tool-selection.md` and hunter `vulnerability-patterns.md` remain operational
   references. They do NOT become vulnerability methodology.
4. **Verification queue continuity and subagent-failure isolation are
   orchestration doctrine, not vulnerability methodology.** They stay with the
   verification agent layer (`security-verification/SKILL.md`).
5. **Triage is a hybrid**: substantive security-review reasoning in an
   agent-bound context, owned by the parallel triage layer, not fragmented into
   the 23-topic methodology set. (Section 7.)
6. **23 canonical methodologies: ownership unchanged**, each at
   `methodology/<topic>-skill/SKILL.md`.
7. **SSTI/XXE: canonical-only**, parallel coverage gap is deliberate and retained.
8. **Impact router**: retained as a router; its canonical-copy pointer must later
   be corrected to `methodology/impact-analysis-skill/SKILL.md §2b` (documented,
   NOT applied).
9. **cve-research**: remains a GAP with no owner. No `cve-research-skill` is
   created.

Bottom line: **zero moves, zero deletions.** The knowledge base is healthy; the
correct ownership model is to declare the owners that already exist, keep the
few genuine overlaps as DERIVED_REFERENCE/AGENT_LOCAL surfaces, and fix one
router pointer in a later maintenance pass.

---

## 2. Final Knowledge Hierarchy

Preserved 10-layer research chain (top → bottom; each layer passes artifacts to
the next). This is the decision order for c2 knowledge resolution, per
`security-research/AGENTS.md` (mission scope + evidence always override).

```
   Layer 1  FOUNDATION PROCESS
            owner:  skills/web-security-research/SKILL.md
            incl.:  references/workflow.md (8-phase workflow companion)
            ↑ evidence categories, scope-first, research loop, minimal-testing
              doctrine, knowledge-usage priority, PortSwigger pattern engine
            ↓
   Layer 2  TARGET SELECTION (PLANNING)
            owner:  skills/web-security-research/references/target-selection.md
            ↑ authorization gate, classification, surface assessment, decision
            ↓
   Layer 3  APPLICATION MAPPING (PLANNING / DISCOVERY)
            owner:  skills/web-security-research/references/application-mapping.md
            ↓
   Layer 4  HYPOTHESIS GENERATION (PLANNING)
            owner:  skills/web-security-research/references/hypothesis-generation.md
            ↓
   Layer 5  RECONNAISSANCE (DISCOVERY)
            agent ops owner:  skills/security-recon/SKILL.md
            methodology owner: methodology/reconnaissance-skill/SKILL.md
            tool selection:    skills/security-recon/references/tool-selection.md
            ↓
   Layer 6  HUNTING + SPECIALIST AGENTS
            hunting loop owner:   skills/security-hunter/SKILL.md
            pattern model:        skills/security-hunter/references/vulnerability-patterns.md
            capability sources:   security-hunter/references/{client-side,server-side}.md
            specialist coverage:  access-control / api / business-logic SKILL layers
            ↓
   Layer 7  CANONICAL METHODOLOGY (23 topics)
            owner:  methodology/<topic>-skill/SKILL.md  (each self-owned)
            ↓
   Layer 8  VERIFICATION (VALIDATION)
            methodology owner:  methodology/verification-skill/SKILL.md
            agent ops owner:    skills/security-verification/SKILL.md
            (incl. queue-continuity + subagent-failure doctrine = ORCHESTRATION)
            ↓
   Layer 9  TRIAGE (TRIAGE)
            owner:  skills/security-triage/* (7 files) + agents/triage.md
            ↓
   Layer 10 IMPACT (IMPACT)
            methodology owner: methodology/impact-analysis-skill/SKILL.md (incl. §2b)
            agent ops owner:   skills/security-impact/SKILL.md
            router:            security-impact/references/impact-analysis.md
            coverage mirror:   security-impact/references/class-impact-coverage.md
            ↓
   Layer 11 REPORTING (REPORTING)
            methodology owner: methodology/reporting-skill/SKILL.md
            agent ops owner:   skills/security-reporting/SKILL.md
```

Each layer declares its owner explicitly. No layer depends on a lower layer's
unique knowledge being re-owned; artifacts flow downward.

---

## 3. Ownership Matrix

Columns: Current Path | Knowledge Type | Current Classification | Proposed
Canonical Owner | Final Role | Action. Final-role values: CANONICAL /
DERIVED_REFERENCE / ROUTER / AGENT_LOCAL / LEGACY_ARCHIVE / GAP. Action values:
KEEP / MIGRATE / SPLIT / DEMOTE / ROUTE / ARCHIVE / UNRESOLVED.

Legend note: "CANONICAL (process/planning)" means the designated authoritative
owner of that knowledge kind (process, planning) in the parallel layer — distinct
from the 23 METHODOLOGY topics, which remain the only CANONICAL class-methodology
owners. Both are single-owner designations.

### 3.1 UNIQUE knowledge (14 files)

| Current Path | Knowledge Type | Current Class | Proposed Canonical Owner | Final Role | Action |
|---|---|---|---|---|---|
| `skills/web-security-research/SKILL.md` | FOUNDATION | UNIQUE | **self** — authoritative foundation process owner | CANONICAL (process) | KEEP |
| `skills/web-security-research/references/workflow.md` | ORCHESTRATION | UNIQUE | companion of foundation owner (`web-security-research/SKILL.md`) | CANONICAL (process) | KEEP |
| `skills/web-security-research/references/target-selection.md` | PLANNING | UNIQUE | **self** — planning/selection capability | CANONICAL (planning) | KEEP |
| `skills/web-security-research/references/application-mapping.md` | PLANNING / DISCOVERY | UNIQUE | **self** — mapping capability | CANONICAL (planning) | KEEP |
| `skills/web-security-research/references/hypothesis-generation.md` | PLANNING | UNIQUE | **self** — hypothesis-generation capability | CANONICAL (planning) | KEEP |
| `skills/security-triage/SKILL.md` | TRIAGE | UNIQUE | `skills/security-triage/` (+ `agents/triage.md`) | AGENT_LOCAL (hybrid, see §7) | KEEP |
| `skills/security-triage/references/duplicate-analysis.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-triage/references/evidence-review.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-triage/references/expected-behavior.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-triage/references/scope-review.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-triage/references/triage-workflow.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-triage/references/validity-review.md` | TRIAGE | UNIQUE | `skills/security-triage/SKILL.md` | AGENT_LOCAL | KEEP |
| `skills/security-recon/references/tool-selection.md` | OPERATIONAL_REFERENCE | UNIQUE | self as operational ref; methodology defers to `methodology/reconnaissance-skill` | AGENT_LOCAL | KEEP |
| `skills/security-hunter/references/vulnerability-patterns.md` | OPERATIONAL_REFERENCE | UNIQUE | self as hunting-pattern ref (class bodies owned by canonical class skills) | AGENT_LOCAL | KEEP |

### 3.2 PARTIAL-OVERLAP knowledge (11 files)

| Current Path | Knowledge Type | Current Class | Proposed Canonical Owner | Final Role | Action |
|---|---|---|---|---|---|
| `skills/security-recon/SKILL.md` | DISCOVERY | PARTIAL-OVERLAP | methodology: `methodology/reconnaissance-skill`; this file = recon agent operational/dispatch surface | AGENT_LOCAL | KEEP |
| `skills/security-hunter/SKILL.md` | METHODOLOGY-adjacent (hunting loop) | PARTIAL-OVERLAP | class skills own class bodies; this file = hunting-loop operational layer | AGENT_LOCAL | KEEP |
| `skills/security-hunter/references/client-side.md` | OPERATIONAL_REFERENCE | PARTIAL-OVERLAP | `methodology/client-side-skill` (derivation source of that skill) | DERIVED_REFERENCE | KEEP |
| `skills/security-hunter/references/server-side.md` | OPERATIONAL_REFERENCE | PARTIAL-OVERLAP | `methodology/server-side-skill` (derivation source) | DERIVED_REFERENCE | KEEP |
| `skills/security-access-control/SKILL.md` | METHODOLOGY | PARTIAL-OVERLAP | `methodology/access-control-skill` (+ `privilege-escalation-skill`); this file = access-control agent ops depth | AGENT_LOCAL | KEEP |
| `skills/security-api/SKILL.md` | METHODOLOGY | PARTIAL-OVERLAP | `methodology/api-security-skill`; this file = api agent ops layer | AGENT_LOCAL | KEEP |
| `skills/security-business-logic/SKILL.md` | METHODOLOGY | PARTIAL-OVERLAP | `methodology/business-logic-skill` (+ `race-conditions-skill`); this file = business-logic agent ops layer | AGENT_LOCAL | KEEP |
| `skills/security-impact/SKILL.md` | IMPACT | PARTIAL-OVERLAP | `methodology/impact-analysis-skill`; this file = impact agent ops layer | AGENT_LOCAL | KEEP |
| `skills/security-impact/references/class-impact-coverage.md` | IMPACT | PARTIAL-OVERLAP | `methodology/impact-analysis-skill §2b` (+ `index/attack-impact-coverage.md`) | DERIVED_REFERENCE | KEEP |
| `skills/security-reporting/SKILL.md` | REPORTING | PARTIAL-OVERLAP | `methodology/reporting-skill`; this file = reporting agent ops layer | AGENT_LOCAL | KEEP |
| `skills/security-verification/SKILL.md` | VALIDATION (+ ORCHESTRATION for queue sections) | PARTIAL-OVERLAP | methodology: `methodology/verification-skill`; queue-continuity/subagent doctrine = AGENT_LOCAL orchestration (§8) | AGENT_LOCAL | KEEP |

### 3.3 ROUTER (1 file)

| Current Path | Knowledge Type | Current Class | Proposed Canonical Owner | Final Role | Action |
|---|---|---|---|---|---|
| `skills/security-impact/references/impact-analysis.md` | ROUTER | ROUTER | `methodology/impact-analysis-skill/SKILL.md §2b` (future pointer correction, §9.1) | ROUTER | ROUTE (repair pointer later; keep file) |

### 3.4 Grouped rows

| Current Path | Knowledge Type | Current Class | Proposed Canonical Owner | Final Role | Action |
|---|---|---|---|---|---|
| 76 DERIVED files across the 10 `skills/` dirs | DERIVED_REFERENCE | DERIVED | respectively the declared `methodology/<topic>-skill` (each summary declares its owner) | DERIVED_REFERENCE | KEEP |
| 23 `methodology/<topic>-skill/SKILL.md` | METHODOLOGY | CANONICAL | **self**, each topic | CANONICAL | KEEP (unchanged) |
| 24 legacy `methodology/<topic>.md` sources (incl. stubs) | LEGACY_SOURCE | LEGACY | retained for provenance only; superseded by `-skill` | LEGACY_ARCHIVE | ARCHIVE (retain, no edits) |
| `cve-research` topic | n/a (no content) | GAP | **none** | GAP | UNRESOLVED (no skill created) |

---

## 4. Canonical Methodologies (23) — Ownership Confirmed

Each topic remains owned by its `methodology/<topic>-skill/SKILL.md`. No change.
Listed for completeness and validation:

access-control, api-security, authentication, business-logic, client-side,
csrf, deserialization, file-security, impact-analysis, injection, jwt,
oauth-sso, privilege-escalation, race-conditions, reconnaissance, reporting,
server-side, ssrf, ssti, traversal, verification, xss, xxe.

Status notes (consistent with `methodology-canonical-map.md`):
- 19 of the canonical skills are body-identical to their legacy `.md`; the
  `-skill` file is the operative owner; the `.md` is legacy archive.
- 4 capability skills have no realized `.md` source (client-side, server-side,
  privilege-escalation, reporting) — they are the only realized content and are
  self-owned; their derivation sources are the parallel hunter refs (§3.2).
- `cve-research` (24th topic) is NOT in this set: canonical GAP, no skill.

---

## 5. Unique Knowledge (14) — Owner Assignments

All 14 UNIQUE files from the audit are accounted for and given a single owner.

1. `web-security-research/SKILL.md` → foundation process owner (CANONICAL).
   Its candidate owner was evaluated as `skills/web-security-research/SKILL.md`
   and adopted. **No migration into methodology.** It remains the authoritative
   owner of the research loop because the canonical topic set is a corpus of
   vulnerability classes, not a process manual.
2. `references/workflow.md` → companion of (1). The 8-phase workflow is the
   process instantiation of the foundation; it shares the foundation owner, not
   a methodology owner.
3. `references/target-selection.md` → planning capability, self-owned.
4. `references/application-mapping.md` → mapping capability, self-owned.
5. `references/hypothesis-generation.md` → hypothesis-generation capability,
   self-owned. The hypothesis-gen ↔ vulnerability-methodology distinction is
   preserved: generation builds PLANNING artifacts (hypotheses/candidates);
   methodology skills explain HOW a class manifests and is tested. Hunter consumes
   hypotheses; it does not own generation.
6–12. `security-triage/` (7 files) → single triage owner (Section 7).
13. `security-recon/references/tool-selection.md` → recon operational reference.
14. `security-hunter/references/vulnerability-patterns.md` → hunter operational
    reference.

No UNIQUE item is left without an owner. None is demoted or relocated.

---

## 6. Partial Overlaps (11) — Owner Assignments

All 11 PARTIAL-OVERLAP files from the audit are accounted for.

The overlap rule: **where a parallel file overlaps a canonical topic, the
canonical `-skill` remains the authoritative owner of that topic's methodology,
and the parallel file is declared an AGENT_LOCAL or DERIVED_REFERENCE surface**
that adds coordination, routing, operational depth, or dispatch — never a second
methodology authority.

- 8 SKILL.md dispatcher/operator layers (recon, hunter, access-control, api,
  business-logic, impact, reporting, verification) → AGENT_LOCAL. Their extra
  content is agent-operation (procedural depth, routing, handoffs, hints), which
  is exactly the material that belongs to an operational layer, not a methodology
  owner.
- `security-hunter/references/{client-side,server-side}.md` →
  DERIVED_REFERENCE, owning their content is already captured in
  `client-side-skill` / `server-side-skill` (the skills were derived from these
  files). The files are kept as the hunting-layer signal references; their owner
  is the derived skill.
- `security-impact/references/class-impact-coverage.md` → DERIVED_REFERENCE of
  `impact-analysis-skill §2b` (+ `index/attack-impact-coverage.md`).

No overlap file is deleted. No overlap file becomes a second CANONICAL owner.

---

## 7. Security Triage Architecture (Dedicated Analysis)

Question: is `security-triage/` canonical, operational, agent-specific, or
hybrid? And which of its content is substantive security methodology versus
orchestration/process logic?

**Verdict: HYBRID, kept in the parallel layer, single triage owner.**

Reasoning:

1. **Substantive security-review reasoning exists** — validity
   (`validity-review.md`), expected-behavior derivation
   (`expected-behavior.md`), duplicate analysis (`duplicate-analysis.md`),
   evidence review (`evidence-review.md`), scope review (`scope-review.md`).
   These encode real security methodology (how to judge whether a finding is a
   genuine security-property violation). This is not reducer-copy; it is the
   strongest new methodology content outside the planning layer.
2. **But it is inseparably agent-bound.** Triage has meaning only as an
   operation over finding candidates in a mission context (candidate →
   verification → triage → impact → report). Its inputs are other agents'
   artifacts; its outputs feed impact and reporting. It has no standalone
   "triage class" analog and is not a vulnerability class. Formalizing it inside
   the 23-topic METHODOLOGY set would mislabel orchestration as class methodology.
3. **Orchestration/process content is present** — `triage-workflow.md` (ordered
   review), SKILL.md statuses and handoff, adversarial questions. This is
   process/agent logic, not vulnerability methodology.

Decision:
- Single owner: `skills/security-triage/SKILL.md` (with the 6 references and
  `agents/triage.md` as its agent specification). Nothing recalibrated into
  methodology.
- Knowledge Type: TRIAGE. Final Role: AGENT_LOCAL (agent-specific security review
  capability) — record as **hybrid**: substantive review methodology is retained,
  but it is reviewed-in-context methodology. If it is ever promoted, it must be
  as a top-level process module (e.g., a lifecycle review skill), never as one of
  the 23 vulnerability topics — flagged optional/future, NOT now.

---

## 8. Operational Doctrine

Two bodies of operational doctrine must NOT automatically become vulnerability
methodology:

1. **Verification queue continuity + subagent failure isolation**
   (`security-verification/SKILL.md` unique sections). These are
   ORCHESTRATION resilience rules: candidate-queue continuity, subagent failure
   isolation, queue-state model. They define *how verification agents survive
   interruptions*, not *how vulnerabilities manifest*. Owner: verification agent
   layer (AGENT_LOCAL). Never promoted to `verification-skill` methodology
   (which owns evidence-gate methodology only).
2. **Recon tool selection** (`security-recon/references/tool-selection.md`).
   Operational tooling guidance (minimal-authorized-toolset, selection factors,
   passive-first, footprint-bypass prohibition). Tool-operation knowledge must
   not be turned into vulnerability methodology. Owner: recon layer
   (AGENT_LOCAL operational reference). It may reference
   `methodology/reconnaissance-skill`, but it does not become that skill's body.

Rule statement: **operational and orchestration doctrine is AGENT_LOCAL by
default; promotion to METHODOLOGY requires a documented decision, not automatic
inheritance.**

---

## 9. Link/Router Corrections (documented, NOT applied)

Documented here so a future maintenance pass can apply them; execution is
explicitly out of scope this phase.

1. **Impact router pointer** — `skills/security-impact/references/impact-analysis.md`
   declares its canonical copy as `methodology/impact-analysis.md §2b` (LEGACY
   `.md`). Correct target: `methodology/impact-analysis-skill/SKILL.md §2b`
   (verified present, line 108). Fix = text edit to the router's canonical-copy
   declaration. Action: ROUTE (repair later), file retained.
2. **Impact coverage mirror pointer** — `security-impact/references/class-impact-coverage.md`
   cites `methodology/impact-analysis.md` in its coverage-check note; align to the
   `-skill` path in the same pass.
3. **Index residual `.md` links** — `index/methodology.md` uses the legacy `.md`
   as secondary "Legacy source" links; canonical map recommends re-pointing any
   `.md`-only references to `-skill`. Apply during an index-maintenance pass.
4. **No other link corrections identified.** The 4 new canonical skills'
   outward references (into the parallel tree) resolve correctly. The parallel
   tree has zero inward links into `-skill` — documented as intended (one-way).

---

## 10. Migration Order (dependency-aware; recommended only when executed)

All future execution must be batched and validated per batch. Recommended order:

1. **Batch 0 — no-op baseline**: confirm canonical map, audit, and this plan are
   consistent (Section 11). Stop.
2. **Batch 1 — pointer repairs (lowest risk, zero semantics)**: fix the impact
   router canonical-copy declaration (9.1), the class-impact-coverage citation
   (9.2), and index `.md` residual links (9.3). Validate: markdown-visible,
   zero body changes, canonical map still rule-first.
3. **Batch 2 — optional, deferred, NOT recommended now**: add thin pointer
   `ssti.md` / `xxe.md` references into `security-hunter/references/` pointing at
   the canonical skills. Deferred because canonical-only coverage is a valid,
   already-documented decision (audit §7 risk 4).
4. **Batch 3 — optional, deferred**: formalize triage review methodology as a
   top-level lifecycle review skill (Section 7) if the agent-bound coupling is
   ever dissolved. Not needed today; HIGHER risk, requires dedicated validation.
5. **Batch 4 — explicitly NOT scheduled**: migration of foundation/planning
   content into methodology. Rejected in Sections 5–6. Dependencies
   (target-selection → application-mapping → hypothesis-generation → hunter) make
   any move risk knowledge-loss for zero benefit.
6. **No batch ever** touches the 23 canonical skills, the 4 capability skills, or
   creates a `cve-research` owner.

Each batch is self-containing; no batch may proceed until the previous batch's
validation gate passes.

---

## 11. Validation Strategy

Per-batch gates (adapted from audit validation practice):

1. **Scope gate**: only the declared batch file set changed. Enforced via
   `find <roots> -mmin -N -type f` diff before/after.
2. **Classification gate**: after any batch, re-run the 102-file classification
   against the canonical layer; totals must not regress (14 UNIQUE / 11
   PARTIAL-OVERLAP / 1 ROUTER / 76 DERIVED / 0 DUPLICATE / 0 LEGACY / 0 GAP-FILL).
3. **Reference-integrity gate**: every modified/created file still declares its
   single owner; every canonical `-skill` remains body-identical where the map
   says so; no fantasy links (all new pointers verified to exist).
4. **No-destruction gate**: diff between snapshots shows zero deletion and zero
   semantic body change outside the batch's scope.
5. **No-interaction gate**: no target contacted, no security testing, no network
   activity, no credentials touched.
6. **Record gate**: each executed batch appends a record to this plan's status
   footer; the plan is the durable record of what was approved versus executed.

Status footer (this phase): **DESIGN ONLY — nothing executed.**
Validation for THIS phase: exactly one file created
(`index/canonical-ownership-plan.md`); all 14 UNIQUE accounted for (§5); all 11
PARTIAL-OVERLAP accounted for (§6); all 23 canonical represented (§4);
`cve-research` remains GAP (§3.4); no migration; no deletion; no file modified
outside the plan; no target interaction.

---

## 12. Explicit Non-Goals (this phase and recommended future posture)

- NO migration of foundation/planning/process knowledge into `methodology/`.
- NO creation of `methodology/research-process.md`, `methodology/triage.md`,
  `methodology/target-selection-skill`, or any new canonical skill.
- NO creation of `cve-research-skill`; `cve-research` stays a GAP.
- NO promotion of operational/tooling knowledge (tool-selection,
  vulnerability-patterns, queue-continuity, subagent isolation) to vulnerability
  methodology.
- NO duplication of methodology bodies inside hunter/recon/agent references.
- NO parallel SSTI/XXE references created for "symmetry"; canonical-only coverage
  is the chosen design.
- NO re-pointing or editing of any existing file in this phase.
- NO deletion, rename, merge, or split of any existing knowledge.
- NO security testing; NO target interaction; NO network activity.
- The 23 canonical methodology owners are confirmed as-is and remain unchanged.

---

## Appendix A. Decision Record (domain-by-domain)

| Domain | Decision | Owner(s) after decision | Future path |
|---|---|---|---|
| Foundation / research process | keep parallel; candidate owner `skills/web-security-research/SKILL.md` adopted; no methodology migration | `web-security-research/SKILL.md` + `workflow.md` | none |
| Target selection | standalone planning capability (rejected: fold-to-recon, fold-to-app-mapping, new canonical planning skill) | `target-selection.md` | none |
| Application mapping | standalone mapping/planning capability (rejected: part-of-recon, dispatcher-orchestrator) | `application-mapping.md` | none |
| Hypothesis generation | standalone capability; preserves hypothesis-gen vs vuln-methodology distinction (rejected: part-of-hunter, part-of-foundation, methodology dispatcher) | `hypothesis-generation.md` | none |
| Recon tool selection | operational reference, not methodology | recon layer (AGENT_LOCAL) | none |
| Hunter vulnerability patterns | operational reference; no methodology duplication in hunter refs | hunter layer (AGENT_LOCAL) | none |
| Security triage | hybrid; parallel single owner; not a 23-topic methodology | `security-triage/` + `agents/triage.md` | optional lifecycle-review skill (deferred) |
| Verification queue continuity / subagent isolation | orchestration doctrine, not vulnerability methodology | verification layer (AGENT_LOCAL) | none |
| 23 canonical methodologies | ownership unchanged | `methodology/*-skill/SKILL.md` | none |
| SSTI / XXE | canonical-only; positive signal; no parallel duplicates | `ssti-skill` / `xxe-skill` | optional pointer refs (deferred) |
| Impact router | keep router; correct pointer later | `impact-analysis.md` → `impact-analysis-skill §2b` (future) | Batch 1 |
| cve-research | GAP, no owner, no skill | none | UNRESOLVED |

---

*source: `index/parallel-knowledge-audit.md`, `index/methodology-canonical-map.md`,
`index/methodology.md`; companion design document — DESIGN ONLY, nothing applied.*