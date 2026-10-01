# Metadata — DOM XSS in jQuery selector sink using a hashchange event

| Field | Value |
|---|---|
| Lab | DOM XSS in jQuery selector sink using a `hashchange` event |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/dom-based/lab-jquery-selector-hash-change-event |
| Target | `https://0ae90061041f5f8780298f82002700a3.web-security-academy.net/` |
| Exploit server | `https://exploit-0aef007404205f9c80c58e1901a70095.exploit-server.net` |
| Class | Cross-Site Scripting (XSS) — **DOM-based**, victim-delivered |
| Sub-type | jQuery `$()` selector/HTML-sniff sink; source `location.hash`; gated on `hashchange` event; delivered via framing iframe that mutates the fragment |
| Severity | High (victim-browser code execution at app origin; lure is a same-registration-domain page away; framing permitted — no `X-Frame-Options` on lab responses) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`; victim `GET /exploit/` in access log) |
| Tools used | curl, headless Chromium + CDP (page + browser targets), exploit-server form API |

## Lab objective (verbatim)
> This lab contains a DOM-based cross-site scripting vulnerability on the home page.
> It uses jQuery's `$()` selector function to auto-scroll to a given post, whose title
> is passed via the `location.hash` property.
> To solve this lab, deliver an exploit to the victim that calls the `print()` function
> in their browser.

## What makes this lab different from the sibling DOM labs
- `document.write` / `innerHTML` / jQuery-`href` labs: self-triggering in the attacker's
  own browser (load / error / click).
- **This lab**: the sink only runs on the `hashchange` EVENT, which never fires on a cold
  load — so the attacker must (a) get script running in the VICTIM's browser and (b)
  cause a fragment CHANGE there. Delivery infrastructure (framing iframe + exploit
  server + victim bot) is part of the attack chain, not just the proof.

## Attack surface at a glance
- `/` — home page with the hashchange handler; jQuery 1.8.2 + jQuery Migrate 1.4.1.
- Fragment `location.hash` — never sent to the server (zero server reflection possible).
- Exploit server `/` (STORE / VIEW_EXPLOIT / DELIVER_TO_VICTIM / ACCESS_LOG), `/exploit`
  (served body), `/log` (access log), `/deliver-to-victim` (delivery status).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Full chain incl. victim-delivery leg and event gating |
| `root-cause.md` | jQuery HTML-sniff sink; detached-element execution; trust boundary |
| `verification.md` | Empirical proofs (selector behavior, gating, delivery, log) + failures |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Event-gated sinks; victim-delivery tradecraft; generalizable pattern |