# Methodology Canonical Knowledge Map

Inspection/documentation artifact. Maps the canonical knowledge source for every
web-security-research methodology topic across the three knowledge hierarchies.

Scope of this document:

- All 23 modular methodology skills (`security-research/methodology/*-skill/`)
- Their original/source files (`security-research/methodology/*.md`)
- The parallel foundation + security skills tree (`skills/`)
- The index layer (`security-research/index/`)

Constraints honored: read-only inspection. Nothing was created, consolidated,
deleted, renamed, or rewritten outside this single map file. No security testing.

## Status Legend

| Class | Meaning |
|---|---|
| CANONICAL | Authoritative operational definition for the topic |
| DERIVED | Content condensed or summarized from another source |
| REFERENCE | Supporting / pointer / index material |
| LEGACY | Kept prior version, superseded operationally |
| STUB | Header-only skeleton, content not yet realized |
| GAP | No content exists for the topic anywhere |

## Canonical Knowledge Map

Columns:

- **Canonical Candidate** — the file that best holds authoritative content today
- **Original Source** — the source `.md` (or stub) under `methodology/`
- **Parallel Reference** — the relevant files in the `skills/` tree (or `—`)
- **Operational Agent(s)** — agents that load the modular skill (primary first)
- **Status** — classification across layers (methodology / source / parallel)

