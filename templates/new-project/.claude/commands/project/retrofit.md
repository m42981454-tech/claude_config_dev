---
description: 给已有项目追加 Claude Code 模板基础设施（非破坏性，跳过已存在文件）
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# /project:retrofit

给**已有项目**补装 Claude Code 模板基础设施。与 `/project:init` 的区别：不依赖 `project.env`，逐项检测已有文件后跳过，仅补缺失部分，全程交互式收集实际值。

## 执行步骤

---

### Step 1 — 检测现有状态

用 Glob / Bash 扫描以下路径，建立"已有 / 缺失"清单：

| 检测路径 | 说明 |
|---|---|
| `CLAUDE.md` | 项目级主配置 |
| `.claude/settings.json` | hooks 配置 |
| `.claude/agents/` | 项目级 agent 目录 |
| `.claude/commands/` | 自定义命令目录 |
| `.claude/skills/` | 自定义 skill 目录 |
| `.claude/rules/` | 规则文件目录 |
| `.claude/scripts/` | hook 脚本目录 |
| `progress.md` | 任务进度文件 |
| `.githooks/pre-commit` | 主线保护 hook |
| `.githooks/install.sh` | hook 安装脚本 |
| `.gitignore` | 是否含 `CLAUDE.local.md` |
| `docs/postmortems/README.md` | postmortem 索引 |
| `.github/workflows/claude-review.yml` | CI 评审 workflow |
| `.claudeignore` | context 排除配置 |

输出检测摘要（✅ 已有 / ❌ 缺失），然后继续。

---

### Step 2 — 收集项目信息

向用户提问，获取以下变量（仅询问尚未能从现有文件推断的）：

```
PROJECT_NAME   = ?   # 如能从现有 CLAUDE.md / package.json / pyproject.toml 读到则跳过
MAIN_BRANCH    = ?   # 优先 git symbolic-ref refs/remotes/origin/HEAD；无远端则问用户
PHASE          = ?   # 当前阶段，如 MVP / Beta / v1.0（默认 MVP）
BACKEND_STACK  = ?   # 如 FastAPI / Express / Django / none
FRONTEND_STACK = ?   # 如 Next.js / React / Vue / none
```

推断方式（按优先级）：
- `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||'` → MAIN_BRANCH
- 读取已有 `CLAUDE.md` 提取 PROJECT_NAME
- 读取 `package.json` 的 `name` 字段 → PROJECT_NAME
- 读取 `pyproject.toml` 的 `[project] name` → PROJECT_NAME
- 以上均无则直接询问用户

每个变量确认后记录，不能为空。

---

### Step 3 — 逐项补装（跳过已有）

对每一项：**先检查是否已存在，存在则跳过并注明，缺失则创建。**

#### 3-A　`progress.md`

若缺失，创建以下内容（用收集到的实际值替换占位符）：

```markdown
```
[项目]       {PROJECT_NAME}
[主线名]     {MAIN_BRANCH}
[当前 sprint] —
[最后更新]   {TODAY}
[burning]    —

权威查询命令：
  git log -3 --oneline
  git status
  git branch -a
  gh issue list --state open
```

---

## 🔄 当前进行中

| Track | Sprint | Role(s) | Phase | Branch | Status | ETA |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

---

## 🔴 未完成

### U — 未分类 / 待排期

| N# | 优先级 | 任务 | 依据 | Issue |
|---|---|---|---|---|
| N1 | ⚡ 高 | [第一个任务] | — | — |

### P — 基础设施 / 平台

_（无）_

### L — 功能迭代

_（无）_

### H — 历史遗留

_（无）_

---

## 🟡 待用户验收

_（无）_

---

## ✅ 已完成

| Sprint | 内容 | Merge 日期 |
|---|---|---|
| chore/retrofit | 追加 Claude Code 模板基础设施 | {TODAY} |
```

#### 3-B　`CLAUDE.md`

- 若已存在：**不覆盖**。检查是否缺少 `## Compaction Rules` 段，若缺则在文件末尾追加：

```markdown

## Compaction Rules

When compacting, always preserve:
- Full list of modified files (with paths)
- Current sprint name and phase (design / impl / review / test)
- All test commands run this session and their results
- Any architectural decisions made this session
- Open blockers or unresolved questions
- Error messages and their resolutions
```

- 若不存在：从模板创建完整 CLAUDE.md，用实际值替换所有占位符，并提示用户填写技术栈章节。

#### 3-C　`.claude/` 目录结构

逐个检查，仅创建缺失的目录和文件：

