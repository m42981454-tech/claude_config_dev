#!/bin/bash
# 安装 .githooks/ 到当前 git repo（需 Git 2.9+）。
# 运行一次即可：bash .githooks/install.sh

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    echo "❌ 不在 git repo 内，请先 git init。"
    exit 1
fi

git config core.hooksPath "$REPO_ROOT/.githooks"
chmod +x "$REPO_ROOT/.githooks/pre-commit"

echo "✅ git hooks 已安装（core.hooksPath = .githooks）"
echo "   pre-commit: 拒绝直接 commit 到主线"
