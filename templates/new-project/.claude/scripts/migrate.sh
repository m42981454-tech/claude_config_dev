#!/usr/bin/env bash
# migrate.sh — 将 new-project 模板模块迁移到已有项目（不覆盖已有文件）。
#
# 用法:
#   bash /path/to/new-project/.claude/scripts/migrate.sh [TARGET_DIR]
#
# TARGET_DIR 省略时默认为当前目录（即已有项目根目录）。
# DRY_RUN=1 bash .claude/scripts/migrate.sh [TARGET_DIR] → 只打印动作，不实际执行。
#
# 不会修改 CLAUDE.md / progress.md（已有项目的核心文件由用户维护）。
# 不会运行 .claude/scripts/init.sh（仅适用于新建项目）。
set -u

TMPL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${1:-$(pwd)}"
DRY_RUN="${DRY_RUN:-0}"

COPIED=()
SKIPPED_EXISTS=()
APPENDED=()
MANUAL=()

# ── 输出工具 ──────────────────────────────────────────────────────────────────
ok()   { printf '  \033[32m✅ %s\033[0m\n' "$*"; }
skip() { printf '  \033[33m⏭  %s\033[0m\n' "$*"; }
note() { printf '  \033[36m📌 %s\033[0m\n' "$*"; MANUAL+=("$*"); }
warn() { printf '  \033[33m⚠️  %s\033[0m\n' "$*"; }
hdr()  { printf '\n▸ %s\n' "$*"; }

run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  \033[90m[dry] %s\033[0m\n' "$*"
  else
    eval "$@"
  fi
}

# ── 复制单文件（目标已存在则跳过）─────────────────────────────────────────────
copy_if_missing() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    skip "already exists, skipped: $(basename "$dst")"
    SKIPPED_EXISTS+=("$dst")
  else
    if [ "$DRY_RUN" = "1" ]; then
      ok "[dry] would copy: $dst"
    else
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      ok "copied: $dst"
    fi
    COPIED+=("$dst")
  fi
}

