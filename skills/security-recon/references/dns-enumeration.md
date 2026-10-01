# DNS Enumeration

## Purpose
Map DNS-related assets within authorized scope.

## Look For
- subdomains
- DNS records
- CNAME relationships
- mail infrastructure
- service-specific records
- staging or development naming patterns

## Evidence
Record discovered hostname, record type, source, and scope status.

## Safety
Prefer passive or low-impact techniques. Do not attempt to bypass provider restrictions or rate limits.

## Handoff
Provide validated hostnames to HTTP probing and attack-surface classification.