| Topic | Canonical Candidate | Original Source | Parallel Reference | Operational Agent(s) | Status | Notes |
|---|---|---|---|---|---|---|
| reconnaissance | `methodology/reconnaissance-skill/SKILL.md` | `methodology/reconnaissance.md` (real, 226 lines) | `skills/security-recon/SKILL.md` + `references/` (12); `skills/web-security-research/references/{application-mapping,target-selection}.md` (unique, 712/411) | reconnaissance (primary), orchestrator | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated: body byte-identical to source after header; retitle + provenance only. |
| access-control | `methodology/access-control-skill/SKILL.md` | `methodology/access-control.md` (real) | `skills/security-access-control/SKILL.md` + `references/` (10); `skills/web-security-research/references/access-control.md` (38) | access-control (primary), api, business-logic, impact, orchestrator, recon, triage, verification | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| api-security | `methodology/api-security-skill/SKILL.md` | `methodology/api-security.md` (real) | `skills/security-api/SKILL.md` + `references/` (10, incl. `api-authentication.md`) | api (primary), business-logic, impact, orchestrator, recon, verification | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| business-logic | `methodology/business-logic-skill/SKILL.md` | `methodology/business-logic.md` (real) | `skills/security-business-logic/SKILL.md` + `references/` (9) | business-logic (primary), access-control, api, impact, orchestrator, triage, verification | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| race-conditions | `methodology/race-conditions-skill/SKILL.md` | `methodology/race-conditions.md` (real) | `skills/security-business-logic/references/race-conditions.md` | business-logic (primary), hunter | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| privilege-escalation | `methodology/privilege-escalation-skill/SKILL.md` (109 lines) | `methodology/privilege-escalation.md` (**STUB**) | `skills/security-access-control/references/` (dispatch/coordination refs) | access-control (primary), business-logic, impact, orchestrator, verification | CANONICAL (modular) / STUB (`.md`) / REFERENCE (parallel) | **New skill.** `.md` is the identical header skeleton; full content lives in `-skill` only. Coordination layer over access-control/authentication/jwt/oauth-sso/business-logic/race-conditions. |
| client-side | `methodology/client-side-skill/SKILL.md` (121 lines) | `methodology/client-side.md` (**STUB**) | `skills/security-hunter/references/client-side.md` (22; source of derivation) | hunter (primary), orchestrator, recon, verification | CANONICAL (modular) / STUB (`.md`) / REFERENCE (parallel) | **New skill.** `.md` is identical header skeleton; content in `-skill` only. Derived from the parallel hunter reference + PortSwigger XSS/CSRF/DOM knowledge. |
| server-side | `methodology/server-side-skill/SKILL.md` (127 lines) | `methodology/server-side.md` (**STUB**) | `skills/security-hunter/references/server-side.md` (21; source of derivation) | hunter (primary), api, orchestrator, recon, verification | CANONICAL (modular) / STUB (`.md`) / REFERENCE (parallel) | **New skill.** `.md` is identical header skeleton; content in `-skill` only. Coverage coordinator over the server-side class skills. |
| injection | `methodology/injection-skill/SKILL.md` | `methodology/injection.md` (real) | `skills/security-hunter/references/injection.md` (20) | hunter (primary), impact | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| xss | `methodology/xss-skill/SKILL.md` | `methodology/xss.md` (real) | `skills/security-hunter/references/xss.md` (22) | hunter (primary), impact | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| csrf | `methodology/csrf-skill/SKILL.md` | `methodology/csrf.md` (real) | `skills/security-hunter/references/csrf.md` (17) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| ssrf | `methodology/ssrf-skill/SKILL.md` | `methodology/ssrf.md` (real) | `skills/security-hunter/references/ssrf.md` (18) | hunter (primary), impact | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| traversal | `methodology/traversal-skill/SKILL.md` | `methodology/traversal.md` (real) | `skills/security-hunter/references/traversal.md` (17) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| file-security | `methodology/file-security-skill/SKILL.md` | `methodology/file-security.md` (real) | `skills/security-hunter/references/file-security.md` (22) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| jwt | `methodology/jwt-skill/SKILL.md` | `methodology/jwt.md` (real) | `skills/security-hunter/references/jwt.md` (18) | hunter (primary), access-control, api | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| oauth-sso | `methodology/oauth-sso-skill/SKILL.md` | `methodology/oauth-sso.md` (real) | `skills/security-hunter/references/oauth-sso.md` (17) | hunter (primary), access-control, api | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| ssti | `methodology/ssti-skill/SKILL.md` | `methodology/ssti.md` (real) | **—** (no dedicated file; only mentioned inside `security-hunter/references/{server-side,injection}.md`) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / GAP (parallel) | Migrated; byte-identical body. **Coverage gap in the parallel tree** — no `ssti.md` reference exists. |
| xxe | `methodology/xxe-skill/SKILL.md` | `methodology/xxe.md` (real) | **—** (no dedicated file; only mentioned inside `security-hunter/references/server-side.md`) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / GAP (parallel) | Migrated; byte-identical body. **Coverage gap in the parallel tree** — no `xxe.md` reference exists. |
| deserialization | `methodology/deserialization-skill/SKILL.md` | `methodology/deserialization.md` (real) | `skills/security-hunter/references/deserialization.md` (16) | hunter (primary) | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. |
| authentication | `methodology/authentication-skill/SKILL.md` | `methodology/authentication.md` (real) | `skills/web-security-research/references/authentication.md` (25); `skills/security-api/references/api-authentication.md` | hunter (primary), access-control, api, business-logic, impact, orchestrator, triage, verification | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. No parallel file under `security-hunter/references/` (only `web-security-research` + `security-api`). |
| impact-analysis | `methodology/impact-analysis-skill/SKILL.md` | `methodology/impact-analysis.md` (real) | `skills/security-impact/references/impact-analysis.md` (56,**router**: declares canonical copy = `methodology/impact-analysis.md §2b`); `class-impact-coverage.md` (54) | impact (primary), orchestrator, reporting, triage, verification | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel, self-declared router) | Migrated; byte-identical body. Parallel `impact-analysis.md` explicitly routes to the **`.md` source**, not the `-skill` file. |
| verification | `methodology/verification-skill/SKILL.md` | `methodology/verification.md` (real) | `skills/security-verification/SKILL.md` + `references/` (7); `skills/web-security-research/references/verification.md` (21) | verification (primary; mandatory load), access-control, api, business-logic, hunter, impact, orchestrator, reporting, triage | CANONICAL (modular) / LEGACY (`.md`) / REFERENCE (parallel) | Migrated; byte-identical body. Most widely consumed modular skill (9 agents). |
| reporting | `methodology/reporting-skill/SKILL.md` (117 lines) | `methodology/reporting.md` (**STUB**) | `skills/security-reporting/SKILL.md` + `references/` (7); `skills/web-security-research/references/reporting.md` (57) | reporting (primary), orchestrator | CANONICAL (modular) / STUB (`.md`) / REFERENCE (parallel) | **New skill.** `.md` is identical header skeleton; content in `-skill` only. Derived from `agents/reporting.md` pipeline + triage/impact discipline. |
| agentic-research | `methodology/agentic-research-skill/SKILL.md` (195 lines) | `methodology/agentic-research.md` (139 lines, real) | `—` (no parallel file; closest is AGENTS.md "Tool Autonomy" / "Stopping Points and Autonomy (a)–(f)") | **—** (no agent loads it yet) | CANONICAL (modular) / LEGACY (`.md`) / GAP (parallel) | **New topic, added post-inspection.** Disciplinary skill for agent/harness-executed engagements: read budgets, create-only defaults, tool-level (not prompt-level) enforcement, overstep detection + self-disclosure, human attribution. Derived from an observed incident in a supervised multi-agent engagement. Adds no testing authority. See amendment below. |
| cve-research | **—** (no `cve-research-skill/` exists) | `methodology/cve-research.md` (**STUB**) | **—** (closest: `security-research/index/attack-impact-coverage.md`, `knowledge/portswigger/labs/*` version/framework notes) | **—** (no agent loads it) | **GAP** | Header-only 25-line skeleton; no content, no skill, no owner. Migration report records it as an empty template / future work. NOT created per this task's constraint. |

