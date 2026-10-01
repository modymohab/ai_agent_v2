# Class Knowledge — CSP Bypass via Policy Injection

> Reusable reference derived from PortSwigger lab:
> `reflected-xss-csp-policy-injection` (see its folder for the worked case).
> First CSP lab in the KB — all prior labs noted CSP's ABSENCE as an enabler.

## Definition
CSP policy injection: attacker-influenced bytes reach a `Content-Security-Policy`
(response header or `<meta>`) unsanitized for the POLICY grammar, and a delimiter
(`;`, sometimes `,`) smuggles live directives into the enforced policy — typically
re-permitting the very sink the policy was deployed to contain.

## The core mechanics
- Policies split into directives on `;` BEFORE value contexts are considered. Any
  raw `;` in attacker-controlled header bytes starts a new directive.
- Directive-combination semantics decide impact (not all injections loosen):
  `script-src-elem` OVERRIDES `script-src` for `<script>` elements (Chromium);
  multiple `script-src` INTERSECT (tighten); first `report-uri` WINS (later ignored).
- Know which forged directive changes YOUR sink; verify with A/B (blocked vs fired).

## Recognition checklist
1. Attacker bytes in the policy: `report-uri` tokens/URLs, reflected nonces,
   `Report-To` JSON with request data, policy preview/debug endpoints.
2. Diff the CSP header across requests with different param values — moving bytes
   are injectable bytes.
3. Candidate delimiters: `;` (directives), `,` (source lists in some positions),
   whitespace (source separation — rarely smuggleable usefully).
4. Target directives per sink: inline scripts → `script-src[-elem] 'unsafe-inline'`;
   external scripts → `script-src <attacker-origin>`; plugins → `object-src`;
   forms → `form-action`; frames → `frame-src`; base hijack → `base-uri`.
5. Browser gates: `script-src-elem` (Chromium), `navigate-to` (Chromium), strict-dynamic
   semantics — verify per engine.

## Verification methodology (reusable)
1. Marker-in-header proof (attacker bytes verbatim in the policy?).
2. A/B: payload alone (must BLOCK) vs payload + injection (must FIRE) — the
   load-bearing pair proving the policy was the barrier AND is now defeated.
3. Dump the enforced bytes (confirm the forged directive survives verbatim).
4. Inventory sound clauses (what STILL holds — scope honesty).
5. Real-browser acceptance.

## Impact frame
- A bypassed CSP contributes NOTHING — assess as unprotected XSS from that point.
- Worse: compliance/audit reliance on the policy ("XSS mitigated by CSP") voids
  silently; the bypass is invisible to scanners checking header presence.
- Report-endpoint confusion is a secondary effect (mangled report-uri misroutes
  defender telemetry).

## Fix shape (recognition = know the fix)
Strict allow-list formats for anything entering the policy (hex/alphanumeric fixed
length), or server-side token stores keyed by session (no request data in headers
at all). Never interpolate request bytes into security headers without
delimiter-stripping. Consider `report-to` (JSON, structured) over `report-uri`
(string-concatenated) for new code.