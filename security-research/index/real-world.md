# Real-World Research Index

This index maps real-world research (public writeups, disclosed CVEs, bug-bounty
reports) to the vulnerability classes and generalized methodology in this
repository. Unlike the PortSwigger lab notes (controlled, single-variable
teaching environments), real-world entries carry messier signal: multiple
candidate causes, partial disclosure, program-specific context. Treat every
entry here as a **hypothesis source**, exactly like a lab note — never as proof
for a current target — per the "knowledge is not proof" rule in
`methodology/impact-analysis-skill/SKILL.md`.

> **Status: scaffold populated, entries pending.** This file previously shipped
> as headers only with zero content. It now defines the required structure and
> intake rules. **Nothing below the intake rules constitutes research
> knowledge yet — see the explicit distinction in the next section.**

## Two different things this file can hold — do not conflate them

1. **Actual entries** (`## Writeups`, `## Case Studies`, `## Lessons Learned`):
   real, reviewed, public sources with an extracted generalized pattern. These
   ARE citable as a hypothesis source, the same way a PortSwigger lab note is.
2. **The intake queue** (`Candidate sources to review first` under `## Writeups`,
   and the per-class "no entries yet" notes under `## Vulnerability Classes`):
   this is a **to-do list of where to look**, not knowledge that was found. A
   queue entry has not been reviewed, has no extracted pattern, and must never
   be cited or treated as if it were an actual entry. If this file is ever
   read as a source during hypothesis generation, only category (1) counts.

## How an entry gets added here

1. The source must be public (published writeup, CVE record, disclosed bounty
   report) — never a private/active engagement's findings (those stay in the
   mission's own `report/` artifact, per `mission-artifact-schema.md`).
2. Extract the GENERALIZABLE pattern only — no target-identifying details,
   no secrets, no working exploit code for still-unpatched issues.
3. File it under the matching class skill's real-world-pattern list (or
   `## Vulnerability Classes` below if no class skill exists yet), with a link
   back to the source and a one-line note on what's NEW versus what the class
   skill's lab-derived methodology already covers.
4. Once added, an entry moves from "queue" to "actual entry" status — update
   both the entry itself and remove it from any "candidate sources" list it
   was previously named in, so the same source isn't listed twice under two
   different trust levels.
5. If the pattern reveals a gap in an existing class skill, flag it for that
   skill's maintainer instead of duplicating full methodology here — this
   index points, it does not replace `methodology/*-skill/SKILL.md`.

## Writeups

*(format: `- [Title](source-url) — class — one-line generalized pattern — what it adds beyond existing lab-derived methodology)`*

- No actual entries yet.

**Intake queue (not knowledge — see distinction above):** classes with thin
lab coverage per `methodology.md`'s canonical map are the suggested starting
point for review — particularly XSS, CSRF, and NoSQL injection (see
`index/attack-impact-coverage.md` "Genuine Gaps"). This is a suggestion for
where to look next, not a claim that anything has been found there.

## Case Studies

*(format: multi-finding chains or program-wide patterns that don't fit a
single class-skill row)*

- No actual entries yet.

## Vulnerability Classes

*(use this section only for classes with NO existing `methodology/*-skill/SKILL.md`
— currently NoSQL injection, request smuggling, clickjacking — until a
dedicated class skill is created; once a class skill exists, move real-world
patterns into that skill's own "Lessons Learned" instead and remove the
section here)*

### NoSQL Injection (no dedicated class skill yet)
- Pattern class: JSON query-operator injection (`$where`, `$ne`, `$gt` and
  similar Mongo-style operators) supplied via a field the application expects
  to hold a literal value.
- Status: **queue item, not an entry.** No lab-derived or real-world-derived
  methodology exists in this repository yet.

### HTTP Request Smuggling (no dedicated class skill yet)
- Status: **queue item, not an entry.** Documented as an explicit coverage
  boundary in `methodology/server-side-skill/SKILL.md`.

### Clickjacking / UI Redress (no dedicated class skill yet)
- Status: **queue item, not an entry.** Documented as an explicit coverage
  boundary in `methodology/client-side-skill/SKILL.md`.

## Lessons Learned

*(cross-cutting process/tooling/triage lessons that don't belong to one
vulnerability-class row)*

- No actual entries yet.

## Maintenance Rule

This file must not silently regress to headers-only. If a review pass finds no
new real-world material to add, leave the existing entries and this note
intact rather than truncating the file back to a stub. When adding an entry,
always update it to category (1) status per the distinction above — never
let a queue item accumulate detail that starts to read like a reviewed entry
without actually being promoted.