## 19 Migrated vs. Source Validation

For all 19 migrated topics the `-skill/SKILL.md` differs from `methodology/<topic>.md`
in exactly **line 1** (`# X Methodology` → `# X Skill`) plus a blank line and a
`> Provenance: migrated from ...` note (`+3 -1`). After removing the header
(H1 + blank + provenance), the bodies are **byte-identical** for all 19.

Conclusion: migrated skills are **semantically identical** to their sources by
content; only title and provenance differ. The `.md` files remain as `LEGACY`
source-of-truth copies; the `-skill` files are the operational `CANONICAL` set.

## The 4 New Skills vs. Stub Sources

`client-side.md`, `server-side.md`, `reporting.md`, `privilege-escalation.md` are
**byte-identical header-only skeletons** (md5 `ad956e5d244109bb5110334efdc64b9f`,
25 lines, same 12-section shell). All four full 100+ line bodies live **only in**
the `-skill` directories. See `Source / Derivation` inside each new skill for
lineage (derived from parallel `skills/` references, PortSwigger knowledge, other
modular skills, and `agents/`).

Note: `cve-research.md` shares the identical stub md5.

## Parallel Skills Tree Classification

Classification per file: `duplicate` / `complementary` / `legacy` / `index-router` /
`unique knowledge`.

| Parallel location | Classification |
|---|---|
| `skills/web-security-research/SKILL.md` (295) | Foundation core process (OBSERVE→CLASSIFY→…→REPORT). Complementary to modular layer; not a topic owner. |
| `skills/web-security-research/references/{hypothesis-generation,application-mapping,target-selection,attack-surface,workflow}.md` (58–809) | **Unique knowledge** with no modular equivalent (hypothesis pipeline, attack-surface mapping, target selection). Owned by foundation/recon. |
| `skills/web-security-research/references/{access-control,api-security,authentication,business-logic,impact-analysis,reporting,verification}.md` (21–57) | Compact topic summaries; DERIVED/REFERENCE (downsampled signals), not duplicates of modular bodies. |
| `skills/security-hunter/SKILL.md` (272) + `references/*.md` (16–23 each) | Section-based class summaries mapped by section, not file; references are short signal-style summaries. DERIVED/REFERENCE. No `ssti.md`, `xxe.md`, `authentication.md` (coverage gap vs modular). |
| `skills/security-access-control/SKILL.md` (188) + `references/` (10) | Reference/summary layer; complementary to `access-control-skill` + `privilege-escalation-skill`. |
| `skills/security-api/SKILL.md` (155) + `references/` (10) | Reference/summary layer; complementary to `api-security-skill`. |
| `skills/security-business-logic/SKILL.md` (157) + `references/` (9, incl. `race-conditions.md`) | Reference/summary layer; complementary to `business-logic-skill` + `race-conditions-skill`. |
| `skills/security-impact/references/impact-analysis.md` (56) | **index-router**: self-declared "Canonical copy: methodology/impact-analysis.md §2b". Points at the `.md` source, not the `-skill`. |
| `skills/security-impact/references/class-impact-coverage.md` (54) | Complementary matrix, mirrors `index/attack-impact-coverage.md`. |
| `skills/security-impact/references/{account,confidentiality,integrity,availability,privilege}-impact.md` (9–11) | Short derived impact prompts. |
| `skills/security-recon/SKILL.md` (287) + `references/` (12, e.g. `dns-enumeration.md`) | Complementary procedural content (e.g., DNS enumeration method) overlapping `reconnaissance-skill`; DERIVED/REFERENCE + some unique operational steps. |
| `skills/security-verification/SKILL.md` (203) + `references/` (7) | Reference layer for `verification-skill`; compact. |
| `skills/security-triage/SKILL.md` (112) + `references/` (6) | **Lifecycle-only skill** — no modular triage topic exists (triage is not in the 23-topic set). Complementary. |
| `skills/security-reporting/SKILL.md` (114) + `references/` (7) | Reference layer for `reporting-skill`; compact. Dedicated `reporting.md` (57) in foundation refs is a fuller summary. |
| `skills/security-{recon,hunter,…}/SKILL.md` cross-links (e.g., hunter handoff → security-api / security-access-control / security-business-logic / security-verification) | Complementary dispatch/router edges. |

