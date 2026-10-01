# Reporting Skill

> Dedicated capability built from existing project knowledge. Source template `../reporting.md` is a header-only stub; the reporting knowledge base already lives in four places — the reporting agent (`../../../agents/reporting.md`), the `security-reporting` skill (`../../../skills/security-reporting/SKILL.md` + its `references/`), the triage/impact agents, and the impact-analysis skill. This capability organizes that workflow into one dispatchable skill. See `# Source / Derivation`.

## Purpose

Convert a **verified, triaged, impact-analyzed finding** into a professional, reproducible, evidence-backed vulnerability report. Reporting is not research: it adds no new evidence, invents no claims, and only reports findings that reached `report_ready`.

The workflow is: verified finding → evidence → impact → severity rationale → report. This skill binds together the existing reporting inputs, structure, severity rules, and quality gates so any agent can produce a report that another researcher or program triager can independently reproduce.

## Scope

- **Reports `report_ready` findings only** (per `../../../agents/reporting.md` §15). Never report candidates, `verification_pending`, `inconclusive`, or `rejected` findings.
- **Uses existing severity methodology only.** This repository already defines how to reason about severity (see `# Verification`); this skill must not invent a new severity framework.
- **Respets program scope, exclusions, and reporting requirements.** If evidence is missing, the finding returns to verification — missing evidence is never invented (reporting agent §17).

## Inputs

- Verification result (`../verification-skill/SKILL.md`); triage decision (`../../../skills/security-triage/SKILL.md`, `../../../agents/triage.md`); impact analysis (`../impact-analysis-skill/SKILL.md`, `../../../agents/impact.md`).
- Program scope/exclusions and program-specific reporting requirements.
- Evidence artifacts (requests/responses/state before-after/reproduction) from the mission directory (`../../missions/<mission-id>/`).
- Structure, title, reproduction, evidence, remediation, quality-check references under `../../../skills/security-reporting/references/`.
- Report structure from the reporting agent and from `../../../skills/security-reporting/references/report-structure.md`.

## Workflow

Follow the reporting pipeline from `../../../agents/reporting.md` §2:

```
VERIFIED EVIDENCE
↓
CLAIM
↓
ROOT CAUSE
↓
REPRODUCTION
↓
SECURITY IMPACT
↓
REMEDIATION
↓
QUALITY CHECK
```

Concretely:

1. **Collect verified evidence.** Only confirmed, reproduced, current-target evidence. Check the mission artifacts (verification, triage, impact) for the finding.
2. **State the claim.** Title + one-line summary that answers: what is wrong, where, who can exploit it, what happens. No impact beyond what was demonstrated (reporting agent §3–§4).
3. **Identify affected asset.** Hostname, application, endpoint, HTTP method, relevant component — only assets supported by evidence (§5).
4. **Document preconditions.** Authentication requirement, required role/account, required resource/state — never invented (§6).
5. **Write reproduction steps.** Sequential, minimal, deterministic, evidence-backed; every step corresponds to something actually performed (§7). Include meaningful request details (method, path, relevant headers/body, auth context); strip unnecessary secrets; never fabricate requests (§8).
6. **Separate expected vs actual.** Explain the violated security property explicitly (§9).
7. **Include only verified evidence** — request/response, response fragment, before/after state, authorization comparison, controlled reproduction (§10).
8. **Apply impact from the Impact Agent's output**, separating demonstrated from potential impact, never inflated (§11; also `# Impact` below).
9. **Root cause** only when evidence permits (missing server-side authorization, inconsistent middleware, insufficient state validation, missing ownership check, unsafe workflow transition); otherwise state "Root cause not conclusively established." (§12).
10. **Remediation, specific** (enforce authorization server-side, verify resource ownership, enforce tenant boundaries, validate state transitions, bind decisions to server-side state, reject unauthorized fields); not generic when a specific recommendation is supported (§13).
11. **Run the quality check** (§14 and `../../../skills/security-reporting/references/quality-check.md`).
12. **Knowledge feedback.** If the finding reveals a reusable pattern, create a concise artifact under `./knowledge/` (pattern, preconditions, observable indicators, verification concept, false positives, lessons learned); never overwrite existing methodology; no secrets (`../impact-analysis-skill/SKILL.md` step 10 and `../../../agents/reporting.md` §16).

## Detection / Hypothesis Areas

This is a **detection-of-report-defects** capability, not a vulnerability-detection capability. Before finalizing, check that the report never contains:

