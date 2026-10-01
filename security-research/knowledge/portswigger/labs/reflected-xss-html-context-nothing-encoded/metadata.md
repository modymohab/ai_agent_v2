# Lab Metadata

- **Lab:** Reflected XSS into HTML context with nothing encoded
- **URL (sessioned):** https://0af600c103e3e267806dd5a5002800f8.web-security-academy.net/
- **Official description:** https://portswigger.net/web-security/cross-site-scripting/reflected/lab-html-context-nothing-encoded
- **Objective:** Perform a cross-site scripting attack that calls the `alert` function.
- **Vulnerability class:** Reflected Cross-Site Scripting (XSS) — HTML text/element context, no output encoding.
- **Status:** SOLVED (2026-09-19) — lab widget flipped to "Solved" after the payload request; benign marker did not.
- **Relevant knowledge:** `methodology/xss.md`, `methodology/client-side.md`, `index/attack-impact-coverage.md`, `knowledge/portswigger/labs/xss-scanning-non-standard-data-structures.md`
- **Environment notes:** Burp MCP usable; browser-control MCP absent → evidence via curl + plain headless Chromium emulator.