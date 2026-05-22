#!/bin/bash
# Project-local agent loader for new-project template.
# Reads .claude/agents/.enabled and copies missing agents from the user-level dev pool.
# Normal path is silent; only new, missing, or pool-missing states produce a short systemMessage.

set -u

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ENABLED_FILE="$PROJECT_ROOT/.claude/agents/.enabled"
POOL="${CLAUDE_AGENT_POOL:-$HOME/.claude/agency-agents-dev}"
TARGET_DIR="$PROJECT_ROOT/.claude/agents"

if [ ! -f "$ENABLED_FILE" ]; then
    exit 0
fi

if [ ! -d "$POOL" ]; then
    echo '{"systemMessage":"⚠️ agent pool not found. Set CLAUDE_AGENT_POOL or install user-level agency-agents-dev."}'
    exit 0
fi

mkdir -p "$TARGET_DIR"

LOADED=0
MISSING=0
MISSING_NAMES=""

while IFS= read -r line || [ -n "$line" ]; do
    name=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$name" ] && continue
    echo "$name" | grep -qE '^#' && continue

    kebab=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -e 's|/|-|g' -e 's|(||g' -e 's|)||g' | tr -s '[:space:]' '-' | sed -e 's/^-//' -e 's/-$//')
    source_file="$POOL/$kebab.md"
    target_file="$TARGET_DIR/$kebab.md"

    if [ -f "$target_file" ]; then
        continue
    fi

    if [ ! -f "$source_file" ]; then
        MISSING=$((MISSING + 1))
        MISSING_NAMES="$MISSING_NAMES $name"
        continue
    fi

    cp "$source_file" "$target_file"
    LOADED=$((LOADED + 1))
done < "$ENABLED_FILE"

MSG=""
if [ $LOADED -gt 0 ]; then
    MSG="Agent loader: +$LOADED new"
fi
if [ $MISSING -gt 0 ]; then
    [ -n "$MSG" ] && MSG="$MSG, "
    MSG="${MSG}$MISSING missing in pool:$MISSING_NAMES"
fi

if [ -n "$MSG" ]; then
    MSG_ESC=$(echo "$MSG" | sed -e 's/"/\\"/g' -e 's/\\/\\\\/g')
    echo "{\"systemMessage\":\"$MSG_ESC\"}"
fi

exit 0