- A claim without a current-target evidence trace (see AGENTS.md "Evidence Integrity": no invented requests/responses/credentials/vulnerabilities/impact/affected users/reproduction).
- Impact without proof, or potential impact stated as demonstrated.
- A severity that is higher than the evidence supports.
- A reproduction that cannot be replayed from the written steps alone.
- Preconditions that were assumed rather than observed.
- An unsupported "privilege escalation" or "full compromise" framing.
- Knowledge-base/lab-solution content presented as current-target proof.
- A privilege claim that leaves the standard objection unanswered — if the report
  does not state the *minimum* privilege that reaches the sink and show the
  negative facts, triage will ask, and the round-trip costs a day. See
  `../verification-skill/SKILL.md` ("Preempt the standard triage objection").
- **Scope self-limitation done wrong.** Discovering an adjacent weakness while
  proving the first does not obligate you to file it separately, and filing both
  can split one bounty and dilute the fix. Disclose the adjacent gap *inside* the
  main report as reachability evidence and state plainly that it is not being
  reported separately. Programs read that as discipline, not as sandbagging.
- **A version range that drifts.** When a prior CVE covers the same class, the
  affected range must be anchored to the *fix* boundary, not to when the
  underlying sink was introduced. Claiming the pre-fix range re-opens a closed
  advisory; omitting the residual range understates exposure. State both, and
  disclaim the covered range explicitly.
- **Claiming a new identifier without a prior-art check.** If the finding is a
  residual of a prior advisory, say whether you found an existing public report
  on the missed sink. "I found the original hardening change but no public report
  covering this sink" is what justifies a *new* CVE instead of an addendum.

## Verification

- **Severity and impact correctness — use the repository's severity methodology, do not invent one:**
  - Impact classes mapped to the severity spectrum **only as evidenced impact**, never as the base class alone (`../impact-analysis-skill/SKILL.md` §4: sensitive/personal data exposure, unauthorized modification/deletion, availability, authentication, authorization, privilege, attack chain, code/command execution — each "only when demonstrated").
  - Classify every impact claim: **demonstrated / supported inference / potential / not demonstrated** (Impact Agent model), or CONFIRMED / PLAUSIBLE-UNVERIFIED / INAPPLICABLE per `../impact-analysis-skill/SKILL.md` step 8. Verify every claimed impact has a minimal safe proof — "No proof → no claim" (step 9).
  - Never treat a PortSwigger lab's educational severity as target severity (`../impact-analysis-skill/SKILL.md` §5).
- **Facts vs assumptions:** separate stated facts (traceable to artifacts) from reasoning labeled as such. "Knowledge is not proof" is the repository core principle (`../../README.md`).
- **Reproduction is verified** — steps correspond to actually performed operations; a fresh run reproduces the same outcome.
- **Impact is evidence-backed** — matches the impact artifact produced by the Impact Agent; the report's "quality check" section lists the explicit checks used.

## Evidence

Evidence in the report is drawn verbatim from mission artifacts — never created for the report. Use the evidence/reproduction conventions of `../../../skills/security-reporting/references/evidence.md` and `../../../skills/security-reporting/references/reproduction.md`. Requests must carry meaningful details and be scrubbed of secrets; responses/fragments only from recorded outputs; state proof requires the before→after pairing from verification.

### Do not ship a WAF rule as part of an analysis
A signature rule appended to a write-up is close to always a liability, and it is
routinely copy-pasted by readers who believe the issue is now contained:

- **A WAF rule does not remediate a code-level defect.** If the release is patched the
  rule is unnecessary; if it is unpatched the rule is cosmetic. Say so rather than
  presenting the rule as a mitigation.
- **Rules keyed to a parameter name plus a metacharacter class are signatures, not
  fixes.** They are bypassed by encoding, alternate separators, `$IFS`/tab substitution
  and case variation, and they break on legitimate values. The false sense of safety
  costs more than the rule provides.
- **Check the rule for syntax faults before publishing it.** A metacharacter alternation
  containing empty branches matches the empty string, so the rule fires on essentially
  every request to the page — the "mitigation" becomes a self-inflicted denial of
  service. Verify a rule on a throwaway instance, or omit it.
- If the rule is worth sharing, put it in a clearly labelled *temporary detection note*
  in a remediation section, with the bypass caveat attached.

### Treat a machine-generated artefact as a claim about the target, not as evidence
Machine-written analyses are common after a public CVE, and they mix solid mechanism
analysis with unsupported scoring, synthetic patches and unexecuted proofs. Read them
as a lead, then re-establish every load-bearing fact from a primary source:

