# Security Research Tool Registry

This file describes the tools available to the security research agent.

The agent must choose tools based on the research question.

Do not run every available tool automatically.

---

# 1. Burp MCP

## Purpose

HTTP-level inspection, manipulation, replay, comparison, and verification.

## Use When

- Inspecting HTTP requests/responses
- Modifying requests
- Replaying requests
- Testing authorization boundaries
- Investigating authentication/session behavior
- Testing API behavior
- Comparing requests between users/roles
- Verifying suspected vulnerabilities

## Prefer Over

Browser automation when browser state is not required.

## Avoid When

A simple curl request is sufficient.

## Input

HTTP requests, application behavior, target functionality.

## Output

Requests, responses, headers, parameters, cookies, response differences, and behavioral evidence.

---

# 2. Browser Control MCP

## Purpose

Browser-level interaction and stateful application workflows.

## Use When

- Login flows
- Session-dependent behavior
- JavaScript-driven functionality
- Forms
- Multi-step workflows
- Browser-only behavior
- Client-side functionality

## Avoid When

The same behavior can be tested reliably with HTTP requests.

## Input

Application URL and browser workflow.

## Output

Observed browser behavior, page state, navigation results, and relevant application behavior.

---

# 3. httpx

## Purpose

HTTP probing and identification of live web services.

## Use When

A list of domains, subdomains, or URLs needs HTTP validation.

## Input

Hosts/domains/URLs.

## Output

Live HTTP/HTTPS services and useful HTTP metadata.

## Typical Position

Asset Discovery
→ httpx
→ Live Web Assets

---

# 4. Nmap

## Purpose

Network and service discovery.

## Use When

Network/service enumeration is explicitly authorized and useful.

## Input

Authorized hosts/IPs.

## Output

Open ports and detected services.

## Avoid When

The scope does not permit network scanning or when it provides no useful information.

---

# 5. Katana

## Purpose

Web crawling and endpoint discovery.

## Use When

The application needs to be mapped through crawling.

## Input

Live web targets.

## Output

Discovered URLs, paths, endpoints, and application resources.

## Typical Position

httpx
→ Katana
→ Endpoint Analysis

---

# 6. Gobuster

## Purpose

Authorized content discovery.

## Use When

Predictable paths, directories, files, or DNS names need discovery.

## Input

Target + appropriate wordlist.

## Output

Discovered resources.

## Wordlist Categories

Canonical categories are defined in `wordlists/README.md`:

directories/, headers/, parameters/, subdomains/, api/, passwords/, general/

Relevant for Gobuster:

- directories/
- subdomains/
- general/

## Avoid When

The target does not justify content discovery or the selected wordlist is unnecessarily large.

---

# 7. ffuf

## Purpose

Controlled fuzzing and discovery.

## Use When

A specific parameter, path, header, or input needs systematic variation.

## Input

Target + fuzz location + appropriate wordlist.

## Output

Responses and behavioral differences.

## Wordlist Categories

Canonical categories are defined in `wordlists/README.md`:

directories/, headers/, parameters/, subdomains/, api/, passwords/, general/

Relevant for ffuf:

- directories/
- headers/
- parameters/
- subdomains/
- api/
- passwords/
- general/

## Principle

Fuzz a specific hypothesis.

Do not fuzz blindly.

---

# 8. curl

## Purpose

Simple HTTP requests and reproduction.

## Use When

- Reproducing a request
- Verifying behavior
- Comparing responses
- Testing a simple hypothesis

## Prefer When

Burp/browser functionality is unnecessary.

---

# 9. jq

## Purpose

JSON/API response analysis.

## Use When

Responses contain structured JSON.

## Typical Workflow

curl
→ jq
→ Extract relevant fields

---

# 10. rg / grep

## Purpose

Search and filtering.

## Use When

- Searching recon output
- Searching knowledge
- Filtering URLs
- Finding parameters
- Finding indicators

---

# 11. sed / awk / cut / tr

## Purpose

Text transformation and normalization.

Use when raw tool output needs processing.

---

# 12. sort / uniq

## Purpose

Normalization and deduplication.

Typical workflow:

Raw Results
→ normalize
→ sort
→ uniq
→ analyze

---

# Tool Selection Rules

The agent must ask:

"What research question am I trying to answer?"

Then choose the smallest appropriate toolset.

Examples:

Which hosts respond over HTTP?
→ httpx

What endpoints can I discover by crawling?
→ Katana

Are there predictable resources?
→ Gobuster

Does changing this parameter reveal different behavior?
→ Burp / curl / ffuf depending on context

Does the workflow require browser state?
→ Browser Control MCP

What network services are exposed?
→ Nmap when authorized

How can I reproduce this request simply?
→ curl

How can I analyze JSON?
→ jq

How can I filter large output?
→ rg / grep / awk / sort / uniq

---

# General Principle

Tool availability does not mean tool necessity.

Every tool invocation should have a reason.
