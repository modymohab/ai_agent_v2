# Parallel Knowledge Audit

Read-only audit of the parallel `skills/security-*` tree against the canonical
methodology layer (`security-research/methodology/*-skill/SKILL.md` and their
source `.md` files).

Scope: all 102 files under `skills/` (10 skill directories) classified against
the 23-topic canonical layer (`security-research/index/methodology-canonical-map.md`
is the companion canonicalization map; this document is the file-level audit).

Constraints honored: read-only inspection. Nothing was created, consolidated,
deleted, renamed, or rewritten outside this single audit file. No security
testing performed; no target interaction; no network activity.

---

## 1. Executive Summary

Every file in the parallel `skills/` tree was read and classified against the
canonical methodology layer. The parallel tree is a **process + compact-summary
layer**: it complements, not duplicates, the modular methodology skills.

- **76 / 102 files (75%) DERIVED** — compact operational synopses of canonical
  topics. Safe to keep as fast-load reference material; they do not carry a
  competing methodology.
- **14 / 102 files (14%) UNIQUE** — content with **no canonical counterpart**:
  the foundation research-process layer (`web-security-research/SKILL.md`),
  `target-selection`, `application-mapping`, `hypothesis-generation`,
  `workflow`, the entire `security-triage/` tree, recon `tool-selection`, and
  hunter `vulnerability-patterns`. These are the tree's non-redundant assets.
- **11 / 102 files (11%) PARTIAL-OVERLAP** — SKILL.md dispatcher/coordination
  layers (recon/hunter/access-control/api/business-logic/impact/reporting/
  verification) plus the two canonical derivation sources
  (`security-hunter/references/{client-side,server-side}.md`) and
  `security-impact/references/class-impact-coverage.md`.
- **1 / 102 files (1%) ROUTER** — `security-impact/references/impact-analysis.md`,
  which self-declares its canonical copy and routes operational work to it.
- **0 DUPLICATE, 0 LEGACY, 0 GAP-FILL, 0 UNRESOLVED** primary classifications.

Special-area findings (Phase 4): the four foundation process/reference files
(`target-selection`, `application-mapping`, `hypothesis-generation`,
`web-security-research/SKILL.md` + `workflow`) are confirmed **unique**; SSTI and
XXE exist as **canonical-only** topics with a deliberate **coverage gap** in the
parallel tree (no parallel methodology file, only signal mentions — no
divergence or conflict); the impact router points at the **LEGACY `.md` source**
rather than the canonical `-skill` file (a routing inconsistency to fix later).

The parallel tree does **not** undermine canonical ownership of any of the 22
realized methodology topics. `cve-research` remains the only content gap in the
entire knowledge hierarchy (canonical `GAP`, unchanged — see unresolved items).

---

## 2. Classification Table

Legend (single primary classification per file):

- **DUPLICATE** — body/copy semantically identical to a canonical file.
- **DERIVED** — compact summary or synopsis of canonical content; no new methodology.
- **UNIQUE** — content with no canonical counterpart in the methodology layer.
- **PARTIAL-OVERLAP** — overlaps canonical content but adds material of its own.
- **GAP-FILL** — supplies content the canonical layer lacks for an owned topic.
- **ROUTER** — dispatch/pointer layer; defers methodology to a canonical source.
- **LEGACY** — superseded prior version retained for provenance.
- **UNRESOLVED** — could not be classified.

Future-action allowed values: **KEEP**, **MIGRATE LATER**, **DEMOTE TO REFERENCE**,
**MERGE AFTER REVIEW**, **UNRESOLVED**.

