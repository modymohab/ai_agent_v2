# Methodology Note — JSON-RPC endpoint namespace-registration divergence testing

Date: 2026-09-19 | Origin: mission arc-bbp-fullspectrum-2026-09-19 (Arc testnet RPC)
Status: reusable pattern (sanitized, generalizable)

## When to use
A public JSON-RPC service is fronted by multiple gateways/providers (e.g., first-party
gateway vs third-party aggregator) for the same chain/API. Test whether they expose
different method namespaces.

## Technique (bounded, safe)
1. For each namespace of interest, send a **zero-argument probe** `{"method":"<ns_method>","params":[]}`.
   No real payloads, no transactions, no tracing, no gas manipulation.
2. Interpretation of responses:
   - `-32601` "method not supported" -> NOT registered / deliberately blocked.
   - Method-specific **argument-validation error** (e.g., "missing value for required argument 0")
     -> REGISTERED (namespace is reachable/gated by args).
   - Provider **paywall/plan error** (e.g., "method is not available on free plan") -> REGISTERED
     but gated by subscription. Accept the boundary; do NOT attempt to bypass.
   - `result` -> REGISTERED and FUNCTIONAL.
3. Compare registrations across gateways for the SAME chain. A functional divergence
   (e.g., one gateway serves a method the other blocks) is a **filtering-policy difference**.

## Triage reality-check
A divergence is NOT automatically a finding:
- Assess whether the served data actually crosses a security boundary (sensitivity analysis).
  e.g., `net_peerCount` = one integer of public topology metadata on a public testnet ->
  no demonstrated impact -> rejected.
- Irrelevant/excluded classes: version/banner disclosure (`web3_clientVersion`), header
  disclosure, rate-limiting on non-auth endpoints, DoS-only impacts (e.g., free-tier tracing).
- Paywalled vs blocked is a commercial-tier design, not a vulnerability.

## Evidence standards
- Record exact `{method, params, host, response}` tuples.
- Repeat each divergence once (deterministic check: stable across ids/samples).
- Include a control (a namespace you EXPECT on both, e.g., `eth_syncing`) to prove the
  divergence is method-specific, not host-degradation.
- Count requests; spread with delays; never exceed a self-imposed low budget.

## Avoid
Sending valid call objects / tracers / transaction hashes "just to see" — that starts
execution. Keep every probe shape-failing at arg validation.