- `.claude/settings.json` — 缺失则写入基础 hooks 配置（SessionStart / SessionEnd / PreToolUse）
- `.claude/agents/` — 缺失则从模板复制 8 个项目级 agent（backend-architect / frontend-developer / reality-checker / security-engineer / api-tester / database-optimizer / agents-orchestrator / project-management-jira-workflow-steward）
- `.claude/commands/` — 缺失则从模板复制全套命令（cr / debug / issue / status / postmortem / sprint/* / git/branch / project/init）
- `.claude/skills/` — 缺失则从模板复制全套 skill
- `.claude/rules/` — 缺失则从模板复制全套规则文件，并对 git-workflow.md / behavioral-rules.md 中的 `[MAIN_BRANCH]` 执行替换
- `.claude/scripts/` — 缺失则复制 agent-loader.sh / session-end-learn.sh
- `.claude/.gitignore` — 缺失则创建

> **复制来源**：模板文件位于 `~/.claude/templates/new-project/.claude/`。
> 用 `Read` 读取模板内容，`Write` 写入目标项目路径。

#### 3-D　`.githooks/`

若缺失，创建以下两个文件（`{MAIN_BRANCH}` 替换为实际值）：

**`.githooks/pre-commit`**：
```bash
#!/bin/bash
# 拒绝直接 commit 到主线（main / {MAIN_BRANCH}）。
# merge commit、cherry-pick、revert 不受限制。

PROTECTED="main {MAIN_BRANCH}"
CURRENT=$(git symbolic-ref --short HEAD 2>/dev/null)

for branch in $PROTECTED; do
    if [ "$CURRENT" = "$branch" ]; then
        GIT_DIR=$(git rev-parse --git-dir)
        [ -f "$GIT_DIR/MERGE_HEAD" ]        && exit 0
        [ -f "$GIT_DIR/CHERRY_PICK_HEAD" ]  && exit 0
        [ -f "$GIT_DIR/REVERT_HEAD" ]       && exit 0
        echo "❌ 禁止直接 commit 到主线 '$branch'。请开子分支后再提交。"
        echo "   git checkout -b $branch.<topic>"
        exit 1
    fi
done

exit 0
```

**`.githooks/install.sh`**：
```bash
#!/bin/bash
set -e
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    echo "❌ 不在 git repo 内，请先 git init。"
    exit 1
fi
git config core.hooksPath "$REPO_ROOT/.githooks"
chmod +x "$REPO_ROOT/.githooks/pre-commit"
echo "✅ git hooks 已安装（core.hooksPath = $REPO_ROOT/.githooks）"
echo "   pre-commit: 拒绝直接 commit 到主线"
```

创建后自动执行 `bash .githooks/install.sh`（项目已有 git repo，无需 git init）。

#### 3-E　`.gitignore`

- 若已存在：检查是否含 `CLAUDE.local.md`，若无则在文件末尾追加：
  ```
  # 个人 Claude Code 本地覆盖
  CLAUDE.local.md
  ```
- 若不存在：创建含 `CLAUDE.local.md` 的基础 `.gitignore`。

#### 3-F　`docs/postmortems/README.md`

若缺失，创建目录和文件（从模板复制内容）。

#### 3-G　`.github/workflows/claude-review.yml`（可选）

询问用户是否需要 CI 自动 review：
- 是 → 创建（若已存在则跳过）
- 否 → 跳过

#### 3-H　`.claudeignore`（视情况）

若项目根目录有 `templates/` 或其他大型文档目录需要排除，询问用户是否需要创建。

---

### Step 4 — 输出安装摘要

```
━━━ /project:retrofit 完成 ━━━━━━━━━━━━━━━━━━━
✅ 新建：<列出所有新创建的文件>
⏭️  跳过：<列出所有已存在而跳过的文件>
⚠️  追加：<列出追加了内容的已有文件>

后续手动步骤：
  1. 检查 .claude/rules/stack-backend.md — 填写实际技术栈
  2. 检查 .claude/rules/stack-frontend.md — 填写实际技术栈
  3. 编辑 .claude/agents/.enabled — 按需启用 agent
  4. 重启 Claude Code，验证 SessionStart 摘要正常
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## $ARGUMENTS

无参数。直接运行 `/project:retrofit`。

## 关联

- `/project:init` — 新项目版本（依赖 `project.env`）
- `~/.claude/templates/new-project/` — 模板文件来源
- `.claude/rules/git-workflow.md` — 分支 / hook 规约
- `progress.md` — 任务进度唯一真相源
