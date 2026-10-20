#!/usr/bin/env bash
# Builds every demo tag with the Live scheme.
# step-2-wip must fail with exactly one "switch must be exhaustive" error; every other tag must
# build with zero compiler warnings. Then runs the tests at step-4-tested (8) and demo/super-like (9).
set -u

# This file doesn't exist in the older tags, so run from a temporary copy.
if [[ "${VERIFY_TAGS_COPY:-}" != "1" ]]; then
  copy=$(mktemp -t verify-tags)
  cp "$0" "$copy"
  VERIFY_TAGS_COPY=1 exec bash "$copy" "$@"
fi

cd "$(git rev-parse --show-toplevel)" || exit 1
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "✗ working tree has local changes; commit or stash them first"; exit 1
fi

# Newest "iPhone NN Pro" simulator, else the first available iPhone.
SIM=$(xcrun simctl list devices available | grep -oE "iPhone [0-9]+ Pro \(" | sed 's/ ($//' | sort -t' ' -k2 -n | tail -1)
[[ -z "$SIM" ]] && SIM=$(xcrun simctl list devices available | grep -m1 -oE "iPhone[^(]*" | sed 's/ *$//')
DEST="platform=iOS Simulator,name=$SIM"
echo "Simulator: $SIM"

TAGS=(step-0-spaghetti step-1-wip step-1-split step-2-wip step-2-state step-3-wip step-3-fake-horses step-4-tested)
START=$(git rev-parse --abbrev-ref HEAD)
fail=0

xcb() { xcodebuild -project stable-date.xcodeproj -scheme Live -destination "$DEST" "$@" 2>&1; }
# Compiler diagnostics only (tool log lines like appintentsmetadataprocessor's "warning:" don't count).
diags() { grep -E "^/.*: $1:" | sort -u; }

for t in "${TAGS[@]}"; do
  git checkout -q -f "$t" || { echo "✗ cannot checkout $t"; fail=1; continue; }
  out=$(xcb build)
  errors=$(echo "$out" | diags error)
  warnings=$(echo "$out" | diags warning)
  if [[ "$t" == "step-2-wip" ]]; then
    n=$(echo -n "$errors" | grep -c . )
    if [[ "$n" -eq 1 ]] && echo "$errors" | grep -q "exhaustive"; then
      echo "✓ $t fails exactly as intended (1 error: switch must be exhaustive)"
    else
      echo "✗ $t should fail with ONE exhaustive error, got $n:"; echo "$errors"; fail=1
    fi
  else
    if echo "$out" | grep -q "BUILD SUCCEEDED"; then echo "✓ $t builds"; else echo "✗ $t does not build"; echo "$errors"; fail=1; fi
  fi
  if [[ -n "$warnings" ]]; then echo "  ⚠ $t has warnings:"; echo "$warnings"; fail=1; fi
done

run_tests() {
  local ref=$1 expected=$2
  git checkout -q -f "$ref" || { echo "✗ cannot checkout $ref"; fail=1; return; }
  local out summary
  out=$(xcb -parallel-testing-enabled NO test)
  summary=$(echo "$out" | grep -E "Test run with [0-9]+ tests" | tail -1)
  if echo "$out" | grep -q "TEST SUCCEEDED" && echo "$summary" | grep -q "with $expected tests"; then
    echo "✓ $ref: $summary"
  else
    echo "✗ $ref: expected $expected passing tests. ${summary:-no test summary}"; fail=1
  fi
}
run_tests step-4-tested 8
git rev-parse -q --verify demo/super-like >/dev/null && run_tests demo/super-like 9

git checkout -q -f "$START"
exit $fail
