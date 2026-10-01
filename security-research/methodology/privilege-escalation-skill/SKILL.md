# Privilege Escalation Skill

> Dedicated capability built from existing project knowledge. Source template `../privilege-escalation.md` is a header-only stub. This skill is a **capability-coordination layer**: it organizes privilege-escalation research across the existing class skills and must NOT duplicate their tested methodology. See `# Source / Derivation`.

## Purpose

Coordinate the detection and proof of **privilege escalation** — any path by which an actor's effective permissions exceed the permissions the application intends them to hold. This is a cross-cutting capability: escalations surface through authorization flaws, authentication/identity trust, token/claim trust, and workflow state, so this skill's job is to (1) recognize the escalation shape, (2) dispatch to the owning class skill, and (3) define the proof that the effective privilege really changed.

**Non-duplication rule.** Do not re-derive the authorization mechanics here. The detailed, lab-verified methodology for role markers, method/verb bypasses, multi-step and URL-desync access control, Host/Referer/IP-header trust, and horizontal object access lives in `../access-control-skill/SKILL.md` and its sibling references (see the `security-access-control` skill's `references/`). Identity/token forgery lives in `../authentication-skill/SKILL.md`, `../jwt-skill/SKILL.md`, and `../oauth-sso-skill/SKILL.md`. Workflow-state privilege changes live in `../business-logic-skill/SKILL.md` and `../race-conditions-skill/SKILL.md`. This capability selects among them.

## Scope

Escalation shapes covered (dispatched to owning skills):

- Horizontal privilege escalation (same role, different object/tenant/owner).
- Vertical privilege escalation (low-priv → higher-priv role/function).
- Role-boundary violations (a privilege marker or default flips role without authorization).
- Authorization boundary failures (function-level, object-level, forced browsing).
- Identity/token trust failures (claims/algorithms/keys/identity-binding escalated to privileged identity).
- Workflow-based privilege changes (a step, endpoint, or omission grants privilege). 

Out of scope: the lower-level exploitation mechanics themselves (owned by the class skills), and authorization *enumeration* without an escalation (see `../access-control-skill/SKILL.md`).

## Inputs

- Attachment-surface model + session/identity model: which actor has which role, which functions are denied, which objects/tenants exist (recon output).
- Denied-function baselines (e.g. `/admin` → 401/403) and role-marker observations (`Admin=false`, JWTs, OAuth identity claims, dual-use editable identity fields).
- Token/SSO context: JWT segments, OAuth implicit grant, profile-linking endpoints, stay-logged-in cookies, encryption-oracle cookies.
- Workflow maps: multi-step flows, parallel writers, staged logins, dual-use endpoints, race-condition-prone transitions.
- Evidence framework: `../verification-skill/SKILL.md` and `../impact-analysis-skill/SKILL.md` (privilege-impact reasoning).

## Workflow

1. **Establish the baseline authority** — what each actor can demonstrably do (reproduce the denial: which functions return 401/403/an empty view).
2. **Classify the escalation shape** from the surface (see `# Detection / Hypothesis Areas`).
3. **Dispatch to the owning class skill** for the tested mechanics and test matrix. Only ONE variable changes per test.
4. **Prove the effective change** — the escalated actor can now perform an action or read data they previously could not (privileged UI render, victim state change, cross-tenant object read), verified per `../verification-skill/SKILL.md` (state re-read, marker, fresh-session logins; never status code alone).
5. **Chain further** per `../impact-analysis-skill/SKILL.md` step 6 (escalations beget more: low-priv→admin→arbitrary deletion).
6. **Pass a candidate** to verification and (if confirmed) to impact analysis.

## Detection / Hypothesis Areas

### Horizontal privilege escalation (supported — dispatch to access-control)

- Shape: same role, cross-object/cross-tenant/cross-user access (IDOR/BOLA, object-ownership failures). The tested mechanics (GUID-keyed objects without ownership checks, leak-driven discovery, swap-one-variable proof) are in `../access-control-skill/SKILL.md`. The referenced methodology also lives under `../../../skills/security-access-control/references/` (`../../../skills/security-access-control/references/horizontal-escalation.md`, `../../../skills/security-access-control/references/object-ownership.md`, `../../../skills/security-access-control/references/tenant-isolation.md`, `../../../skills/security-access-control/references/function-level-authorization.md`).

### Vertical privilege escalation (supported — dispatch to access-control)

- Shape: low-priv → admin or higher-priv function. Includes client-trusted role markers, method/verb-scoped authorization, multi-step flows with unguarded confirm steps, URL/filter desync (rewrite headers), Referer-gated mutations, Host-header locality checks, TRACE-disclosed IP headers. All detail in `../access-control-skill/SKILL.md` and `../../../skills/security-access-control/references/vertical-escalation.md`.

### Role-boundary violations (supported — dispatch to access-control + business-logic)

- Shape: a role or privilege takes effect without an authorized decision — e.g. privileged-domain role applied by a parallel writer, default-admin staged logins when a downgrade step is omitted. Mechanics in `../business-logic-skill/SKILL.md` (inconsistent parallel validation; step-omission in staged logins) and escalation proof in `../access-control-skill/SKILL.md`.

### Authorization boundary failures (supported — dispatch to access-control)

- Shape: function-level authorization gaps, forced browsing, inconsistent enforcement between endpoints. `../access-control-skill/SKILL.md` + `../../../skills/security-access-control/references/forced-browsing.md`, `../../../skills/security-access-control/references/function-level-authorization.md`.

### Identity/token trust failures (supported — dispatch to authentication/JWT/OAuth)

- Shape: privileged identity achieved through token/claim/identity trust — JWT claim forgery (`sub`→administrator) and algorithm/key confusion (`../../../skills/security-access-control`-adjacent; mechanics in `../jwt-skill/SKILL.md`), OAuth identity-field confusion and forced profile linking (`../oauth-sso-skill/SKILL.md`), stay-logged-in cookie forgery and encryption-oracle token forgery (`../authentication-skill/SKILL.md`).
- Boundary: identity-bound escalation IS privilege escalation only when the forged identity is more privileged. Proof: privileged function rendered under the forged identity.

### Workflow-based privilege changes (supported — dispatch to business-logic + race-conditions)

- Shape: a workflow step or omission changes effective privilege — dual-use endpoints acting on any named target, staged-login downgrade-step omission, privilege-changing transitions raced. Mechanics: `../business-logic-skill/SKILL.md` (dual-use endpoint, state-machine omission variants), `../race-conditions-skill/SKILL.md` where a racing transition grants privilege.

## Verification

- **Effective-privilege proof** (mandatory before escalation claims): the escalated actor can now do what they could not at baseline — privileged function renders, victim state changes (deletion, role upgrade, cross-tenant read), marker flips — per `../verification-skill/SKILL.md`. Never report panel render without victim state change/solved marker as confirmed escalation (`../access-control-skill/SKILL.md` common failure modes).
- **Single-variable discipline:** change session/role/object one at a time; re-read state after the executing action (302 ≠ effect).
- **Fresh-session confirmation:** role may load at login; redirect alone is not proof.
- Use `../../../skills/security-impact/references/privilege-impact.md` when present to frame the finding: distinguish object-level access, function-level access, role change, and administrative capability; use demonstrated authorization effects only.

## Evidence

Per the owning skills: actor-before / actor-after, endpoint, expected permission vs observed permission, the exact one-variable delta (cookie flip, method, header, forged claim, omitted step), and the resulting state change with proof artifacts. Record the baseline denial and the escalated success as a pair so the boundary crossed is self-evident.

## Handoff

- Confirmed escalations → `../impact-analysis-skill/SKILL.md` (privilege-impact reasoning; escalation-chaining per step 6).
- Impact framing → `../../../skills/security-impact/references/privilege-impact.md` (if present).
- Escalation that is also an identity/ATO finding → `../authentication-skill/SKILL.md` impact framing; SSO-specific → `../oauth-sso-skill/SKILL.md`.
- Reporting → `../reporting-skill/SKILL.md` with demonstrated-boundary and impact proof.

## Related Skills

- `../access-control-skill/SKILL.md` — the core lower-level skill (do NOT duplicate its mechanics; dispatch to it).
- `../../../skills/security-access-control/SKILL.md` + `references/` (`../../../skills/security-access-control/references/horizontal-escalation.md`, `../../../skills/security-access-control/references/vertical-escalation.md`, `../../../skills/security-access-control/references/idor-bola.md`, `../../../skills/security-access-control/references/method-confusion.md`, `../../../skills/security-access-control/references/object-ownership.md`, `../../../skills/security-access-control/references/tenant-isolation.md`, `../../../skills/security-access-control/references/forced-browsing.md`, `../../../skills/security-access-control/references/function-level-authorization.md`) — the authorization reference tree this capability coordinates.
- `../authentication-skill/SKILL.md` — identity/token-trust forgery paths (stay-logged-in, encryption-oracle).
- `../jwt-skill/SKILL.md`, `../oauth-sso-skill/SKILL.md` — claim/identity-based escalation.
- `../business-logic-skill/SKILL.md`, `../race-conditions-skill/SKILL.md` — workflow/state-based privilege changes.
- `../verification-skill/SKILL.md` — effective-change proof standard.
- `../impact-analysis-skill/SKILL.md` — impact matrix (escalation-path rows) and privilege-impact output.
- `../reporting-skill/SKILL.md`, `../../../skills/security-impact/references/privilege-impact.md` — demonstration discipline and framing.

## Source / Derivation

- **Organized (not duplicated):** the escalation shapes and their dispatch targets are a coordination layer over `../access-control-skill/SKILL.md`, `../../../skills/security-access-control/references/`, `../authentication-skill/SKILL.md`, `../jwt-skill/SKILL.md`, `../oauth-sso-skill/SKILL.md`, `../business-logic-skill/SKILL.md`, and `../race-conditions-skill/SKILL.md`. Detailed testing methodology remains in those skills; this capability selects and sequences.
- **Directly derived:** effective-privilege proof discipline from `../verification-skill/SKILL.md` and `../access-control-skill/SKILL.md`; escalation-chaining from `../impact-analysis-skill/SKILL.md`.
- **Source template:** `../../methodology/privilege-escalation.md` was an empty header-only stub; no verbatim body existed to migrate.

## Coverage Boundaries

The current knowledge base does not yet contain a dedicated methodology for:

- **Cloud/identity-provider privilege escalation** (IAM roles, Azure AD/Okta tenant-level, cross-tenant IdP trust, provider-to-provider chains).
- **Container/OS-level privilege escalation** (kernel, SUID, capability abuse) — this skill covers application-layer web privilege changes only.
- **Delegated-administration and hierarchical role-granting models** beyond the documented role-marker patterns.
- **Privilege-escalation *measurement coordinates*** (e.g. quantified privilege graphs) — only the demonstrated-permission-before-after model above is supported.