### 2.1 `skills/web-security-research/` (13 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `web-security-research/SKILL.md` (295) | UNIQUE | none (process layer; referenced by index) | Foundation research framework: evidence categories (FACT/OBSERVATION/HYPOTHESIS/CANDIDATE/FINDING/IMPACT), scope-first, research loop, knowledge-usage priority, PortSwigger pattern engine, evidence/minimal-testing/rate-limit doctrine | KEEP |
| `references/workflow.md` (58) | UNIQUE | none | 8-phase research workflow (authz → mapping → model → hypothesis → test → verify → impact → report) with per-phase checklists | KEEP |
| `references/target-selection.md` (411) | UNIQUE | none | Target-selection process: authorization gate, candidate discovery, target classification, research-surface assessment, suitability, constraints, selection decision, failure conditions, anti-bias rules, artifact schema | KEEP |
| `references/application-mapping.md` (712) | UNIQUE | none (extends recon attack-surface at operational depth) | Full application-mapping methodology: hosts → routes → APIs → auth → roles → resources → identifiers → workflows → state → trust boundaries → sensitive functions → unknowns, with YAML artifact schemas | KEEP |
| `references/hypothesis-generation.md` (809) | UNIQUE | none | Hypothesis pipeline: good-hypothesis definition, required fields, security-property framing, hypothesis categories, quality gate, prioritization, test design, candidate creation, negatives, false positives, lifecycle, handoffs, artifact schema | KEEP |
| `references/attack-surface.md` (30) | DERIVED | reconnaissance-skill §13 | — (classification taxonomy mirrors canonical) | KEEP |
| `references/access-control.md` (38) | DERIVED | access-control-skill | — | KEEP |
| `references/api-security.md` (30) | DERIVED | api-security-skill | — | KEEP |
| `references/authentication.md` (25) | DERIVED | authentication-skill | — | KEEP |
| `references/business-logic.md` (21) | DERIVED | business-logic-skill | — | KEEP |
| `references/impact-analysis.md` (30) | DERIVED | impact-analysis-skill | — | KEEP |
| `references/reporting.md` (57) | DERIVED | reporting-skill | — (fuller structure than security-reporting refs) | KEEP |
| `references/verification.md` (21) | DERIVED | verification-skill | — | KEEP |

### 2.2 `skills/security-recon/` (13 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-recon/SKILL.md` (287) | PARTIAL-OVERLAP | reconnaissance-skill | Deeper procedural recon (philosophy, scope, passive, subdomain, DNS, HTTP probing, fingerprinting, crawling, JS, endpoint/parameter classification, API discovery, prioritization, output, handoff) with tool hints | KEEP |
| `references/api-discovery.md` (13) | DERIVED | reconnaissance-skill §12 | — | KEEP |
| `references/attack-surface-classification.md` (16) | DERIVED | reconnaissance-skill §13 | — | KEEP |
| `references/crawling.md` (14) | DERIVED | reconnaissance-skill §8 | — | KEEP |
| `references/dns-enumeration.md` (15) | DERIVED | reconnaissance-skill §5 | — (record-type list mirrors canonical) | KEEP |
| `references/endpoint-discovery.md` (16) | DERIVED | reconnaissance-skill §10 | — | KEEP |
| `references/http-probing.md` (12) | DERIVED | reconnaissance-skill §6 | — | KEEP |
| `references/javascript-recon.md` (17) | DERIVED | reconnaissance-skill §9 | — | KEEP |
| `references/parameter-discovery.md` (17) | DERIVED | reconnaissance-skill §11 | — | KEEP |
| `references/passive-recon.md` (11) | DERIVED | reconnaissance-skill §3 | — | KEEP |
| `references/subdomain-enumeration.md` (13) | DERIVED | reconnaissance-skill §4 | — | KEEP |
| `references/technology-fingerprinting.md` (13) | DERIVED | reconnaissance-skill §7 | — | KEEP |
| `references/tool-selection.md` (17) | UNIQUE | none | Minimal-authorized-toolset principle; selection factors; prefer-passive/observe-first; prohibited footprint-bypass rule | KEEP |

### 2.3 `skills/security-hunter/` (13 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-hunter/SKILL.md` (272) | PARTIAL-OVERLAP | injection/xss/csrf/ssrf/traversal/file-security/jwt/oauth-sso/deserialization/authentication class skills; client-side/server-side capability skills | Hunting loop (OBSERVE→CLASSIFY→MODEL→HYPOTHESIZE→TEST→ANALYZE→VERIFY), input-role analysis, candidates-creation rule, handoff dispatch | KEEP |
| `references/client-side.md` (22) | PARTIAL-OVERLAP | client-side-skill (derived FROM this file) | Client-side hunting signals (sources/transformations/sinks; victim-browser trust) — canonicalization source | KEEP |
| `references/server-side.md` (21) | PARTIAL-OVERLAP | server-side-skill (derived FROM this file) | Server-side hunting method (input→component→observable behavior; safety/non-destructive proof) — canonicalization source | KEEP |
| `references/vulnerability-patterns.md` (23) | UNIQUE | none | Pattern model (source/trust-boundary/processing/control/effect/impact); prioritization; "pattern is hypothesis until verified" | KEEP |
| `references/injection.md` (20) | DERIVED | injection-skill | — | KEEP |
| `references/xss.md` (22) | DERIVED | xss-skill | — | KEEP |
| `references/csrf.md` (17) | DERIVED | csrf-skill | — | KEEP |
| `references/ssrf.md` (18) | DERIVED | ssrf-skill | — | KEEP |
| `references/traversal.md` (17) | DERIVED | traversal-skill | — | KEEP |
| `references/file-security.md` (22) | DERIVED | file-security-skill | — | KEEP |
| `references/jwt.md` (18) | DERIVED | jwt-skill | — | KEEP |
| `references/oauth-sso.md` (17) | DERIVED | oauth-sso-skill | — | KEEP |
| `references/deserialization.md` (16) | DERIVED | deserialization-skill | — | KEEP |