- Verify the "vulnerable" and "patched" versions against the project's own changelog or
  tracker, and read the real before/after files. A diff in which the entire file is
  deleted and re-added is a generated artefact, not a patch; the accompanying prose
  about what the patch does is then also unverified.
- Re-derive the severity yourself from demonstrated impact. A published score with no
  vector string, and no acknowledgement of the privilege prerequisite, is an opinion in
  the summary field.
- Treat "the payload was accepted; the action will occur on the next run" as a
  mechanism, not an execution. No side effect read back means no execution claim.
- When you restate a machine-generated report, carry across the parts that survive
  checking and drop the parts that do not — and say which is which. The value you add
  over the generated text is exactly the calibration, so do not reproduce its inflation.

## Report Calibration Models

Publicly-resolved reports used as calibration anchors. They are **precedent, not
methodology** — and the operative lesson in all three is the same: the class
label is a hypothesis, the demonstrated capability is the finding (see
`../impact-analysis-skill/SKILL.md` Step 11).

**Model C (the positive model) — a real boundary crossing, Critical, fixed,
disclosure approved.** An internal Teams/Azure-OpenAI application enforced
authentication on exactly one route (the Bot Framework webhook, correctly
returning 401 on a missing `Authorization` header) and left six sibling data
routes open: list sessions, read history, delete session, drive the LLM, submit
feedback, health. What made the report exemplary:

1. **Auditable root cause** — a per-route auth matrix (endpoint × method × auth
   enforced?) made impact self-evident and eliminated clarification rounds.
   Triage took hours with no follow-up questions.
2. **Controls before claims** — the WAF parser-differential bypass (the WAF
   evaluated the *last* `Content-Type` and skipped body inspection while the
   application evaluated the *first* and parsed JSON) shipped with **two controls
   in the failing direction** (single header; then duplicate headers in reversed
   order), proving the result was not an ordering artefact.
3. **A control for the surprising claim** — "data survives deletion" was
   demonstrated by contrasting a deleted session (messages still returned) with a
   never-existing identifier (empty array), proving orphaned data rather than a
   generically-responding endpoint, and proving no remediation route exists.
4. **Self-created test data only** — a purpose-built `poc-`-prefixed session and
   a deliberately off-topic prompt, so no existing conversation was read and no
   proprietary content was retrieved through the RAG backend.
5. **Honest scoring, including self-downgrades** — availability rated *None with
   written reasoning* despite holding an unauthenticated delete. Giving away
   available points is what makes the rest of the vector trustworthy.
6. **Self-reported overstep** — see `../agentic-research-skill/SKILL.md`.

Note the report was classified by the program as `Misconfiguration` (CWE-16) when
it is plainly **CWE-306, Missing Authentication for Critical Function** — an
access-control failure, not a configuration nit. Expect this on under-scoped
submissions; naming the CWE explicitly steers triage toward the right internal fix
priority. *This KB does not derive CVSS vectors — see `# Coverage Boundaries` — so
treat any public vector in these precedents as the report author's reasoning to
be checked, not reproduced.*

**Model B — public fetch plus reflection is XSS, not SSRF.** A userinfo
host-discrepancy bypassed a fetch host allowlist and the fetched body was
reflected into the site's own origin. Filed Critical SSRF; re-triaged to XSS and
paid at Medium. None of the four SSRF capabilities were demonstrable, and the
reporter said so plainly. The real bug was genuine and was fixed. See
`../ssrf-skill/SKILL.md`.

**Model B also runs in the opposite direction, and that is the more dangerous
case.** A submission proved an unauthenticated write primitive end to end —
attachment upload returning a server-side filename, ticket submission returning
`success:true` with an empty anti-bot token, no CSRF token, wildcard CORS, eight
rapid submissions accepted, an arbitrary tenant ID honoured — and then asserted a
Critical chain built on top of it: script in a privileged back-office → operator
account takeover → administrator account creation → server-side code execution,
scored 9.0. **The write was proven; the render never was.** Not one payload was
ever triggered, and the report itself conceded the rendering might be encoded.
Every impact link above the first was an assumption, and the two headline
mechanisms were each independently hollow: the cookie-exfiltration payload returns
nothing under `HttpOnly`, and installing a server-side code package is an
administrator capability the administrator's own session already has, so it is not
escalation at all. The underlying control failures were real and worth fixing; the
9.0 was not earned by the evidence supplied.

