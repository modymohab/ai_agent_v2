# Deserialization Hunting

## Signals
- serialized objects in cookies, parameters, bodies, or hidden fields
- framework-specific serialization formats
- opaque encoded application state
- server-side object reconstruction

## Hypotheses
Consider unsafe object handling, type confusion, or unexpected object properties.

## Evidence
Record format, location, parser context, and observed behavior.

## Safety
Do not escalate to destructive payloads. Establish the weakest observable security impact first.
