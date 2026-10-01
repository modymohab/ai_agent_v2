# Security Research System

## Purpose

This directory is the persistent research workspace for the web security
multi-agent system.

The system performs authorized web security research, CTF/lab research,
methodology development, verification, triage, impact analysis, and reporting.

All real-world testing must remain within explicitly authorized scope and
program rules.

---

# Canonical Knowledge Hierarchy

Use the following sources in this order:

1. Current mission scope and rules
2. Observed evidence from the current mission
3. `methodology/`
4. `knowledge/`
5. `index/`
6. `tooling/`
7. `wordlists/`

The current mission and observed evidence always override generic knowledge.

Never treat historical knowledge as evidence for the current target.

---

# Tool Autonomy

> Added after observed operational friction: agents were stopping mid-task and
> waiting for the human operator to invoke tools manually, defeating the
> purpose of an agentic research workflow. This section states the intended
> autonomy model explicitly. **Note: this section governs agent BEHAVIOR
> (what an agent should attempt once it has a tool available). It does NOT
> and CANNOT grant actual tool-invocation permission — that is enforced by
> the runtime (Claude Code settings, an Agent SDK `canUseTool` callback, or
> equivalent), which must be separately configured to match this policy. If
> agents are still stopping for manual tool approval after this section is
> in place, the fix is in that runtime configuration, not in this file.**

Within authorized scope and the constraints already recorded for the current
mission, agents should:

- Invoke read-only, information-gathering tools (recon/discovery/inspection —
  see `tooling/tools.md`) proactively and without pausing to ask permission
  for each individual call. Recon is non-destructive by design; asking
  per-request approval for `httpx`, `katana`, subdomain enumeration, or a
  Burp MCP inspection/replay call defeats the purpose of delegating recon to
  an agent at all.
- Chain a sequence of read-only tool calls needed to answer one research
  question (e.g. subdomain enum → `httpx` liveness check → `katana` crawl)
  as a single uninterrupted workflow, reporting the consolidated result
  rather than stopping after each step.
- Continue to a natural stopping point (a completed recon pass, a fully
  investigated hypothesis, a verified/rejected candidate) before summarizing
  and handing off — not stop at the first tool call "just in case."

Agents should still pause and request explicit human confirmation before:

- Any action that changes target state (submitting a form that mutates data,
  a destructive test, anything the mission's `constraints` record as
  requiring approval — see `planning/target-selection/SKILL.md` §4 Step 6).
- Expanding scope beyond what `mission.yaml`/`scope.md` currently authorizes.
- Any action explicitly flagged `prohibited_actions` for the current mission.
- Using a tool for the first time in a mission where its output could be
  irreversible or rate-limit-sensitive at scale (e.g. a large `ffuf` fuzz
  run) — confirm the scope/volume once, then proceed autonomously within it.

This mirrors the existing Evidence Integrity and Agent Separation rules below:
agents are trusted to operate within their lane autonomously, and the
human/orchestrator's role is to set scope and catch genuine escalations — not
to manually drive every tool invocation.

## Configured ≠ Available ≠ Used

> Added after observed drift: a plan correctly stated the autonomy policy in
> one section, then contradicted it with a blanket "no tool runs until
> approved" gate in another section of the SAME output. This distinction
> exists to stop that drift at its root, and to make tool-availability
> failures diagnosable instead of silently blocked.

Three different things are easy to conflate and must be checked separately:

1. **Configured** — a tool/MCP server exists in `opencode.json` (or
   equivalent). This does NOT mean the agent can see or call it this session.
2. **Available** — the tool actually appears in the agent's current tool
   list this session. Configured-but-not-available (e.g. an MCP server
   defined but not exposed to the active agent/session) is a real,
   reportable state — flag it explicitly as a coverage gap rather than
   silently working around it or pretending the capability doesn't exist
   in the architecture at all.
3. **Permitted** — an available tool is allowed to run under the current
   `permission` config for the active agent mode.

None of the three implies the next one, and none of them means the tool WILL
actually get called — that still depends on the model choosing to call it.
When a plan says a capability is "wanted but missing," always state which of
the three layers it's missing at (configured-only, available-but-denied, or
available-and-permitted-but-the-model-didn't-invoke-it) — this is what
distinguishes an architecture problem, a permissions problem, and a model
behavior problem, and only one of those three is fixable by editing config
or `.md` files.