The transferable rule: **relabeling is not inherently downward.** Downgrading an
overstated class (Model B proper) is good calibration. Inflating a proven narrow
primitive with a speculative chain is the same error pointed the other way, and it
is worse, because it is the direction triage is least able to catch and most likely
to pay on first impression. Score to the confirmed link; put the rest in
"potential impact" prose, clearly labelled. See `../xss-skill/SKILL.md` for the
render gate and `../impact-analysis-skill/SKILL.md` for chain discipline.

**Model A — same-party mechanism, no new capability, closed Informative.** A
flawless analysis of a wildcard-FTP path-traversal defect (an `escape()` then
`urldecode()` round-trip reconstructing `../` because `.` survives
percent-encoding, with no `..` filtering) closed as "a bug to fix" — a malicious
server that controls the response can already serve anything on the path the
client requested. A fix shipped anyway. That program also pays **no bounty at
all**, which is worth checking before investing effort. See
`../traversal-skill/SKILL.md`.

**Model D (the operational-excellence model) — residual argument injection to
command execution, CVE assigned, triaged in 12 hours.** A self-hosted
translation platform passed repository-controlled filenames to a version-control
binary without an option terminator; a filename beginning with `-` was parsed as
a command-line option, and a **config-defined command alias** (the
`--config=alias.<name>=!<cmd>` shape common to VCS and build tools) replaced the
intended subcommand with a shell alias. A **project-scoped** editor
(non-superuser, non-staff) reached it through a file-processing add-on that fired
on a later repository update. Execution was shown as `uid=1000(svc)` reading a
researcher-created synthetic file — and the whole thing was tested in a
checksum-verified official container against an ephemeral database, with the
runner script attached. What made it exemplary:

1. **The finding was the sink the prior fix missed.** The value was not "argument
   injection exists" but "the earlier hardening patched several call sites and
   omitted this one." The version range was anchored to the *fix* boundary
   (first fixed release onward), with the pre-fix range explicitly disclaimed as
   already covered.
2. **A one-line patched control proved causation and pre-verified the fix.**
   Adding only the `--` terminator made the effect vanish while the normal path
   kept working — so the maintainer received a tested patch, not a theory.
3. **Privilege was preempted in the report** (`superuser=False, staff=False`),
   closing the "is this admin-only?" objection before triage raised it.
4. **Scope was self-limited.** An adjacent add-on-permission gap was disclosed as
   reachability evidence and explicitly *not* filed as a second vulnerability.
5. **The claim was bounded** — "does not claim root execution," synthetic file
   only, no production or hosted instance touched.