Summary: the parallel tree is a **process + compact-summary layer**, predominantly
DERIVED/REFERENCE with a small amount of **unique knowledge**
(`hypothesis-generation`, `application-mapping`, `target-selection`, recon
procedure files). It does **not** duplicate the modular layer; it complements it.

## Link Analysis

### Layer → Layer references

| Source layer | Reference target style | Resolves? | Verdict |
|---|---|---|---|
| Agents → modular skills | `methodology/<topic>-skill/SKILL.md` | All 23 exist | Valid (verified across 10 agents) |
| `index/methodology.md` | `methodology/<topic>.md` (24 refs) | All exist | Valid BUT stale — routes to **LEGACY `.md`**, not to the canonical `-skill` dirs |
| `index/attack-impact-coverage.md` | `methodology/*.md`, `index/portswigger.md`, bare lab names (`csrf-no-defenses.md`, …), `knowledge/portswigger/labs/<lab>.md` (12 refs) | Root-relative resolve; 6 literal-missing but files exist under `knowledge/portswigger/labs/` (bare-name reference convention) | Mostly valid / conceptual |
| `index/portswigger.md` | `/api/openapi.json`, `/jwks.json`, `openapi.json` | Not file refs | Example endpoint patterns, not links |
| Modular skills (19 migrated) | Single backticked provenance ref `methodology/<topic>.md` each | Resolves root-relative | Valid |
| Modular skills (4 new) | 21–23 backticked refs each (`../`, `../../`, `../../../` style) | All resolve | Valid (correct relative-depth links) |
| Modular skills (cross-topic, conceptual) | Non-backticked `methodology/<topic>.md` mentions (e.g. `verification.md` cited by 14 skills) | Root-relative only | **CONCEPTUAL** — plain-text mentions, resolve only from `security-research/` root; they point at the `.md` source, not the `-skill`; do not resolve from the new `-skill` dir depth |
| `impact-analysis-skill/SKILL.md` | `csrf-no-defenses.md`, `xss-scanning-non-standard-data-structures.md` | Literal-missing from skill dir; files exist in `knowledge/portswigger/labs/` | Conceptual lab-name refs |
| Parallel `skills/` tree → modular | Any `*-skill` reference | **Zero** references to `-skill` dirs | One-way knowledge flow (modular → parallel is acyclic) |
| Parallel `skills/` tree | `./security-research/index/portswigger.md`, `./security-research/knowledge/` (security-hunter, foundation) | Root-relative; resolve | Valid |
| 4 new modular skills → parallel tree | `skills/security-hunter/references/*.md`, `skills/security-{access-control,reporting}/…` | All resolve | Valid (derivation back-references) |

### Findings

1. **Index staleness:** `index/methodology.md` still routes every topic to the
   LEGACY `.md` file; the canonical operational layer (`-skill`) is unreferenced by
   the index.
2. **One-way links:** parallel tree has zero references into the modular layer;
   only the 4 new modular skills reference outward to the parallel tree.
