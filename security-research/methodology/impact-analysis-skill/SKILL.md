# Impact Analysis Skill

> Provenance: migrated from `methodology/impact-analysis.md`. Content preserved verbatim; original file kept as source of truth.

The impact phase answers:

> What can an attacker actually do with the primitive we discovered?

NOT merely:

> Can I reproduce the vulnerability?

Impact analysis runs on **confirmed** findings only (verification already done).
The PortSwigger knowledge base is a source of **attack-pattern knowledge**, not a
command list. Reason from the application's actual behavior; test only attack
classes that are technically applicable to the observed source, sink, and trust
context.

---

## 1. Inputs

- verified evidence (requests/responses)
- triage decision (confirmed / rejected / inconclusive)
- mission scope and rules
- `index/portswigger.md` (lab index) + `knowledge/portswigger/labs/` (lab notes)
- `methodology/` class files (injection, xss, ssrf, xxe, traversal, ssti, csrf,
  deserialization, race-conditions, jwt, oauth-sso, authn, privesc, api-security, etc.)

---

## 2. Mandatory process for every confirmed finding

### Step 1 — Identify the confirmed primitive
State precisely and minimally what was proven: the exact request/param/path,
the observed behavior, and the mechanism (e.g., missing object check, unchecked
redirect target, unescaped reflection in sink, unauthenticated endpoint).

### Step 2 — Determine the trust/security boundary crossed
Name the boundary explicitly. Examples:

- unauthenticated → authenticated
- user → other user (horizontal)
- user → admin (vertical)
- tenant → tenant
- client → server (request smuggling, SSRF)
- app → file system (traversal)
- app → command interpreter (injection)
- app → backend database / cache
- trust of user-controlled data (CSRF, open redirect, HTMLi)

### Step 3 — Search the PortSwigger knowledge base for related classes
For the primitive's class, find the relevant labs/writeups and extract:
vulnerability classes, attack primitives, sinks/sources, exploitation patterns,
impact-escalation patterns, verification techniques, second-order effects, and
common missed attack paths. These are HYPOTHESES, not proof for this target.

Use `index/portswigger.md` (solved-lab index) and
`index/attack-impact-coverage.md` (class → primitive → sink → impact → verify
matrix for SQLi, XXE, XSS, CSRF, SSRF, path traversal, and adjacent classes).
Map the confirmed primitive onto the matrix rows and extract the applicable
impact hypotheses.

### Step 4 — Build an Impact Hypothesis Matrix
For each candidate impact class that is technically plausible:
record the primitive that would drive it, the sink that would have to be
reachable, why it is applicable or not, and the current status
(confirmed / plausible-unverified / inapplicable). One row per class.

### Step 5 — Test applicable impact paths systematically
Proceed through the matrix rows that are applicable. Minimal safe tests only.
Do not test inapplicable classes just to "complete a list".

### Step 6 — Do not stop after proving the initial vulnerability
Chain and escalate. For every confirmed primitive, actively look for:

- privilege escalation (horizontal and vertical)
- unauthorized modification / deletion
- access to sensitive data or personal data
- account takeover
- arbitrary file access / listing
- server-side request behavior (SSRF)
  - code / command execution (only where technically applicable)

**Chain discipline — every link is a separate claim requiring its own proof.**
Escalation is where severity inflation actually happens, because each step is
individually plausible and they compound. Observed failure: a proven unauthenticated
write primitive was reported as a Critical chain of *stored XSS → operator account
takeover → admin account creation → server-side code execution*, where only the first
link was demonstrated and each subsequent link added an unverified assumption.

- **Prove each link or explicitly mark it inferred.** Write the chain as a numbered
  list and label every element *Demonstrated* / *Inferred* / *Theoretical*. A chain
  with four Inferred links scores as its one Demonstrated link, not as their product.
- **Script execution inherits the session's privileges; it does not exceed them.**
  "XSS → create administrator account" is only true if the victim is *already* an
  administrator, and "XSS → install a server-side code package" is an
  **administrator-only capability the admin session already has** — that is not
  escalation, it is a restatement of the victim's own power. Claiming RCE this way
  is a category error that a competent triager will dismantle, taking the credible
  parts of the report down with it.
