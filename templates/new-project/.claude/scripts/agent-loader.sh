#!/usr/bin/env bash
# Project-local agent loader for new-project template.
# Reads .claude/agents/.enabled and copies missing agents from:
#   1. project-local .claude/agents/_available/
#   2. user-level shared pool ($CLAUDE_AGENT_POOL or ~/.claude/agency-agents-dev)
# Normal path is silent; only new or missing states produce a short systemMessage.

set -u

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ENABLED_FILE="$PROJECT_ROOT/.claude/agents/.enabled"
LOCAL_POOL="$PROJECT_ROOT/.claude/agents/_available"
SHARED_POOL="${CLAUDE_AGENT_POOL:-$HOME/.claude/agency-agents-dev}"
TARGET_DIR="$PROJECT_ROOT/.claude/agents"

if [ ! -f "$ENABLED_FILE" ]; then
    exit 0
fi

mkdir -p "$TARGET_DIR"

LOADED_LOCAL=0
LOADED_SHARED=0
MISSING=0
MISSING_NAMES=""

while IFS= read -r line || [ -n "$line" ]; do
    name=$(printf '%s' "$line" | sed -e '1s/^\xEF\xBB\xBF//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$name" ] && continue
    echo "$name" | grep -qE '^#' && continue

    kebab=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -e 's|/|-|g' -e 's|(||g' -e 's|)||g' | tr -s '[:space:]' '-' | sed -e 's/^-//' -e 's/-$//')
    target_file="$TARGET_DIR/$kebab.md"

    if [ -f "$target_file" ]; then
        continue
    fi

    local_source="$LOCAL_POOL/$kebab.md"
    shared_source="$SHARED_POOL/$kebab.md"

    if [ -f "$local_source" ]; then
        cp "$local_source" "$target_file"
        LOADED_LOCAL=$((LOADED_LOCAL + 1))
        continue
    fi

    if [ -f "$shared_source" ]; then
        cp "$shared_source" "$target_file"
        LOADED_SHARED=$((LOADED_SHARED + 1))
        continue
    fi

    MISSING=$((MISSING + 1))
    MISSING_NAMES="$MISSING_NAMES $name"
done < "$ENABLED_FILE"

MSG=""
if [ $LOADED_LOCAL -gt 0 ]; then
    MSG="Agent loader: +$LOADED_LOCAL local"
fi
if [ $LOADED_SHARED -gt 0 ]; then
    [ -n "$MSG" ] && MSG="$MSG, "
    MSG="${MSG}+$LOADED_SHARED shared"
fi
if [ $MISSING -gt 0 ]; then
    [ -n "$MSG" ] && MSG="$MSG, "
    MSG="${MSG}$MISSING missing:$MISSING_NAMES"
fi

if [ -n "$MSG" ]; then
    MSG_ESC=$(echo "$MSG" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    echo "{\"systemMessage\":\"$MSG_ESC\"}"
fi

exit 0
