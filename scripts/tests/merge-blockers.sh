#!/usr/bin/env bash
# Run with Bash, Git and jq. All migrations run in disposable Git repositories.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCAN="$ROOT/scripts/pretooluse-secrets-scan.sh"
MIGRATE="$ROOT/templates/new-project/.claude/scripts/migrate.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd)"
TEST_TMP="$(mktemp -d "$TMP_BASE/claude-regression.XXXXXX")" || exit 1
cleanup() {
  local resolved
  resolved="$(cd "$TEST_TMP" && pwd)" || return
  case "$resolved" in
    "$TMP_BASE"/claude-regression.*) rm -rf -- "$resolved" ;;
  esac
}
trap cleanup EXIT

failures=0
run_test() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
  else
    printf 'FAIL: %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

asks_with_valid_json() {
  local payload output
  payload="$(jq -cn --arg content "$1" '{tool_name:"Write",tool_input:{file_path:"fixture.txt",content:$content}}')" || return 1
  output="$(printf '%s' "$payload" | bash "$SCAN")" || return 1
  printf '%s' "$output" | jq -se '
    length == 1 and
    (.[0].hookSpecificOutput |
      .hookEventName == "PreToolUse" and
      .permissionDecision == "ask" and
      (.permissionDecisionReason | type == "string" and length > 0))
  ' >/dev/null
}

allows_safe_input() {
  local output
  output="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"hello.txt","content":"Hello world"}}' | bash "$SCAN")" || return 1
  [ -z "$output" ]
}

allows_empty_input() {
  local output
  output="$(bash "$SCAN" </dev/null)" || return 1
  [ -z "$output" ]
}

preserves_existing_hook() {
  local target="$TEST_TMP/existing project"
  git init -q --initial-branch=feature/test "$target" || return 1
  mkdir -p "$target/.githooks" || return 1
  printf '#!/usr/bin/env bash\n# User-owned [MAIN_BRANCH] [PROJECT_NAME]\nprintf "custom hook\\n"\n' >"$target/.githooks/pre-commit"
  cp "$target/.githooks/pre-commit" "$TEST_TMP/original-hook" || return 1
  printf 'MAIN_BRANCH=release\nPROJECT_NAME=regression-fixture\n' >"$target/project.env"
  bash "$MIGRATE" "$target" >"$TEST_TMP/existing.log" 2>&1 || return 1
  cmp "$TEST_TMP/original-hook" "$target/.githooks/pre-commit"
}

installs_hook_for_configured_branch() {
  local target="$TEST_TMP/new project" status
  git init -q --initial-branch=release "$target" || return 1
  printf 'MAIN_BRANCH=release\n' >"$target/project.env"
  bash "$MIGRATE" "$target" >"$TEST_TMP/new.log" 2>&1 || return 1
  [ "$(git -C "$target" config core.hooksPath)" = '.githooks' ] || return 1
  # Test the generated hook's behavior: the configured main branch is protected.
  (cd "$target" && bash .githooks/pre-commit) >"$TEST_TMP/new-hook.log" 2>&1
  status=$?
  [ "$status" -eq 1 ] || return 1
  git -C "$target" symbolic-ref HEAD refs/heads/feature/test || return 1
  (cd "$target" && bash .githooks/pre-commit)
}

# Synthetic strings only. The assignment fixture triggers the existing rule's
# character class; this regression intentionally does not change matching scope.
run_test 'AWS access key produces valid ask JSON' asks_with_valid_json 'AKIA0000000000000000'
run_test 'AWS marker produces valid ask JSON' asks_with_valid_json 'aws_secret_access_key'
run_test 'private key marker produces valid ask JSON' asks_with_valid_json '-----BEGIN RSA PRIVATE KEY-----'
run_test 'GitHub token produces valid ask JSON' asks_with_valid_json 'ghp_000000000000000000000000000000000000'
run_test 'secret key prefix produces valid ask JSON' asks_with_valid_json 'sk-00000000000000000000'
run_test 'Slack token produces valid ask JSON' asks_with_valid_json 'xoxb-0000000000'
run_test 'Google API key produces valid ask JSON' asks_with_valid_json 'AIza00000000000000000000000000000000000'
run_test 'assignment rule with quotes and backslashes produces valid ask JSON' asks_with_valid_json 'password=xFAKEVALUEONLYx'
run_test 'safe input produces no permission request' allows_safe_input
run_test 'empty input produces no permission request' allows_empty_input
run_test 'migration preserves existing hook bytes' preserves_existing_hook
run_test 'new hook protects configured main branch and allows feature branch' installs_hook_for_configured_branch

printf '\nFailures: %d\n' "$failures"
[ "$failures" -eq 0 ]
