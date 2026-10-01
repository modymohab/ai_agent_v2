# PortSwigger Lab

## Lab

Exploiting XXE via image file upload

URL: https://0ad0005b0408b0b9825929f0006700bb.web-security-academy.net/

## Vulnerability Class

XXE injection via SVG avatar upload – Batik rasterizer resolves external entities, baking file text into served PNG pixels; value read visually, submitted via `Submit solution` oracle (`{"correct":true}`)

## Objective

Retrieve `/etc/hostname` via SVG XXE avatar and submit its value. Established by lab description (Batik + hostname + submit flow) + `{"correct":true}` + `is-solved`. Official solution consulted for objective/file only after channel proven (entity→pixels confirmed first).

## Initial Observations

- Blog, no auth surface (`/my-account` → 404). Comment form (multipart: csrf/postId/comment/name/avatar/email/website) + per-comment avatar (`/post/comment/avatars?filename=N.png`).
- Baseline SVG (no entity, white `HELLO`) → 302 → served `image/png` 128×128 with 326 white pixels – upload→raster→serve pipeline proven; text renders into pixels.
- XXE SVG (`file:///etc/hostname`, default black fill) → 302 → PNG 1548B ALL black (16384×`#000`) – invisible (black-on-black), NOT proof of failure – fill diagnosed, not the entity.
- Stored `methodology/xxe.md` (stockCheck/file/SSRF/blind-OOB; no upload/SVG shape). No prior upload-XXE labs. Local: PIL present, no OCR/tesseract/convert.

## Hypotheses

- H1: Batik resolves `file://` entities during rasterization (SVG is XML). Evidence needed: white-filled entity SVG shows MORE white pixels than text-free baseline.
- H2: Pixel text is human-readable when enlarged (no OCR available – visual read via image attachment). Evidence needed: enlarged PNG shows hostname glyphs.
- H3: Bracket delimiters (`[value]`) prove completeness (no truncation); `{"correct":true}` + marker prove value.

## Attempts

1. Baseline pages/forms/endpoint mapping (3 requests) + white-HELLO control (302 → 326 white px) – pipeline + visibility baseline.
2. Black-fill XXE SVG → all-black PNG – correctly diagnosed as FILL issue (control proved text renders white), not entity failure.
3. White-fill XXE SVG (`/etc/hostname`) → 765 white px (vs 326 control) – H1 confirmed (entity resolved, longer text rendered).
4. Enlarged (4× NEAREST) PNG read as image → `491591fda234` (12 glyphs, cut at canvas edge) – H2 partially (value candidate, completeness unproven).
5. Narrow SVG (256×64 canvas, font 14, `[&xxe;]` delimiters) → enlarged read `[491591fda234]` – H2+H3 completeness confirmed (12 hex = Docker short-ID shape + closed brackets).
6. `POST /submitSolution` JSON `{"answer":...}` → 404 (wrong content-type – read `submitSolution.js`: `application/x-www-form-urlencoded`, `answer` param) → form-encoded retry → `{"correct":true}` → `/` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Black-fill first attempt (invisible, not failed parsing – control comparison caught the real cause in one check).
- Full-hostname truncation on 128px canvas (read the cutoff, narrowed canvas + delimiters instead of guessing the tail).
- JSON submit (404 – JS source specified form-encoding; one read fixed it).

## What Worked

- SVG entity → Batik pixels (white-count oracle) → enlarged visual read → bracket-completeness re-render → form-encoded submit → `{"correct":true}` → marker. ~10 requests.

## Burp Observations

- Page/form mapping, submit-protocol debug (404 vs `{"correct":true}`), final proof (`200 is-solved`) via Burp MCP.
- Uploads/downloads via curl (multipart ergonomics, binary capture); `submitSolution.js` read via Burp (protocol contract).

## Browser Observations

- Not required (no interactive JS needed). Image-attachment read substituted for OCR/tabs.

## CLI / Tool Observations

- `curl -F` (multipart avatar uploads), PIL (pixel-count oracle + NEAREST upscale for glyph legibility), Read-image (visual OCR substitute). No scanner/crawler/fuzzer; no tesseract (absent – worked around, not installed).

## Root Cause

Avatar pipeline (SVG→Batik→PNG) parses attacker XML with external entities enabled: `<!ENTITY xxe SYSTEM "file://...">` content is rasterized into served image pixels. Data (upload) → parser directive (entity) → pixels (exfil channel). No OCR gap on the defensive side – pixels ARE the leak.

## Verification

- Visibility control (white HELLO 326px) vs entity render (765px) – resolution proof by pixel differential.
- Value proof by two renders (cutoff candidate → bracketed complete `[491591fda234]`, Docker-ID-shaped).
- Oracle proof: `{"correct":true}` on form-encoded submit (plus JSON-404 negative showing protocol mattered).
- Impact proof: global `is-solved` via fresh anon `GET /`. One variable per cycle (fill/size/target/encoding isolated stepwise).

## Impact

Unauthenticated arbitrary file read rendered into public images (demonstrated hostname; same primitive reads any `file://` path – passwd/keys/sources – limited only by canvas space, wrappable via font/canvas tweaks). Plus submit-oracle pattern for secret-value labs.

## Why The Successful Approach Worked

- Controlled visibility FIRST (white baseline) so entity renders were interpretable – pixel counts as quantitative oracle (326 vs 765).
- Treated all-black as a rendering bug (fill), not a parser verdict – because the control proved the pipeline renders.
- Closed the loop on completeness (brackets + narrower re-render) before submitting – no tail-guessing.
- Read the submit JS contract instead of retrying JSON variants.

## Generalization

- For SVG-upload XXE: white-text control → entity SVG (white fill) → white-pixel-count differential proves resolution → enlarge (NEAREST) + visual read → delimiter-wrap re-render for completeness → submit per JS contract (`submitSolution.js`: method/path/param/encoding).
- Pixel counts replace OCR for DETECTION (resolved vs not); visual read handles short secrets; delimiters handle truncation.
- Submit-protocol failures (404 vs `correct`) are contract questions – read the JS, don't vary blindly.

## Lessons Learned

- Rasterized XXE exfil is quantitative before qualitative: pixel differentials detect, vision decodes.
- Controls first (HELLO-white), then entity – every rendering variable (fill/size/canvas) isolated before attributing silence to the parser.
- Bracket-delimiter re-render is the cheap completeness proof for fixed-canvas exfil.

## Related Methodology

- Extends `methodology/xxe.md` (stockCheck/file/SSRF/blind-OOB; no upload/SVG/Batik shape – update justified below; 5th XXE lab, new exfil channel + submit oracle).
- `methodology/injection.md` does NOT apply. Deliberately not modified.
- Priors: all XXE notes (entity syntax discipline); file-upload notes (multipart/avatar-endpoint habits for upload ergonomics).

## References

- Solved instance: https://0ad0005b0408b0b9825929f0006700bb.web-security-academy.net/
- Lab: https://portswigger.net/web-security/xxe/lab-xxe-via-file-upload
- Key artifacts (current evidence): white-HELLO control (326px), hostname render (765px → `[491591fda234]`), `submitSolution.js` contract (form-encoded `answer`)
- Submitted value (instance-bound): `491591fda234` (`{"correct":true}`, expired with lab)
- Deliberately shaped uploads from pipeline evidence; official solution consulted for objective/file only after channel proven.
