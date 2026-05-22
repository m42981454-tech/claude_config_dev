---
description: 从 project.env 智能初始化新项目（替换占位符 + 清理未用行 + 推荐 agent 配置）
---

# /project:init — 新项目智能初始化

## 执行步骤

**Step 1 — 读取配置**

用 `Read` 工具读取 `project.env`，提取所有变量。若文件不存在，提示用户先填写并停止。

**Step 2 — 智能替换占位符**

对以下文件逐一执行替换（用 `Read` → `Edit`，不用 shell sed）：

| 文件 | 主要占位符 |
|---|---|
| `CLAUDE.md` | `[PROJECT_NAME]` / `[PHASE]` / `[DATE]` / `[MAIN_BRANCH]` / 目录名 / 技术栈描述 |
| `.claude/rules/git-workflow.md` | `[MAIN_BRANCH]`（约 15 处，用 `replace_all: true`）|
| `.claude/rules/behavioral-rules.md` | `[MAIN_BRANCH]` |
| `.claude/rules/project-context.md` | 技术栈版本 / 测试命令 |
| `.claude/rules/stack-backend.md` | frontmatter `[backend-dir]` + 技术栈列表 |
| `.claude/rules/stack-frontend.md` | frontmatter `[frontend-dir]` + 技术栈列表 |
| `.claude/rules/README.md` | `[backend-dir]` / `[frontend-dir]` |

**Step 3 — 智能清理**

读取替换后的 stack 文件，按以下规则清理：

- `STATE_MGMT` 为空 → 删除 stack-frontend.md 中 State 管理那行
- `I18N` / 国际化未配置 → 删除 i18n 行
- `DATABASE` 中无 Redis 描述 → 删除 Redis 行
- `TASK_QUEUE` 未配置 → 删除 Celery/BullMQ 行
- 替换完成后删除所有 `# ← ...` 注释行和文件顶部的 `<!-- ╔══...╚══ -->` 初始化注释块

**Step 4 — 推荐 agent 配置**

根据 `project.env` 的技术栈，输出建议的 `.claude/agents/.enabled` 内容：

```
# 根据你的技术栈，建议启用以下 agent：
api-tester          # 有后端 API
security-engineer   # 有 auth / token / 用户数据
database-optimizer  # 有数据库
devops-automator    # 有 Docker / CI
evidence-collector  # 有前端 UI
```

**Step 5 — 输出替换摘要**

列出所有替换结果（变量名 → 实际值），标出任何空值或需要手动确认的项。

## 完成后提示用户

```
✅ 初始化完成。剩余手动步骤：

1. 检查 stack-backend.md / stack-frontend.md — 删除不适用的技术行
2. 编辑 .claude/agents/.enabled（参考上方推荐）
3. 若无后端 → 删除 stack-backend.md；若无前端 → 删除 stack-frontend.md
4. 删除 project.env / SETUP.md（可保留 init.sh 作文档参考或直接删除）
5. git init && git add . && git commit -m "chore: init project from template"
6. 重启 Claude Code，验证 SessionStart 摘要正常
```
