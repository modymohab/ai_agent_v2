# Methodology → Skills Migration Report

Date: 2026-09-20
Scope: `~/.config/opencode/security-research/methodology/` (24 files) → modular `*-skill/SKILL.md`

> **Superseded in part — read with `verify-architecture.sh`.** The counts below are a
> point-in-time record of the 2026-09-20 migration and are correct *as of that date*.
> Subsequent work changed the totals: a new `agentic-research` topic was added after
> this report was written, and the reporting topic's canonical content moved into
> `reporting-skill/SKILL.md` while its `.md` was deliberately restored to an
> unimplemented stub. The authoritative current figures — produced by
> `./methodology/verify-architecture.sh`, which self-tests its comparator before
> reporting — are: **24** skill directories, of which **4** are stub-backed
> (their `.md` is an intentionally unimplemented 25-line placeholder), leaving
> **20** topics with real `.md` mirrors, and **5** `.md` stubs at checksum
> `ad956e5d244109bb5110334efdc64b9f`. `cve-research` has no skill directory and
> remains a documented gap. Do not read "19/19" below as the current state, and do
> not hand-edit the counts in this file — regenerate with
> `./methodology/verify-architecture.sh` and `./methodology/rebuild-mirrors.sh`.
Task classifier: local documentation migration. No source files modified, no agents/skills touched.

## Migration decisions

1. Every methodology file that represents a reusable security-research capability becomes a sibling directory `methodology/<name>-skill/SKILL.md`.
2. Content is preserved **byte-for-byte** (original section structure retained). The only additions are the rewritten H1 (`# <Name> Skill`) and a one-line provenance note. Original files are the source of truth and remain untouched.
3. Files that are empty 25-line template shells are **intentionally kept as reference** (no content to migrate; converting them would invent content, which is prohibited).
4. The existing `~/.config/opencode/skills/security-*/` modular skills and `web-security-research/SKILL.md` were examined for context but NOT modified.

## Completeness check (source vs output)

### Migrated (19/19 verified byte-level OK)

```
SOURCE: methodology/access-control.md
OUTPUT: methodology/access-control-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/api-security.md
OUTPUT: methodology/api-security-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/authentication.md
OUTPUT: methodology/authentication-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/business-logic.md
OUTPUT: methodology/business-logic-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/csrf.md
OUTPUT: methodology/csrf-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/deserialization.md
OUTPUT: methodology/deserialization-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/file-security.md
OUTPUT: methodology/file-security-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/impact-analysis.md
OUTPUT: methodology/impact-analysis-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/injection.md
OUTPUT: methodology/injection-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/jwt.md
OUTPUT: methodology/jwt-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/oauth-sso.md
OUTPUT: methodology/oauth-sso-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/race-conditions.md
OUTPUT: methodology/race-conditions-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/reconnaissance.md
OUTPUT: methodology/reconnaissance-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/ssrf.md
OUTPUT: methodology/ssrf-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/ssti.md
OUTPUT: methodology/ssti-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/traversal.md
OUTPUT: methodology/traversal-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/verification.md
OUTPUT: methodology/verification-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/xss.md
OUTPUT: methodology/xss-skill/SKILL.md
STATUS: migrated

SOURCE: methodology/xxe.md
OUTPUT: methodology/xxe-skill/SKILL.md
STATUS: migrated
```

Verification method: for each file, the source body (all lines after the H1) is required to appear verbatim inside the output; every non-empty source line matched. `FAILURES: 0`.

### Intentionally kept as reference (5 empty template shells, 277 bytes / 25 lines each)

```
SOURCE: methodology/client-side.md
OUTPUT: (none)
STATUS: intentionally kept as reference (empty template, no content to migrate)

SOURCE: methodology/cve-research.md
OUTPUT: (none)
STATUS: intentionally kept as reference (empty template, no content to migrate)

SOURCE: methodology/privilege-escalation.md
OUTPUT: (none)
STATUS: intentionally kept as reference (empty template, no content to migrate)

SOURCE: methodology/reporting.md
OUTPUT: (none)
STATUS: intentionally kept as reference (empty template, no content to migrate)

SOURCE: methodology/server-side.md
OUTPUT: (none)
STATUS: intentionally kept as reference (empty template, no content to migrate)
```

