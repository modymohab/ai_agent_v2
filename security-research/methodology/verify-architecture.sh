#!/usr/bin/env bash
# Validate the methodology mirror architecture.
#
# Written because the previous ad-hoc parity check was VACUOUS: it iterated
# `for d in methodology/*/`, but the only directories under methodology/ are
# `*-skill` dirs, which the loop body immediately `continue`d past. It therefore
# compared nothing and printed "PARITY OK" every run — a tautological predicate
# of exactly the kind verification-skill now documents. This script:
#   1. proves it CAN fail (negative control) before trusting any result
#   2. enumerates real skill dirs, excluding the protected stub topics
#   3. checks index <-> skill-dir agreement in BOTH directions
#   4. checks stub checksums
#   5. checks .md/skill parity for every non-stub topic
set -uo pipefail
cd "$(dirname "$0")/.."

readonly STUB_MD5="ad956e5d244109bb5110334efdc64b9f"
readonly -a STUB_TOPICS=(client-side server-side privilege-escalation cve-research reporting)
fail=0

is_stub() { local t="$1"; for s in "${STUB_TOPICS[@]}"; do [[ "$t" == "$s" ]] && return 0; done; return 1; }

echo "=== 0. NEGATIVE CONTROL: can this script detect a real defect? ==="
tmp=$(mktemp -d); cp methodology/xss.md "$tmp/xss.md.bak"
printf 'DRIFT\n' >> methodology/xss.md
if diff -q <(grep -v '^> Provenance:' methodology/xss.md) \
           <(grep -v '^> Provenance:' methodology/xss-skill/SKILL.md) >/dev/null 2>&1; then
  echo "  FAIL: control did not detect planted drift -> this script cannot be trusted"; exit 1
fi
echo "  OK: planted drift detected, comparator is live"
mv "$tmp/xss.md.bak" methodology/xss.md; rm -rf "$tmp"

echo "=== 1. stubs ==="
for t in "${STUB_TOPICS[@]}"; do
  got=$(md5sum "methodology/$t.md" 2>/dev/null | cut -d' ' -f1)
  if [[ "$got" == "$STUB_MD5" ]]; then printf '  ok   %-22s %s lines\n' "$t" "$(wc -l < "methodology/$t.md")"
  else echo "  FAIL $t: $got"; fail=1; fi
done

echo "=== 2. index <-> skill dirs (both directions) ==="
skills=$(ls -1d methodology/*-skill | sed 's#.*/\(.*\)-skill#\1#' | sort)
idx=$(grep -oE '^Canonical: `methodology/[a-z-]+-skill/SKILL\.md`' index/methodology.md \
      | sed 's#.*/\([a-z-]*\)-skill.*#\1#' | sort)
if [[ "$skills" == "$idx" ]]; then
  echo "  ok   $(echo "$skills" | wc -l | tr -d ' ') topics, sets identical"
else
  echo "  FAIL set mismatch:"; diff <(echo "$skills") <(echo "$idx") | sed 's/^/    /'; fail=1
fi

echo "=== 3. .md / skill parity (non-stub topics only) ==="
n=0; checked=0
for t in $skills; do
  is_stub "$t" && continue
  [[ -f "methodology/$t.md" ]] || { echo "  FAIL $t: no legacy .md mirror"; fail=1; continue; }
  n=$((n+1))
  if diff -q <(grep -v '^> Provenance:' "methodology/$t.md" | tail -n +2 | sed "s#\.\./\([a-z-]*\)-skill/SKILL\.md#\1-skill/SKILL.md#g" | cat -s) \
             <(grep -v '^> Provenance:' "methodology/$t-skill/SKILL.md" | tail -n +2 | sed "s#\.\./\([a-z-]*\)-skill/SKILL\.md#\1-skill/SKILL.md#g" | cat -s) >/dev/null; then
    checked=$((checked+1))
  else
    echo "  DRIFT $t ($(wc -l < "methodology/$t.md") md vs $(wc -l < "methodology/$t-skill/SKILL.md") skill lines)"; fail=1
  fi
done
echo "  $checked/$n non-stub topics at parity"

echo "=== 4. verdict ==="
if [[ $fail -eq 0 ]]; then echo "  ALL CHECKS PASS"; else echo "  FAILURES PRESENT"; fi
exit $fail
