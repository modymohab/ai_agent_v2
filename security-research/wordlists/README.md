# Wordlist Registry

This directory contains wordlists organized by their intended research purpose.

The agent must select wordlists based on the research question and target behavior.

Do not use a wordlist simply because it is available.

Canonical categories:

wordlists/
├── directories/
├── headers/
├── parameters/
├── subdomains/
├── api/
├── passwords/
└── general/

---

## directories/

### DirBuster-2007_directory-list-lowercase-2.3-medium.txt

Purpose:
- Directory discovery
- Common path discovery
- Content discovery

Typical tools:
- Gobuster
- ffuf

Use when:
- Content discovery is justified

---

## headers/

### lowercase-headers

Purpose:
- HTTP header name discovery/testing

Use when:
- Header behavior is relevant
- A hypothesis involves non-obvious HTTP headers

Do not treat this as a normal parameter wordlist.

---

## parameters/

Purpose:
- Parameter discovery and parameter-related fuzzing

Currently:
- No wordlists registered

Do not populate this directory without a useful parameter wordlist.

---

## subdomains/

### subdomains-top1million-5000.txt

Purpose:
- Subdomain discovery

Typical tools:
- Gobuster
- other authorized DNS enumeration workflows

Use when:
- Subdomain enumeration is relevant to the authorized scope.

---

## api/

### api-endpoints.txt

Purpose:
- API endpoint discovery
- API route discovery

Typical tools:
- ffuf
- Gobuster
- other authorized discovery workflows

Use when:
- An application exposes an API
- API endpoint discovery is relevant

---

## passwords/

### rockyou.txt

Purpose:
- Password-related testing in explicitly authorized environments

This is not a general-purpose discovery wordlist.

Use only when the specific authorized task requires password wordlist testing.

---

## general/

Currently empty.

Do not add files here merely to populate the directory.

---

# Selection Rules

Before selecting a wordlist:

1. Identify the research question.
2. Identify what is being enumerated or fuzzed.
3. Select the matching category.
4. Consider target technology and context.
5. Prefer a smaller appropriate list when sufficient.
6. Avoid unnecessary noise.
7. Record the wordlist used when it materially affects the research.

A wordlist supports a hypothesis.

It does not replace reasoning.