# ── 复制目录（逐文件，目标已存在则跳过）─────────────────────────────────────
copy_dir_missing() {
  local src_dir="$1" dst_dir="$2"
  for f in "$src_dir"/*; do
    [ -e "$f" ] || continue
    copy_if_missing "$f" "$dst_dir/$(basename "$f")"
  done
}

# ── 追加 .gitignore / .claudeignore 中尚未存在的行 ───────────────────────────
append_missing_lines() {
  local src="$1" dst="$2" label="$3"
  [ -f "$src" ] || return 0
  if [ ! -f "$dst" ]; then
    copy_if_missing "$src" "$dst"
    return
  fi
  local added=0
  while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    if ! grep -qxF "$line" "$dst" 2>/dev/null; then
      [ "$DRY_RUN" != "1" ] && printf '%s\n' "$line" >> "$dst"
      added=1
    fi
  done < "$src"
  if [ "$added" = "1" ]; then
    ok "appended missing entries → $label"
    APPENDED+=("$dst")
  else
    skip "no new entries to add → $label"
  fi
}

# ── 占位符替换（只在新复制的文件上执行）──────────────────────────────────────
_replace() {
  local file="$1" key="$2" val="$3"
  [ -f "$file" ] || return 0
  local escaped
  escaped=$(printf '%s' "$val" | sed -e 's/[\\&|]/\\&/g')
  sed -i -e "s|\\[$key\\]|$escaped|g" "$file"
}

sub_placeholders() {
  local file="$1"
  [ -f "$file" ] || return 0
  _replace "$file" "MAIN_BRANCH"             "$MAIN_BRANCH"
  _replace "$file" "PROJECT_NAME"            "$PROJECT_NAME"
  _replace "$file" "PHASE"                   "$PHASE"
  _replace "$file" "DATE"                    "$DATE"
  _replace "$file" "REPO_OWNER"              "$REPO_OWNER"
  _replace "$file" "REPO_NAME"               "$REPO_NAME"
  _replace "$file" "REPO"                    "$REPO_OWNER/$REPO_NAME"
  _replace "$file" "backend-dir"             "$BACKEND_DIR"
  _replace "$file" "frontend-dir"            "$FRONTEND_DIR"
  _replace "$file" "BACKEND_STACK"           "$BACKEND_STACK"
  _replace "$file" "FRONTEND_STACK"          "$FRONTEND_STACK"
  _replace "$file" "INFRA"                   "$INFRA"
  _replace "$file" "BACKEND_LANGUAGE_VERSION" "$BACKEND_LANGUAGE_VERSION"
  _replace "$file" "BACKEND_FRAMEWORK"       "$BACKEND_FRAMEWORK"
  _replace "$file" "ORM_AND_MIGRATIONS"      "$ORM_AND_MIGRATIONS"
  _replace "$file" "DATABASE"               "$DATABASE"
  _replace "$file" "TASK_QUEUE"              "$TASK_QUEUE"
  _replace "$file" "TEST_FRAMEWORK"          "$TEST_FRAMEWORK_BACKEND"
  _replace "$file" "FRONTEND_FRAMEWORK"      "$FRONTEND_FRAMEWORK"
  _replace "$file" "LANGUAGE"               "$FRONTEND_LANGUAGE"
  _replace "$file" "STYLING"                "$STYLING"
  _replace "$file" "STATE_MGMT"             "$STATE_MGMT"
  _replace "$file" "I18N"                   "$I18N"
  _replace "$file" "TEST_FRAMEWORK_FRONTEND" "$TEST_FRAMEWORK_FRONTEND"
}

# ─────────────────────────────────────────────────────────────────────────────
printf '\n'
printf '╔══════════════════════════════════════════════════════╗\n'
printf '║   new-project 模板迁移工具 (.claude/scripts/migrate.sh)  ║\n'
printf '╚══════════════════════════════════════════════════════╝\n'
printf '\n'
printf '  Template : %s\n' "$TMPL"
printf '  Target   : %s\n' "$TARGET"
[ "$DRY_RUN" = "1" ] && printf '  Mode     : DRY RUN（只打印，不实际执行）\n'
printf '\n'

if [ ! -d "$TARGET" ]; then
  printf '  ❌ Target 目录不存在: %s\n' "$TARGET"
  exit 1
fi

# ── 读取占位符变量 ────────────────────────────────────────────────────────────
# 优先从 target 的 project.env 读（若用户保留了它）；否则使用模板默认值。
MAIN_BRANCH="main"
PROJECT_NAME="my-app"
PHASE="development"
DATE="$(date +%Y-%m-%d)"
REPO_OWNER="my-org"
REPO_NAME="my-app"
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"
BACKEND_STACK="FastAPI + PostgreSQL"
FRONTEND_STACK="Next.js 14 + TypeScript"
INFRA="Docker Compose + GitHub Actions"
BACKEND_LANGUAGE_VERSION="Python 3.11"
BACKEND_FRAMEWORK="FastAPI"
ORM_AND_MIGRATIONS="SQLAlchemy + Alembic"
DATABASE="PostgreSQL 15"
TASK_QUEUE="Celery"
TEST_FRAMEWORK_BACKEND="pytest"
FRONTEND_FRAMEWORK="Next.js 14 App Router"
FRONTEND_LANGUAGE="TypeScript 5"
STYLING="Tailwind CSS 3"
STATE_MGMT="TanStack Query"
I18N="next-intl"
TEST_FRAMEWORK_FRONTEND="Jest + Playwright"

trim() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

if [ -f "$TARGET/project.env" ]; then
  printf '  📄 从 project.env 读取占位符值\n'
  while IFS='=' read -r k v || [ -n "${k:-}" ]; do
    [[ "${k:-}" =~ ^[[:space:]]*# ]] && continue
    k="$(trim "${k:-}")"
    [ -z "$k" ] && continue
    v="${v%%#*}"
    v="$(trim "$v")"
    export "$k=$v"
  done < "$TARGET/project.env"
else
  printf '  ℹ️  project.env 不存在，使用模板默认占位符值\n'
  printf '     （迁移完成后可手动在规则文件中替换 [MAIN_BRANCH] 等占位符）\n'
fi
printf '\n'

# ─────────────────────────────────────────────────────────────────────────────
# CLAUDE.md / progress.md — validate.sh 必需；已有项目应已存在，不存在时从模板创建最小版本
hdr "CLAUDE.md"
if [ -f "$TARGET/CLAUDE.md" ]; then
  skip "already exists — 对照 $TMPL/CLAUDE.md 手动补充缺失节"
  note "手动对照补充: CLAUDE.md（参照 $TMPL/CLAUDE.md）"
else
  warn "CLAUDE.md 不存在，从模板复制（含占位符，需手动替换项目信息）"
  if [ "$DRY_RUN" != "1" ]; then
    cp "$TMPL/CLAUDE.md" "$TARGET/CLAUDE.md"
    sub_placeholders "$TARGET/CLAUDE.md"
    ok "created: CLAUDE.md（请替换顶部占位符为实际项目信息）"
  else
    ok "[dry] would copy + substitute: CLAUDE.md"
  fi
  COPIED+=("$TARGET/CLAUDE.md")
fi

hdr "progress.md"
if [ -f "$TARGET/progress.md" ]; then
  skip "already exists"
else
  warn "progress.md 不存在，从模板复制（含占位符，需手动替换）"
  if [ "$DRY_RUN" != "1" ]; then
    cp "$TMPL/progress.md" "$TARGET/progress.md"
    sub_placeholders "$TARGET/progress.md"
    ok "created: progress.md（请替换顶部占位符为实际项目信息）"
  else
    ok "[dry] would copy + substitute: progress.md"
  fi
  COPIED+=("$TARGET/progress.md")
fi

hdr ".claude/scripts/"
copy_dir_missing "$TMPL/.claude/scripts" "$TARGET/.claude/scripts"

hdr ".claude/commands/"
for d in "$TMPL/.claude/commands"/*/; do
  [ -d "$d" ] || continue
  ns="$(basename "$d")"
  for f in "$d"*.md; do
    [ -e "$f" ] || continue
    copy_if_missing "$f" "$TARGET/.claude/commands/$ns/$(basename "$f")"
  done
done

hdr ".claude/agents/"
copy_dir_missing "$TMPL/.claude/agents/_available" "$TARGET/.claude/agents/_available"
copy_if_missing  "$TMPL/.claude/agents/README.md"        "$TARGET/.claude/agents/README.md"
copy_if_missing  "$TMPL/.claude/agents/.enabled.example" "$TARGET/.claude/agents/.enabled.example"

hdr ".claude/rules/"
# 需要占位符替换的规则文件（与 init.sh targets 对齐）
RULE_SUB_FILES=(
  git-workflow.md
  behavioral-rules.md
  project-context.md
  stack-backend.md
  stack-frontend.md
  README.md
)
for f in "$TMPL/.claude/rules/"*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  dst="$TARGET/.claude/rules/$name"
  if [ -e "$dst" ]; then
    skip "already exists, skipped (手动 merge): $name"
    SKIPPED_EXISTS+=("$dst")
    note "手动 merge: .claude/rules/$name"
  else
    if [ "$DRY_RUN" = "1" ]; then
      ok "[dry] would copy + substitute: $dst"
    else
      mkdir -p "$TARGET/.claude/rules"
      cp "$f" "$dst"
      # 对需要替换的规则文件做占位符替换
      for sub_name in "${RULE_SUB_FILES[@]}"; do
        if [ "$name" = "$sub_name" ]; then
          sub_placeholders "$dst"
          break
        fi
      done
      ok "copied + substituted: $dst"
    fi
    COPIED+=("$dst")
  fi
done

hdr ".claude/skills/"
if [ -d "$TMPL/.claude/skills" ]; then
  for d in "$TMPL/.claude/skills"/*/; do
    [ -d "$d" ] || continue
    skill_name="$(basename "$d")"
    dst_skill="$TARGET/.claude/skills/$skill_name"
    if [ -e "$dst_skill" ]; then
      skip "skill already exists: $skill_name"
    else
      if [ "$DRY_RUN" = "1" ]; then
        ok "[dry] would copy skill: $skill_name"
      else
        mkdir -p "$TARGET/.claude/skills"
        cp -r "$d" "$dst_skill" && ok "copied skill: $skill_name" || warn "failed to copy skill: $skill_name"
      fi
      COPIED+=("$dst_skill")
    fi
  done
fi

hdr ".githooks/"
copy_dir_missing "$TMPL/.githooks" "$TARGET/.githooks"
# pre-commit 含 [MAIN_BRANCH] 占位符，与 init.sh 对齐做替换
if [ -f "$TARGET/.githooks/pre-commit" ]; then
  [ "$DRY_RUN" != "1" ] && sub_placeholders "$TARGET/.githooks/pre-commit"
fi
if [ -f "$TARGET/.githooks/install.sh" ]; then
  if [ "$DRY_RUN" != "1" ]; then
    (cd "$TARGET" && bash .githooks/install.sh 2>/dev/null) && ok "hooks installed (core.hooksPath=.githooks)"
  else
    ok "[dry] would run: bash .githooks/install.sh"
  fi
fi

hdr ".gitattributes"
copy_if_missing "$TMPL/.gitattributes" "$TARGET/.gitattributes"

hdr ".gitignore (追加缺失行)"
append_missing_lines "$TMPL/.gitignore" "$TARGET/.gitignore" ".gitignore"

hdr ".claudeignore (追加缺失行)"
append_missing_lines "$TMPL/.claudeignore" "$TARGET/.claudeignore" ".claudeignore"

hdr ".claude/settings.json"
if [ -f "$TARGET/.claude/settings.json" ]; then
  skip "already exists — hook 段需手动 merge"
  note "手动 merge hook 段: .claude/settings.json（参照 $TMPL/.claude/settings.json）"
else
  copy_if_missing "$TMPL/.claude/settings.json" "$TARGET/.claude/settings.json"
fi

hdr "docs/postmortems/"
copy_if_missing "$TMPL/docs/postmortems/README.md" "$TARGET/docs/postmortems/README.md"

hdr "docs/report/ 目录"
if [ ! -d "$TARGET/docs/report" ]; then
  [ "$DRY_RUN" != "1" ] && mkdir -p "$TARGET/docs/report"
  ok "created: docs/report/"
else
  skip "already exists: docs/report/"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n'
printf '══════════════════════════════════════════════════════\n'
printf '  迁移完成\n'
printf '  已复制 / 创建 : %d 项\n' "${#COPIED[@]}"
printf '  追加行        : %d 项\n' "${#APPENDED[@]}"
printf '  已跳过（已存在）: %d 项\n' "${#SKIPPED_EXISTS[@]}"
printf '\n'

if [ "${#MANUAL[@]}" -gt 0 ]; then
  printf '  📌 需要手动 review 的项目：\n'
  for item in "${MANUAL[@]}"; do
    printf '     - %s\n' "$item"
  done
  printf '\n'
fi

printf '  下一步：\n'
printf '    1. 检查上方 ⏭ 跳过项，按需手动 merge（尤其是 settings.json 和 rules）。\n'
printf '    2. 对照 %s/CLAUDE.md，补充 CLAUDE.md 中缺失的节。\n' "$TMPL"
printf '    3. 确认 progress.md 存在且格式合规。\n'
printf '    4. 运行: bash .claude/scripts/validate.sh\n'
printf '    5. 不需要运行 init.sh（仅适用于新建项目）。\n'
printf '    6. migrate.sh / project.env 可在确认完成后删除（可选）。\n'
printf '══════════════════════════════════════════════════════\n'
printf '\n'

exit 0
