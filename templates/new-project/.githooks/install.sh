#!/usr/bin/env bash
# Install project-local Git hooks.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Not inside a git repository. Run git init first." >&2
  exit 1
fi

cd "$REPO_ROOT"
git config core.hooksPath ".githooks"
chmod +x ".githooks/pre-commit"

echo "Git hooks installed: core.hooksPath=.githooks"
echo "pre-commit blocks direct commits to protected main branches."
