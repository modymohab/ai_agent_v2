# Impact Analysis — Reference

Canonical process: `security-research/methodology/impact-analysis-skill/SKILL.md` (read it fully).

The impact phase answers "What can an attacker ACTUALLY do with the primitive?"
not "Can I reproduce the vulnerability?"

PortSwigger knowledge (`index/portswigger.md`, `knowledge/portswigger/labs/`)
is a structured knowledge base used to extract vulnerability classes, attack
primitives, sinks/sources, exploitation patterns, impact-escalation patterns,
verification techniques, second-order effects, and missed attack paths.
Lab patterns are hypotheses for the current target, never proof.

Use `index/attack-impact-coverage.md` as the class checklist for the Impact
Coverage Check (SQLi, XXE, XSS, CSRF, SSRF, path traversal, SSTI, command
injection, NoSQLi, deserialization, race conditions).

IMPACT-SIDE matrix: `references/class-impact-coverage.md` in this skill gives
the PortSwigger-referenced boundary → impact-hypothesis → escalation framing per
class (SQLi, XXE, XSS, CSRF, SSRF, path traversal) used to drive the Impact
Hypothesis Matrix and the Coverage Check. Canonical copy: methodology/impact-analysis-skill/SKILL.md §2b.

## Mandatory workflow for each confirmed finding

1. Identify the confirmed primitive.
2. Determine the trust/security boundary crossed.
3. Search the PortSwigger knowledge base for related classes/patterns.
4. Build an Impact Hypothesis Matrix.
5. Test applicable impact paths systematically (minimal safe tests).
6. Do not stop after the initial vulnerability.
7. Look for privilege escalation, unauthorized modification/deletion, sensitive
   data access, account takeover, arbitrary file access, server-side request
   behavior, and code/command execution where technically applicable.
8. For input-processing vulnerabilities, evaluate XSS, XXE, SSRF, CSRF, path
   traversal, command injection, SQL/NoSQL injection, template injection, etc.
   ONLY when the source/sink/context makes them relevant.
9. Distinguish CONFIRMED / PLAUSIBLE-unverified / INAPPLICABLE.
10. Verify every claimed impact with a minimal safe proof.
11. Update the knowledge base with newly discovered patterns.

## Impact Coverage Check (before finishing)

Record which relevant impact classes were TESTED (outcome), NOT APPLICABLE (why),
and remain UNVERIFIED (what test would settle them). The finding is incomplete
without it.

## Output per finding (write to `impact/`)

- confirmed primitive
- boundary crossed
- impact summary (what an attacker can actually do)
- demonstrated impact (proof references)
- supported inferences (separated)
- potential / not demonstrated
- impact hypothesis matrix
- impact coverage check
- suggested escalation paths for reporting