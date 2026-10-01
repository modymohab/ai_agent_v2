# Injection Hunting

## Coverage
Consider:
- XSS
- SQL injection
- NoSQL injection
- command injection
- template injection
- LDAP/XPath/XML injection
- header injection

## Method
Identify input -> processing context -> observable effect.

## Evidence
Use minimal controlled input and compare against a baseline.

## Safety
Avoid destructive database, operating-system, or service actions. Stop once the security property is demonstrated.
