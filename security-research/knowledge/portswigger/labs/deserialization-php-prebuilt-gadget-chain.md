# PortSwigger Lab

## Lab

Exploiting PHP deserialization with a pre-built gadget chain

URL: https://0a61005d0402349e80d81ce600a6005b.web-security-academy.net/

## Vulnerability Class

Deserialization – signed PHP session cookie (HMAC-SHA1 with phpinfo-leaked key) carrying phpggc pre-built gadget chain (`Symfony/RCE4`, CVE-2019-18889) → RCE (file delete)

## Objective

Delete `/home/carlos/morale.txt` via malicious signed session object. Established by deserialization-lab pattern (prior RCE labs delete `morale.txt`) + `is-solved` flip after trigger. Official description not fetched; chain selected from current evidence (framework version), not memory.

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty session, shop (integer productIds) + `/my-account`.
- `POST /login wiener:peter` → 302 + `session={"token":"Tzo0...","sig_hmac_sha1":"2f24..."}` (URL-encoded JSON) – FIRST signed session in this KB (priors unsigned). Token decodes to familiar `O:4:"User":2:{username wiener, access_token 32c}`.
- `/my-account?id=wiener` → 200 account page + `<!-- <a href=/cgi-bin/phpinfo.php>Debug</a> -->` – pointer (current evidence).
- `/cgi-bin/phpinfo.php` → 200, 69KB, PHP 7.4.3: `SECRET_KEY=bhd0ey3lcgncywdvymlu4xj2u17tp55k` in Environment (signing key leak), app at `/home/carlos/cgi-bin/`, user `carlos`. No `libs/` dir (`/cgi-bin/libs/` → 404) – no app-specific gadget source this time.
- No prior signed-cookie or phpggc labs in repo. Local: PHP 8.4, no phpggc.

## Hypotheses

- H1: `sig_hmac_sha1 = HMAC-SHA1(base64_token, SECRET_KEY)`. Evidence needed: recompute over captured token equals `2f24...` (signing oracle – no exploit yet).
- H2: Framework gadget available server-side; error on first gadget trial will name it (`Symfony Version: 4.3.6` or Monolog absence via `__PHP_Incomplete_Class` silence). Evidence needed: version string in trigger error.
- H3: phpggc chain matching that version + `system('rm ...')`, signed with leaked key, fires on session parse → `is-solved`.

## Attempts

1. Baseline `GET /` + `POST /login` → signed session captured, token shape recorded.
2. Comment pointer → `/cgi-bin/phpinfo.php` → `SECRET_KEY` captured (grep, delegated to file to save context).
3. Signing-oracle check: `HMAC-SHA1(captured token, captured key)` → `2f241622...` EXACT match – H1 confirmed without sending anything.
4. `git clone ambionics/phpggc` → `/tmp/opencode/phpggc` (outside repo). First guess `Monolog/RCE1 system 'rm ...'` (widest PHP-chain habit) → signed → trigger → `500 Invalid user in /var/www/index.php:13` + `Symfony Version: 4.3.6`, still `is-notsolved` – USEFUL failure: signature accepted (no HMAC error), app rejected non-User type, Monolog absent (no-op), framework fingerprinted.
5. `phpggc -l Symfony` → exact-range `RCE4 (4.3.0-7, CVE-2019-18889)` matches 4.3.6 → generated (519B, `Symfony` + cmd embedded) → signed → `GET /my-account?id=wiener` → `500` → `/` → `is-solved`. H2+H3 confirmed.

## What Failed

- `Monolog/RCE1` – wrong-library guess (habit from generic PHP practice, not evidence). Diagnosed via `Invalid user` (proves signature path works, type check is the only gate) + `Symfony 4.3.6` version leak (redirects chain selection). One failed trigger, high information value.

## What Worked

- `phpggc Symfony/RCE4 system 'rm /home/carlos/morale.txt'` → base64 → HMAC-SHA1 → JSON session → cookie → 500 trigger → global solved marker.

## Burp Observations