Coverage note: no `ssti.md` / `xxe.md` / `authentication.md` reference exists in
`security-hunter/references/` (parallel `GAP`; SSTI/XXE are canonical-only, see
Section 5; authentication is covered by `web-security-research/references/authentication.md`
and `security-api/references/api-authentication.md`).

### 2.4 `skills/security-access-control/` (11 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-access-control/SKILL.md` (188) | PARTIAL-OVERLAP | access-control-skill; privilege-escalation-skill | Core model (ACTOR+RESOURCE+ACTION+EXPECTED+OBSERVED), ownership/function-auth/forced-browsing/method-differential coverage, evidence & false-positive rules, PortSwigger routing, output schema | KEEP |
| `references/authorization-modeling.md` (20) | DERIVED | access-control-skill | — | KEEP |
| `references/authorization-testing.md` (17) | DERIVED | access-control-skill | — | KEEP |
| `references/forced-browsing.md` (16) | DERIVED | access-control-skill §forced browsing | — | KEEP |
| `references/function-level-authorization.md` (16) | DERIVED | access-control-skill §8 | — | KEEP |
| `references/horizontal-escalation.md` (13) | DERIVED | access-control-skill §4 | — | KEEP |
| `references/idor-bola.md` (17) | DERIVED | access-control-skill §hereinafter IDOR/BOLA | — | KEEP |
| `references/method-confusion.md` (15) | DERIVED | access-control-skill §10 | — | KEEP |
| `references/object-ownership.md` (13) | DERIVED | access-control-skill §7 | — | KEEP |
| `references/tenant-isolation.md` (13) | DERIVED | access-control-skill §6 | — | KEEP |
| `references/vertical-escalation.md` (13) | DERIVED | access-control-skill §5 | — | KEEP |

### 2.5 `skills/security-api/` (11 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-api/SKILL.md` (155) | PARTIAL-OVERLAP | api-security-skill | API model + auth/authz/object-level/mass-assignment/data-exposure/GraphQL/workflows coverage; routing to access-control & business-logic; PortSwigger pattern library hook | KEEP |
| `references/api-authentication.md` (14) | DERIVED | api-security-skill / authentication-skill | — | KEEP |
| `references/api-enumeration.md` (15) | DERIVED | api-security-skill / reconnaissance API discovery | — | KEEP |
| `references/api-parameters.md` (16) | DERIVED | api-security-skill | — | KEEP |
| `references/api-testing.md` (14) | DERIVED | api-security-skill | — | KEEP |
| `references/api-workflows.md` (14) | DERIVED | api-security-skill §8 / business-logic-skill | — | KEEP |
| `references/excessive-data-exposure.md` (13) | DERIVED | api-security-skill §6 | — | KEEP |
| `references/graphql.md` (15) | DERIVED | api-security-skill §7 | — | KEEP |
| `references/mass-assignment.md` (13) | DERIVED | api-security-skill §5 | — | KEEP |
| `references/object-authorization.md` (10) | DERIVED | api-security-skill §4 | — | KEEP |
| `references/rest.md` (14) | DERIVED | api-security-skill | — | KEEP |

