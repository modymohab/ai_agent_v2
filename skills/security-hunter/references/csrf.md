# CSRF Hunting

## Signals
- state-changing requests
- cookie-based authentication
- missing or weak CSRF defenses
- unsafe cross-origin assumptions
- sensitive actions without explicit user intent

## Verify
Compare behavior with and without relevant anti-CSRF controls.

## Evidence
Record the affected action, authentication model, request method, and server-side behavior.

## Safety
Use only authorized test accounts and controlled state changes.
