# Agentic Research Methodology

## Purpose

Govern the use of LLM agents, autonomous harnesses, or multi-agent pipelines as
the *executor* of a security engagement. This skill exists because agentic
research has a failure surface that human pentesting does not: the agent acts on
a live target faster than a human can supervise, and its mistakes are
attributable to the human.

The operating principle: **an agent may propose, verify, and draft. An agent may
not be the sole authority on anything that touches production state or other
people's data.**

## Scope

- Applies whenever research is executed by an agent or harness rather than
  fully hand-driven, on **any** target class — CTF, lab, or live program.
- Complements, never overrides, the engagement's own mission scope. The
  `mission.yaml` authorization boundary (AGENTS.md "Stopping Points and
  Autonomy", gates (a)–(f)) is inherited unchanged; an agent may not widen it.
- **No new testing authority.** This skill adds operational discipline, not
  permission. A new topic here is not a scope expansion for any mission.

## Inputs

- The current mission's `mission.yaml` / `scope.md` — especially
  `constraints` and `prohibited_actions`.
- AGENTS.md "Tool Autonomy", "Stopping Points and Autonomy (a)–(f)", and
  "Evidence Integrity".
- Whether the target is production, staging, or lab — established from
  **evidence** (hostname, config, TLS), never assumed.
- Real-user surface: does the target store conversations, tickets, sessions,
  messages, invoices, or any record attributable to a named person?

## Workflow

Follow this order. Steps 1–3 are pre-engagement gates; step 4 is a standing
monitor; steps 5–6 are disclosure and attribution duties.

```
1. Classify the target (prod / staging / lab) FROM EVIDENCE
2. Map the real-user surface
3. Set read budget + create-only default + tool-level enforcement
4. Monitor state-changing calls for the whole engagement
5. On anomaly: HALT, then disclose precisely
6. Verify every agent-derived claim personally before filing
```

1. **Classify the target from evidence.** Confirm environment before the first
   write, not from assumption. "I believed it was a sandbox" is not a defence; it
   is a finding about your own process.
2. **Map the real-user surface first.** On a live product, assume every readable
   record belongs to a named person. If the target stores conversations, tickets,
   sessions, or messages, the agent is one loop from reading a human's private
   data.
3. **Set a hard read budget per target.** "Read at most N records, only those I
   created, and log every read." Unread access is still access; bulk history
   fetches are indefensible if the finding only needed a handful of records.
   Enforce the create-only default **in tooling** (a scope file the agent must
   consult, read-only credentials, a separate test tenant, or a mock backend) —
   not in the prompt. Prompts are advisory; tool permissions are not.
4. **Monitor state-changing calls, not prose.** The failure mode is a single
   mutating request, so watch write/delete verbs and any body carrying an
   identifier the agent did not mint. **Halt on first anomaly** — if an agent
   touches a record outside its own namespace, stop the harness immediately.
   Continued operation converts one incident into a pattern and materially
   worsens the disclosure.

## Detection / Hypothesis Areas

These are the pre-flight warning signs that an agentic run is about to overstep:

- A target that is nominally internal but internet-reachable, storing per-user
  records behind an unauthenticated sibling route.
- An endpoint that accepts a caller-chosen identifier, so "read" and "write"
  become operations on someone else's record.
- Any bulk-list endpoint that enumerates every record in one response.
- An agent asked to "check whether the other records are affected" — that
  phrasing is how 300+ third-party records get read in a single sweep.
- No per-request log. If you cannot reconstruct what the agent did, you cannot
  disclose it, and you will be unable to certify the engagement.

## Verification

- **Scope conformance is verified, not assumed.** Diff what the agent actually
  did against the mission's authorized scope and prohibited actions. This is the
  same evidence gate as any other claim: no invented requests, no assumed
  non-touching.
- **Every read is logged with timestamp and target identifier.** An engagement
  you cannot audit is an engagement you cannot certify in a report.
- **The create-only invariant holds**, or the deviation is documented before
  filing.
- **The environment classification was proven from evidence.**

## Evidence

- The harness's request log is the primary evidence for the engagement's
  compliance, exactly as recorded responses are primary evidence for a finding.
  Retain it; the disclosure in step 5 is impossible to write without it.
  - Findings and evidence rules are unchanged and still govern
    `verification-skill/SKILL.md` and `impact-analysis-skill/SKILL.md`:
    no invented requests, responses, reproduction, or impact.
  - **Live artifacts in production are containment obligations, not evidence
    storage.** Any probe that persists where other people or systems will meet it
    — a stored record, a queued message, an uploaded file, a cache entry — remains
    an armed capability in someone else's environment long after the report is
    written. Observed failure, and a good-faith one: a set of fifteen-plus
    executable script payloads was deliberately submitted into a live
    customer-service queue, correctly marked, correctly disclosed to the program,
    and offered for cleanup — but left in place across a fifty-day remediation
    window, in a queue that also carried real customer data. Good intentions do
    not discharge this. The queue belonged to the target's staff and its customers
    for the entire period, and every one of those payloads was one accidental
    click, one curious operator, or one compromised workstation away from firing
    in a privileged session.
    Discipline: submit **the minimum number of live records needed to prove the
    claim** — ideally one, with an inert greppable marker — and keep every
    remaining variant inert. Do not batch-submit a payload family "so the
    maintainer can see the pattern"; a pattern can be described in prose and
    demonstrated with one marker. If a finding genuinely requires several live
    records, say so explicitly in the report with counts and a cleanup offer,
    agree a removal plan with the program, and never let live proof outnumber
    live need. When the class is *"a privileged human will open this"*, the
    blast radius is a human being's session, and the count is not a detail.
  - **Track live artifacts as state, with an expiry.** Record what you left, where,
    when, how many, and whether it is armed or inert — and get confirmation of
    removal. A proof-of-concept whose cleanup status is unknown is an unfinished
    engagement, not a finished one.
  - **Screen recordings and screenshots are disclosure artifacts and carry the
    highest accidental-leak risk of any evidence you produce.** A recording
    captures *everything in frame*, including things you never intended to submit:
    browser bookmarks to unrelated or private programs, other open tabs, extension
    dashboards, notification content, chat clients, password-manager prompts, and
    the surrounding desktop. Observed: a PoC screen recording incidentally captured
    a bookmark to a private bug-bounty program, which would have published the
    existence and location of a program that had chosen not to be public.
    Discipline: treat a recording as **higher** risk than the equivalent text
    evidence, not lower, because text is curated by you and a frame is not. Prefer
    text transcripts and cropped stills where they carry the proof; record only
    when motion is genuinely the evidence; and before submitting, review the
    recording at 1× with sound off and the whole desktop in frame, not just the
    browser viewport. Where a leak is already out, self-report immediately and
    request removal before disclosure — the program in this case redacted the
    artifact and deferred publication, which is the correct and cooperative
    response, and the self-report is what made it possible. Volunteering your own
    mistake is a technique, not a confession.
- **Restraint is severity-neutral, and the positive case proves it.** Observed
  against the same program as the overstep above, by a comparable research
  operation: an unauthenticated blind injection with stacked queries against a
  production cloud database, fully proven (tautology pair, engine fingerprint,
  time-based delay), and therefore arbitrarily deep to exploit. The operator
  extracted two table names out of a ten-table schema — both public catalog and
  reference tables — and **stopped**. They did not enumerate the remaining tables,
  did not touch customer data, and asked the program for permission to mask
  sensitive values before disclosing anything public. The program confirmed the
  report valid and fixed it.
  Two lessons, and the second is the one that matters:
  - **Refusing to over-collect cost nothing.** Unauthenticated injection with
    stacked queries is Critical on the primitive alone; the remaining tables would
    have added severity zero and evidentiary nothing. The restraint did not
    weaken the finding by a single point.
  - **The stop line was a rule, not a feeling** — public reference data is
    acceptable evidence, unknown tables are not. That distinction is available
    *before* extraction starts, which is the only time it is cheap. Decide it in
    advance.
  Contrast directly with the overstep in "The Overstep Disclosure" below: same
  program, similar technical sophistication, opposite outcome, and the only
  difference was where the line was drawn. One forced a public disclosure of a
  customer's data and spent the engagement's credibility; the other was fixed on
  its merits.
- **A blind oracle that can enumerate a schema is where discipline binds
  hardest, because the interesting tables are the reason you want to.** The moment
  a technique *can* reach sensitive data is the moment its use needs a
  justification you could defend to the target afterwards. "I already had the
  primitive, so one more table was free" is exactly the reasoning behind every
  overstep on record — the marginal request always feels free because the cost is
  paid by someone else, later, in a disclosure.

## The Overstep Disclosure

If an agent acted outside scope, **self-report it in the report itself**, with the
same rigour as the finding. This is not an optional confession to avoid — it is
what keeps the rest of the report credible, and it is what programs reward.

Include, at minimum:

- What was affected and how (endpoint shape, operation).
- Exact timestamp(s), and your source IP.
- The affected identifier(s), redacted if they identify a third party — but
  *precisely* enough for the vendor to find and remediate.
- The content of any message/data written, so the vendor can assess victim
  impact.
- A complete inventory of test records you created, so they can be cleaned up.
- An honest count of records *read* (even if unread/unstored), split by
  environment.
- What you did on detecting it (halted the harness), and an apology.

Frame it factually. Do not minimise ("minor issue"), do not inflate ("I may have
compromised your users"), and do not omit it hoping it goes unnoticed — the
program almost certainly already sees the traffic.

Expect this to be survivable when the impact is small, the write is caught, and
the disclosure is prompt and precise. It is survivable *because* it is disclosed.
Concealment is what turns an overstep into a trust-ending event.

## Handoff

- If an overstep occurred, the disclosure travels **inside the report**, not as a
  separate apology thread — see `# The Overstep Disclosure`.
- A human owns the report. The human is the reporter, the discloser, and the
  party bound by the program. "My agent did it" is not a defence and weakens the
  submission.
- If the engagement used agents, say so in the report. Programs adjust posture
  once they know, and the disclosure is far more credible when the harness is
  already on the record.
- Reusable, generalizable lessons → `impact-analysis-skill/SKILL.md` step 10.
  No target-specific data, identifiers, or raw evidence.

## Related Skills

- `impact-analysis-skill/SKILL.md` — step 9 (every claim needs a minimal safe
  proof), step 11 (calibrate the claim against demonstrated capability, not the
  class label). Apply with *more* scepticism to agent-derived analysis, not less.
- `verification-skill/SKILL.md` — evidence gate and differential proofs.
- `reporting-skill/SKILL.md` — the positive reporting model, and the
  disclosure lifecycle.
- `access-control-skill/SKILL.md` — the class this skill's most common
  incident actually belonged to.
- `../../AGENTS.md` — Tool Autonomy; "Stopping Points and Autonomy" (a)–(f);
  Evidence Integrity. Agents inherit these gates and may not widen them.

## Source / Derivation

- **Directly derived:** the operational controls in `# Workflow` and
  `# Detection / Hypothesis Areas` from an observed incident — a supervised
  multi-agent harness researching a live authorized application wrote a message
  into a conversation it had not created, belonging to a real user, and
  separately fetched 334 conversation histories (14 production, 320 dev) across
  the engagement. The finding produced was strong; the data handling was not.
  Neither fact indicts the finding — it indicts the harness scope.
- **Directly derived:** `# The Overstep Disclosure` from the shape of that
  incident's self-disclosure, which was prompt, specific, and unprompted — and
  which the program resolved without penalty.
- **Cross-referenced:** AGENTS.md "Tool Autonomy" and "Stopping Points and
  Autonomy (a)–(f)" for the enforcement-vs-advisory distinction in workflow
  step 3; `impact-analysis-skill/SKILL.md` steps 9–11 for the verification
  and calibration gates.
- **Cited as precedent:** a public HackerOne triage thread, enterprise program,
  resolved and approved for disclosure. No target-specific data, identifier, or
  raw evidence is reproduced here.

## Coverage Boundaries

The current knowledge base does not yet contain a dedicated methodology for:

- **Prompt/tool sandboxing mechanics** — no recommended harness framework,
  proxy, or allowlist implementation is documented here. Workflow step 3 states
  the *requirement*; the tooling is environment-specific.
- **Multi-agent orchestration patterns** (fan-out, reviewer agents, adjudication
  of conflicting agent conclusions) — not documented.
- **Agent output as evidence quality assurance** — no procedure for measuring or
  auditing agent false-positive/false-negative rates exists.
- **Regulatory or contractual notification duties** arising from an overstep
  (GDPR/contractual breach-notification timelines). Only the *bounty-program*
  disclosure path is covered above; do not assume it exhausts legal obligations.
- **Cost and time budgeting** for agentic runs, including when a manual
  investigation is cheaper and safer than an agentic one.
