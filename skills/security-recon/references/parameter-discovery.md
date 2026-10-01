# Parameter Discovery

## Purpose
Identify input locations relevant to later security testing.

## Sources
- query parameters
- body fields
- JSON properties
- path parameters
- headers
- cookies
- form fields

## Classify
Mark parameters as likely:
- object identifiers
- authorization-related
- workflow/state
- filtering/search
- redirect/navigation
- file-related
- template or rendering input

## Evidence
Preserve parameter name, location, method, endpoint, and authentication context.

## Stopping Condition
Discovery must remain safe and within authorized scope.
