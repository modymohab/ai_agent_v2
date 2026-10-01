# Verification Methodology

## Core Concept

A finding is confirmed only by independent, reproducible evidence of a crossed security boundary — never by a single response attribute, a remembered payload output, or a status code alone. Every verification answers: what changed, for whom, and how do I know it wasn't noise?

## Security Boundary

Intended: testing activity leaves no false conclusions.
Violated when: ambiguous signals (generic 200s, error pages, client-only effects, unrendered positions) are reported as vulnerabilities.

## Recognition Patterns

- A 302 + `Set-Cookie: session` + redirect target naming the victim = authentication proof (stronger than any 200 body change).
- Account page rendering the identity (`Your username is: X`) = identity proof; the solved marker may live on a DIFFERENT surface (authenticated homepage vs account page — check both).
- Admin verdicts must show privileged FUNCTION (roster/delete links), never status alone (200-denial pages exist).
- Victim state change (user deleted, password overwritten, file bytes returned) beats response codes (302 ≠ effect; always re-read state).
- Error text that EMBEDS requested data (file bytes, credentials, query text) is exfiltration proof in one request.

## Common Locations

- `GET /my-account?id=<user>` (identity render + marker surface).
- `GET /` authenticated (marker surface — flips here in several auth families).
- `GET /admin` re-read after delete (victim-row absence + success message + marker).
- Inbox / access-log oracles (email arrival, exfil hits) for out-of-band flows.

## Indicators

- Password proof: exactly one 302 among N×200s, with session cookie + redirect naming the user.
- Oracle determinism: odd-one-out reproduces across re-requests (byte-exact for message oracles; median-stable for timing oracles with controls).
- Solved marker (`is-solved`/`Solved`/congratulations banner) on the appropriate authenticated surface.

## Testing Methodology

1. Reproduce the payload and confirm the result is deterministic (re-request the outlier; timing oracles need n≥6 plus controls).
2. Confirm the authorization context: which session, which identity, which redirect target.
3. Confirm resource ownership: the affected account/data belongs to the victim, not the attacker.
4. Confirm application-level result: render, roster, state change — not status codes.
5. Verify the resulting state by RE-READING it (account page, admin panel, homepage marker — each checked explicitly).
6. Rule out alternatives: caching (repeat requests), randomness (determinism runs), soft-404s, client-only effects, unrendered positions.
7. For CSRF-bound flows: token and session cookie from the SAME response, resubmitted as a pair; never mix jars with explicit `Cookie` headers (duplicates make results undefined).
8. For oracle scans: log BOTH hit shapes (302 AND warning-absence); fixed-outcome-only matching blinds alternative hit shapes.
9. **Differential patch control (the strongest available causal proof).** After
   confirming an exploit, re-run the *identical* proof against a build in which
   you changed **exactly one element** — the missing `--` terminator, the absent
   validator, the flipped permission. If the effect disappears while the normal
   path still succeeds, you have proven causation rather than correlation, and you
   have pre-verified the maintainer's fix before they write it. Always report both
   halves: `effect_present=True` and `effect_present_after_one_line_patch=False,
   normal_path_still_works=True`. This is strictly stronger than a benign-input
   control, which only shows the *trigger* matters and not the *mechanism*.
10. **Hermetic replica harness for self-hosted software.** When the target is
    software people deploy themselves, do not test a hosted or production
    instance. Rebuild the real product locally: official source distribution or
    image, **checksum-verified**; official container tag; ephemeral backing
    services (throwaway database, temp repositories); real integration tests
    against the real API surface; and self-cleanup of every container, network and
    file created. Ship the runner script as an attachment so triage can reproduce
    it unaided. This converts "trust my transcript" into "run this", which is
    why such reports get triaged in hours.
11. **Residual / incomplete-fix analysis (version-range archaeology).** When a
    prior CVE exists for the same class, the valuable finding is usually the
    **sink the fix missed**, not a new class. Method:
    - Identify the exact prior fix (PR/commit/advisory) and the version that first
      contained it.
    - Enumerate every call site of the same dangerous primitive and diff the fixed
      set against the full set. The gap *is* the finding.
    - Anchor the range precisely: the residual is affected from
      `<fix version>` onward, even if the underlying sink predates it. State the
      pre-fix range as already covered — do not re-report it, and do not let the
      range slide.
    - Prove it against the **first** fixed version, the **latest** release, and
      **current main**, so the claim survives "we thought that was fixed."
    - Check for an existing public report on the missed sink before claiming it;
      if none, say so explicitly — that is what justifies a *new* CVE rather than
      an addendum, and it is what gets one assigned.

12. **Climb the verification ladder, then declare which rung you reached.** For any
    finding that turns on what a *framework or runtime* does with your input
    (URL parsers, request dispatchers, template engines, deserializers, CLI
    argument handling), the library call is not the end of the proof. Progress
    toward the layer that actually acts:
    1. the library in isolation (both implementations, side by side, same input);
    2. the framework's prepared/normalized object (e.g. a `PreparedRequest`);
    3. the resolved destination/handle the framework derived from it;
    4. a live observation at the boundary (socket, file, process, packet capture).
    Then **state which rung you reached and what remains unproven.** A finding
    verified to rung 3 with rung 4 unperformed is a real, payable finding — but
    only if the report says so plainly and supplies the remaining steps for the
    reviewer. Overclaiming past your rung is the same error as under-verifying.