- **Run the prerequisite-capability test on the *score*, not only on the claim.**
  Before assigning a severity to an authenticated finding, write two sentences: what
  the required privilege already confers, and what the vulnerability adds on top. A
  WordPress **administrator can already install plugins and edit plugin/theme PHP**,
  so "administrator → shell command execution" adds no capability the attacker did
  not already hold — it is defence-in-depth, not escalation, and a High rating rests
  entirely on ignoring that.
  - If the answer is "nothing", say so and drop the score to the finding's real
    class (often Low / hardening). Do not let the CVSS number launder an inflated
    prerequisite.
  - If there *is* a residual gap, name it precisely or drop it. The legitimate
    variant here is an attacker holding a hijacked admin **session** but not
    server-side code execution; that converts web-session access into shell as the
    web user. It is a real distinction — and it is only worth claiming if you say so
    explicitly, because the same admin can usually install a plugin to the same end.
  - An asserted CVSS number with **no vector string is not evidence.** Do not adopt
    or reverse-engineer a vendor's score; recompute from the vector they publish, and
    say "score asserted, vector not published" when they do not publish one.
    Contributor-versus-scoring disagreement is a triage discussion, not a fact you
    can cite in either direction.
- **Check the specific mechanism before claiming the specific exfiltration.**
  `document.cookie` returns nothing when the session cookie is `HttpOnly`; many
  back-office/auth frameworks set it by default. Verify the `Set-Cookie` flags, and
  if the cookie is `HttpOnly` then pivot to what *is* readable — the DOM, the CSRF
  token, in-origin API responses via the victim's session — or scope the claim down.
  A report whose headline exfiltration primitive returns an empty string has no
  confidentiality impact.
- **`Scope: Changed` requires a demonstrated authority crossing**, not a different
  login context. Script running in a back-office that a differently-privileged user
  merely *views* is the standard case, but it must be shown — and the higher
  authority (admin, a different tenant, a server-side process) must be reached by
  something the attacker did, not assumed from the job title of whoever opens the
  record.
- **"The victim will definitely encounter it" is not impact, it is a probability.**
  Arguing that a role's *job function* guarantees they open the record is a
  reasonable reachability argument — label it as such. It justifies *retesting*
  priority, not Confidentiality/Integrity scores.

- **Memory corruption is not automatically code execution.** A stack or heap
  overflow establishes a write primitive, not instruction control. The distance
  between them is the mitigation stack of the *shipped build* — canaries, ASLR,
  DEP/NX, pointer authentication, guard pages, control-flow integrity — and
  effective exploitation additionally requires the attacker to control the
  *content* that lands out of bounds, not merely the *length*. A primitive where
  the attacker influences only how far past the end a write reaches is
  substantially weaker than one where they choose the bytes, and the two should
  never share a severity. "Remote crash" is the honest ceiling for a length-only
  overflow found by reading source; escalate to execution language only with a
  working primitive.
- **Bounds bugs measured in elements are not bounds bugs measured in bytes.** A
  size argument to a bounded-write function counts elements, so identical source
  overflows to different depths on targets with different element widths (16- vs
  32-bit wide characters, 32- vs 64-bit pointers). State the unit, and state it
  per platform, before comparing severities across a multi-platform product.

**When a report's own hedge contradicts its title, believe the hedge.** A submission
that carefully writes "if the operator-facing rendering is HTML-encoded, the others
still expose the same primitive" has told you the render is unverified. Score and title
the finding to the confirmed half.

### Step 7 — Evaluate input-processing classes when relevant
For input-processing vulnerabilities, evaluate applicable classes such as
XSS, XXE, SSRF, CSRF, path traversal, command injection, SQL/NoSQL injection,
template injection — but ONLY when the application's source/sink/context makes
them relevant. Prove the data reaches the sink before spending effort.

### Step 8 — Distinguish impact certainty
Classify every impact claim as one of:

- CONFIRMED — demonstrated with minimal safe proof
- PLAUSIBLE/UNVERIFIED — technically supported but not proven (record the test that would prove it)
- INAPPLICABLE — assessed and excluded with reason

### Step 9 — Verify every claimed impact
Every impact claimed in the report must have a minimal safe proof.
No proof → no claim.

