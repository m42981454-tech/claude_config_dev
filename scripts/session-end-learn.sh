#!/bin/bash
# SessionEnd local learning recorder.
# Writes short metadata only; does not call LLMs, agents, network, or read transcript bodies.

set -u

START_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)
INPUT=$(cat 2>/dev/null || true)

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
MEM_DIR="$ROOT/.claude/session-memory"
LATEST="$MEM_DIR/latest.md"
DAY_FILE="$MEM_DIR/$(date -u +"%Y-%m-%d" 2>/dev/null || date +%Y-%m-%d)-session.md"

mkdir -p "$MEM_DIR" 2>/dev/null || exit 0

reason=$(printf '%s' "$INPUT" | sed -n 's/.*"reason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$reason" ] && reason="unknown"

branch=$(git -C "$ROOT" branch --show-current 2>/dev/null || true)
[ -z "$branch" ] && branch="unknown"

porcelain=$(git -C "$ROOT" status --porcelain 2>/dev/null || true)
staged=$(printf '%s\n' "$porcelain" | awk '/^[MADRC]/{c++} END{print c+0}')
unstaged=$(printf '%s\n' "$porcelain" | awk '/^.[MD]/{c++} END{print c+0}')
untracked=$(printf '%s\n' "$porcelain" | awk '/^\?\?/{c++} END{print c+0}')
dirty="staged=$staged unstaged=$unstaged untracked=$untracked"

last_commit=$(git -C "$ROOT" log -1 --format="%h %s" 2>/dev/null | cut -c1-120)
[ -z "$last_commit" ] && last_commit="none"

progress_path=$(find "$ROOT" -maxdepth 3 -iname 'progress.md' 2>/dev/null | head -1)
if [ -n "$progress_path" ] && [ -f "$progress_path" ]; then
    progress_rel=${progress_path#"$ROOT"/}
    progress_lines=$(wc -l < "$progress_path" 2>/dev/null | tr -d ' ')
    progress_mtime=$(date -r "$progress_path" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
else
    progress_rel="not found"
    progress_lines="0"
    progress_mtime="unknown"
fi

{
    printf '# Session Memory\n\n'
    printf -- '- timestamp: %s\n' "$START_TS"
    printf -- '- reason: %s\n' "$reason"
    printf -- '- cwd: %s\n' "$ROOT"
    printf -- '- branch: %s\n' "$branch"
    printf -- '- dirty: %s\n' "$dirty"
    printf -- '- last_commit: %s\n' "$last_commit"
    printf -- '- progress: %s (%s lines, mtime %s)\n' "$progress_rel" "$progress_lines" "$progress_mtime"
} > "$LATEST" 2>/dev/null || exit 0

{
    printf '\n---\n\n'
    cat "$LATEST" 2>/dev/null
} >> "$DAY_FILE" 2>/dev/null || true

exit 0