### 2.6 `skills/security-business-logic/` (10 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-business-logic/SKILL.md` (157) | PARTIAL-OVERLAP | business-logic-skill; race-conditions-skill | Workflow/invariant/bypass/state/replay/transaction/invitation/approval/race coverage; evidence rules; handoff to verification | KEEP |
| `references/business-logic-testing.md` (17) | DERIVED | business-logic-skill | — | KEEP |
| `references/invariant-analysis.md` (13) | DERIVED | business-logic-skill §2 | — | KEEP |
| `references/invitation-flows.md` (12) | DERIVED | business-logic-skill §7 | — | KEEP |
| `references/race-conditions.md` (15) | DERIVED | race-conditions-skill | — | KEEP |
| `references/replay.md` (13) | DERIVED | business-logic-skill §5 | — | KEEP |
| `references/state-machines.md` (13) | DERIVED | business-logic-skill §4 | — | KEEP |
| `references/transaction-abuse.md` (15) | DERIVED | business-logic-skill §6 | — | KEEP |
| `references/workflow-bypass.md` (13) | DERIVED | business-logic-skill §3 | — | KEEP |
| `references/workflow-modeling.md` (13) | DERIVED | business-logic-skill §1 | — | KEEP |

### 2.7 `skills/security-impact/` (8 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-impact/SKILL.md` (111) | PARTIAL-OVERLAP | impact-analysis-skill | Three-level impact model (DEMONSTRATED/SUPPORTED/POTENTIAL); confidentiality/integrity/availability/authn/authz/privilege/data-scope sections; output schema | KEEP |
| `references/impact-analysis.md` (57) | ROUTER | impact-analysis-skill (self-declared canonical copy = `methodology/impact-analysis.md §2b`) | Mandatory per-finding workflow (11 steps), impact coverage check, per-finding output list; explicitly routes to the canonical source | KEEP (fix pointer to `-skill`, see unresolved items) |
| `references/class-impact-coverage.md` (54) | PARTIAL-OVERLAP | impact-analysis-skill §2b; `index/attack-impact-coverage.md` | Class→boundary→impact-hypothesis→escalation→labs matrix (SQLi/XXE/XSS/CSRF/SSRF/traversal); adjacent classes note | KEEP |
| `references/account-impact.md` (9) | DERIVED | impact-analysis-skill §4 | — | KEEP |
| `references/availability.md` (10) | DERIVED | impact-analysis-skill §4 | — | KEEP |
| `references/confidentiality.md` (10) | DERIVED | impact-analysis-skill §4 | — | KEEP |
| `references/integrity.md` (10) | DERIVED | impact-analysis-skill §4 | — | KEEP |
| `references/privilege-impact.md` (10) | DERIVED | impact-analysis-skill §4 (§7 privilege) | — | KEEP |

### 2.8 `skills/security-reporting/` (8 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-reporting/SKILL.md` (114) | PARTIAL-OVERLAP | reporting-skill (§referenced by it); `agents/reporting.md` | Operational report structure/title/reproduction/evidence/expected-vs-actual/impact/root-cause/remediation/quality-check/knowledge-feedback | KEEP |
| `references/evidence.md` (10) | DERIVED | reporting / evidence conventions | — | KEEP |
| `references/impact.md` (10) | DERIVED | reporting / impact-analysis | — | KEEP |
| `references/quality-check.md` (9) | DERIVED | reporting / quality gates | — | KEEP |
| `references/remediation.md` (11) | DERIVED | reporting / remediation | — | KEEP |
| `references/report-structure.md` (9) | DERIVED | reporting / structure | — | KEEP |
| `references/reproduction.md` (10) | DERIVED | reporting / reproduction | — | KEEP |
| `references/title.md` (9) | DERIVED | reporting / title | — | KEEP |

### 2.9 `skills/security-triage/` (7 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-triage/SKILL.md` (112) | UNIQUE | none (triage is not in the 23-topic canonical set; complements `agents/triage.md`) | Adversarial triage: scope/validity/expected-behavior/duplicates/evidence/impact separation/status/adversarial questions/handoff | KEEP |
| `references/duplicate-analysis.md` (9) | UNIQUE | none | Duplicate root-cause/endpoint/security-property/asset/impact comparison; not class-based dedup | KEEP |
| `references/evidence-review.md` (8) | UNIQUE | none | Evidence supports asset/claim/impact/reproducibility; observation vs interpretation | KEEP |
| `references/expected-behavior.md` (7) | UNIQUE | none | Expected-behavior derivation from docs/program/auth-model/normal workflow | KEEP |
| `references/scope-review.md` (8) | UNIQUE | none | Asset-in-scope, feature, permitted method, exclusions; record scope decision source | KEEP |
| `references/triage-workflow.md` (8) | UNIQUE | none | Ordered review (scope→validity→evidence→reproducibility→impact→duplicate→readiness); keep uncertainty explicit | KEEP |
| `references/validity-review.md` (8) | UNIQUE | none | Validity = real security-property violation; baseline/changed-condition/server-side-effect/authz-context/repeatability | KEEP |

