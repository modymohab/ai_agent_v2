# PortSwigger Lab

## Lab

Developing a custom gadget chain for PHP deserialization

URL: https://0a5700f90493b07c8119e88c00850022.web-security-academy.net/

## Vulnerability Class

Deserialization – custom PHP gadget chain (`CustomTemplate.__wakeup` → `Product` property access → `DefaultMap.__get` → `call_user_func(exec)`) via unsigned base64 session cookie → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via crafted serialized `CustomTemplate` session object. Established by prior deserialization-lab pattern (3 prior labs all delete `morale.txt`) + `is-solved` flip after trigger. Official description not fetched; source (`/cgi-bin/libs/CustomTemplate.php~`) gave gadget structure directly.

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty session, shop + `/my-account`, HTML comment `TODO: Refactor once /cgi-bin/libs/CustomTemplate.php is updated` – direct pointer to gadget source (current evidence, not stored).
- `POST /login wiener:peter` → 302, `session=Tzo0OiJVc2VyIjoyOntzOjg6InVzZXJuYW1lIjtzOjY6IndpZW5lciI7czoxMjoiYWNjZXNzX3Rva2VuIjtzOjMyOiJkdjIzc2ZqOG00bzh4NjI4ZG51OWRqaXM1amsxbXprZiI7fQ%3d%3d` → decoded `O:4:"User":2:{s:8:"username";s:6:"wiener";s:12:"access_token";s:32:"...";}` – 2-field User, no `admin`/`avatar_link` (differs from both prior PHP labs – payloads do not transfer).
- `/cgi-bin/libs/` → 404 (no index) but `/cgi-bin/libs/CustomTemplate.php~` → 200 `text/plain` 1396B full source (backup-extension disclosure, same technique as prior PHAR lab's `Blog.php~`).
- Source classes: `CustomTemplate{private default_desc_type, private desc, public product}` with `__sleep->[default_desc_type,desc]`, `__wakeup->build_product`, `build_product: product=new Product(default_desc_type, desc)`, `Product::__construct: desc=$desc->$default_desc_type`, `DefaultMap{private callback}` with `__get($name)=call_user_func(callback, $name)`.
- Stored methodology `methodology/deserialization.md` (read, 90 lines) covers PHP flag/path + Java CC4, no custom-gadget section. No prior custom-gadget labs.

## Hypotheses

- H1: Chain `CustomTemplate(desc=DefaultMap('exec'), default_desc_type='<cmd>')` → on unserialize `__wakeup` → `new Product('<cmd>', DefaultMap)` → `$desc-><cmd>` hits `__get` → `exec('<cmd>')`. `<cmd>=rm /home/carlos/morale.txt`.
- H2: Session cookie is the deserialization sink (unsigned base64, as in prior PHP labs). Any authenticated request with crafted cookie triggers `__wakeup` during session parse.
- H3: Trigger may 500 (gadget side-effects) while still solving – same oracle as Java CC4 lab. Evidence needed: 500 on trigger + global `is-solved`.

## Attempts

1. Baseline `GET /` + `POST /login` → session captured, decoded – shape recorded (2-field User+token).
2. HTML-comment pointer → `GET /cgi-bin/libs/CustomTemplate.php~` → source captured – gadget mapped without guessing.
3. Wrote `/tmp/opencode/gen_custom_gadget.php` (outside repo) with matching class/property names; `ReflectionClass` to set private `desc=DefaultMap('exec')`; `new CustomTemplate('rm /home/carlos/morale.txt')`; `serialize` → base64 → URL-encode (279B). Local serialization includes `product=N` (no local `__sleep`) – harmless: server `__wakeup` overwrites `product`.
4. `GET /my-account?id=wiener` with gadget session via curl (large cookie) → `HTTP/2 500`. WORKED as H3 predicted.
5. Anon `GET /` + Burp `GET /` → `is-solved` / `Solved` / `Congratulations`.

## What Failed

- Nothing material. No dead ends; first gadget worked. Did not need `__sleep` replication locally, backup account, or browser.

## What Worked

- Single crafted `CustomTemplate` cookie → 500 trigger → global solved marker.

## Burp Observations

- Baseline, login (302 + Java-free PHP session), and final proof (`200 is-solved`) via Burp MCP.
- Trigger via curl for 279B cookie pragmatism (same HTTP semantics). `burp_base64_decode` confirmed session shape.

## Browser Observations

- Not required. Pure HTTP cookie replay.

## CLI / Tool Observations

- `php` + `ReflectionClass` for private-property gadget building; `curl -sk -i` for trigger (500 captured), `grep is-solved` + Burp for proof. No scanner/crawler/fuzzer – no discovery question.

## Root Cause

Custom gadget chain over unsigned PHP serialization: attacker-controlled `session` bytes unserialize into `CustomTemplate`; `__wakeup→build_product→new Product(cmd, DefaultMap)` turns attacker string into property name; missing property invokes `DefaultMap::__get` → `call_user_func('exec', cmd)` → OS command. Data (cookie) → object graph (`__wakeup`) → dynamic property access → magic-method function call → RCE. `__sleep` exclusion of `product` does not protect – `__wakeup` rebuilds it from tainted fields.

## Verification

- Single variable: only `session` cookie replaced (baseline token → gadget object).
- Trigger 500 (deserialization path hit) + anon global `is-solved` (not session-local).
- Did not rely on 500/200 alone – relied on `is-solved`/`Solved`/`Congratulations` marker.

## Impact

Remote code execution as app user (demonstrated `rm`). Same primitive yields reverse shell/exfiltration with other commands. Higher than flag/path labs – full `exec` sink.

## Why The Successful Approach Worked

- Read the pointer (HTML comment) and source (`~` backup) before crafting – gadget derived from current code, not remembered payloads.
- Recognized `__get` + `call_user_func` as arbitrary-call sink and `$desc->$default_desc_type` as attacker-controlled property-name bridge – composed chain entry→bridge→sink.
- Accepted 500-trigger oracle from Java-lab lesson instead of retrying for 200.

## Generalization

- For PHP libs with `__wakeup`/`__destruct` + dynamic property/method calls: read `~`/backup sources → map entry (`__wakeup`/`__destruct`) → bridge (`->$var`, `$var()`, `call_user_func($var)`) → sink (`exec`, `unlink`, `file_put_contents`) → build object graph with matching class/private names → serialize locally (private encoding automatic) → base64+URL → replay as session → check global marker even on 500.
- `__sleep` on server does not sanitize – it only selects stored fields; `__wakeup` re-derives danger from them.
- HTML comments disclosing lib paths + `~` backups are first-class recon for gadget source.

## Lessons Learned

- Custom-gadget labs are source-driven, not payload-driven: prior `admin b:1` / `avatar_link` / `CC4` payloads were all inapplicable (different classes). Only discipline transferred.
- `DefaultMap.__get→call_user_func` is the canonical arbitrary-call gadget shape; `$x->$y` with controlled `$y` is the canonical bridge.
- Backup-extension (`~`) disclosure justified one recon request each – cheapest source primitive.

## Related Methodology

- Extends `methodology/deserialization.md` (custom-gadget section missing – update justified below; 4th deserialization lab, new sub-technique).
- `methodology/injection.md` does NOT apply (query/shell vs `unserialize→__wakeup→__get→exec`). Deliberately not modified.
- Priors: `deserialization-modifying-serialized-objects.md` (unsigned-cookie discipline), `deserialization-using-application-functionality.md` (length handling), `deserialization-java-apache-commons.md` (500-trigger oracle).

## References

- Solved instance: https://0a5700f90493b07c8119e88c00850022.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-developing-a-custom-gadget-chain-for-php-deserialization
- Sources (current evidence): `/cgi-bin/libs/CustomTemplate.php~` (1396B, via Burp), homepage HTML comment pointer
- Deliberately did NOT fetch official solution; gadget derived from disclosed source + stored patterns.
