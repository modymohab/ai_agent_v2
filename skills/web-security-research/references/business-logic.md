# Business Logic Research

Understand the intended workflow before testing it.

Look for inconsistencies involving:

- state transitions
- ownership
- authorization
- transaction sequencing
- workflow assumptions
- security-sensitive actions

Document:

EXPECTED STATE
→ TEST ACTION
→ ACTUAL STATE

Only classify the behavior as a vulnerability when the security impact
is established.
