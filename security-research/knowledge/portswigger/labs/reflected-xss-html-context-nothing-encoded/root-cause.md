# Root Cause — Reflected XSS, nothing encoded

## Vulnerability

Server reflects the `search` query parameter into the HTML response body without
HTML-encoding it, in an element-text position where the browser interprets
markup.

## Root cause

**Missing context-aware output encoding at the server-side renderer.**

The template writer interpolated a user string directly into the `<h1>` heading:

```
<h1>0 search results for '<SEARCH>'</h1>
```

No escaping of `<`, `>`, `&`, `"`, `'`, no policy/allow-list, no CSP. The server
correctly treats the parameter as *data* for the search operation, but *also*
emits it as *markup* for the response — the same bytes, two different trust
domains. This is the classic "data used as code" confusion.

## Assumptions that made the app vulnerable

1. "The value is wrapped in single quotes in the heading" — quotes have NO
   syntactic meaning inside element text content, so they provide zero defense.
2. "It's only a heading / only affects the current user" — reflected XSS
   executes in ANY viewer's browser; delivery is via link (phishing, sharing).
3. "URL-encoding of the request protects us" — URL-decoding happens at the HTTP
   layer before rendering; markup characters arrive decoded.
4. "The search feature is harmless so user input there is low-risk" — every
   reflection surface is an execution surface until proven otherwise.

## Why the exploit needed nothing fancier

- Element-text reflection: no attribute breakout (`">`) or JS-context
  manipulation required — a bare `<script>` tag in text content executes during
  initial parse.
- No filter: reflection is verbatim (see the double-encoded control that showed
  no decode-then-render pipeline either).
- No `X-XSS-Protection`/CSP effect on this lab for the `<script>` path.

## Class generalization

"When a server takes user input and places it into an HTML response without
encoding, EVERY markup character regains syntactic power in the browser.
Determine the exact context (text / attribute / script / URL / comment / CSS)
because each context demands a different payload to reach execution."