13. **Measuring algorithmic complexity (ReDoS / parser-DoS) — measure the
    target's own grammar, never a reimplementation.** A reproduction that
    retypes the grammar is worthless: the first objection will be "that isn't the
    target's parser." Instead, extract the *exact* definitions from the target's
    own source and execute them:
    - Pull the real source text of the grammar/parser construction and any
      supporting expression classes out of the target's files (e.g. with
      `ast.get_source_segment` / `inspect.getsource`), then `exec` them against a
      namespace containing only the library symbols they need. The parser under
      test is then provably the target's.
    - **Pin both ends:** the exact commit under test, and the exact library
      version taken from the project's own manifest or lockfile — not whatever
      `pip` resolves today. Grammar performance is version-sensitive, so an
      unpinned library invalidates the measurement.
    - **Swap terminal parse actions for counters.** Parse actions do real work and
      can dominate or distort a timing measurement; replacing them with a counter
      proves the cost is in the *parser*, not in the instrumentation or in
      successful evaluation.
    - **Include a failing-parse payload family.** A short input that *fails* to
      parse (unbalanced delimiters) yet still burns CPU proves the blowup is
      backtracking, not result construction. This is the cleanest available
      evidence and almost nobody tests it.
    - **Report the growth ratio and the smallest payload crossing each
      threshold**, with byte length: e.g. ">1s at n=6, len=13" and ">10s at n=8,
      len=17", plus the derived complexity ("≈4× per level ⇒ O(4ⁿ)"). A single
      duration is unfalsifiable; a ratio and a threshold table are checkable.
    - **Defeat result caches explicitly.** If an `lru_cache` fronts the expensive
      operation, identical payloads may be free. Vary the input trivially (change
      one trailing character) and say so — otherwise impact is overstated.
14. **Measure amplification at the shared-resource boundary, not just the cost.**
    A slow operation is not yet a denial of service. If the expensive work runs
    under a lock, in a shared worker, or against a bounded pool, then measure the
    *victim*: run unrelated benign operations concurrently and report their
    before/after latency. "Four unrelated queries went from 0.75 ms to 52.8 s
    (≈70,000×) while one attacker request was in flight" is impact evidence. "The
    lock is held for 52 s" is an assertion about impact.
15. **Deployment reality check before asserting a deployed product is
    vulnerable.** Offline and component-level measurements can overstate
    deployed exploitability, because a mitigation you did not enable may already
    be active in the real configuration. Before claiming the shipped product is
    affected, confirm the mitigation is genuinely off at runtime:
    - **Library defaults** may differ from the version you pinned, or may have
      changed between the affected release and now.
    - **Import side effects from unrelated transitive dependencies** can silently
      enable the exact feature whose absence you are relying on (a plotting
      library enabling parser memoization on import is a real, observed case).
    - Whether the **deployed lockfile** matches the one you tested, and whether
      the vulnerable code path is actually reached in the default configuration.
    A report that says "feature X is never enabled" is making a claim about a
    *running system*, and it is falsifiable. Check it, or scope the claim to the
    grammar and say the deployment was not confirmed.

16. **Audit credential *pairing*, not credential *sources*.** A secret's origin
    does not protect it when the *destination* is untrusted, and both halves
    usually look fine in isolation — the environment variable looks safe because
    it is a secret, the config file looks dangerous because it is writable. The
    vulnerability lives in the combination, so the analysis unit is the tuple, not
    the field. For every credential path, enumerate explicitly:
    - **secret source** — CLI flag, environment variable, config file, keyring,
      OS credential store;
    - **destination source** — the same set, plus anything discovered from the
      environment (a config file found by walking the working directory, a remote
      value, a manifest in the repository);
    - **whether the destination is bound to the secret's origin** — this is the
      only question that matters, and the answer is usually "no" somewhere.
    The productive reframing: never ask "is the secret well protected?" Ask **"what
    determines where this secret is sent, and who can influence that?"**
17. **Treat environment variables as configuration inputs, not trust anchors.**
    An env var is routinely treated as safe because it is a secret — but in the
    threat model an attacker influencing CI, a container, a self-hosted runner, or
    a co-tenant process can often influence environment contents even when they
    cannot read them. `*_KEY` / `*_TOKEN` are therefore in the *untrusted* class
    whenever the paired destination is influenced by a lower-trust input. Sweep
    the adjacent namespace too: proxy variables, service `*_ENDPOINT` /
    `*_URL` / `*_REGISTRY` overrides, and CA-bundle paths are the same shape of
    bug and are routinely missed.
18. **To find a bypass of an existing control, enumerate the control's escape
    hatches — do not ask whether the control exists.** Once you find a security
    property the code already enforces (credentials keyed by origin, arguments
    terminated with `--`, URLs normalized to one base), the productive question
    becomes: *list every path that produces a credential or a request, then check
    which of them bypass that property.* Observed: a properly origin-keyed
    credential store coexisted with an unscoped environment-variable path that
    returned the secret for any destination. The hardening was real, complete in
    intent, and bypassed in one branch.
19. **For self-hosted tools, treat the working directory as attacker-controlled
    input.** Any config discovery that walks the working directory or its
    ancestors, reads a manifest inside the repository, or auto-detects a project
    root makes the *checkout location* part of the threat model. Ask what a
    malicious pull request, a cloned untrusted repository, a nested dependency, or
    a planted file in any parent directory can plant — and remember that in CI the
    checkout directory is exactly where untrusted contributions land.

## Verification

