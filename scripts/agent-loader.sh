#!/bin/bash
# Agent loader — read .claude/agents/.enabled in project and sync from L1.5 pool
# Called by SessionStart hook (~/.claude/settings.json)
# Idempotent: only copies missing agents; never overwrites or deletes existing files.
# Project-local agents win: if <project>/.claude/agents/<id>.md exists, the
# loader treats it as present even when the shared pool has no matching file.

set -u

# Find project root (git toplevel or cwd)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ENABLED_FILE="$PROJECT_ROOT/.claude/agents/.enabled"
POOL="$HOME/.claude/agency-agents-dev"
TARGET_DIR="$PROJECT_ROOT/.claude/agents"

# Quick exit if no manifest
if [ ! -f "$ENABLED_FILE" ]; then
    echo '{}'
    exit 0
fi

# Pool must exist
if [ ! -d "$POOL" ]; then
    echo '{"systemMessage":"⚠️ agent pool not found: ~/.claude/agency-agents-dev/"}'
    exit 0
fi

# Ensure target dir exists
mkdir -p "$TARGET_DIR"

LOADED=0
SKIPPED=0
MISSING=0
MISSING_NAMES=""

# Read .enabled line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading/trailing whitespace
    name=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # Skip blank lines and comments
    [ -z "$name" ] && continue
    echo "$name" | grep -qE '^#' && continue

    # Convert "Title Case Name" to "title-case-name"
    kebab=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -e 's|/|-|g' -e 's|(||g' -e 's|)||g' | tr -s '[:space:]' '-' | sed -e 's/^-//' -e 's/-$//')

    source_file="$POOL/$kebab.md"
    target_file="$TARGET_DIR/$kebab.md"

    if [ -f "$target_file" ]; then
        SKIPPED=$((SKIPPED + 1))
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

# Build report
MSG=""
if [ $LOADED -gt 0 ]; then
    MSG="🤖 Agent loader: +$LOADED new"
fi
if [ $SKIPPED -gt 0 ]; then
    [ -n "$MSG" ] && MSG="$MSG, "
    MSG="${MSG}$SKIPPED already present"
fi
if [ $MISSING -gt 0 ]; then
    [ -n "$MSG" ] && MSG="$MSG, "
    MSG="${MSG}⚠️ $MISSING missing in pool:$MISSING_NAMES"
fi

if [ -n "$MSG" ]; then
    # Escape for JSON
    MSG_ESC=$(echo "$MSG" | sed -e 's/"/\\"/g' -e 's/\\/\\\\/g')
    echo "{\"systemMessage\":\"$MSG_ESC\"}"
else
    echo '{}'
fi

exit 0