### Step 10 — Update the research knowledge base
Promote newly discovered generalizable patterns to the knowledge base
(only generalizable knowledge; no target secrets or raw evidence).

### Step 11 — Calibrate the claim against demonstrated capability, not the label

The claimed vulnerability CLASS is a hypothesis, not a finding. Real triage
reclassifies findings routinely, in both directions. Before writing a report,
answer the question an analyst will actually ask:

> **What can the attacker now do that they could not do before?**

If the answer is "nothing new", the finding is a code-quality or
defence-in-depth defect, not a vulnerability — regardless of how alarming the
mechanism looks. A finding filed under the wrong class can still be legitimately
payable at a *lower* severity if a real capability is demonstrated. So both
failure directions are real, and the class name is never the finding.

**Calibration case A — same-party traversal grants nothing.** A traversal defect
where the untrusted party is *also* the party that serves the content usually
confers no new capability. If a malicious or MITM'd origin controls the response
metadata, it can already return arbitrary content for the path the client
legitimately requests. Redirection grants nothing. Closed **Informative** — a bug
to fix — despite exact code analysis, and the project shipped a fix anyway. See
`../traversal-skill/SKILL.md`.

**Calibration case B — public fetch plus reflection is XSS, not SSRF.** A
userinfo host-discrepancy (`?u=https://trusted@attacker/…`) defeated a fetch
host allowlist, and the fetched body was reflected into the site's own origin.
That is a real **host-allowlist bypass + reflected XSS**, worth reporting and
fixed as such. It was filed as Critical SSRF, re-triaged to XSS, and paid at
Medium — because none of the four SSRF capabilities could be demonstrated. See
`../ssrf-skill/SKILL.md`.

Four questions that reveal a finding's true ceiling:

1. Does the destination reach **internal-only** assets (loopback, RFC1918, admin)?
2. Does it drive **internal service interaction** (state-changing calls, gopher)?
3. Does it read **local files** via `file://` or a path primitive?
4. Does it touch **cloud credentials** (link-local metadata, IMDS)?

Any "no" on all four caps the class at the real primitive. A report that bounds
its own impact is stronger than one that leaves triage to find the ceiling; the
reporter who conceded the untestable parts is the one who got paid.

