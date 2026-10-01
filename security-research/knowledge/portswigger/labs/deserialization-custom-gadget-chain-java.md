# PortSwigger Lab

## Lab

Developing a custom gadget chain for Java deserialization

URL: https://0a1800b10446149a8279ecaf00060082.web-security-academy.net/

## Vulnerability Class

Deserialization – custom Java gadget (`ProductTemplate.readObject` → string-interpolated Postgres SQL) via unsigned session cookie → SQL injection → credential extraction → vertical escalation

## Objective

Obtain administrator password via deserialized-SQLi gadget chain, log in as administrator, delete carlos. Established by lab description objective (read for goal + source pointers; payload shapes derived from disclosed source + prior SQLi discipline, validated by errors).

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty session, shop with string productIds (`PROD1`…), HTML comment `<!-- <a href=/backup/AccessTokenUser.java>Example user</a> -->` – source pointer (current evidence).
- `/backup/` index → `AccessTokenUser.java` (486B: simple `Serializable` bean `username`+`accessToken`, no gadget) + `ProductTemplate.java` (1651B: `Serializable`, `serialVersionUID=1L`, `private final String id`, `transient Product product`, `readObject` runs `SELECT * FROM products WHERE id = '%s'` via `String.format`, Postgres driver).
- `POST /login wiener:peter` → 302 + Java session `rO0ABXNyAC9sYWI...` (`lab.actions.common.serializable.AccessTokenUser`, `rO0A` magic – same runtime as prior CC4 lab, different sink).
- No cart/basket (`/cart`, `/basket` → 404); product pages set no object cookies. Sink must be the session deserializer accepting any class (prior CC4 lab proved generic `readObject` on session bytes).
- Stored methodology `methodology/deserialization.md` (read – PHP flag/path, Java CC4, PHP custom gadget; no readObject→SQLi pattern). Stored `methodology/injection.md` (UNION/error-based SQLi discipline) relevant as secondary source for extraction syntax.

## Hypotheses

- H1: Session deserializer instantiates whatever class the bytes name. Supplying serialized `data.productcatalog.ProductTemplate` with malicious `id` executes `readObject` → SQLi during session parse.
- H2: `id="'"` → Postgres `Unterminated string literal` error (proves SQLi + reveals query shape). Evidence needed: reflected SQL text in 500.
- H3: UNION error-based extraction (`CAST(password AS numeric)` into non-string column) reflects `users.password` in error; first row = administrator. Then login → `/admin` → delete carlos → `is-solved`.

## Attempts

1. Baseline `GET /` + `POST /login` → Java session captured (shape recorded, not modified).
2. `/backup/` recon → both Java sources captured – gadget + query shape mapped before crafting (2 requests).
3. No `javac` on host (only JRE 25) – wrote `/tmp/opencode/ser_product_template.py` (outside repo): hand-builds stream (`ACED0005/73/72/class 35B/uid=1/02/1 field L:id/String/78/70/74+len+payload`) mirroring validated `AccessTokenUser` bytes; base64+URL-encodes.
4. `id="'"` as session → `500: Unterminated string literal ... SELECT * FROM products WHERE id = ''' LIMIT 1` – H1+H2 confirmed, serializer validated, query shape leaked.
5. `id="' UNION SELECT NULL×8--"` → `500 ClassCastException: Cannot cast ProductTemplate to AccessTokenUser` (NO SQL error) – 8 columns confirmed in ONE probe: success-oracle is exception-type flip (SQL error vs cast error), not content.
6. `id="' UNION SELECT NULL,NULL,NULL,CAST(password AS numeric),NULL,NULL,NULL,NULL FROM users--"` → `500 invalid input syntax for type numeric: "hcwbv1sguqwi0cp9gzma"` – password extracted in ONE probe (column 4 non-string, per theory).
7. `POST /login administrator:hcwbv1sguqwi0cp9gzma` → 302 to `/my-account?id=administrator` – credential verified by use, not assumed admin.
8. `GET /admin` (admin session) → 200 Users (`wiener`, `carlos` + delete links) → `GET /admin/delete?username=carlos` → 302 → `GET /` → `is-solved`/`Solved`/`Congratulations`.

## What Failed