## Architecture report

### A. Files inspected

All 24 files in `methodology/`:

| File | Lines | Disposition |
|---|---|---|
| access-control.md | 126 | migrated |
| api-security.md | 91 | migrated |
| authentication.md | 110 | migrated |
| business-logic.md | 123 | migrated |
| csrf.md | 65 | migrated |
| deserialization.md | 114 | migrated |
| file-security.md | 86 | migrated |
| impact-analysis.md | 225 | migrated |
| injection.md | 280 | migrated |
| jwt.md | 90 | migrated |
| oauth-sso.md | 68 | migrated |
| race-conditions.md | 81 | migrated |
| reconnaissance.md | 84 | migrated |
| ssrf.md | 83 | migrated |
| ssti.md | 105 | migrated |
| traversal.md | 76 | migrated |
| verification.md | 81 | migrated |
| xss.md | 69 | migrated |
| xxe.md | 129 | migrated |
| client-side.md | 25 | kept as reference (empty) |
| cve-research.md | 25 | kept as reference (empty) |
| privilege-escalation.md | 25 | kept as reference (empty) |
| reporting.md | 25 | kept as reference (empty) |
| server-side.md | 25 | kept as reference (empty) |

Also inspected for context (NOT modified): `~/.config/opencode/skills/` (12 skill dirs incl. 9 `security-*` + `web-security-research`), their `references/` dirs, `index/` (methodology.md, portswigger.md, attack-impact-coverage.md, real-world.md).

### B. Skills created

19 directories under `methodology/`: `access-control-skill/ … xxe-skill/`, each with `SKILL.md` (byte-verbatim copy of source body + provenance note + retitled H1).

### C. Files kept as references

5 empty template shells: `client-side.md`, `cve-research.md`, `privilege-escalation.md`, `reporting.md`, `server-side.md`. These share a 12-section skeleton but have zero content; converting them would require inventing knowledge. They remain as explicit to-dos for a future content-writing phase.

### D. Duplicated knowledge discovered

The 19 migrated methodology files overlap three existing locations:

1. **`skills/web-security-research/references/`** already contains condensed refs with the same names: `access-control.md`, `api-security.md`, `authentication.md`, `business-logic.md`, `impact-analysis.md`, `verification.md` (plus `reporting.md`). Realization: the methodology files are the RICH counterparts of these refs (e.g. access-control 126 vs 38 lines; impact-analysis 225 vs 30; authentication 110 vs 25). The `web-security-research/SKILL.md` references correspond to topics that now have full `*-skill` dirs.
2. **`skills/security-hunter/references/`** holds class-level refs (`csrf.md`, `deserialization.md`, `file-security.md`, `injection.md`, `jwt.md`, `oauth-sso.md`, `ssrf.md`, `traversal.md`, `xss.md`, `client-side.md`, `server-side.md`) — the same class families now duplicated.
3. **`skills/security-*/references/`** for recon/impact/verification/access-control/api/business-logic map topically to the corresponding new `*-skill/` dirs.

Observation: the same canonical knowledge now exists in up to three forms (methodology source → `*-skill/SKILL.md` → existing `references/*.md`). No consolidation was performed in this pass (out of scope); the duplication is flagged for a later phase.

Notable coverage gaps in existing refs vs migrated methodology: `ssti.md`, `xxe.md`, `race-conditions.md`, `deserialization.md` have NO dedicated `security-hunter` reference file; only `*-skill` carries that content now.

### E. Conflicting instructions discovered

No hard contradictions found between the migrated files. Minor stylistic/topical tensions to reconcile later:

- `methodology/injection.md` and `methodology/xss.md` both discuss "string-opened eval" families (server-side `eval`/template vs browser sinks) — overlapping language without alignment.
- `methodology/business-logic.md` and `methodology/race-conditions.md` both cover coupon/promotion economics (per-entry vs once-per-order) — divergent anti-pattern taxonomies.
- `methodology/deserialization.md` references old PHP lab conventions while the knowledge base (`knowledge/portswigger/labs/deserialization-object-state.md`) is Python-side; naming/terminology drift.
- Empty `client-side.md` / `server-side.md` imply a client-side/server-side split that existing hunter refs already use, but no shared definition anchors it.
- `security-impact/references/impact-analysis.md` and `methodology/impact-analysis.md` use different severity frameworks (evidence-based consequence classes vs the methodology's "highest severity with proof" rule) — consistent in spirit, inconsistent in headings.

### F. Skills too broad to split later

- `injection-skill` (280 src lines): mixes SQLi, command injection, template/eval families, and non-ORM contexts. Split candidate: SQL vs command vs template-based injection.
- `impact-analysis-skill` (225 src lines): mixes scoring, evidence translation, and reporting-tagging duties. Split candidate: severity scoring vs consequence documentation.
- `access-control-skill` (126 src lines): mixes vertical/horizontal IDOR, method-based bypass, URL-desync, Referer-gate, and header-trust primitives. Splittable into method-based bypass and object-idor families.
- `authentication-skill` (110 src lines): mixes enumeration/brute-force, 2FA logic, password-reset, and crypto-oracle primitives. Splittable into auth-flow-logic vs credential-guessing vs token-crypto.

### G. Skills that should later reference other skills

These capabilities share methods and should cross-link in a future phase:

- `verification-skill` ← referenced by nearly every `*-skill` (differential single-variable testing, state oracles) — make it the shared dependency.
- `access-control-skill` ↔ `authentication-skill` (session/cookie vs identity handling).
- `business-logic-skill` ↔ `race-conditions-skill` (promotion money-check, once-per-order).
- `ssrf-skill` ↔ `api-security-skill` (server-side fetch/stock APIs) and `verification-skill` (external OOB proofs).
- `reconnaissance-skill` → every `*-skill` (surface index assignment, attack-surface handoff).
- `xss-skill` ↔ `csrf-skill` (page-token readability, browser-side sinks).
- `xxe-skill` ↔ `ssrf-skill` (external entity fetch channel) ↔ `verification-skill` (blind OOB).
- `ssti-skill` ↔ `injection-skill` (server-side string-opened eval) ↔ `deserialization-skill` (gadgets execute attacker strings).
- `file-security-skill` ↔ `traversal-skill` (upload vs read, path-join sanitization) and `xxe-skill` (polyglot/upload DOM).
- `impact-analysis-skill` → `reporting` (reporting.md is an empty template; needs content before linking).
- `oauth-sso-skill` ↔ `access-control-skill` (email-keyed IDOR) and `authentication-skill` (verified-claim vs ownership).

### H. Recommended next migration phase

Phase 2 (proposed, NOT executed here):

1. **Fill content for the 5 empty templates** (`client-side`, `cve-research`, `privilege-escalation`, `reporting`, `server-side`) then migrate them to `*-skill/` like the other 19 — completing 24/24 coverage.
2. **Consolidation**: decide the canonical home for each topic — merge `*-skill/SKILL.md` against `skills/web-security-research/references/*.md` and `skills/security-hunter/references/*.md` so one canonical source exists per capability (favor the full `*-skill` bodies as canonical, refs as indexes).
3. **Cross-reference injection**: add explicit "see also" links (section G) and make `verification-skill` the shared dependency.
4. **Split review**: evaluate splitting candidates in section F (injection, impact-analysis, access-control, authentication) with each split preserving byte-level content.
5. **Hooks**: decide whether the orchestration skill should load `*-skill` files via opencode skill conventions (requires opencode.json permission wiring) — coordination with `skills/web-security-research/SKILL.md` loading rule.