- **Source-only findings: three separate claims, three separate evidence bars.**
  When a finding rests on reading code rather than observing behaviour, keep these
  apart, because they are usually asserted together and only the first is proven:
  1. **The defect is real** — settleable by reading the code. A bounded-write call
     whose size argument exceeds the buffer's remaining capacity is a defect on its
     face; no execution is required.
  2. **It is reachable** — requires showing attacker-influenced data actually
     arrives at the call. This is the claim most often skipped, and it is the one
     that decides the finding. Ask what bounds the value *before* it gets here: a
     parser-side length cap, a protocol field limit, a validation layer, or
     nothing. If something upstream bounds it, the overflow may be unreachable and
     the honest conclusion is defence-in-depth. If nothing bounds it, say so
     explicitly — that is usually the finding.
  3. **It is exploitable** — a memory-safety defect is not automatically code
     execution. Mitigations (stack canaries, ASLR, DEP/NX, pointer authentication,
     guard pages, control-flow integrity) sit between "overflow" and
     attacker-controlled execution, and whether they are present and effective is a
     property of the **shipped build**, not of the source.
  A title asserting remote code execution is asserting claims 2 and 3 with no
  evidence for either. "Remote crash" is the defensible claim from source alone;
  code execution is a hypothesis to test or to label as one. Fold these into the
  *Observed / Demonstrated / Inferred / Theoretical* ladder in
  `impact-analysis-skill/SKILL.md` rather than asserting a single verdict.
- **When you cannot reproduce, the useful ask is a question, not a bigger claim.**
  State the defect precisely, name the invariant it violates, present reachability
  as unproven, and ask the vendor to confirm whether anything bounds the value
  upstream and whether the call path is reachable. That is answerable in one line
  and converts an assertion into a question — whereas escalating severity without
  new evidence invites closure on the weakest claim in the report.
- **The bounded-format size-argument invariant (recognition rule for source
  review).** When writing into a fixed buffer at a running offset, the size
  argument must be the **remaining** capacity from the current position, never the
  total capacity. `swprintf(buf + off, TOTAL, ...)` and `snprintf(buf + off, TOTAL,
  ...)` authorise writes up to `TOTAL` elements *past* `buf + off`; inside a loop
  that authorisation grows with every iteration while the buffer does not.
  - Greppable signature: a bounded-write call whose second argument is a literal
    buffer size, or a constant equal to the buffer's declared size, where the
    destination is `buffer + <running variable>`. Correct-looking offset arithmetic
    is *not* evidence the bound is enforced — bounded-format functions return the
    count written **excluding** the terminator, so an offset accumulated from the
    return value tracks correctly while the authorisation passed alongside it is
    still wrong.
  - **Units trap:** the size argument counts *elements*, not bytes, so byte-level
    overflow scales with element size and therefore differs per platform for
    identical source — 16-bit and 32-bit `wchar_t` builds of the same routine
    overflow to different depths. State the unit you are reasoning about.
  - The same shape recurs in `strncat`/`memcpy` with a running offset and in
    hand-rolled delimited-string builders, which is where this pattern usually
    appears.
- Meta-rule: verification itself must be independently re-performed (second session, second surface), not copied from the discovery request.
- Dual-surface marker check (account page AND homepage) is mandatory in auth families — marker location varies per instance.
- Dual-session proof for credential findings (Burp + CLI independent sessions).
- **Preempt the standard triage objection, don't wait for it.** For every RCE or
  privilege finding, the first question is "is this admin-only?" Answer it inside
  the report: state the *minimum* privilege that reaches the sink and show the
  negative facts too (`superuser=False, staff=False, elevated_flag=False`). For
  every data-exposure finding, answer "whose data?" with the ownership argument.
  A report that closes its own objection triages faster and survives contact with
  a skeptical reviewer.
- **Bound your own claim.** State what you did *not* achieve (no root, no
  third-party data, no production instance) and what you did not test. A bounded
  claim is a stronger claim; an unbounded one invites a downgrade when triage
  finds the real ceiling for you.

## Pre-Promotion Gates (run before a candidate leaves `candidate`)

A candidate is not promoted because the code looks wrong. It is promoted only after it
clears every gate below. These gates are cheap, and the entire point is to run them
*before* the expensive work. Reading the exclusions after investing a day in a proof of
concept is how a complete, correct, well-evidenced investigation ends up describing a
class the program excluded by name in its first line of policy.

### Gate 1 — Read the live exclusion lists, in both layers

Exclusions live at two levels, and checking only the obvious one is the common miss.

1. **Program-specific exclusions.** The security page / bug-bounty policy, read as it is
   *currently published* — not a cached copy, not your memory of it from a previous
   session, not an archived snapshot. Programs rename, retire, and add exclusions
   frequently, and the current text is the only binding version.
2. **Platform-standard exclusions.** Many bug-bounty platforms ship a shared list of
   findings that are out of scope for *every* program unless the program explicitly says
   otherwise. Where a program links such a list, it binds exactly as a program exclusion
   does. Read it once and carry it; it recurs across targets and it is not obvious.

Both layers are cheap to read and expensive to discover late. Record the URL, the date
you read it, and the specific wording of anything that touches your candidate — quoted,
not paraphrased, because the exact phrasing is what determines scope.

**Scope confirmation is a separate obligation from exclusion checking.** If you could not
read the scope table, say "unconfirmed" — do not record it as "out of scope", and do not
record it as confirmed either. Some scope tables are client-rendered and will look empty
to a plain fetch while being perfectly readable in a browser; treat an empty fetch as
"retry with a real renderer" before concluding anything. A blocker written down as a
permanent property of the target will outlive its own cause and silently strand the
mission.

