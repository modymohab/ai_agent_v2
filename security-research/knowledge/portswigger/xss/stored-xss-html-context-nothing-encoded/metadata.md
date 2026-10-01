# Metadata — Stored XSS into HTML context with nothing encoded

| Field | Value |
|---|---|
| Lab | Stored XSS into HTML context with nothing encoded |
| Lab URL | https://portswigger.net/web-security/cross-site-scripting/stored/lab-html-context-nothing-encoded |
| Target | `https://0a8f008e0451414d8055d587006a0065.web-security-academy.net/` |
| Class | Cross-Site Scripting (XSS) — Stored / Persistent |
| Sub-type | Reflected-into-storage; HTML text context; no output encoding |
| Severity (classic) | High (stored, executes for every page viewer, no interaction required) |
| Date solved | 2026-09-19 |
| Status | SOLVED (banner: `is-solved`) |
| Tools used | curl, headless Chromium, parsed HTML responses |

## Lab objective (verbatim)
> This lab contains a stored XSS vulnerability in the comment functionality.
> To solve this lab, submit a comment that calls the `alert()` function when the blog post is viewed.

## Attack surface at a glance
- Blog application with posts at `/post?postId=N`.
- Comment submission: `POST /post/comment` (form-encoded) with fields:
  `csrf`, `postId`, `comment`, `name`, `email`, `website`.
- Comments are stored server-side and re-rendered for **every** visitor of the post page.
- A CSRF token is required for comment submission (anti-CSRF present, but trivially obtainable).

## Key files
| File | Purpose |
|---|---|
| `attack-chain.md` | Field-by-field input→output map and full exploit flow |
| `root-cause.md` | Why the comment field is injectable and the others are not |
| `verification.md` | Evidence, proof-of-execution, and failed-candidate analysis |
| `impact.md` | Confirmed vs plausible vs not-applicable impact |
| `lessons.md` | Generalizable pattern and recon/verification guidance |