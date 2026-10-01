# Impact — DOM XSS in document.write inside select

## Applicability reasoning
The input (`storeId`) reaches `document.write` parsed in select/option context — a
browser-executable context with (proven) three live payload shapes, firing on page
load at the application origin. Relevant categories are **client-side, link-delivered**.
No server consumer, no storage, no state change in this chain.

## CONFIRMED
- **Load-time code execution at the application origin** on crafted product-URL visit,
  via THREE independent shapes (breakout+img, bare-img-in-option, bare-script) —
  distinct title markers + DOM-shape dumps + real-browser `alert(1)` + acceptance.
- **No interaction required** for any vector (resource-error and parser-inserted
  script both fire during load).
- **Pure DOM delivery**: zero server reflection — filters, WAFs, and server logs see
  only an opaque `storeId` string; only client execution differs.

## PLAUSIBLE (same primitive, not separately demonstrated)
- **Session theft / account takeover** in any authenticated context (e-commerce
  sessions, carts, stored payment profiles reachable from page JS).
- **Cart/order/payment-flow abuse** as the victim (the vulnerable app IS a shop —
  actions available to page JS include the stock/purchase flows).
- **Admin compromise** if staff open crafted product links (support, merchandising).
- **Phishing overlays / credential capture / keylogging** injected into the shop DOM.
- **Further auto-firing shapes** through the same sink (`<svg onload>`, `<details>`,
  `<body onload>`-style if wrapper escapable further, `onfocus`+`autofocus` inside
  option) — same primitive, interchangeable triggers.

## NOT APPLICABLE (structurally excluded or disproven)
| Category | Verdict | Basis |
|---|---|---|
| "Select context neutralizes markup" | NOT APPLICABLE (disproven ×3) | img fires in-option, script runs in-select, breakout works |
| Server-side code/command/SQL/OS/URL/XML/filesystem | NOT APPLICABLE | zero server reflection; no server consumer |
| Stored/persistent delivery | NOT APPLICABLE | per-load execution; fresh link per victim |
| State-change / CSRF abuse via THIS primitive | NOT APPLICABLE | `storeId` is read-only input to a renderer |
| Click/hover-gating | NOT APPLICABLE (better than that) | all vectors fire during load |

## NOT TESTED
- `POST /product/stock` endpoint security (separate feature; form shows no CSRF token
  — flagged as a surface worth its own assessment, not this lab's chain).
- CSP-hardened variants (no CSP here).
- Non-Chrome parser behavior for option-children leniency (Chrome 150 confirmed;
  other engines reasoned similar but unexecuted).

## What would increase impact in a real application
- **Authenticated shop**: victim sessions own money-moves (cart, checkout, saved
  cards) — one link = full shopping-session hijack.
- **Order/support staff tooling** rendering the same product pages → back-office ATO.
- **Reviews/Q&A with product links**: attacker plants crafted product URLs where
  shoppers browse organically (converts link-delivery into quasi-stored reach).
- **Absence of CSP** (true here) keeps all three shapes viable; even with CSP,
  the multi-shape redundancy means single-mechanism fixes (e.g. blocking only
  `<script>`) leave the handler shapes live.
- **Fragment (`#`) delivery variant**: if the same sink read `location.hash`,
  server logs would never even see the payload (here it's `search`, visible in logs).

## Lab-scoped confirmed impact
Trigger `alert()` through the stock-check page — delivered via select-breakout img,
first poll solved.