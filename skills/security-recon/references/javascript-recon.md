# JavaScript Recon

## Purpose
Extract useful application intelligence from authorized JavaScript resources.

## Look For
- API routes
- endpoint paths
- parameter names
- feature flags
- client-side routing
- source maps
- authentication-related flows
- dangerous client-side sinks

## Evidence
Record the JavaScript source and the discovered artifact.

## Handoff
Send endpoint discoveries to endpoint/API analysis and client-side signals to the Hunter.

## Safety
Do not treat client-side references as proof of server-side behavior.
