# Attack Surface Classification

## Purpose
Turn discovered assets and endpoints into a structured attack-surface map.

## Classify
- authentication
- authorization
- API
- file handling
- business workflows
- client-side functionality
- server-side functionality
- administrative functionality
- integrations and webhooks
- sensitive data flows

## Inputs
Use:
- URLs
- endpoints
- HTTP methods
- parameters
- technologies
- JavaScript references
- observed workflows

## Output
Each surface should have:
- surface type
- endpoint or asset
- relevant functionality
- authentication requirement
- likely vulnerability classes
- confidence

## Stopping Condition
Classification should be sufficient to drive later hunting. Do not treat classification itself as proof of a vulnerability.
