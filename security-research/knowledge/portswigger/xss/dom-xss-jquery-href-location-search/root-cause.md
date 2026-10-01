# Root Cause — jQuery anchor-href sink sourced from location.search

## The vulnerability
Client-side code copies the `returnPath` query parameter verbatim into the `href`
attribute of the "Back" anchor via jQuery `.attr()`. An attacker who controls the URL
controls the link target; a `javascript:` target turns a click into arbitrary script
execution in the application's origin.

## Root cause (framing)
- **Dangerous sink**: anchor `href` (and equivalents: `location=`, `location.href=`,
  `window.open()`, form `action`, `src`/`srcdoc` setters) interprets certain URI schemes
  as code. Assigning URL-derived data to it without scheme validation hands the attacker
  a code-execution primitive gated only by one click.
- **Dangerous source**: `location.search` is fully attacker-controlled.
- **Missing boundary**: no allow-list of paths, no `javascript:`-scheme rejection, no
  same-origin check, no Trusted Types enforcement between the source read and the sink.
- Failed assumption: *"a link target is navigation data, not code."* For `javascript:`
  URIs that assumption is false — navigation IS execution. This is the **data → code**
  boundary, and it sits at **click time**, not parse time (unlike `document.write` /
  `innerHTML` labs).

## Trust boundary model
```
Attacker URL ──► location.search ──► URLSearchParams.get ──► JS string (data)
                                                                     │
              [PLANTED — inert until interaction]
                                                                     ▼
                    $('#backLink').attr("href", value)  →  poisoned anchor
                                                                     │
              [TRUST BOUNDARY: navigation(data) → execution(code), AT CLICK]
                                                                     ▼
                              javascript: URI runs in page origin (victim context)
```

## Why this differs from the sibling labs
| Lab | Sink | Execution moment | Payload shape |
|---|---|---|---|
| `document.write` | markup parser | page load | HTML + `"`/`>` breakout, `<script>` works |
| `innerHTML` | fragment parser | resource error / auto event | event-handler element, no breakout |
| **this lab (jQuery href)** | navigation target | **user click** | URI with script scheme, no markup at all |

## Enabling conditions (checklist)
1. URL-derived string assigned to a navigation-capable attribute/property (`href`,
   `src`, `action`, `location`, `open()`).
2. No scheme allow-listing (`http(s)` + relative only) and no `javascript:`/`data:`/`vbscript:` rejection.
3. A plausible-looking link the victim will click ("Back", breadcrumb, logo, cancel,
   continue) — social-engineering surface is built into the feature.
4. No `Content-Security-Policy` restricting `javascript:` navigation (no CSP here).

## Fix shape (recognition = know the fix)
Validate `returnPath` against an allow-list of same-origin relative paths (reject
anything matching `^\s*\w+:` scheme syntax), or drop the parameter and hard-code the
target. Defense-in-depth: CSP `script-src` does not block `javascript:`-URI navigation
in all browsers — scheme validation at the sink is the real fix.