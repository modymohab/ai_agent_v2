#!/usr/bin/env bash
# Rebuild legacy methodology mirrors (methodology/<topic>.md) from their canonical
# skill (methodology/<topic>-skill/SKILL.md).
#
# WHY THIS SCRIPT EXISTS: running an ad-hoc `for t in ...; do rebuild; done` loop
# twice silently overwrote the intentionally-unimplemented reporting.md stub with
# 355 lines of skill content. Documenting the failure mode did NOT prevent it —
# only a script that physically cannot do it will. So the exclusion list below is
# a hard guard, not advice.
#
# Usage:  ./methodology/rebuild-mirrors.sh <topic> [<topic> ...]
#         ./methodology/rebuild-mirrors.sh --all
set -euo pipefail

cd "$(dirname "$0")/.."

# Topics whose .md is an intentionally unimplemented placeholder. These must keep
# their original bytes; rebuilding them destroys documented architecture.
readonly STUB_MD5="ad956e5d244109bb5110334efdc64b9f"
readonly -a STUB_TOPICS=(
  client-side server-side privilege-escalation cve-research reporting
)

is_stub_topic() {
  local t="$1"
  for s in "${STUB_TOPICS[@]}"; do
    [[ "$t" == "$s" ]] && return 0
  done
  return 1
}

rebuild_one() {
  local t="$1"
  local skill="methodology/$t-skill/SKILL.md"

  if is_stub_topic "$t"; then
    echo "REFUSING: '$t' is a protected stub topic — $skill must not be mirrored into" \
         "methodology/$t.md (see rebuild-mirrors.sh header)." >&2
    return 1
  fi
  if [[ ! -f "$skill" ]]; then
    echo "SKIP: no canonical skill at $skill" >&2
    return 1
  fi

  awk 'NR==1{sub(/ Skill$/," Methodology")} !/^> Provenance:/' "$skill" \
    | awk 'NR<=3{ if(seen_blank && $0==""){ next } if($0==""){seen_blank=1} else {seen_blank=0} } {print}' \
    | sed "s#\.\./\([a-z-]*\)-skill/SKILL\.md#\1-skill/SKILL.md#g" \
    > "methodology/$t.md"
  printf '  rebuilt methodology/%s.md (%s lines)\n' "$t" "$(wc -l < "methodology/$t.md")"
}

# Post-write invariant: the protected stubs must be byte-unchanged. Run on EVERY
# invocation, and fail loudly — a silent stub overwrite is invisible to every
# content-level check.
verify_stubs() {
  local ok=0
  for t in "${STUB_TOPICS[@]}"; do
    local got
    got="$(md5sum "methodology/$t.md" | cut -d' ' -f1)"
    if [[ "$got" == "$STUB_MD5" ]]; then
      ok=$((ok + 1))
    else
      echo "STUB VIOLATION: methodology/$t.md is $got, expected $STUB_MD5" >&2
    fi
  done
  if [[ $ok -ne ${#STUB_TOPICS[@]} ]]; then
    echo "ABORT: ${#STUB_TOPICS[@]}-$ok/$((ok)) stubs intact" >&2
    exit 1
  fi
  printf '  stubs intact: %d/%d\n' "$ok" "${#STUB_TOPICS[@]}"
}

  if [[ "${1:-}" == "--all" ]]; then
    for d in methodology/*-skill; do
      t="${d%/}"; t="${t##*/}"; t="${t%-skill}"
      is_stub_topic "$t" && continue
      [[ -f "methodology/$t.md" ]] && rebuild_one "$t"
    done
  else
    # A protected-stub refusal (or a missing skill) must NOT abort the remaining
    # topics. Batching `reporting` with real topics used to skip every topic after
    # it, silently leaving them at parity DRIFT while the operator believed the
    # rebuild had run. Collect failures, finish the batch, then exit non-zero so
    # the refusal is still impossible to ignore.
    failed=()
    for t in "$@"; do rebuild_one "$t" || failed+=("$t"); done
    if [[ ${#failed[@]} -gt 0 ]]; then
      echo "NOT REBUILT (${#failed[@]}): ${failed[*]}" >&2
      verify_stubs
      exit 1
    fi
  fi

  verify_stubs