The contrast with Model C is the point: C and D are the same vulnerability *class*
(crossing an authorization boundary to execute or read), but C was found by a
harness that overstepped into a real user's data and needed a disclosure, while D
was contained by deliberate design. Same finding class, opposite operational
outcome. See `../agentic-research-skill/SKILL.md` for the containment discipline
and `../verification-skill/SKILL.md` for the differential patch control.

  **Model E (the invariant-as-evidence model) — credential egress to an untrusted
  destination, fixed in 30 hours, advisory + release.** A CLI walked the working
  directory and every ancestor for a project config file that names the API URL;
  the API token was resolved independently from an environment variable; the token
  was then sent to whatever URL the discovered file specified. What made it
  exemplary was not the primitive but the *argument*:
  
  1. **The framing was an invariant the maintainers had already established, not
     a new claim.** The report cited an existing URL-normalization feature that
     enforces "a token must never egress to an unexpected origin" and pointed out
     the configured base URL was the one input path where that property was
     unenforced. Acceptance then required no new belief from the maintainer —
     only agreement with their own stated rule. **This is the strongest available
     report shape: identify the security property the code already tries to
     guarantee, then find the path that does not enforce it.** It is far more
     robust than asserting a novel property and hoping it is agreed with.
  2. **A bypass of an existing control is categorically stronger than a missing
     control.** The credential store was already keyed *by origin* — the fix for
     an earlier CVE — but an environment variable short-circuited that scoping
     and returned the secret for any URL. "You were right, you shipped the
     hardening, and here is the bypass" is effectively unanswerable on the merits.
     "You should add origin binding" invites "that is a design choice."
  3. **The vulnerable configuration was the vendor's own documented pattern.** The
     docs recommended the exact env-var-plus-repo-config combination being
     reported. That forecloses the standard dismissal — that the reporter chose a
     misuse case — and should be checked explicitly in any credential-egress
     finding: *is the precondition the vendor recommends?*
  4. **Self-hosted software inverts the usual "the user configured it" defence.**
     For a hosted service, an argument that the user chose the destination is
     sometimes reasonable. For a self-hosted tool whose configuration lives
     *inside the repository it operates on*, it is not: the repository is the
     attack surface, and the config is inside the trust boundary being crossed.
     Say so explicitly when the target is self-hosted.
  5. **End-to-end through the real client, not a reimplementation** — real repo,
     pinned commit, installed dependencies, actual token captured at a collector
     with its real `Host` and `Authorization` headers. This is the opposite of the
     component-extraction approach that grammar-DoS work is forced into, and the
     right lesson from both is the same: **use the strongest rung available, and
     extract the target's own code when a higher rung is unreachable.**
  6. **Inference was labelled as inference.** The collector listened on loopback;
     the extension to arbitrary reachable internal hosts was presented as chain
     potential, not as demonstrated. Correct restraint — and note the severity is
     unaffected by it, because the attacker *chooses* the destination, so its
     addressability is a deployment detail rather than a limit on the primitive.
  
  The cheapest triage pre-filter across all five: **is the victim a third party the
  attacker could not already reach?** Model C's, D's and E's victims were third
  parties the attacker could not otherwise reach (named employees; the shared
  service account and its data; the victim's CI secret); Models A and B's
  "victims" were the attacker. Model E is also the cleanest example of the second
  pre-filter — **is the precondition the vendor's own documented usage?**

  **Establish claimability before the deep work, not after it.** The pre-filter
  that actually decides outcomes is scope, and it must be settled *first* when the
  affected host is not one the program obviously lists. Observed near-miss: a
  flawless, Critical, unambiguously valid finding — unauthenticated injection with
  stacked queries against a production cloud database, boolean-pair controlled,
  time-proven, fingerprint-confirmed — was submitted against a program whose scope
  list named the *front-end* wildcard, while the vulnerable service sat on a
  different, separately-hosted backend that the front-end merely called. The entire
  argument for claimability was a single "Scope Note" placed *after* the impact
  claims, resting on reachability: the in-scope site loads it, the API answers
  with wildcard CORS, it is "the production backend of" the in-scope property.

  That is an **argument, not a determination.** Scope is decided by the program's
  own list, not by whether an in-scope asset can reach the host — and programs
  routinely exclude cloud- or SaaS-hosted backends precisely because the vendor
  relationship, the data, and the contractual relationship are all different.
  Note especially that **wildcard CORS says nothing about scope.** "Any website can
  reach it" (a real, separately reportable weakness) and "this host is in scope"
  are independent questions, and conflating them weakens both.

  Discipline for this class:
  - **Put the scope argument at the top**, before severity and impact, and make it
    explicit and addressable to a triager who has not read the rest.
  - **Ask the program directly and early, in the first comment.** A written scope
    confirmation is the only durable claimability, and it is worth far more than
    any amount of additional technical proof.
  - **Do the minimum proof, then ask.** A boolean tautology pair plus an engine
    fingerprint establishes the primitive in a handful of requests. Extracting a
      full schema by binary search — a thousand-plus requests against a production
      database — before scope is settled risks performing an unbounded collection
      against a host that may turn out to be someone else's, and the requests
      cannot be un-made.
  - **If scope is confirmed late, say so and keep the early work minimal in the
    writeup.** A report that shows restraint before it had scope is far stronger
    than one that shows extraction volume.

  **Never delete evidence from a live report thread.** Deleting a comment removes
  it from the program's record and from any later independent review. Redact the
  sensitive value in place and repost a sanitized version, or post the sanitized
  version and note that the unsanitized original was withdrawn — the audit trail
  matters more than tidiness, and a deleted comment is indistinguishable from
  evidence that was never provided.

- **Scope-by-impact is an argument, not a shortcut, and it must be made explicitly.** When the *vulnerable* asset is out of scope but the *victim* of the resulting attack is in scope — a phishing page delivered from an out-of-scope host to users of an in-scope relying party, an out-of-scope service that leaks an in-scope tenant's data — this is the forced-browsing shape and it is sometimes legitimate. Handle it honestly:
  - state the scope problem **up front, in its own paragraph**, not as a footnote under Impact. A triager must be able to triage the scope question without excavating it;
  - demonstrate the **cross-boundary step**, not just the local weakness. "The payload renders here" is a finding; "the payload renders here *and is delivered to users of a different relying party who then follow it*" is the scope argument. Show the delivery path and the trust boundary crossed;
  - identify precisely **whose users** are affected and whether they are the reporter's users, the reporter's customers, or a third party. "Our customers" is weaker than "our assets" and materially different from "a third party we integrate with";
  - accept that a program may legitimately decline, because the vulnerable host being out of scope is not automatically cured by the impact landing elsewhere. If it is declined, the correct outcome is a note to the affected party, not a re-filed version of the same argument.
- **A finding that lives in customization code changes who can fix it, and may change whether it is in scope.** Client-side scripts injected by themes, plugins, or site customisation — not the vendor's core, not the server template — are a distinct discovery surface: read the shipped JavaScript, not only the server-rendered HTML, because the entire defect can live there. Then expect the harder question of ownership: a customisation-layer defect may be fixable only by the site owner rather than the vendor, which changes urgency, disclosure path, and whether the vendor considers it their bug at all. Establish the layer before writing the remediation, or you will recommend a patch to code the recipient does not own.

## Handling Objections and Disposition Disputes
A triager rejecting a real finding is a normal outcome, and the disposition — not the
severity — is what decides whether anything gets fixed. "This is a footgun", "use the
API correctly", "let's document it" are **disposition disputes**: they assert that the
behaviour is the user's problem, not a bug. These are winnable, but not by arguing
harder about impact.

- **Read the documentation and cite what it actually says.** The strongest move
  against "this is a documented footgun" is evidence that the documentation
  recommends the pattern that triggered it. Handle reuse, connection pooling, and
  reusing client objects across requests are performance recommendations in most
  client libraries, and the "you must reset between operations" rule is almost never
  written down. Quote the file and the sentence. If the docs genuinely do warn,
  the finding is a docs gap and a weak report — find out before you argue.
- **Check whether the proposed remedy matches the reference implementation.** A
  maintainer proposing "always call the reset function between operations" is
  proposing a rule the project's own reference client does not follow, because the
  reference client avoids the bug by a different route. Pointing this out is factual
  rather than adversarial, and it removes the remedy as a resolution without
  requiring anyone to concede the bug.
- **Precedent is the strongest lever available, and it beats principle.** Do not
  argue "this is more severe than you are treating it" — the severity call is theirs
  and they will hold it. Argue **consistency with their own published record**:
  *"This is the same primitive as <sibling CVE>, which was fixed in code in
  `<commit>` and rated <severity>. I cannot see a technical distinction between
  leaking credentials to <component A> being a CVE and leaking them to
  <component B> being a documentation issue."* A maintainer who has already minted a
  CVE, or already merged a code fix, for the same class of defect cannot easily
  un-mint it. "We have painted ourselves into a corner" is a real and common
  disposition outcome, and it is reached through precedent rather than persuasion.
- **Therefore: do the precedent research before you report.** Search the project's
  advisories, release notes, and history for the same primitive before submitting.
  If the same class was previously fixed in code, "footgun" is not available as a
  disposition and you can go in knowing the likely outcome. This is the highest-value
  pre-flight research in the whole workflow, and it is routinely skipped.
- **When a maintainer's objection contradicts their own prior advocacy, quote it.** A
  maintainer who writes "I have always advised the correct usage for this" while
  rejecting a report on the grounds that nobody was told — while conceding the
  behaviour is wrong — is not an opponent, they are a maintainer who has changed
  their mind about disposition. Naming the contradiction, generously and without
  triumph, converts the fastest route to a code fix. Attack the disposition, never
  the person.
- **Concede the parts that are wrong, in your own words, in the first sentence.**
  When a technical point is corrected — your impact statement implied a capability
  the system does not grant, your version claim was untested, your reproduction was
  incomplete — the fastest correct response is: acknowledge it plainly, state
  explicitly what you are *not* claiming, then restate the claim with the correct
  mechanism and explain why the correction changes the threat model. Example shape:
  the initial impact statement implied a passive observer could read encrypted
  early data, which is false; the correct claim is that the client establishes
  traffic keys with a peer whose certificate it will ultimately reject and delivers
  request bytes to that peer, so the peer can decrypt as the endpoint rather than as
  an observer. Same finding, corrected claim, and the correction is what produces an
  accurate downstream write-up.
- **Do not bundle a severity challenge with a request.** Raising "I believe Attack
  Complexity should be Low, not High" in the same message as "could a CVE be
  assigned?" spends goodwill on two asks at once and the second one gets declined
  more readily as a result. Separate them, lead with whatever serves the maintainer's
  own workflow (releases, backports, credits), and let the severity argument be a
  single closing note you explicitly frame as optional.
- **For a CVE request, establish production status first.** Identifiers are generally
  reserved for production-ready or stable releases; findings confined to an alpha,
  beta, or pre-release build are commonly declined on that basis, and this is
  industry-standard rather than a judgement on the research. Check whether any
  affected version is actually deployed, and if not, say so in your own report
  instead of asking for an identifier that will be refused. Fixes and hardening in
  the current stable line matter more than the identifier, and a project that fixed
  your issue and declined the CVE has still done the right thing.

## Disclosure Lifecycle

**The 180-day last-resort clock runs from the formal disclosure REQUEST, not
from resolution.** This is the most commonly miscounted date in bounty work.
Resolution date is irrelevant to the clock. Never compute the window as
resolution → request; that interval is meaningless and will make a comfortable
margin look like an imminent deadline (or the reverse).

Conditions that must **all** hold before self-disclosure is permitted:

1. **180 days elapsed since the formal disclosure request** to the program, with
   **no response**.
2. **Reasonable follow-up at least once every 30 days.** Silence on the
   researcher's side breaks the "reasonable follow up" requirement and can
   invalidate the clock entirely. Log every request and follow-up with dates.
3. **Not otherwise prohibited by the program's policy.** A program's own
   disclosure setting, or a stricter clause, supersedes the platform default.
4. **The fix is live**, where a fix was made.

Practical notes:

- Ask for disclosure consent explicitly once resolved, and propose your own
  redactions — approval is routine, not adversarial, and needs no justification.
- A report transferred between programs after resolution may sit under a different
  triage regime and its own disclosure terms. Confirm current handling before
  assuming the standard timeline.
- Some programs publish every report by policy (common for volunteer OSS). For
  those there is no disclosure step at all — the record is public from
  submission. Check before assuming a non-disclosure agreement binds you.
- **Confidentiality of the report itself is a governed boundary.** Some programs
  treat report contents as their confidential information with release solely at
  their discretion. Check the program's disclosure posture *before* submitting,
  because it governs what you may do with the finding afterwards.

## Post-Resolution Follow-Through

Being resolved is not the end of the engagement, and the remaining steps are
mechanical — but they are the steps that get a CVE assigned and a report
published, and they are routinely forgotten.

1. **Confirm the fix shipped**, in a release, not just a commit. Re-test the
   patched version if the finding was non-trivial.
2. **Confirm an advisory exists** and read what it actually says. Advisory text
   becomes the permanent public record of your finding.
3. **Check whether a CVE was assigned.** Advisories frequently read "No known
   CVE" — and the reason is usually procedural, not a judgement about the finding:
   the hosting platform acts as CNA for repository advisories, but **only an
   advisory administrator can submit the CVE request**. So address the admin
   specifically, note that you checked, cite the patched version, and ask. This
   is a one-message action that routinely takes weeks of queue time to resolve.
4. **Request report disclosure explicitly** once resolved, and propose your own
   redactions — approval is routine.
5. **Recognise when disclosure has effectively already happened.** If the
   advisory is public, the vulnerability's substance is public regardless of the
   report's status. Say so when requesting disclosure; it usually accelerates
   approval and it means the 180-day clock in `# Disclosure Lifecycle` is
   largely moot.
6. **Keep following up on the 30-day cadence** even after the fix, for anything
   still outstanding (CVE, disclosure, credit). Silence on the researcher's side
   can invalidate the last-resort clock.

Advocacy that works is patient, technically specific, and cites the mechanism
rather than applying pressure: check the thing yourself, explain who has the
authority to act, and ask once. Repeatedly re-asking without adding new
information reads as pressure and slows the maintainer down.

## Research Provenance Declaration
If any part of discovery, triage, or reproduction was performed by an automated
tool — language model, scanner, fuzzer, agentic harness — **declare it**, because
silence reads as a weaker claim and most programmes will discount a report whose
provenance they cannot assess. The pattern that works is a three-part statement:

1. **what the tool did** — "initial discovery was produced by an automated analysis",
   scoped to the specific stage, not the whole report;
2. **what a human verified** — "all technical claims were independently reproduced
   and revised by <named reviewer>", naming the review, not merely asserting it;
3. **who is accountable** — report on behalf of a named team or organisation, with
   the credit line you want, requested explicitly if the default attribution is
   wrong.

Say what a tool found; assert only what a human confirmed. A tool-generated
candidate that nobody reproduced is not a finding, and describing it as one is
worse than describing it accurately as unreviewed. Where a tool surfaced a large
candidate set, state the reviewed-versus-unreviewed count so the reader can calibrate
how much of the submission is unproven — an honest ratio reads as competence, and a
laundered candidate list reads as a padded report and is rejected outright.

Also fix the credit line **before** the advisory is written rather than after.
Projects without a reward programme treat accurate attribution as the deliverable
itself, so a late correction request against a published advisory is a real cost.

## Handoff

- Final report is delivered as the mission's `report/` artifact, referencing verification/triage/impact artifacts (a fully executed example exists in the mission archive; see the artifact checklist below).
- If the report reveals missing evidence, return the finding to verification — never invent the missing evidence (`../../../agents/reporting.md` §17).
- Reusable knowledge is written to `./knowledge/` (generalizable only).
- Report readiness is gated by triage (`../../../agents/triage.md`), and severity/impact is gated by impact analysis (`../../../agents/impact.md`).

## Related Skills

- `../../../skills/security-reporting/SKILL.md` and its `references/` (structure, title, reproduction, evidence, remediation, quality-check) — the authoritative reporting reference in the skills tree. **Note:** this `reporting-skill` in `methodology/` is the capability layer that orchestrates them; the `security-reporting` skill is loaded by the reporting agent.
- `../../../agents/reporting.md` — the reporting agent that consumes inputs and produces the report.
- `../../../agents/triage.md` and `../../../skills/security-triage/SKILL.md` — report-readiness gating.
- `../../../agents/impact.md` and `../impact-analysis-skill/SKILL.md` — severity/impact methodology.
- `../verification-skill/SKILL.md` — evidence standard (demonstrated vs inferred; differential proofs).
- `../access-control-skill/SKILL.md`, `../authentication-skill/SKILL.md`, and the class skills — so the report's claims match the tested methodology behind each boundary.
- `../../README.md` — the "Knowledge is not proof" core principle.

## Source / Derivation

- **Directly derived:** the pipeline and every report section (title, summary, affected asset, preconditions, reproduction, requests, expected vs actual, evidence, impact, root cause, remediation, quality check, report states, knowledge feedback, no-new-research) from `../../../agents/reporting.md`.
- **Directly derived:** severity-as-evidence rules and the demonstrated-vs-inference discipline from `../impact-analysis-skill/SKILL.md` and the Impact Agent; triage gating from `../../../agents/triage.md`.
- **Cross-referenced:** structure/title/reproduction/evidence/remediation/quality-check from `../../../skills/security-reporting/`; impact-class matrix from `../../index/attack-impact-coverage.md` (if present).
- **Illustrative artifact:** a fully executed mission report under `missions/<mission-id>/report/` (structure: mission report with header, compliance statement, executive summary, findings table, verified observations, evidence index, hardening notes, knowledge feedback, and sign-off quality check).
- **Source template:** `../../methodology/reporting.md` was an empty header-only stub; no verbatim body existed to migrate.
- **Added — `# Report Calibration Models`:** three publicly-resolved reports used
  as calibration anchors (one Critical positive model, one reclassified-from-SSRF,
  one closed-Informative). The disclosure lifecycle clock rule (180 days from
  formal *request*, 30-day follow-up, program policy precedence) is documented in
  `# Disclosure Lifecycle`; the platform default is HackerOne's last-resort
  guidance, and program policy overrides it. Recorded here because the clock is
  the single most commonly miscounted date in bounty work, and because the
  repository previously had no disclosure-lifecycle content in any layer.

## Coverage Boundaries

The current knowledge base does not yet contain a dedicated methodology for:

- **CVSS score derivation** (base/temporal/environmental vector computation is not documented). Severity here is reasoned from demonstrated impact classes, not CVSS — do not fabricate a vector. The calibration models in `# Report Calibration Models` reference public reports that *did* publish CVSS 4.0 reasoning; treat those as the author reasoning to be checked and reproduced, never as a template to copy. If a submission needs a vector, derive it from that report's own stated metric-by-metric reasoning and label it as the reporter's judgment, or state severity qualitatively.
- **Program-specific report formats beyond the generic structure** (e.g. a specific platform's submission template not present in this repository).
- **Mass/multi-finding report aggregation** (one-report-per-finding is the documented model; batching/prioritization of many findings is not documented).
- **Automated report validation tooling** (the quality check is a manual checklist, `../../../skills/security-reporting/references/quality-check.md`).