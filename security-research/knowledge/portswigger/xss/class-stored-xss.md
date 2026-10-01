# Class Knowledge — Stored / Persistent XSS

> Reusable reference derived from PortSwigger lab:
> `stored-xss-html-context-nothing-encoded` (see its folder for the worked case).

## Definition
Stored XSS (a.k.a. persistent / second-order XSS) occurs when attacker-controlled input is
**persisted by the server** and later rendered, **unsafely**, into the HTML served to other
users. Payload delivery is decoupled from the request that stored it.

## The trust-boundary model
```
Input (attacker) ── store ──► persistence ── render (no encoding) ──► HTML parser (victim)
                                   ^                                ^
                                   │                TRUST BOUNDARY: data→code
                       [injection occurs here when payload is re-read]
```
Distinguishing trait vs reflected: attack survives a **request boundary** — a payload
submitted through any channel (comment form, profile field, ticket, upload metadata,
headers stored in DB) executes whenever **any** user hits the page that renders it.

## Recognition checklist (recon conditions)
1. Exists an input accepted by the app and **stored server-side** (user content, profile,
   logs, uploaded file metadata, review, moderation decisions, error messages saved to DB).
2. Some page re-displays that stored content **to other users** (public or admin views).
3. The re-render path does **not** context-appropriately encode or sanitize.
4. No restrictive CSP (allows inline script) — otherwise fall to event-handler/jQuery routes.

## Field context mapping (the core skill)
A single form may have 4+ fields landing in DIFFERENT contexts. Always map them all in ONE
probe request using unique markers:
- text node (`<p>MARK</p>`) → need `<` `>` (or `&lt;`? no—raw means raw) to break out;
  `<script>` works only if context is script-allowed and encoding absent.
- attribute value (double-quoted) → need `"` to close attr + new event/`>`; encoding of `"`
  as `&quot;` blocks breakout because browser decodes only inside the value.
- `<a>` content / URL fields → href/srckeyword abuse if `javascript:` allowed or encoding
  of quotes absent.
- script block (`<script>var x="…"</script>` or JSON) → `"` breakout → JS injection;
  `</script>` only if encoder doesn't handle it.
- attribute **inside** tags like `<img src=x onerror=…>` depends on tag whitelist presence.

## Payload strategy per context (only AFTER mapping)
| Context | Probe | Breakout requires |
|---|---|---|
| raw text node in `<p>`/`<div>` | `<script>alert(1)</script>` | nothing else |
| tag-whitelist HTML | `<img src=x onerror=alert(1)>` / `<svg onload=…>` | allowed tag + event handler |
| double-quoted attribute | `" onclick="alert(1)` | unencoded `"`; `&quot;` blocks it |
| URI-valued attribute (`href`/`src`/`action`), quotes ENCODED | `javascript:alert(1)` as the whole value | NO breakout needed — needs ABSENT scheme validation (lab: `stored-xss-anchor-href-double-quotes-encoded`) |
| script/JS context | `" ;alert(1)//` or `<\/script><script>alert(1)</script>` | unencoded quotes/backslashes |
| CSS/JSS-contexts | `}body{…}` / `javascript:` schemes (image src / link href) | absence of scheme/context filtering |

## Fix pattern (recognition = know the fix)
Context-aware output encoding at the **render boundary**, consistently applied to *every*
field; never rely on "input filtering" alone (filter bypasses are common and encoding
coverage gaps are the actual bug class here).
For URI-valued attributes, encoding delimiters is INSUFFICIENT on its own — additionally
enforce a scheme allow-list (`http(s)` + relative paths; reject `javascript:`/`data:`/
`vbscript:`). Quote-encoding without scheme validation leaves the whole-value degree of
freedom open (proven: `stored-xss-anchor-href-double-quotes-encoded`).

## Entity-smuggling through late decode stages (lab `stored-xss-onclick-entity-decode`)
An escaper handling `'"<>\` but leaving `&` raw is bypassed with `&apos;` (or
`&#x27;`/`&quot;` per quoting): stored inert, decoded to a live delimiter when the
victim parser computes the attribute value — AFTER (downstream of) the defense.
Rules: encode `&` FIRST, always (dual of backslash-first); assert on DECODED values
(`getAttribute`, never raw grep) for code sinks; keep smuggled inner payloads
quoteless; parenthesize `-x=` assignments (precedence); sync-read clicks on
navigating anchors before href-navigation destroys evidence. Decode-stage matrix:
HTML-entity, URL-percent, JS-escape, CSS-escape — evaluate every escaper against its
DOWNSTREAM decoders, never just its input alphabet.

## Impact pedigree (tiers)
- Mass exploitation vs reflected: one store → all future viewers; no luring.
- Admin-view pages: converge to full-org impact if admins moderate/listen to the content.
- Second-order sinks: stored value later consumed by a *different* sink (e.g., admin clicks
  a stored URL, exports stored text into a report file → stored XSS into file-download /
  HTML-export / SSRF / template engines).
- Persistence = durable backdoor if combined with an authenticated write primitive
  (self-propagation / worm potential).

## Verification do's (reusable)
- Markers: unique strings per field; diff rendered DOM for encoding.
- Prove persistence: re-fetch in fresh session/delayed request.
- Prove execution: non-blocking probe (`document.title=…`) or CDP dialog handler; note
  `alert()` freezes headless dump (hang is a symptom, not an assertion).
- Separate stored vs reflected: check a *second* independent viewer context.