3. **Two link conventions coexist:** root-relative conceptual mentions
   (`methodology/verification.md`) vs. correct relative-depth links used by the 4
   new skills. The 19 migrated skills keep root-relative conceptual mentions that
   do not resolve from their new directory depth.
4. **Router inconsistency:** `security-impact/references/impact-analysis.md`
   declares the `.md` source canonical, not the `-skill` file.

## Canonical Ownership (per topic category)

| Category | Canonical owner | Remarks |
|---|---|---|
| 19 migrated topics | The modular `*-skill/SKILL.md` (CANONICAL); `.md` retained as LEGACY source-of-truth copy | Body-identical content |
| 4 new topics (client-side, server-side, reporting, privilege-escalation) | The modular `*-skill/SKILL.md` (CANONICAL) — the **only** realized content | `.md` is STUB |
| cve-research | **UNRESOLVED / GAP** | No content anywhere; not created |
| Holistic process (scoping, loop, evidence, minimal testing, rate limiting) | Foundation `skills/web-security-research/SKILL.md` (+ index `portswigger.md`, `attack-impact-coverage.md`) | Complementary |
| Unique operational knowledge (hypothesis pipeline, application mapping, target selection, recon procedures) | Foundation `skills/web-security-research/references/*` + `skills/security-recon/` | No modular counterpart |
| Topic dispatch index | `index/methodology.md` (needs re-pointing to `-skill`) | Currently routes to LEGACY |
| Triage (lifecycle) | Parallel `skills/security-triage/` only | No modular triage topic |

**Canonical ownership verdict:** modular `*-skill` for all 22 realized topics;
foundation + index for process and unique operational knowledge; **unresolved**
for cve-research.

## Future Consolidation (recommendations only — NOT applied)

| Action | Targets | Rationale |
|---|---|---|
| KEEP | All 23 modular `*-skill/SKILL.md` | Canonical operational layer; agents loaded |
| KEEP | Foundation `skills/web-security-research/` + unique references | Process core + unique knowledge (hypothesis, mapping, target-selection) |
| KEEP | 19 LEGACY `methodology/*.md` | Refers provenance "keep as source of truth" |
| MIGRATE (index) | Re-point `index/methodology.md` topics → `methodology/<topic>-skill/SKILL.md` (canonical), keep `.md` link as secondary | Removes index staleness, restores single navigation path |
| MIGRATE (stubs) | Decide: (a) delete STUB `.md` and route index to `-skill`, or (b) fill stubs to mirror skill | Removes stub/skill mismatch (4 topics) |
| DEMOTE TO REFERENCE | 4 STUB `.md` files (client-side, server-side, reporting, privilege-escalation) | They add no content beyond the header shell |
| DEMOTE TO REFERENCE | Compact parallel summaries that mirror modular content | Avoid future drift; mark as synopsis |
| ADD | `skills/security-hunter/references/ssti.md`, `xxe.md` (+ consider `authentication.md`), or accept modular-only | Closes parallel coverage gap |
| DEPRECATE LATER | Root-relative conceptual `methodology/*.md` mentions **inside** 19 migrated skills, if `-skill` links standardize | Currently non-resolving from new depth |
| UNRESOLVED | cve-research (author content against a defined agent/owner, or explicitly drop) | Stub only; no owner; migration report calls it future work |

## CVE Research — Explicit Gap Record

- `methodology/cve-research.md`: header-only skeleton (25 lines, identical stub md5
  `ad956e5d244109bb5110334efdc64b9f`). No `cve-research-skill/` directory exists.
- No agent loads or owns this topic; no content in `skills/` tree.
- Existing knowledge that partially supports the topic elsewhere:
  - `security-research/index/attack-impact-coverage.md` (per-class primitives +
    impact hypotheses; framework/version fingerprint entries in lab notes)
  - `security-research/knowledge/portswigger/labs/*` (version/framework disclosure
    notes, e.g. `info-disclosure-error-messages-framework-version.md`,
    `*-oracle-version.md`, `*-gadget-chain.md`)
  - `skills/security-recon/` (target/technology fingerprinting)
- Closest existing skill by theme: **`reconnaissance-skill`** (attack-surface +
  fingerprinting) with **`verification-skill`** as the evidence gate; no dedicated
  CVE-skill exists.
- Per this task's constraint, no CVE research skill or content was created.

