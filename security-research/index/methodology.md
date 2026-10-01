# Methodology Index

## Architecture

This index maps methodology topics to their canonical operational location.

### CANONICAL

`methodology/<topic>-skill/SKILL.md`

The authoritative operational methodology content.

All realized methodology topics are served from the modular `*-skill/SKILL.md`
layer. See `index/methodology-canonical-map.md` for the canonicalization decisions.

### LEGACY / SOURCE

`methodology/<topic>.md`

Historical/source material retained for provenance and comparison. Not the
canonical operational destination.

### DERIVED / REFERENCE

`skills/security-*`

Operational reference/process material. Contains routing, compact summaries, and
some additional unique knowledge (e.g. hypothesis-generation, application-mapping,
target-selection, recon procedures). Not redundant with the canonical layer.

---

## Reconnaissance

Canonical: `methodology/reconnaissance-skill/SKILL.md`

Legacy source: `methodology/reconnaissance.md`

## Authentication

Canonical: `methodology/authentication-skill/SKILL.md`

Legacy source: `methodology/authentication.md`

## Access Control

Canonical: `methodology/access-control-skill/SKILL.md`

Legacy source: `methodology/access-control.md`

## API Security

Canonical: `methodology/api-security-skill/SKILL.md`

Legacy source: `methodology/api-security.md`

## Business Logic

Canonical: `methodology/business-logic-skill/SKILL.md`

Legacy source: `methodology/business-logic.md`

## Injection

Canonical: `methodology/injection-skill/SKILL.md`

Legacy source: `methodology/injection.md`

## XSS

Canonical: `methodology/xss-skill/SKILL.md`

Legacy source: `methodology/xss.md`

## SSRF

Canonical: `methodology/ssrf-skill/SKILL.md`

Legacy source: `methodology/ssrf.md`

## File Security

Canonical: `methodology/file-security-skill/SKILL.md`

Legacy source: `methodology/file-security.md`

## Client-Side Security

Canonical: `methodology/client-side-skill/SKILL.md`

Legacy source: `methodology/client-side.md`

## Server-Side Security

Canonical: `methodology/server-side-skill/SKILL.md`

Legacy source: `methodology/server-side.md`

## OAuth / SSO

Canonical: `methodology/oauth-sso-skill/SKILL.md`

Legacy source: `methodology/oauth-sso.md`

## JWT

Canonical: `methodology/jwt-skill/SKILL.md`

Legacy source: `methodology/jwt.md`

## Race Conditions

Canonical: `methodology/race-conditions-skill/SKILL.md`

Legacy source: `methodology/race-conditions.md`

## Privilege Escalation

Canonical: `methodology/privilege-escalation-skill/SKILL.md`

Legacy source: `methodology/privilege-escalation.md`

## Impact Analysis

Canonical: `methodology/impact-analysis-skill/SKILL.md`

Legacy source: `methodology/impact-analysis.md`

## Verification

Canonical: `methodology/verification-skill/SKILL.md`

Legacy source: `methodology/verification.md`

## Reporting

Canonical: `methodology/reporting-skill/SKILL.md`

Legacy source: `methodology/reporting.md`

## Traversal

Canonical: `methodology/traversal-skill/SKILL.md`

Legacy source: `methodology/traversal.md`

## Agentic Research

Canonical: `methodology/agentic-research-skill/SKILL.md`

Legacy source: `methodology/agentic-research.md`

Discipline for executing engagements with LLM agents or autonomous harnesses:
read budgets, create-only defaults, tool-level (not prompt-level) enforcement,
overstep detection and self-disclosure, and human attribution of findings. Adds
no testing authority — the mission scope boundary is inherited unchanged.

## Deserialization

Canonical: `methodology/deserialization-skill/SKILL.md`

Legacy source: `methodology/deserialization.md`

## SSTI

Canonical: `methodology/ssti-skill/SKILL.md`

Legacy source: `methodology/ssti.md`

## XXE

Canonical: `methodology/xxe-skill/SKILL.md`

Legacy source: `methodology/xxe.md`

## CSRF

Canonical: `methodology/csrf-skill/SKILL.md`

Legacy source: `methodology/csrf.md`

## CVE Research

**GAP** — not yet implemented.

`methodology/cve-research.md` is a header-only stub and no `cve-research-skill/`
directory exists. No canonical methodology content is available for this topic.
Recorded as an explicit gap in `index/methodology-canonical-map.md`. Do not treat
this topic as implemented.