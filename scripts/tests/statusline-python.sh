#!/usr/bin/env bash
# Run with Bash (Git for Windows) and Node. Every run uses a disposable HOME, so
# the result does not depend on which Pythons this machine actually has.
#
# Why this exists: on 2026-09-17 the statusline kept opening the Windows
# "Open with" dialog for statusline-render.py. Its hard-coded miniconda
# fallback had gone stale, so it resolved `python3` from PATH and reached the
# pyenv-win shim, whose `pyenv exec $(basename "$0") "$@"` drops the command
# name whenever basename prints nothing. The script path then lands where the
# command should be, and cmd opens it by file association. The statusline must
# prefer a real interpreter and reach PATH only when none exists.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATUSLINE="$ROOT/scripts/statusline-lines.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd)"
TEST_TMP="$(mktemp -d "$TMP_BASE/claude-statusline.XXXXXX")" || exit 1
cleanup() {
  local resolved
  resolved="$(cd "$TEST_TMP" && pwd)" || return
  case "$resolved" in
    "$TMP_BASE"/claude-statusline.*) rm -rf -- "$resolved" ;;
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

# Shared fixtures: a claude-hud stand-in that passes stdin through, a renderer
# path the interpreter is called with, and a PATH directory whose python3 and
# python announce that PATH was used.
PLUGIN="$TEST_TMP/plugin"
mkdir -p "$PLUGIN/dist" || exit 1
printf 'process.stdin.pipe(process.stdout);\n' >"$PLUGIN/dist/index.js"
RENDERER="$TEST_TMP/probe-renderer.py"
printf 'print("real python ran the renderer")\n' >"$RENDERER"
FAKEBIN="$TEST_TMP/fakebin"
mkdir -p "$FAKEBIN" || exit 1
for name in python3 python; do
  printf '#!/bin/sh\ncat >/dev/null\necho SHIM_USED\n' >"$FAKEBIN/$name"
  chmod +x "$FAKEBIN/$name"
done

# A stand-in interpreter that prints the script path it was given, so the
# output shows exactly which binary the statusline invoked.
ECHOING_EXE=/usr/bin/echo.exe
SILENT_EXE=/usr/bin/true.exe

new_home() {
  local home="$TEST_TMP/home-$1"
  mkdir -p "$home/.claude" || return 1
  printf '%s' "$home"
}

add_pyenv() {
  # pyenv-win writes its version file with a CRLF line ending.
  local home="$1" exe="$2"
  mkdir -p "$home/.pyenv/pyenv-win/versions/9.9.9" || return 1
  printf '9.9.9\r\n' >"$home/.pyenv/pyenv-win/version"
  cp "$exe" "$home/.pyenv/pyenv-win/versions/9.9.9/python.exe"
}

add_miniconda() {
  local home="$1" exe="$2"
  mkdir -p "$home/miniconda3" || return 1
  cp "$exe" "$home/miniconda3/python.exe"
}

run_statusline() {
  local home="$1"
  (
    cd "$TEST_TMP" || exit 1
    printf '{}' | env -u CLAUDE_STATUS_PYTHON \
      HOME="$home" \
      CLAUDE_CONFIG_DIR="$home/.claude" \
      CLAUDE_HUD_PLUGIN_DIR="$PLUGIN" \
      CLAUDE_STATUS_RENDERER="$RENDERER" \
      PATH="$FAKEBIN:$PATH" \
      bash "$STATUSLINE"
  ) 2>&1
}

uses_pyenv_interpreter_not_path() {
  local home output
  home="$(new_home pyenv)" || return 1
  add_pyenv "$home" "$ECHOING_EXE" || return 1
  output="$(run_statusline "$home")"
  printf '%s\n' "$output" >"$TEST_TMP/pyenv.log"
  case "$output" in *SHIM_USED*) return 1 ;; esac
  case "$output" in *probe-renderer.py*) return 0 ;; esac
  return 1
}

uses_home_miniconda_when_no_pyenv() {
  local home output
  home="$(new_home miniconda)" || return 1
  add_miniconda "$home" "$ECHOING_EXE" || return 1
  output="$(run_statusline "$home")"
  printf '%s\n' "$output" >"$TEST_TMP/miniconda.log"
  case "$output" in *SHIM_USED*) return 1 ;; esac
  case "$output" in *probe-renderer.py*) return 0 ;; esac
  return 1
}

prefers_pyenv_over_miniconda() {
  local home output
  home="$(new_home both)" || return 1
  add_pyenv "$home" "$ECHOING_EXE" || return 1
  add_miniconda "$home" "$SILENT_EXE" || return 1
  output="$(run_statusline "$home")"
  printf '%s\n' "$output" >"$TEST_TMP/both.log"
  case "$output" in *probe-renderer.py*) return 0 ;; esac
  return 1
}

falls_back_to_path_without_known_interpreter() {
  local home output
  home="$(new_home none)" || return 1
  output="$(run_statusline "$home")"
  printf '%s\n' "$output" >"$TEST_TMP/none.log"
  case "$output" in *SHIM_USED*) return 0 ;; esac
  return 1
}

for exe in "$ECHOING_EXE" "$SILENT_EXE"; do
  [ -x "$exe" ] || { printf 'setup: %s is missing\n' "$exe" >&2; exit 2; }
done

run_test 'pyenv interpreter is used and PATH python3 is not' uses_pyenv_interpreter_not_path
run_test 'miniconda under HOME is used when pyenv has no interpreter' uses_home_miniconda_when_no_pyenv
run_test 'pyenv is preferred when both interpreters exist' prefers_pyenv_over_miniconda
run_test 'PATH lookup still works when no known interpreter exists' falls_back_to_path_without_known_interpreter

if [ "$failures" -gt 0 ] && [ -n "${STATUSLINE_TEST_SHOW_LOGS:-}" ]; then
  for log in "$TEST_TMP"/*.log; do
    printf '\n--- %s ---\n' "$(basename "$log")"
    cat "$log"
  done
fi

printf '\nFailures: %d\n' "$failures"
[ "$failures" -eq 0 ]
