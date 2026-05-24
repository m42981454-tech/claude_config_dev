#!/usr/bin/env bash
# Collect bounded context for /project:session-review.
# Read-only by design. Does not read transcript bodies or modify files.

set -u

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" 2>/dev/null || exit 0

TODAY="$(date -u +"%Y-%m-%d" 2>/dev/null || date +%Y-%m-%d)"
PROJECT_MEM="$ROOT/.claude/session-memory"
USER_CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
USER_MEM="$USER_CLAUDE_DIR/session-memory"

print_file() {
  local title="$1"
  local file="$2"
  local limit="$3"

  printf '\n## %s\n\n' "$title"
  if [ -f "$file" ]; then
    printf 'Path: `%s`\n\n' "$file"
    sed -n "1,${limit}p" "$file" 2>/dev/null
  else
    printf '_not found_\n'
  fi
}

print_command() {
  local title="$1"
  shift

  printf '\n## %s\n\n' "$title"
  "$@" 2>/dev/null || printf '_command unavailable or failed_\n'
}

find_memory_file() {
  local name="$1"
  if [ -f "$PROJECT_MEM/$name" ]; then
    printf '%s\n' "$PROJECT_MEM/$name"
    return 0
  fi
  if [ -f "$USER_MEM/$name" ] && grep -Fq -- "- cwd: $ROOT" "$USER_MEM/$name" 2>/dev/null; then
    printf '%s\n' "$USER_MEM/$name"
    return 0
  fi
  printf '%s\n' "$PROJECT_MEM/$name"
}

printf '# Session Review Context\n'
printf '\nGenerated: `%s`\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"
printf 'Project: `%s`\n' "$ROOT"

latest_memory="$(find_memory_file latest.md)"
day_memory="$(find_memory_file "$TODAY-session.md")"

print_file "Latest Session Memory" "$latest_memory" 120
print_file "Today Session Memory" "$day_memory" 180

print_command "Git Status" git status --short --branch
print_command "Recent Commits" git log --oneline -5

print_file "Progress Snapshot" "$ROOT/progress.md" 160

if [ "$#" -gt 0 ]; then
  printf '\n## Candidate Evidence Files\n'
  for candidate in "$@"; do
    case "$candidate" in
      *..*|/*|*:*)
        printf '\n### `%s`\n\n_skipped: unsafe or absolute path_\n' "$candidate"
        continue
        ;;
    esac

    if [ -f "$ROOT/$candidate" ]; then
      printf '\n### `%s`\n\n' "$candidate"
      sed -n '1,120p' "$ROOT/$candidate" 2>/dev/null
    else
      printf '\n### `%s`\n\n_not found_\n' "$candidate"
    fi
  done
else
  printf '\n## Candidate Evidence Files\n\n'
  printf '_none requested_\n'
fi

exit 0
