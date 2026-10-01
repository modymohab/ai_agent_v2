# XSS Hunting

## Coverage
Consider reflected, stored, and DOM-based XSS.

## Method
Trace:
source -> transformations -> HTML/JS context -> sink -> execution.

## Signals
- reflected parameters
- stored user content
- unsafe DOM sinks
- JavaScript evaluation
- event-handler contexts
- client-side URL processing

## Evidence
Record the input location, context, transformation, sink, and controlled execution result.

## Safety
Use harmless proof-of-concept behavior and authorized targets only.
