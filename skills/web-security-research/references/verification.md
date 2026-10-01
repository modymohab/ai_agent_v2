# Verification

Before treating a behavior as a confirmed finding:

1. Reproduce it.
2. Confirm authorization context.
3. Confirm resource ownership.
4. Confirm application-level result.
5. Verify the resulting state.
6. Document evidence.
7. Assess severity.

Common false positives include:

- generic 200 responses
- application errors inside 200 responses
- client-side-only behavior
- requests that do not change server state
- resources already authorized to the current user

Do not report ambiguous behavior as confirmed.