## Validation Notes

- Only `index/methodology-canonical-map.md` was created this phase; no other file
  modified.
- No `*-skill/SKILL.md`, `methodology/*.md`, `skills/**`, or `agents/*.md` edited or
  deleted.
- All 23 skill topics present in the map + explicit `cve-research` gap row.
- Conflicts documented above: three parallel hierarchies; 19 semantically-identical
  pairs; 4 stub/skill mismatches; index staleness; ssti/xxe parallel gaps;
  one-way links; router inconsistency.
- No security testing performed; no target interaction; no network activity.

---

# Amendment — New Topic + Post-Inspection Changes

Added after this map was written. Recorded here so the map is not read as
current state. The original inspection above is left unedited; this section
supersedes it where they conflict.

## New topic: `agentic-research`

Added as a full topic with both layers, matching the 19-migrated-topic shape
(`.md` = source, `-skill/SKILL.md` = canonical operational copy):

- `methodology/agentic-research.md` (139 lines) — source
- `methodology/agentic-research-skill/SKILL.md` (195 lines) — canonical
- Registered in `index/methodology.md` under "Agentic Research"

Content is a real source/skill pair, so this topic is **not** a stub mismatch.
No agent loads it yet — it is a discipline reference, not a dispatchable
capability yet. No parallel `skills/security-*` equivalent exists (GAP); the
nearest existing content is AGENTS.md "Tool Autonomy" and "Stopping Points and
Autonomy (a)–(f)", which it cross-references.

## Superseded findings

- **Finding 1 (index staleness) is RESOLVED.** `index/methodology.md` now routes
  every realized topic to `methodology/<topic>-skill/SKILL.md` as Canonical, with
  the `.md` retained as Legacy source. It also now includes `agentic-research`.
  The remaining recommendation in `# Future Consolidation` to re-point the index
  no longer applies.
- **`traversal-skill` / `traversal.md` drift is RESOLVED.** The skill previously
  carried a step-0 "blanket file-surface probe" addition that its `.md` source
  lacked. The `.md` has been rebuilt from the canonical body, so the pair is
  consistent again. The step-0 addition is therefore now present in both layers
  rather than being skill-only — the `# Future Consolidation` note about
  deciding the stub/skill mismatch direction is unaffected (different topics).

## Content promoted to the canonical layer

Three lessons were initially written only into the LEGACY `.md` files, which the
`reporting`/`impact`/`hunter` agents do **not** load. All were propagated to the
canonical `-skill/SKILL.md` and the `.md` bodies rebuilt as faithful mirrors
(link depth normalized; bodies now byte-identical modulo H1, provenance, and
blank-run):

- `impact-analysis-skill/SKILL.md` — **Step 11**, "Calibrate the claim against
  demonstrated capability, not the label", with calibration cases A/B/C and the
  "is the victim a third party?" pre-filter. Mirrored to `impact-analysis.md`.
- `ssrf-skill/SKILL.md` — **"When a server-side fetch is NOT SSRF"**: the userinfo
  host-discrepancy as an allowlist bypass rather than SSRF, a response-handling →
  accurate-class table, and the calibration probes. Mirrored to `ssrf.md`.
- `traversal-skill/SKILL.md` — the **same-party exception** in Impact
  Considerations plus the volunteer-OSS Informable calibration entry in Lessons
  Learned. Mirrored to `traversal.md`.
- `reporting-skill/SKILL.md` — **"Report Calibration Models"** (the three
  public precedents, positive model first) and **"Disclosure Lifecycle"** (the
  180-day clock from formal *request*, 30-day follow-up, program-policy
  precedence, fix-live condition, report-confidentiality boundary).

`methodology/reporting.md` remains the documented 25-line STUB (md5
`ad956e5d244109bb5110334efdc64b9f`, restored byte-exact), consistent with this
map. All reporting knowledge lives in `reporting-skill/SKILL.md`, which was
previously the only realized location for that topic.

## Constraints observed

- No security testing, no target interaction, no network activity.
- No existing topic, skill, agent, or parallel `skills/` file was deleted.
- No target-specific secrets, credentials, program names, reporter names, or raw
  evidence were written into any methodology file (verified by grep).
- The `cve-research` GAP is unchanged and still unresolved.
