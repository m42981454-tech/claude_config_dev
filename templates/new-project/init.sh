#!/usr/bin/env bash
# 新项目初始化脚本 — 读取 project.env，替换所有占位符
# 用法：bash init.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE="project.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ 找不到 $ENV_FILE，请先填写配置文件" >&2
  exit 1
fi

# 读取变量（跳过注释行和空行）
while IFS='=' read -r key value; do
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$key" ]] && continue
  key="${key%%#*}"          # 去掉行内注释
  key="${key%"${key##*[![:space:]]}"}"  # trim trailing space
  value="${value%%#*}"
  value="${value%"${value##*[![:space:]]}"}"
  export "$key=$value"
done < "$ENV_FILE"

DATE="${DATE:-$(date +%Y-%m-%d)}"

echo "▶ 开始初始化 PROJECT_NAME=$PROJECT_NAME MAIN_BRANCH=$MAIN_BRANCH"

# ---- 替换函数（用 | 作 delimiter，避免值中含 /）----
sub() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -i \
    -e "s|\\[PROJECT_NAME\\]|$PROJECT_NAME|g" \
    -e "s|\\[PHASE\\]|$PHASE|g" \
    -e "s|\\[DATE\\]|$DATE|g" \
    -e "s|\\[MAIN_BRANCH\\]|$MAIN_BRANCH|g" \
    -e "s|\\[backend-dir\\]|$BACKEND_DIR|g" \
    -e "s|\\[frontend-dir\\]|$FRONTEND_DIR|g" \
    -e "s|\\[BACKEND_STACK\\]|$BACKEND_STACK|g" \
    -e "s|\\[FRONTEND_STACK\\]|$FRONTEND_STACK|g" \
    -e "s|\\[INFRA\\]|$INFRA|g" \
    -e "s|\\[BACKEND_LANGUAGE_VERSION\\]|$BACKEND_LANGUAGE_VERSION|g" \
    -e "s|\\[BACKEND_FRAMEWORK\\]|$BACKEND_FRAMEWORK|g" \
    -e "s|\\[ORM_AND_MIGRATIONS\\]|$ORM_AND_MIGRATIONS|g" \
    -e "s|\\[DATABASE\\]|$DATABASE|g" \
    -e "s|\\[TEST_FRAMEWORK\\]|$TEST_FRAMEWORK_BACKEND|g" \
    -e "s|\\[FRONTEND_FRAMEWORK\\]|$FRONTEND_FRAMEWORK|g" \
    -e "s|\\[LANGUAGE\\]|$FRONTEND_LANGUAGE|g" \
    -e "s|\\[STYLING\\]|$STYLING|g" \
    -e "s|\\[STATE_MGMT\\]|$STATE_MGMT|g" \
    -e "s|\\[TEST_FRAMEWORK_FRONTEND\\]|$TEST_FRAMEWORK_FRONTEND|g" \
    "$file"
}

# ---- 需要替换的文件 ----
sub CLAUDE.md
sub .claude/rules/git-workflow.md
sub .claude/rules/behavioral-rules.md
sub .claude/rules/project-context.md
sub .claude/rules/stack-backend.md
sub .claude/rules/stack-frontend.md
sub .claude/rules/README.md
sub .githooks/pre-commit
sub progress.md

echo "✅ 占位符替换完成"
echo ""
echo "📋 后续手动步骤："
echo "  1. 检查 .claude/rules/stack-backend.md — 删除不适用的技术行（如无 Redis/Celery）"
echo "  2. 检查 .claude/rules/stack-frontend.md — 删除不适用的技术行（如无 i18n）"
echo "  3. 编辑 .claude/agents/.enabled — 按需启用额外 agent"
echo "  4. 若无后端：删除 .claude/rules/stack-backend.md"
echo "  5. 若无前端：删除 .claude/rules/stack-frontend.md"
echo "  6. 删除 project.env / init.sh / SETUP.md，做第一次 commit"
echo ""
echo "🚀 完成后重启 Claude Code，验证 SessionStart 摘要输出正常"