## Stopping Points and Autonomy (the exact boundary — do not widen it)

Once authorization and scope have been verified for the current mission:

- Passive reconnaissance proceeds autonomously.
- Read-only, low-volume reconnaissance explicitly permitted by the program
  proceeds autonomously.
- Tool execution is performed directly by the agent via the available
  Bash/MCP tools — never by asking the human operator to manually run a
  command on the agent's behalf.

The agent MUST stop and request explicit approval before, and ONLY before:

(a) Any state-changing action.
(b) Any test that could materially alter target state.
(c) Scope expansion beyond what `mission.yaml`/`scope.md` authorizes.
(d) Any action flagged `prohibited_actions`, or genuinely ambiguous scope.
(e) First-time large-scale or rate-limit-sensitive execution (confirm
    volume/scope once, then proceed autonomously within it).
(f) Any action the program/mission explicitly requires human sign-off for.

After approval is granted for a bounded activity, the agent continues
autonomously within that approved scope and volume — approval is not
re-requested per subsequent call inside the same bounded activity.

Do NOT phrase a plan's stopping condition as "no tool runs until approved"
or any other blanket gate covering recon — that directly contradicts this
section and recreates the exact operational friction this file exists to
prevent. A plan's own "Stopping Points" section must name gates (a)–(f)
specifically, never a global "wait for approval before doing anything."

---

# PortSwigger Knowledge

Solved PortSwigger labs are reusable educational knowledge.

Location:

`knowledge/portswigger/labs/`

PortSwigger knowledge may be used to:

* recognize vulnerability patterns
* generate hypotheses
* identify useful test sequences
* identify relevant application behaviors
* suggest verification strategies
* connect observed attack surfaces to known vulnerability classes

PortSwigger knowledge must NOT be treated as proof that the current target
contains the same vulnerability.

A lab pattern creates a hypothesis, not a finding.

---

# Real-World Writeups

Location:

`knowledge/portswigger/writeups/`
and other relevant knowledge locations.

Writeups may be used to understand:

* real-world vulnerability patterns
* attack chains
* root causes
* authorization boundaries
* impact demonstrations
* verification approaches
* reporting practices

Claims from writeups must never be presented as observations from the current
target.

---

# Agent Separation

Agents must remain within their assigned responsibilities.

Recon:
Discover attack surface.

Hunter:
Generate vulnerability hypotheses.

Specialized hunters:
Investigate their specific vulnerability domains.

Verification:
Prove or disprove hypotheses.

Triage:
Challenge findings and identify false positives.

Impact:
Document demonstrated security impact.

Reporting:
Convert verified evidence into a report.

Orchestrator:
Coordinate the lifecycle.

No agent may silently assume another agent's role.

---

# Evidence Integrity

Never invent:

* requests
* responses
* credentials
* accounts
* permissions
* vulnerabilities
* successful exploitation
* impact
* affected users
* reproduction results

Every claim about the current target must be traceable to current evidence.

Historical examples and lab solutions are not current-target evidence.

---

# Finding Lifecycle

candidate
→ verification
→ confirmed / rejected / inconclusive
→ triage
→ impact
→ report

A candidate is not a confirmed vulnerability.

---

# Artifact-First Communication

Agents should communicate through persistent mission artifacts rather than
depending on conversational memory.

Mission artifacts are stored under:

`security-research/missions/<mission-id>/`

Agents must preserve useful intermediate results.

---

# Knowledge Feedback

After completing a mission or lab, reusable knowledge may be added to the
persistent knowledge base.

Only generalizable knowledge should be promoted.

Do not copy target-specific secrets, credentials, private data, or unnecessary
raw evidence into reusable knowledge.

---

# Tool Usage

Use available tools deliberately.

Tool execution must respect:

* authorization
* scope
* exclusions
* rate limits
* program rules
* safe concurrency
* minimal necessary requests

Do not attempt to bypass service-side rate limits.

See `# Tool Autonomy` above for how deliberate tool use and autonomous
operation are reconciled: "deliberate" means purposeful and scope-respecting,
not "ask permission for every call."

---

# Quality Standard

The system should prefer:

evidence over assumptions

reproduction over speculation

minimal tests over noisy testing

structured artifacts over raw output

verified impact over exaggerated impact

reusable knowledge over target-specific notes