### 2.10 `skills/security-verification/` (8 files)

| Parallel Path | Classification | Canonical Counterpart | Unique Knowledge | Recommended Future Action |
|---|---|---|---|---|
| `security-verification/SKILL.md` (203) | PARTIAL-OVERLAP | verification-skill (mandatory evidence gate) | Verification claim/baseline/controlled-test/differential/reproduction/causality/false-positive/result/evidence/handoff **plus exceptional queue-continuity and subagent-failure isolation doctrine** (unique operational content) | KEEP |
| `references/baseline.md` (8) | DERIVED | verification-skill §2 | — | KEEP |
| `references/confirmation.md` (8) | DERIVED | verification-skill §5/§7 | — | KEEP |
| `references/controlled-testing.md` (9) | DERIVED | verification-skill §3 | — | KEEP |
| `references/differential-analysis.md` (9) | DERIVED | verification-skill §4 | — | KEEP |
| `references/evidence.md` (9) | DERIVED | verification-skill §9 | — | KEEP |
| `references/false-positive-analysis.md` (10) | DERIVED | verification-skill §7 | — | KEEP |
| `references/reproduction.md` (9) | DERIVED | verification-skill §5 | — | KEEP |

---

## 3. Unique Knowledge Inventory

Only knowledge with **no canonical counterpart** (source paths relative to
`skills/`, listed with topic and likely canonical home if it ever needs one).

| # | Source path | Topic | What is unique | Likely canonical destination (if moved) | Confidence |
|---|---|---|---|---|---|
| 1 | `web-security-research/SKILL.md` | Foundation research process | Evidence-category taxonomy; scope-first checklist; research loop; knowledge-usage priority chain; PortSwigger pattern-engine process; minimal-testing and rate-limit-aware doctrine | New `methodology/research-process.md` or retained as foundation layer | High |
| 2 | `web-security-research/references/target-selection.md` | Target selection | Authorization gate; candidate discovery; target classification; research-surface assessment; suitability; constraints; decision/failure conditions; anti-bias rules; artifact schema | New `methodology/target-selection.md` or extension of `reconnaissance-skill` | High |
| 3 | `web-security-research/references/application-mapping.md` | Application mapping | 19-section operational mapping (hosts→routes→APIs→auth→roles→resources→identifiers→workflows→states→trust boundaries→sensitive functions→unknowns) with YAML schemas | New `methodology/application-mapping.md` or extension of `reconnaissance-skill` | High |
| 4 | `web-security-research/references/hypothesis-generation.md` | Hypothesis generation | Hypothesis definition, required fields, security-property framing, categories, quality gate, prioritization, test design, lifecycle, handoffs, artifact schema | New `methodology/hypothesis-generation.md` (feeds hunter) | High |
| 5 | `web-security-research/references/workflow.md` | Phase-gate research workflow | 8-phase workflow with per-phase checklists and evidence requirements | New `methodology/research-process.md` (with item 1) | Medium |
| 6 | `security-triage/SKILL.md` + `references/*` (7 files) | Triage | Adversarial triage methodology (scope, validity, expected behavior, duplicates, evidence review, statuses, adversarial questions) — no modular triage topic exists | New `methodology/triage.md` (or formalize as parallel-owned complement to `agents/triage.md`) | High |
| 7 | `security-recon/references/tool-selection.md` | Tool election | Minimal-authorized-toolset principle; selection factors; passive-before-active preference; prohibition on footprint/safeguard bypass | Merge into `reconnaissance-skill` | Medium |
| 8 | `security-hunter/references/vulnerability-patterns.md` | Pattern recognition model | Source/trust-boundary/processing/control/effect/impact; hypothesis-before-verification rule | Merge into `injection-skill`/hunter capability | Medium |
| 9 | `security-verification/SKILL.md` (queue-continuity sections) | Orchestration resilience | Candidate-queue continuity, subagent failure isolation, queue-state model — operational doctrine absent from canonical verification | Orchestrator/verification agent doctrine (nowhere else) | High |
| 10 | `security-hunter/references/client-side.md` | Client-side hunting signals | Source/transformation/sink hunting signals that drove `client-side-skill` derivation | Already captured in `client-side-skill` (keep as the hunting-layer signal ref) | High (resolved) |
| 11 | `security-hunter/references/server-side.md` | Server-side hunting signals | Input→component→observable-behavior mapping + safety rules that drove `server-side-skill` derivation | Already captured in `server-side-skill` (keep as the hunting-layer signal ref) | High (resolved) |

