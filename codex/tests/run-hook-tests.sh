#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT_DIR/hooks/codex-workflow-dispatcher.sh"
TEST_HOME="${TMPDIR:-/tmp}/codex-workflow-tests.$$"
mkdir -p "$TEST_HOME"
export CODEX_WORKFLOW_HOME="$TEST_HOME"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_hook() {
  local prompt="$1"
  jq -n --arg prompt "$prompt" '{prompt: $prompt}' | "$HOOK"
}

assert_block_contains() {
  local output="$1"
  local expected="$2"
  printf '%s' "$output" | jq -e '.decision == "block"' >/dev/null || fail "expected block output: $output"
  printf '%s' "$output" | jq -r '.reason' | grep -F "$expected" >/dev/null || fail "missing reason fragment '$expected': $output"
}

assert_inject_contains() {
  local output="$1"
  local expected="$2"
  printf '%s' "$output" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null || fail "expected context injection: $output"
  printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext' | grep -F "$expected" >/dev/null || fail "missing context fragment '$expected': $output"
}

out=$(run_hook '$pending first Fix the "quoted" value \ path')
assert_block_contains "$out" "Saved pending prompt: first"
grep -F 'Fix the "quoted" value \ path' "$TEST_HOME/pending-prompts/first.txt" >/dev/null || fail "pending file content mismatch"

out=$(run_hook '$send first')
assert_inject_contains "$out" 'Fix the "quoted" value \ path'
[ ! -f "$TEST_HOME/pending-prompts/first.txt" ] || fail "send should remove prompt file"

out=$(run_hook '$send missing')
assert_block_contains "$out" "Pending prompt 'missing' not found."

out=$(run_hook '$queue step1 Do the first thing')
assert_block_contains "$out" "Queued: step1 (position 1)"
out=$(run_hook '$queue step2 Do the second thing')
assert_block_contains "$out" "Queued: step2 (position 2)"
out=$(run_hook '$queue-list')
assert_block_contains "$out" "1. step1"
out=$(run_hook '$sendqueue')
assert_inject_contains "$out" "Do the first thing"
grep -Fx 'step2' "$TEST_HOME/queue-order.txt" >/dev/null || fail "queue should retain second item"
out=$(run_hook '$sendqueue')
assert_inject_contains "$out" "Do the second thing"

out=$(run_hook '$pending bad/name nope')
assert_block_contains "$out" "Invalid name"

out=$(run_hook '$commit auth changes')
assert_inject_contains "$out" "Commit with Conventional Commit Format"
assert_inject_contains "$out" "auth changes"

out=$(run_hook '$mass-commit split frontend and backend')
assert_inject_contains "$out" "Mass Commit"
assert_inject_contains "$out" "split frontend and backend"

printf 'ok - hook tests passed using %s\n' "$TEST_HOME"