#### In scope is not the same as alive — precheck liveness with passive DNS

A scope table is static documentation of what *was* true when someone last edited it.
Assets get decommissioned, renamed, and migrated, and the entry usually lingers for
years. Before you build a plan around an in-scope asset, spend one cheap command
confirming it still resolves.

Read the table's **staleness signal**: most scope tables carry a per-row last-updated
date. A row whose service has not been touched in many years is a row whose asset may
long since be gone, and the overall table being "last updated" recently says nothing —
individual rows drift independently.

A passive DNS resolution sweep across the candidate assets is the highest
cost-to-information probe available: no target traffic, near-instant, and it collapses
or confirms the entire plan before a single request is sent. In practice, sampling the
in-scope assets of one program found **12 of 14 already NXDOMAIN** — including the asset
the whole plan had been built around, and including every sibling endpoint the intended
technique depended on. The work stopped at zero requests to the wrong host and the
method was never wrongly validated.

Two habits follow. Resolve the asset **and every sibling the technique depends on** —
a method that needs a sibling set dies with the first missing sibling, and you only
discover that at the point of use. And confirm a negative from more than one resolver,
or read for an authoritative `NXDOMAIN` in the `AUTHORITY` section, so that a local
cache artefact is not mistaken for a decommissioned asset and the reverse. Record the
outcome as one of *in scope and alive*, *in scope but unresolvable*, or *unconfirmed* —
never collapse the middle case into the first.

#### Liveness is layered — report the layer you actually reached

A DNS answer is not reachability. Treat the layers as separate findings and report
which one you got to, because each failure means something different and has a
different remedy:

| Layer | Test | Failure means |
|---|---|---|
| DNS | resolves to an address | asset decommissioned — report is dead on arrival |
| TCP | connect completes | network filtering, or wrong port |
| TLS | `ServerHello` arrives | source allowlist, or an mTLS listener dropping clients with no certificate |
| Application | HTTP status and body | a real, in-band observation you can reason about |

The TLS layer deserves particular care because it is **ambiguous by construction**: a
handshake that opens and then produces nothing is consistent with several unrelated
postures — a source-IP allowlist, a mutual-TLS listener, or a listener that is simply
not configured. Do not guess which. And when a handshake fails, prove the failure is
the target's rather than your own tooling: complete a handshake against an unrelated
public host in the same run and keep the result as a control. Without that control, a
client-side TLS problem is indistinguishable from a target-side one, and the whole
finding can invert.

**In-scope and eligible is not the same as publicly testable.** An asset can be listed
In scope, Critical, and bounty-eligible while being operationally unreachable from the
public internet because of a network control or a client-certificate requirement. That
is a scope-freshness problem as much as a reachability one, and it is common enough to
check deliberately rather than assume away. When it happens, the honest verdict is a
**coverage gap**, and the distinction to hold onto is: *absence of observation is not
evidence of absence of divergence.* Say what you could not see, not what you concluded
about it.

#### A scope table is not internally consistent — read the row, never the convention

Assets that are siblings by name are frequently *not* siblings by policy. Development,
staging, and acceptance entries can point in opposite directions for different product
families in the same table: one family's `*.development` host may be explicitly
**out of scope / ineligible** while a neighbouring family's `*.development` host is
in scope and bounty-eligible. The naming convention is not the policy; the row is.

The failure this prevents is specific and expensive: a researcher reasons by analogy,
"this dev host is excluded, so that one is too," and either wastes effort on an
ineligible asset or — worse — declines to test an eligible one. Never generalize scope
from a sibling's scope. Read the row, quote it, and record the quote.

### Gate 2 — Check what already exists, before writing anything up

Before investing in a writeup, answer two questions:

- **Is this class, or this specific asset, already covered by an existing candidate,
  known issue, or previously-closed report in this mission?** Search the candidate
  register and the report archive. Multiple endpoints or instances of one flaw are one
  root issue, not several findings.
- **Does an existing candidate dominate this one?** A candidate is *dominated* when a
  broader one already establishes the same root cause, and a report for it would be
  closed as a duplicate. The narrower observation may still be worth *recording* — it is
  evidence, and it can be a building block for a later chain — but it is not worth
  filing, and conflating "worth recording" with "worth filing" is what produces a
  duplicate on someone's program.

**Record supersession explicitly.** When a candidate is closed because another one
dominates it, say so in the register and say *why*. When a candidate is later closed
because it turned out to be excluded by name, the earlier dominance reasoning should be
demoted to traceability and the name-based exclusion promoted to the controlling
rationale. Two independent reasons for a close is normal; recording only the weaker one
means the next session may try to reopen it on the stronger-but-wrong theory. An
out-of-scope determination is not weakened by the fact that the bug is also
low-impact — both hold at once, and the scope reason is the one that survives.

### Gate 3 — Confirm the band is survivable before you build the writeup

Ask, before the deep work: **if this is confirmed, what is the best realistic severity,
and is that band paid at this program?** Two failure shapes are worth screening early:

- **Self-exploitation.** Behaviour that a user can only trigger against their own
  session, own browser, or own data is normally treated as ineligible regardless of how
  elegant the code defect is. Platform-standard lists usually name this explicitly, in
  terms like "self-XSS" or "self-DoS", and often attach a single exception: *unless it can
  be used to attack a different account or a different user*. That exception is the whole
  ballgame. Ask immediately: **is there a genuinely different principal on the other side
  of this?** Same-origin code reading the same user's own storage is self-exploitation no
  matter how sensitive the material; the same material reachable by a *different* origin
  is a real finding. Do not confuse "the secret is valuable" with "the attacker is
  different" — those are independent properties, and conflating them is the standard way
  a well-evidenced finding becomes an invalid one.
