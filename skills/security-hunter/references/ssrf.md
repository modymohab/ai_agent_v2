# SSRF Hunting

## Signals
- URL fetchers
- webhooks
- image importers
- document processors
- preview services
- integration callbacks

## Method
Identify server-controlled network requests and determine whether destinations are attacker-influenced.

## Evidence
Record input location, destination control, and observable server-side interaction.

## Safety
Use controlled endpoints and authorized environments. Do not probe unrelated internal networks.
