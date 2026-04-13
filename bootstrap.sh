#!/usr/bin/env bash
set -euo pipefail

echo "==> Claude config bootstrap starting..."

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${CLAUDE_DIR}"
mkdir -p "${CLAUDE_DIR}/plugins"
mkdir -p "${CLAUDE_DIR}/plugins/claude-hud"

copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [ -f "$src" ]; then
    cp -f "$src" "$dst"
    echo "Copied: $(basename "$src")"
  else
    echo "Skip missing: $src"
  fi
}

echo "==> Copying tracked config files..."
copy_if_exists "${SCRIPT_DIR}/settings.json" "${CLAUDE_DIR}/settings.json"
copy_if_exists "${SCRIPT_DIR}/plugins/installed_plugins.json" "${CLAUDE_DIR}/plugins/installed_plugins.json"
copy_if_exists "${SCRIPT_DIR}/plugins/known_marketplaces.json" "${CLAUDE_DIR}/plugins/known_marketplaces.json"
copy_if_exists "${SCRIPT_DIR}/plugins/claude-hud/config.json" "${CLAUDE_DIR}/plugins/claude-hud/config.json"

echo "==> Ensuring runtime directories exist..."
mkdir -p "${CLAUDE_DIR}/backups"
mkdir -p "${CLAUDE_DIR}/cache"
mkdir -p "${CLAUDE_DIR}/debug"
mkdir -p "${CLAUDE_DIR}/downloads"
mkdir -p "${CLAUDE_DIR}/file-history"
mkdir -p "${CLAUDE_DIR}/projects"
mkdir -p "${CLAUDE_DIR}/session-env"
mkdir -p "${CLAUDE_DIR}/sessions"
mkdir -p "${CLAUDE_DIR}/shell-snapshots"
mkdir -p "${CLAUDE_DIR}/statsig"
mkdir -p "${CLAUDE_DIR}/todos"

echo "==> Bootstrap complete."
echo
echo "Next step:"
echo "1. Start Claude Code once"
echo "2. Check whether plugins are recognized"
echo "3. If some plugins are missing, install them manually once in Claude Code"