- Baseline, login (302 + signed session), my-account (200 + Debug pointer), phpinfo (200 69KB), final proof (`200 is-solved`/`Solved`/`Congratulations`) via Burp MCP.
- Triggers via curl (large cookies). Trigger errors carried version/type oracles.

## Browser Observations

- Not required. No JS/state workflow.

## CLI / Tool Observations

- `git` (phpggc fetch), `php` (phpggc runner, local 8.4 generates 7.4-compatible payloads), `python3` (HMAC/base64/URL + signing-oracle check), `curl` (triggers/marker), `grep` (phpinfo mining via saved output). No scanner/crawler/fuzzer.

## Root Cause

Two compounding flaws: (1) HMAC signing key (`SECRET_KEY`) disclosed via debug `phpinfo.php` (Environment section), making the session signature forgeable – verified by oracle recomputation; (2) unsigned-equivalent trust after verify: verified bytes are `unserialize`d into whatever classes they name, and Symfony 4.3.6 gadget classes (`RCE4`) are autoloadable, ending in function-call RCE at `__destruct`. Leaked-key → forged-signed gadget object → RCE.

## Verification

- Oracle-level: recomputed HMAC equaled server signature (algorithm/key/input all proven before exploit).
- Negative control: Monolog payload signed identically → accepted-signature path (`Invalid user`, no HMAC error) but no RCE (wrong lib) – proves signature is the ONLY gate and gadget must match installed code.
- Positive: Symfony/RCE4 payload → `is-solved` via anon + Burp (global, not session-local). Single variable (session bytes; key constant).

## Impact

Remote code execution as app user (demonstrated file delete). Same primitive yields reverse shell/exfiltration. Key-leak additionally allows arbitrary session forgery (any object, any identity).

## Why The Successful Approach Worked

- Treated signature as a key-management problem first (phpinfo pointer → key → oracle math) instead of attacking crypto.
- Let the failed trigger fingerprint the framework (`Symfony 4.3.6`) instead of guessing chains – version-range match (RCE4 4.3.0-7) beat habit (Monolog).
- Kept failed payload as evidence (signature path proven working), so only the gadget – not the whole approach – needed changing.

## Generalization

- For `{"token","sig_hmac_sha1"}` sessions: login → recompute HMAC over captured token with any candidate key (phpinfo/robots/JS/env) until match (oracle before exploit) → `phpggc -l <framework-from-errors>` → pick chain whose range covers the leaked version → `phpggc <Chain> <fn> <cmd>` → sign → replay → global marker even on 500.
- `Invalid user`-style type errors after verify = signature OK, gadget/type wrong – read them as version/type oracles, not failures.
- phpinfo is a key oracle first, version oracle second: mine `SECRET*, *_KEY, *TOKEN*, *PASS*` + app paths + framework versions before choosing chains.

## Lessons Learned

- Signed ≠ safe when the key is disclosed alongside the verifier – check debug endpoints before assuming integrity.
- Framework-version-conditional chains: `-l` range match beats popularity (Monolog habit cost one request; RCE4 exact-range solved first try).
- Oracle hierarchy for signed gadgets: HMAC recompute (integrity) → type error (class gate) → version string (chain select) → solved marker (RCE proof).

## Related Methodology

- Extends `methodology/deserialization.md` (no signed-session/phpggc pattern – update justified below; 7th deserialization lab, first signed cookie + first framework-range chain selection).
- `methodology/injection.md` does NOT apply (no query/shell sink in session path). Deliberately not modified.
- Priors: all deserialization notes (unsigned-cookie discipline, 500-trigger oracle); Ruby note (primary-source + version-range method reused for chain selection).

## References

- Solved instance: https://0a61005d0402349e80d81ce600a6005b.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-exploiting-php-deserialization-with-a-pre-built-gadget-chain
- Key source (current evidence): `/cgi-bin/phpinfo.php` → `SECRET_KEY=bhd0ey3lcgncywdvymlu4xj2u17tp55k` (instance-bound, expired with lab)
- Tool: ambionics/phpggc (`Symfony/RCE4`, CVE-2019-18889); generators in `/tmp/opencode/` (outside repo)
- Deliberately did NOT fetch official solution; chain selected from leaked version evidence.
