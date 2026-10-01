# API Discovery

## Purpose
Identify API surfaces and API-specific attack opportunities during reconnaissance.

## Signals
- `/api/`, `/v1/`, `/v2/`, `/graphql`, `/rest`
- JSON responses or JSON request bodies
- OpenAPI or Swagger references
- API-specific authentication headers
- Mobile or SPA traffic using backend APIs
- Versioned endpoints

## Apply When
Use this reference when recon identifies application endpoints that appear to expose structured API functionality.

## Hypotheses
Consider:
- undocumented endpoints
- alternate API versions
- inconsistent authentication
- inconsistent authorization
- excessive response data
- undocumented parameters
- workflow endpoints

## Evidence
Record:
- endpoint
- HTTP method
- authentication state
- request/response format
- source of discovery
- observed access behavior

## Stopping Condition
Do not aggressively enumerate or stress an API. Stop when the authorized scope or safe request budget is reached.