---

## 4. Overlap Analysis

Depth of overlap against the canonical layer per parallel area:

- **No duplicate files.** Zero parallel files are byte- or semantic duplicates of
  canonical methodology. The only body-identical pairs in the repository are the
  19 `methodology/*.md` ↔ `*-skill/SKILL.md` pairs (documented in
  `methodology-canonical-map.md`), which are outside this parallel tree.
- **Substantial (thematic) overlap with canonical:** the 8 class-level hunter
  references (injection/xss/csrf/ssrf/traversal/file-security/jwt/oauth-sso/
  deserialization) and 9 business-logic + 10 access-control + 10 api references.
  These mirror canonical sections at 8–20× lower depth; no divergent methodology.
- **Partial overlap (SKILL dispatchers):** recon (287) vs `reconnaissance-skill`
  (84); hunter (272) vs 10+ class skills; access-control (188) vs
  `access-control-skill` (126); api (155) vs `api-security-skill` (91);
  business-logic (157) vs `business-logic-skill` (123); impact (111) vs
  `impact-analysis-skill` (225); reporting (114) vs `reporting-skill` (117);
  verification (203) vs `verification-skill` (81). Each adds coordination,
  routing, and some procedural detail on top of canonical content.
- **Minimal overlap / unique:** foundation SKILL.md, workflow, target-selection,
  application-mapping, hypothesis-generation, triage tree, tool-selection,
  vulnerability-patterns, verification queue-continuity doctrine.
- **Structural relation:** the parallel tree carries **zero links into the
  modular `-skill` layer** (one-way flow). Only the 4 new canonical skills
  (`client-side`, `server-side`, `privilege-escalation`, `reporting`) reference
  outward into the parallel tree (as derivation sources).

---

## 5. Special Areas (Phase 4 findings)

### A. Target Selection — `skills/web-security-research/references/target-selection.md` (411 lines)
- Parallel presence: full, 411-line operational procedure with artifact schema.
- Canonical presence: **none**. `reconnaissance-skill` covers scope and
  attack-surface composition but has no target-selection module. `index/methodology.md`
  explicitly lists `target-selection` as additional unique knowledge in the
  `skills/` tree ("not redundant with the canonical layer").
- Verdict: **UNIQUE; no duplication; keep.** No canonical change required.

### B. Application Mapping — `skills/web-security-research/references/application-mapping.md` (712 lines)
- Parallel presence: full, 19-section application-mapping methodology.
- Canonical presence: **none at this depth**. Canonical attack-surface
  classification is a summary; operational host/route/API/role/resource/state/
  trust-boundary mapping with YAML artifacts exists only here. Listed as unique
  in `index/methodology.md`.
- Verdict: **UNIQUE; no duplication; keep.** No canonical change required.

### C. Hypothesis Generation — `skills/web-security-research/references/hypothesis-generation.md` (809 lines)
- Parallel presence: full hypothesis pipeline (809 lines).
- Canonical presence: **none**. No hypothesis-generation module exists in
  `methodology/`; hunter and class skills produce candidates informally.
  Listed as unique in `index/methodology.md`.
- Verdict: **UNIQUE; no duplication; keep.** No canonical change required.

### D. SSTI — canonical `methodology/ssti-skill/SKILL.md` (107 lines) vs parallel tree
- Parallel presence: **no dedicated `ssti.md`**. SSTI appears only as signal
  mentions: `security-hunter/references/server-side.md` (lists "server-side
  template injection" as a class) and `injection.md` (lists "template injection"
  as a context); impact references mention SSTI in coverage lists without content.
- Canonical posture: `ssti-skill` is authoritative and complete (5 lab-validated
  shapes, engines, testing methodology). Canonical map records parallel status as
  **GAP**.
- Verdict: **no divergence, no conflict.** Parallel layer does not duplicate or
  contradict canonical SSTI; the absence of a parallel `ssti.md` is an accepted
  coverage choice (canonical-only topic). Optionally add a pointer reference later.