**Calibration case C (the positive model) — a real boundary crossing.** An
internal Teams/Azure-OpenAI application enforced authentication on exactly one
route (the Bot Framework webhook, which correctly 401'd) and left six sibling
data routes open: list, read, delete sessions, drive the LLM, submit feedback,
health. Unauthenticated `GET` of the session list yielded every conversation; the
`session_id` was the Teams user identifier in the `29:` (individual) namespace, so
records were attributable to named people. That is genuine new capability across a
boundary the application itself proved it intended to hold — and it cleared at
Critical. See `../reporting-skill/SKILL.md` and
`../agentic-research-skill/SKILL.md`.

Note the contrast with cases A and B: in A and B the attacker and the victim were
the same party, or the destination was public. In C the attacker was an anonymous
internet party and the victims were identifiable third parties. **That test —
is the victim a third party the attacker could not already reach? — is the
cheapest triage pre-filter available.**

**A "Suggested Severity" field is a hypothesis, not a claim of demonstrated
impact.** Submitters routinely supply a CVSS vector and rating up front, and
routinely those exceed the evidence. Two distinct failures to separate:

- **Inflated class with no ceiling shown** (public fetch reflected to the
  attacker → filed as Critical SSRF, paid as XSS). The label sets a ceiling the
  evidence never reached.
- **Real finding, severity ahead of the proof** (a parser differential that
  redirects a client's outbound requests, submitted as Critical with high
  confidentiality and integrity impact when no internal target was ever reached
  and no credential was ever retrieved). The vulnerability is genuine and the fix
  is correct; the *rating* is simply not yet earned. This one survives triage
  more often than the first, which makes it easier to miss.

Rule: if a metric is asserted in a submitted vector, the report must contain the
evidence for that metric. `C:H` requires demonstrated confidentiality loss, not a
plausible path to one. State metrics you cannot support as untested rather than
silently including them.

**A maintainer accepting the report does not retroactively validate the
calibration.** Programs routinely fix real findings whose submitted severity was
too high, and routinely accept findings whose severity was right for reasons the
reporter never articulated. Acceptance is a decision about *validity and
willingness to fix*; severity calibration is a separate judgement about *what was
shown*. Do not read a fast, friendly triage as confirmation that the rating was
earned — the same finding class submitted elsewhere can be downgraded, and the
asymmetry will not be visible to you.

**Calibrate the precondition in both directions.** Reports state the precondition
in whichever direction flatters the finding. "Requires compromising a server
instance" inflates the bar; "user configures the client with an arbitrary URL" may
collapse it to near-zero, because that is often exactly how the client is
documented to be used. Name which is actually required, and check that an
*understated* precondition is not inflating your impact the way an overstated one
flatters your access.

---

## 2b. Impact-Class Coverage Matrix (PortSwigger-referenced)

For every confirmed finding, THIS matrix drives the Impact Hypothesis Matrix
(Step 4), the applicable-path testing (Steps 5–7), and the mandatory Impact
Coverage Check (section 3). Map the confirmed primitive onto the relevant
rows. For each class record: boundary crossed → impact hypotheses → escalation
paths → the PortSwigger labs referenced. Claim impact only where demonstrated.

### SQL Injection
- **Boundary:** app → backend database (and, if login/session logic, authentication boundary).
- **Impact hypotheses:** authentication bypass; read of sensitive/personal data (quantity AS DEMONSTRATED); data modification/deletion (only if stacking/destructive paths actually proven); elevation to higher-privileged data.
- **Escalation paths:** UNION schema enumeration → PII/credential tables; blind boolean/error oracles; second-order stored injection fired in later admin/report queries.
- **Lab refs:** `sql-injection-where-clause-hidden-data`, `sql-injection-login-bypass`, `sql-injection-union-*` (column-count/other-tables/single-column/text-column), `sql-injection-blind-conditional-responses`, `sql-injection-blind-conditional-errors`, `sql-injection-visible-error-based`.

### XXE
- **Boundary:** app → file system (file read), app → internal services (SSRF via entity), stack-dependent protocol handlers.
- **Impact hypotheses:** arbitrary file read (config/source/env); SSRF into internal hosts; blind OOB exfiltration; RCE ONLY where the stack/handler demonstrably supports it (e.g., PHP wrapper coherence).
- **Escalation paths:** file-read → credentials/API keys → deeper access; SSRF → internal admin/console reachable from backend.
- **Lab refs:** `xxe-external-entity-file-retrieval`, `xxe-ssrf-metadata-credentials`, `xxe-blind-oob-interaction`, `xxe-blind-oob-exfiltration-dtd`, `xxe-blind-oob-parameter-entities`, `xxe-xinclude-file-retrieval`, `xxe-targeted-scanning-stock-xinclude`, `xxe-local-dtd-repurposing`, `xxe-svg-avatar-file-upload`.

### XSS
- **Boundary:** trust of user-controlled data re-rendered in a victim's browser context (reflected/stored/DOM).
- **Impact hypotheses:** session theft (ONLY if HttpOnly absent); account takeover via chained CSRF; stored XSS reaching other users/admin; DOM-based extraction in victim scope; phishing/keylogging (weak). Program relevance: XSS without demonstrated business impact is not accepted → demonstrate a real consequence.
- **Escalation paths:** stored XSS in widely-viewed content; admin-context XSS → mass account impact; blind fetch on victim session.
- **Lab refs:** stored XSS in session-cookie username (index line 406), `xss-scanning-non-standard-data-structures.md`.

### CSRF
- **Boundary:** trust of cross-site-originated state-changing requests (missing anti-CSRF token / origin / SameSite enforcement).
- **Impact hypotheses:** forced state change on a victim's account (email/password/role/order/workflow action); login CSRF; admin action forging. Program relevance: CSRF without business impact is not accepted → target high-value actions and prove forced execution from another origin.
- **Escalation paths:** chain with stored XSS (exfil → auto-submit); tokenless JSON endpoints gated only by CORS; SameSite bypass.
- **Lab refs:** `csrf-no-defenses.md`, tokenless email change + SameSite=None auto-submit exploit (index line 458).

### SSRF
- **Boundary:** app → internal/cloud network from a backend fetch.
- **Impact hypotheses:** internal response disclosure (admin consoles/internal APIs that bind to backend); port/service reachability (bounded fingerprinting); cloud metadata short-lived credential access (only where the stack/instance explicitly supports it — treat cloud metadata probing per program hazard); blind OOB (needs a demonstrated effect).
- **Escalation paths:** loopback / native-IP fetches to internal apps behind the edge; redirect-chain / whitelist bypass; SSRF → reach otherwise-401 internal API returning data.
- **Lab refs:** `ssrf-basic-backend-system`, `ssrf-basic-local-server`, `ssrf-blacklist-filter-bypass`, `ssrf-whitelist-double-decode`, `ssrf-open-redirect-chain`, `ssrf-blind-oob-detection`.

### Path Traversal / Arbitrary File Access
- **Boundary:** app → file system (read and, in upload/extract contexts, write).
- **Impact hypotheses:** arbitrary file read (source, config, `.env`, backups, logs carrying personal data); traversal-write in upload/archive extraction (zip-slip); source/context disclosure enabling further chaining.
- **Escalation paths:** read secrets → authenticate deeper; write-side traversal → overwrite/plant files where technically demonstrated; traversal into template dirs → SSTI/RCE only where the loader is demonstrably reached.
- **Lab refs:** `traversal-simple-case`, `traversal-absolute-path-bypass`, `traversal-sequences-stripped-nonrecursively`, `traversal-validate-start-of-path`, `traversal-extension-null-byte`, `file-upload-path-traversal`, `jwt-authentication-bypass-kid-header-path-traversal`.

### Adjacent classes (same matrix discipline)
SSTI, command injection, NoSQL injection, deserialization (e.g., ViewState),
race conditions, JWT/OAuth — see `methodology/` class files and
`index/attack-impact-coverage.md`. Apply identical boundary → hypothesis →
escalation → lab-reference reasoning.

---

## 3. Impact Coverage Check (before finishing a finding)

Record explicitly:

- Which relevant impact classes were TESTED (and outcome)
- Which were NOT APPLICABLE (why)
- Which remain UNVERIFIED (what test would settle them)

Use `index/attack-impact-coverage.md` as the class checklist so no relevant
input-processing class (SQLi, XXE, XSS, CSRF, SSRF, path traversal, SSTI,
command injection, NoSQLi, deserialization, race conditions) is silently skipped
when its source/sink/context makes it applicable.

Add this checklist to the impact artifact for the finding. A finding is not
complete until the coverage check is present. Do not silently drop untested
relevant classes.

---

## 4. Impact categories (classify, never inflate)

Per AGENTS.md and the impact agent: separate convenience/robustness issues from
security consequences. Keep the demonstrated-vs-inference distinction. The
categories below map to the traditional severity spectrum ONLY as evidenced
impact — never as the base vulnerability class alone.

- Sensitive / personal data exposure (data type, owner, sensitivity, quantity demonstrated, access condition)
- Unauthorized modification / deletion (what exactly changed)
- Availability (only when the evidence demonstrates a real availability consequence)
- Authentication impact (session, recovery, identity — ATO only when proven)
- Authorization impact (which object/user/tenant/role/admin boundary)
- Privilege impact (one privileged function vs full admin control)
- Attack chain (only demonstrated links)
- Code / command execution (only when actually demonstrated)

---

## 5. Common failure modes

- stopping at "reproducible" and never asking what it buys an attacker
- claiming mass exposure from one object
- claiming ATO from a profile-field change
- claiming RCE from a version string
- treating an educational lab's severity as target severity
- testing every injection class blindly instead of sink-driven selection
- missing second-order paths (stored data that renders elsewhere, tokens used in later flows, uploaded files served from a different origin)

---

## 6. Output

For each finding, write to `impact/`:

- confirmed primitive
- boundary crossed
- impact summary (what an attacker can actually do)
- demonstrated impact (with proof references)
- supported inferences (separated)
- potential / not demonstrated
- Impact Hypothesis Matrix (rows + status)
- Impact Coverage Check (tested / not applicable / unverified)
- suggested impact escalation paths for the reporting phase

## Sources

- `index/portswigger.md`, `knowledge/portswigger/labs/`
- `knowledge/portswigger/writeups/`
- class methodology files under `methodology/`
- current mission evidence (priority)