- **Best-practice-only findings.** Missing headers, hardening steps, configuration
  opinions, version or banner disclosure, descriptive errors, missing cookie flags, and
  similar items are typically closed as invalid absent demonstrated security impact. If
  the honest answer to "what can the attacker actually do with this?" is "nothing beyond
  deviating from a recommendation", the finding is not a finding. Impact, not
  recommendation, is what makes it submittable.

### What the gates are not

The gates are a *filing* filter, not a *vulnerability* filter. Failing a gate does not
mean the code is correct. A cross-origin message handler with no origin check is still a
real code defect when the program excludes that class — record it, keep the evidence,
and say plainly that it is not reportable. Conflating "we must not file this" with "this
is not a bug" is its own kind of error: the first is a program-policy judgement, the
second is a claim about the target's code, and only the second one is the researcher's
own to make. Keep both statements, separately sourced.

## Common Failure Modes

- Treating 200 status as proof (200-denial pages, unrendered UNION positions, locked-account responses all return 200).
- Treating 302 as effect (redirect ≠ state change — re-read the target).
- Treating stored knowledge as proof (prior lab's password/user/mint vector reused as answer instead of hypothesis).
- Normalized comparisons destroying single-byte oracles (strip/collapse/`$(...)` capture).
- Single-sample timing conclusions (jitter mistaken for signal — medians + controls required).
- Polling a block/lock to check expiry (extends the window — silence or identity-switch instead).
- Reporting from the discovery session only (no independent reproduction).
- **Re-run the whole probe family when verifying a fix, not just the payload you
  originally used.** Fixes are rarely atomic, and a rejected original payload is
  compatible with several very different outcomes. For injection specifically,
  test each rung separately:
  - the **tautology pair** (does the injected condition still control the result?);
  - an **engine-fingerprint subquery** (does arbitrary subquery execution survive?);
  - a **time-based delay** (is statement termination still available?).
  A partial fix that neutralises the quote — escaping instead of parameterising, or
  fixing one parameter of several identical ones — will kill the original payload
  while leaving the class live. Ask specifically: **was the injection itself
  removed, or was only its escalation path removed?** Disabling stacked queries or
  tightening a connection string *narrows* the finding without closing it, and a
  report that confirms "the fix works" without distinguishing the two has verified
  less than it appears to. When the maintainer's stated fix is a mitigation rather
  than a root-cause fix, re-test the primitive.
- **Do not delete evidence from a live report thread** when redacting is the goal;
  see `reporting-skill/SKILL.md`.
- **"I can no longer reproduce it" is not "I verified the fix."** These are
  different claims with different evidence behind them, and researchers conflate
  them at exactly the moment they are most congratulatory. A rejected payload is
  ambiguous by construction: the endpoint may now validate input, or it may now
  reject your *request* for an unrelated reason (auth change, WAF rule, field
  rename, rate limit, a queue that stopped accepting anonymous submissions). None
  of those establish the original defect is fixed. Conversely a *rejected payload*
  is not evidence the vulnerability is gone even when the maintainer says it is —
  it is evidence the observable changed.
  State which one you mean. "The submission endpoint now rejects the payload;
  I have not independently confirmed the back-office encoding path, so I am
  treating the maintainer's statement as authoritative on the render side" is
  honest and is still a useful confirmation. "Confirmed fixed" is not, unless you
  actually re-tested the defect's mechanism. A maintainer asking you to verify is
  asking about the *observable*, and saying yes to a request is a social
  obligation, not a technical finding — see `agentic-research-skill/SKILL.md`
  for why deference to a program's closing request is its own risk.
- **Trusting a verification script that was never itself verified.** The recurring
  failure in automated checking is not a wrong answer — it is a *confident false
  signal* from a check whose logic cannot detect the thing it claims to. Patterns
  that have each produced a false pass in practice:
  - **A check that never ran, reported as a pass.** This is the most dangerous
    variant, because it manufactures evidence rather than merely failing to find
    it. The idiom `if grep -q PAT $FILES; then <hits> else <clean>; fi` treats
    *every* non-zero exit as "no matches" — including exit ≥2, which is grep
    reporting an error (unreadable path, bad option, a filename that does not
    exist) rather than an absence of matches. The result is a confident "clean"
    produced by a command that examined nothing. Distinguish the three outcomes
    explicitly: `0` = matched, `1` = genuinely no match, `≥2` = the check did not
    execute and its result is void.
  - **A file list built by variable expansion, where the shell does not
    word-split.** `grep PAT $FILES` is portable only in shells that split
    unquoted expansions. Under zsh (the default here) an unquoted `$FILES`
    arrives as a *single* argument — one path containing spaces — so grep errors
    with "No such file or directory" and, combined with the case above, yields a
    clean result having read zero files. Use an array and `"${FILES[@]}"`, or
    write the paths inline / use globs. Never assume a bash assumption about
    splitting holds in the shell actually running.
  - **A regeneration script whose file set is broader than its intent.** A script
    that rebuilds `topic.md` from `topic-skill/SKILL.md` is a *write*, and writing
    carries a different risk from checking: it can silently destroy a file whose
    canonical status is deliberately different. Observed: a loop meant to refresh
    two legacy mirrors also matched a topic whose `.md` is intentionally an
    unimplemented stub, overwriting the 25-line placeholder with 355 lines of
    skill content. The architecture was correct and the damage was invisible to
    every content-level check.
    Discipline: **regeneration scripts must carry an explicit exclusion list**,
    never a positive list broad enough to sweep neighbouring topics, and must
    refuse to write any file matching the stub signature. Pair every write script
    with a post-write invariant assertion over the files it must *not* have
    touched (here: `5/5 stubs match their recorded checksum`) and run it on every
    invocation. Checksum invariants over protected files catch this class
    immediately; content greps over the files you edited will not.
  - a **tautological predicate** — `ls FILE | grep -qxF FILE` "verifies" that a
    file exists, and will equally "verify" a file that should not be there;
  - a **pattern that cannot match the format of the text it searches** — a
    single-line grep against prose that wraps across lines, reporting absent
    content that is present two lines down;
  - a **path built after the working directory changed**, silently testing
    nothing;
  - a **count compared against a remembered number** rather than an independent
    source of truth;
  - a **sweep whose pattern is over-broad in the safe direction** (searching for
    a universal constant, or for an identifier class the corpus legitimately
    contains), which hides real hits in the noise.
  Discipline, in order: confirm the check **executed** (exit 0 or 1, not ≥2) and
  confirm it **can fail** (point it at a known positive and confirm it flags).
  Both are required before its output means anything. A verification step that has
  never been shown capable of failing — or never shown to have run at all — is not
  evidence, and "no issues found" from such a step is the most dangerous possible
  output, because it is indistinguishable from a real clean result at a glance.

## Impact Considerations

- Severity from demonstrated effect only: Observed vs Demonstrated vs Inferred vs Theoretical (per skill impact-analysis reference).
- Authenticated session + identity render is the minimum bar for account-compromise claims.
- Eternal/persistent primitives (year-3000 cookies, stateless forgeries) outrank session-bound ones — note lifetime explicitly.

## Lessons Learned

- From PortSwigger “Username enumeration via different responses”: marker flipped on authenticated HOMEPAGE, not the account page — both surfaces checked before concluding (applies across auth families since).
- From PortSwigger “2FA broken logic” instances: dual-session 302 proof + newest-email-only validity + mint-before-scan discipline.
- From PortSwigger JWT labs: body-content verdicts (roster/links) over status codes; victim-row absence as deletion proof.
- From PortSwigger XXE labs: reflected file bytes in error text as one-request exfiltration proof.

- **Exemplary verification, public program (self-hosted software, command
  execution, triaged in hours, CVE assigned).** A residual argument-injection in a
  version-control wrapper: repository-controlled filenames were passed to the VCS
  binary without an option terminator, so a filename beginning with `-` was
  parsed as a command-line option, and a **config-defined command alias**
  (the `--config=alias.<name>=!<cmd>` shape common to VCS and build tools that
  support command aliases) replaced the intended subcommand with a shell alias.
  The escalation from "argument injection" to "command execution" is the
  generalizable part — check whether the invoked tool can alias its own
  subcommands. The proof is the part worth copying:
  - **Command execution shown as an identity, not an inference.** The result was
    `execution_identity='uid=1000(svc)…'`, read from a researcher-created
    synthetic file. Not a parser error, not reflected input, not an inferred
    "this should execute."
  - **The one-line patched control.** Re-running with a single added `--` in the
    argument list produced `effect=None, execution_identity=None` while the
    normal update path still completed. That is the whole finding proven causal
    in one run — and it *is* the recommended fix, verified before the maintainer
    wrote it.
  - **A benign control too** (a well-formed control file completed normally with
    neither controlled output), separating "the path runs" from "the payload
    fired."
  - **Privilege preemption inside the report** (`superuser=False, staff=False`)
    rather than waiting to be asked whether it needs admin.
  - **Hermetic replica, checksum-verified:** official sdist + SHA-256, official
    container tag, ephemeral database, four real integration tests, full cleanup,
    runner script attached.
  - **Explicit scope self-limitation:** the adjacent add-on-permission gap was
    disclosed as reachability evidence and explicitly *not* filed as a second
    vulnerability.
- **Accidental mitigation is not a fix (public program, self-hosted software,
  resolved via explicit hardening).** An unauthenticated parser-DoS was reported
  against a search-query grammar with exponential backtracking, amplified across
  all users by a process-global lock. The maintainer's investigation found the
  vulnerable condition was **no longer reachable**, because an unrelated
  dependency added for a different purpose enabled the parser's memoization as an
  import side effect — so the exposure had been silently removed without anyone
  deciding to remove it. The maintainer still hardened it explicitly.
  Two lessons, and they point in opposite directions:
  - **For the reporter:** a component-level measurement proves the *grammar* is
    exponential, not that the *deployment* is exploitable. See Testing Methodology
    step 15. Checking the real dependency graph would have produced a sharper
    report — "historically exploitable, now accidentally mitigated, and fragile
    because the mitigation depends on an unrelated transitive package" — which
    earns the same fix with better framing and a defensible severity.
  - **For triage and remediation:** never accept "it happens to be mitigated" as a
    resolution. A mitigation that exists only because an unrelated dependency
    enables it on import is one dependency bump, one deprecation, or one
  `pip uninstall` away from re-exposing the bug, and nobody owns it. The correct
    outcome is to make the control explicit and intentional, and to record *why*,
    so the next person to remove the innocent-looking dependency discovers the
    consequence. Closing such a report as "not a vulnerability" teaches everyone
    that accidental mitigations are sufficient.
- **Consequence of getting the boundary wrong in either direction:** a report that
  overstates (claims admin-only impact that is actually project-scoped, or claims
  root without testing it) gets downgraded, and a report that understates its own
  demonstrated primitive gets triaged slowly at the wrong priority. The
  differential patch control plus an explicit bound fixes both at once.

### Version-claim provenance: prove you ran every version you name
Naming additional affected versions is one of the highest-yield moves available —
it is what turns a single-instance report into a release-blocking one — and it is
also the easiest claim to fabricate by accident. The failure mode is not lying, it
is re-testing the environment you already have and recording the result as a second
observation.

- **A file and line citation is not evidence that you executed that version.** It
  is evidence that the code *reads* as vulnerable in the version you fetched. Every
  additional version you name must be backed by a **runtime** observation in an
  environment that is provably that version.
- **Record a distinguishing fingerprint per version, before you test.** A version
  banner, a server-generated footer, `version_compare()` output, an admin
  about-screen string, a release-note identifier, or a hash of the file you cited.
  If you cannot name an observable that would have *distinguished* the two
  environments, you do not have two environments — you have one and a belief.
- **Self-audit the claim before submission:** for each version listed as affected,
  point to the specific observation. If any row's evidence is a code reading rather
  than a run, delete the row or re-test it. A false multi-version claim costs far
  more than a narrow true one: it converts a credible report into one whose
  every other assertion is now suspect, and it hands the triager a reason to
  discount the finding that actually reproduces.
- **Retraction is cheap if early and expensive if late.** Disclosing that you
  misattributed a version — promptly, in your own words, without being asked — is
  routine and does not damage the finding; the triager's job is to establish truth,
  and a reporter who corrects themselves is making that easier. Apologise for the
  wasted time once, plainly, and do not relitigate it in later threads.
- **Ask the triager's version question back at yourself first.** "Can you confirm
  version X is not affected?" is the single best triage question for a
  release-scoping dispute, because the answer bounds the CVE, the backport
  decision, and the severity. Answer it yourself before you submit.

### Proving an ordering violation: assert the violation AND the guard
An ordering bug — verification completing after the action it should gate, a state
flag set before the state it describes exists, a cleanup that runs after the value
it should clear — cannot be shown by a narrative. The reader cannot tell sequence
from prose. Assert **both** conditions mechanically and let the script fail if
either does not hold:

- **the violation occurred** — the thing that must not happen, happened, and is
  observable by the attacker or in captured output;
- **the guard did fire** — the check that should have blocked it did run and
  produced its failure signal;
- and therefore **both are true in the same execution**, which is what makes it an
  ordering bug rather than a missing check or a disabled feature.

Report the two conditions as named booleans the harness prints, not as a
description. A PoC that emits
`leaked=yes verify_failed=yes exit=60` is self-evidencing: a reader sees the
disclosure *and* the rejected handshake in one line, and can see that the guard
firing is not the same thing as the guard preventing. Note what a correct result
looks like: after the fix, the harness must fail on the *violation* condition while
the guard condition still holds. If your harness passes both before and after, it
is not measuring the bug.

### Every disclosure claim needs a pre-fix and post-fix observable
For any claim that data was disclosed, a guard was bypassed, or a control failed,
state the observable difference, concretely, in both directions:

- **pre-fix:** what the attacker or observer can see, with the exact location —
  which header, which field, which process, which log line;
- **post-fix:** what they see instead — usually the guard's error, and the absence
  of the payload.

This is also the sharpest question a triager will ask, in the form *"what exactly is
X leaking that it no longer does when this is fixed?"* A report that can answer it in
one sentence has a finished impact section; one that cannot will be sent back for
clarification. It simultaneously forces you to check that the "fix" actually
inverts the observable — a patch that changes an error code but still delivers the
bytes has not fixed the claim you made.

**Distinguish what was demonstrated from what was deliberately not.** If your PoC
shows request bytes reaching an unverified peer but the client correctly refuses the
response, say both. A disclosure with no response acceptance is a *different and
weaker* finding from a full man-in-the-middle, and stating the boundary is what
makes the severity discussion honest rather than inflated.

### Verify the fix with the same PoC, against the fix branch
The gold standard for confirming a fix is: **the same harness, the same assertions,
the fix branch, and an inverted result.** This is stronger than reading the diff,
because it exercises the actual code path rather than the author's description of
it, and it is stronger than re-running against a release build, because it isolates
the patch from everything else that changed.

State this explicitly in the thread once the fix is proposed — "tested the fix
branch with the same PoC; confirmed the issue no longer reproduces" — because it
converts an open question into a closed one and it is the fastest path to a triager
picking the report up after a delay. A report that only *reads* correctly at the
diff still leaves the reviewer to guess whether the test they would write is the one
that fails.

### Find an observable that reveals internal state continuity
When a finding is "state leaked, persisted, or was not cleared", external output
alone may be ambiguous — the second request looks like the first because the value
is simply the same. Look for an **internal-state tell that leaks into the
observable protocol**: a counter that increments across the boundary, a sequence
number that does not restart, a nonce or client nonce that repeats, a connection
handle, a negotiated identifier, a timestamp that spans both operations.

The tell converts an inference into a demonstration: a nonce-count that advances
from the first origin's request into the second origin's request is *proof* that one
in-memory structure survived the boundary, observable from outside the process. The
same class of tell covers pooled connections, cached TLS sessions, sticky auth
state, and any handle that is documented to be reused.

### Before claiming a control "failed", establish what it was designed for
The most common overstatement in defence-in-depth findings is treating a narrow
legacy control as a comprehensive one and then reporting its absence as a
vulnerability. Classic case: a content scanner whose stated purpose is to stop a
legacy browser's MIME sniffing, which scans a short prefix because sniffing happens
early — described in a report as "the complete failure of the scanner" and proposed
to be fixed by scanning the whole file.

That proposed remediation is a *category error* in the other direction: scanning an
entire file does not address MIME sniffing, and it changes the control's cost profile
to solve a problem it was never assigned. Before writing "the control failed":

- find and quote the control's **stated purpose**, from its own documentation, its
  commit message, its tests, or a maintainer statement;
- decide whether the threat you are reporting is **inside that purpose**;
- if it is not, the finding is not "the control failed" — it is either "no control
  covers this threat" (a hardening request, correctly framed) or, better, **a
  different control is missing entirely** and that is where the vulnerability is.

Watch for the same move in file-type validation, rate limits, referer checks, input
length caps, and legacy browser workarounds: all are commonly scoped to a threat
narrower than "security", and claiming they were defeated generally invites a
correct and confident rebuttal that costs you the report's credibility.

**The most valuable signal that you have mis-scoped the root cause: the vendor
fixes something you did not report.** When a maintainer identifies a defect in a
different component than the one your report blamed, that is a finding you missed,
not a disagreement to argue. Treat it as new evidence, re-open the root-cause
question, and check whether your exploitation chain depended on the component you
originally named — it usually did not, and the corrected root cause is both more
accurate and more likely to be fixed durably.

### Prove a missing control is a defect, not a design decision
"Input is not escaped here" is an observation. "They intended to escape input here and
missed" is a claim, and it is the claim that survives triage. The cheapest way to earn
it is to find the control's **siblings in the same code path**:

- Read the entire statement, not the fragment that matters. If the same function call
  escapes four of five interpolated values and leaves one raw, the omission is
  demonstrable inconsistency, not policy.
- The same shape recurs across classes: only the argument that *is* the sink is left
  unescaped in a build where its neighbours are escaped; only the one field that
  reaches the vulnerable path is skipped by a sanitizer that runs on every sibling
  field; a session handle leaks across origins where the leak shows up only for
  requests that actually carry the prior credentials.
- State the finding as: *the control is applied inconsistently, here is the line where
  it is applied, here is the adjacent line where it is not.* A triager cannot argue
  with two adjacent lines, and the argument does not depend on your CVSS opinion.
- Corollary: if you **cannot** find such a sibling, be suspicious that the omission was
  intentional. Say "no control covers this" (a hardening request) rather than "the
  control failed".

### A stored or deferred trigger is a chain — prove every edge
When a value is persisted and executed later, the write and the execution are separate
events, and the interesting claims live in the gap between them. The report "the payload
is accepted, the command will run at the next backup" has demonstrated **one** edge of
four. Name the chain and mark each edge *Demonstrated* / *Inferred*:

1. **Acceptance** — the request is accepted without rejection or neutralisation.
2. **Persistence** — the value survives the round trip. Prove it by *reading it back*
   (`update_option` → `get_option`, DB row → subsequent fetch). In-memory-only
   inference from the code is not persistence evidence.
3. **Retrieval on the trigger path** — the trigger actually reads that stored value.
   Enumerate the trigger set (manual button, cron, AJAX, queue worker, retry) and show
   which ones you exercised; a value can be stored and never reach the sink because the
   trigger builds its command from a different source.
4. **Execution** — a command actually ran. A PoC that ends "now trigger the backup, then
   check for confirmation" has proven edges 1–2 at best. Observing a **side effect you
   then read back** (file fetched over HTTP, OOB callback received) is the minimum for
   edge 4; printing an expectation is not.

Un-proven edge 3 plus un-proven edge 4 means the impact statement is Inferred, and the
severity has to be written as Inferred too. The most common error in this class is
letting a fully-proven *mechanism* (the raw interpolation is real) silently upgrade an
un-proven *outcome* (a command ran) into a demonstrated RCE.

### A whole-file diff is not a patch artifact
A diff in which every line is removed and every line is re-added is not a diff. It
shows that a file changed, and it makes the actual change **unreviewable** — which means
the only evidence for what the patch does is the prose describing it. Where that holds,
the fix is unverified no matter how confident the prose is.

- Require a **minimal, hunk-level** diff with the security-relevant lines visible. If you
  cannot produce one, state that the fix could not be verified from the supplied
  artefact rather than describing what you assume it does.
- Sanity-check the shape: a "net change" of a couple of dozen lines rendered as a
  multi-thousand-line delete/add pair is the signature of a synthesised diff, not of
  `diff -u`. The same applies to typographic quotes inside code samples
  (`$_POST[‘option_name’]`) and to JSON-wrapped analysis blobs — both indicate a
  generated artefact rather than a captured one, which means the machine's statements
  *about* the patch are not evidence either. Go to the release notes, the tracker and
  the real before/after files instead.
- A fix that only escapes one value can still be incomplete: check the sibling arguments
  again post-patch, and check whether any other caller reaches the same sink.

- methodology/authentication.md (302+session proof standard, dual-surface markers)
- methodology/access-control.md (victim-state-change proof)
- methodology/jwt.md (body-content admin verdicts)

## Sources

- Cross-family synthesis of 80+ solved PortSwigger lab notes (knowledge/portswigger/labs/), each cited inline above.