### E. XXE — canonical `methodology/xxe-skill/SKILL.md` (131 lines) vs parallel tree
- Parallel presence: **no dedicated `xxe.md`**. XXE appears as a mention in
  `security-hunter/references/server-side.md` and as a mirroring impact-matrix row in
  `security-impact/references/class-impact-coverage.md` (boundary/impact-hypothesis/
  escalation/labs — consistent with canonical §2b).
- Canonical posture: `xxe-skill` authoritative (9 lab-validated shapes,
  detection/exfil/DTA chains). Canonical map records parallel status as **GAP**.
- Verdict: **no divergence, no conflict.** The parallel class-impact row is a
  DERIVED mirror of the canonical matrix, not a competing methodology.

### F. Impact Router — `skills/security-impact/references/impact-analysis.md` (57 lines)
- Self-declared: "Canonical process: `security-research/methodology/impact-analysis.md` (read it fully)" and "Canonical copy: methodology/impact-analysis.md §2b".
- Contains: mandatory 11-step per-finding workflow, impact coverage check,
  per-finding output list, and class-impact matrix pointer.
- Issue: it routes to the **LEGACY `.md` source**, not to the canonical
  `impact-analysis-skill/SKILL.md` (where §2b also lives). This is the same
  inconsistency flagged in `methodology-canonical-map.md` ("Router inconsistency").
  The workflow content otherwise matches the canonical skill's steps.
- Verdict: **ROUTER** (self-declared, content mirrors canonical). Keep the file;
  re-point the canonical-copy declaration to `methodology/impact-analysis-skill/SKILL.md §2b`
  during a future index/maintenance pass. No migration needed now.

---

## 6. Canonical Ownership Recommendations

Per-topic owner (all consistent with `methodology-canonical-map.md`):

| Topic / content | Canonical owner | Parallel counterpart kept as | Recommendation |
|---|---|---|---|
| 19 migrated topics | `methodology/<topic>-skill/SKILL.md` | DERIVED reference/summary files | KEEP both layers; no DRIFT remediation required today |
| 4 new topics (client-side, server-side, reporting, privilege-escalation) | `-skill/SKILL.md` (only realized content; `.md` is STUB) | hunter client-side/server-side refs are derivation sources; reporting/triage files are operational refs | KEEP; the 4 canonical skills remain the authoritative capability layers |
| Foundation process (loop, scope, evidence, minimal testing, rate limits) | `skills/web-security-research/SKILL.md` | n/a | KEEP as the process owner; defer canonicalization (see Section 8) |
| Target selection / application mapping / hypothesis generation / workflow | parallel foundation (no canonical module) | n/a | KEEP; treat as canonical candidates for a future methodology module (MIGRATE LATER) |
| Triage | parallel `security-triage/` + `agents/triage.md` | n/a | KEEP; triage stays parallel-owned (no modular triage topic), optionally formalize as `methodology/triage.md` later |
| SSTI | `methodology/ssti-skill/SKILL.md` | none (GAP) | Canonical-only; no parallel file to add unless a pointer reference is desired |
| XXE | `methodology/xxe-skill/SKILL.md` | impact class-impact-coverage row (DERIVED mirror) | Canonical-only; mirror row already consistent |
| Impact routing | `methodology/impact-analysis-skill/SKILL.md` (contains §2b) | `security-impact/references/impact-analysis.md` (ROUTER) | KEEP router; fix its canonical-copy pointer to the `-skill` |
| Verification | `methodology/verification-skill/SKILL.md` | `security-verification/SKILL.md` + refs | KEEP; PARALLEL OWNER of queue-continuity/subagent-isolation doctrine (unique) |
| CVE research | **GAP** (no content anywhere) | none | UNRESOLVED (unchanged from canonical map) |

---

## 7. Risks

1. **Drift risk in DERIVED summaries.** 76 compact summaries mirror canonical
   topics at low depth; if canonical methodology changes, summaries may silently
   diverge. Mitigation: treat `skills/*/references` as synopses, not authorities;
   acknowledge canonical `-skill` as the only source of truth for topic bodies.
2. **One-way link convention.** The parallel tree has zero references into the
   `-skill` layer; only 4 new canonical skills reference outward. This is acyclic
   and safe today, but any future parallel-side edit can orphan coordination.
3. **Router points at LEGACY `.md`.** `security-impact/references/impact-analysis.md`
   declares the `.md` source canonical, not `impact-analysis-skill`. An operator
   following the router could load the LEGACY file instead of the canonical skill.