- Nothing material. No column-count brute force (8 proven by single exception-flip), no per-column type matrix (column-4 CAST worked first try), no JDK install needed (Python serializer sufficed).

## What Worked

- Python-built `ProductTemplate` session objects + 3 injections (quote-proof, count-proof, CAST-extract) → admin login → victim delete → solved. 8 requests total.

## Burp Observations

- Baseline, login (302 + Java session), admin login (302), `/admin` 200 + delete links, delete 302, final `is-solved` – all via Burp MCP (evidence-grade).
- Trigger injections via curl (4KB cookies – CLI pragmatism, same HTTP semantics). Error bodies (`is-warning` `<p>`) carried the oracle.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `python3` serializer (no JDK needed – format mirrored from known-good bytes); `curl -sk -i` for triggers, `grep` for error-oracle extraction. No scanner/crawler/fuzzer.

## Root Cause

Custom gadget over unsigned Java serialization: session bytes control the deserialized CLASS, and `ProductTemplate.readObject` interpolates its `id` field into SQL (`String.format` + Postgres). Attacker string → object → query. `transient product` does not protect – `readObject` re-queries from tainted `id`. Chain: session cookie → `readObject` → SQLi → credential leak → auth bypass → admin function.

## Verification

- Quote probe leaked full query text (shape proof).
- 8-NULL UNION flipped oracle from SQL-error to cast-error (count proof, single variable).
- CAST probe reflected password string (value proof).
- Password USED to log in (302 + administrator identity page + `/admin` 200 + user list) – not assumed from row order.
- Victim delete (302) + global `is-solved` – state proof, not status-alone.

## Impact

Authenticated SQL injection via deserialization (demonstrated credential extraction), chained to full admin compromise (victim deletion). Same primitive yields arbitrary table reads where DB account permits; RCE-class impact via auth bypass rather than command execution.

## Why The Successful Approach Worked

- Read the pointer (HTML comment) + both sources + query shape BEFORE crafting – gadget derived from current code.
- Recognized dual oracle: SQL-error (bad query) vs cast-error (good query, wrong expected type) – count proven without content.
- Reused error-based `CAST(... AS numeric)` reflection from SQLi discipline (value in exception text) instead of blind extraction.
- Built serializer without JDK by mirroring validated bytes (magic/classdesc/field/78/70/value) – format knowledge substituted for toolchain.

## Generalization

- For Java sessions + disclosed `readObject` with SQL: replicate class bytes (name/uid/fields) in any language → quote-proof (`'`) → count via exception-flip (UNION NULLs until SQL-error becomes cast-error) → CAST-extract into reflected error → use credential (login) → admin action → solved marker.
- Exception TYPE is the oracle: `PSQLException` (query bad) vs `ClassCastException` (query good, session-type mismatch). Do not conflate 500s – read the class name.
- `serialVersionUID` + FQN must match; `transient` fields need no replication (skipped in stream).

## Lessons Learned

- Deserialization gadget ≠ RCE-only: `readObject` can be a SQLi gadget (injection via object field). Cross-topic composition (deserialization × SQLi) solves faster than either alone.
- No-JDK serialization is practical: one known-good stream + spec constants (`ACED0005/73/72/78/70/74`) reproduces any simple bean.
- Minimal probes win: 3 injections (quote/count/extract) when each oracle is fully characterized first.

## Related Methodology

- Extends `methodology/deserialization.md` (no readObject→SQLi pattern – update justified below; 5th deserialization lab, new sub-technique bridging SQLi).
- Secondary: `methodology/injection.md` (UNION count + error-based CAST reflection – applied, not modified; belongs to SQLi, already covers it).
- Priors: `deserialization-java-apache-commons.md` (rO0 session discipline, 500-trigger oracle), `deserialization-custom-gadget-chain-php.md` (source-driven graphing).

## References

- Solved instance: https://0a1800b10446149a8279ecaf00060082.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-developing-a-custom-gadget-chain-for-java-deserialization
- Sources (current evidence): `/backup/AccessTokenUser.java`, `/backup/ProductTemplate.java`, quote-error query leak
- Serializer: `/tmp/opencode/ser_product_template.py` (work artifact, outside repo)
- Extracted credential used, then archived here for record: administrator / hcwbv1sguqwi0cp9gzma (instance-bound, expired with lab)
