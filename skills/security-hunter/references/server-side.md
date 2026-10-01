# Server-Side Hunting

## Coverage
Consider:
- SSRF
- XXE
- path traversal
- file processing
- deserialization
- command injection
- server-side template injection
- request parsing weaknesses

## Method
Map input -> server-side component -> observable behavior.

## Evidence
Preserve baseline and differential observations.

## Safety
Prefer non-destructive proof. Do not access unrelated internal systems or data.
