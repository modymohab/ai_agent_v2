# Research Workflow

## Phase 1 — Authorization

Confirm the target is explicitly authorized.

Record:

- target
- scope
- exclusions
- test accounts
- relevant program requirements

## Phase 2 — Mapping

Understand:

- application structure
- authentication
- roles
- APIs
- sensitive functionality
- important resources

## Phase 3 — Security Model

Determine:

- current identity
- resource owner
- required role
- expected authorization
- security-sensitive state transitions

## Phase 4 — Hypothesis

For each interesting behavior ask:

- What security boundary exists?
- What assumption might be incorrect?
- What evidence would demonstrate the issue?

## Phase 5 — Test

Perform the smallest authorized test capable of validating the hypothesis.

## Phase 6 — Verify

Confirm the result independently where possible.

## Phase 7 — Impact

Determine actual security consequences.

## Phase 8 — Report

Only report reproducible, evidence-supported findings.