4. **SSTI/XXE parallel gap.** No `ssti.md`/`xxe.md` in the parallel tree. Agents
   that load only the skills tree get no dedicated SSTI/XXE reference (only signal
   mentions). Accepted design choice, but bodies that might expect a parallel file
   will find none — flag as intended.
5. **Unique foundation knowledge is parallel-only.** `target-selection`,
   `application-mapping`, `hypothesis-generation`, `workflow`, foundation SKILL,
   triage, queue-continuity doctrine have no canonical mirror. If the `skills/`
   tree were ever demoted on the assumption it is pure reference material, this
   unique knowledge would be lost. Mitigation: document the unique inventory
   (Section 3) so it is preserved.
6. **Index still routes to LEGACY `.md`.** `index/methodology.md` lists topics with
   "Legacy source: methodology/<topic>.md" as the secondary link and the `-skill` as
   canonical — no functional break, but the canonical map recommends re-pointing
   any residual `.md`-only references to `-skill`.

---

## 8. Recommended Consolidation Order

Recommendations only — **none applied** in this audit (read-only phase).

1. **Fix the impact router pointer** (smallest change): update
   `skills/security-impact/references/impact-analysis.md` to declare the canonical
   copy as `methodology/impact-analysis-skill/SKILL.md §2b` (the `.md` has the same
   §2b, but the skill is the operational destination).
2. **Decide SSTI/XXE pointer references**: either accept canonical-only coverage
   (record in map, done) or add thin pointer `ssti.md`/`xxe.md` to
   `security-hunter/references/` pointing at the class skills.
3. **Promote unique foundation process knowledge** (MIGRATE LATER, do not do this
   phase): evaluate `target-selection`, `application-mapping`,
   `hypothesis-generation`, and the foundation SKILL/workflow as candidates for a
   `methodology/research-process.md` module or `reconnaissance-skill` extensions;
   beneath that, always resolve to canonical.
4. **Formalize triage** (MIGRATE LATER): consider a `methodology/triage.md` topic
   or keep triage parallel-owned + documented via `agents/triage.md`. Until then,
   KEEP the parallel triage tree.
5. **Re-point `index/methodology.md` residual `.md` links** to the `-skill` layer
   per the canonical map's recommendation, in a future index-maintenance pass.
6. **Re-run this audit** after any canonical methodology change or after the
   parallel-tree demotion discussion (see risks) to refresh Section 3's unique
   inventory.

---

## 9. Unresolved Items

| # | Item | Status | Note |
|---|---|---|---|
| 1 | `cve-research` topic | UNRESOLVED (canonical GAP) | Header-only 25-line stub; no skill/agent owner; no content in `skills/` tree. Unchanged this phase (out of scope to create). |
| 2 | Pointer target inside `security-impact/references/impact-analysis.md` | UNRESOLVED (needs next-phase edit) | Declares LEGACY `.md` canonical instead of `impact-analysis-skill`. Fix deferred to a maintenance pass. |
| 3 | Whether parallel SSTI/XXE should gain pointer references | UNRESOLVED (policy decision) | Canonical-only is valid; document decision explicitly to prevent future "missing file" noise. |
| 4 | Whether unique foundation process files migrate into `methodology/` | UNRESOLVED (deferred) | Recommended MIGRATE LATER; no migration in audit phase. |
| 5 | Whether triage gains a canonical methodology topic | UNRESOLVED (deferred) | Keep parallel-owned; formalizing later is optional. |
| 6 | Drift monitoring for the 76 DERIVED summaries | UNRESOLVED (process) | No automated sync mechanism exists; relies on canonical-first discipline. |

---

## Validation Notes

- Only this file (`index/parallel-knowledge-audit.md`) was created this phase; no
  other file modified, moved, or deleted.
- Protected areas untouched: `security-research/methodology/**`, `skills/**`,
  `agents/**`, `index/methodology.md`, `index/methodology-canonical-map.md`,
  `security-research/README.md`.
- Files analyzed: **102** (all parallel `skills/` files).
- Classification totals: 76 DERIVED, 14 UNIQUE, 11 PARTIAL-OVERLAP, 1 ROUTER,
  0 DUPLICATE, 0 LEGACY, 0 GAP-FILL, 0 UNRESOLVED.
- Special areas A–F resolved with no conflicts found (A/B/C unique; D/E canonical-
  only with accepted gap; F router with a pointer to fix later).
- No migration performed; no consolidation performed; no security testing
  performed; no target interaction; no network activity.