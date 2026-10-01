# Client-Side Hunting

## Focus
Look for security-relevant client-side data flows.

## Signals
- URL data entering DOM sinks
- unsafe HTML insertion
- dangerous JavaScript execution
- client-side redirects
- client-side CSRF patterns
- unsafe message handling
- prototype manipulation where applicable

## Method
Trace source -> transformation -> sink.

## Evidence
Record the source, sink, execution context, and observable security consequence.

## Stopping Condition
A suspicious sink is a candidate, not automatically a vulnerability.
