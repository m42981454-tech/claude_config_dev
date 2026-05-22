# 新项目初始化手顺

> 把 `new-project/` 模板复制到目标目录后，按本文件逐步完成初始化。
> 完成后删除本文件（或移入 `docs/`）。

---

## 快速核对：需要修改的文件

| 优先级 | 文件 | 改什么 |
|---|---|---|
| 🔴 必改 | `CLAUDE.md` | 项目名、阶段、主线分支、技术栈描述 |
| 🔴 必改 | `.claude/rules/git-workflow.md` | 主线分支名 |
| 🔴 必改 | `.claude/rules/behavioral-rules.md` | 主线分支名 |
| 🟡 必改 | `.claude/rules/project-context.md` | 技术栈详细版本 + 测试命令基线 |
| 🟡 必改 | `.claude/rules/stack-backend.md` | 后端技术栈 + 测试命令（文件内有逐行说明）|
| 🟡 必改 | `.claude/rules/stack-frontend.md` | 前端技术栈 + 测试命令（文件内有逐行说明）|
| ⚪ 按需 | `.claude/agents/.enabled` | 按需启用额外 agent |
| ⚪ 按需 | `progress.md` | 初始化任务列表 |

---

## Step 1 — CLAUDE.md（最先改，其他文件依赖它）

打开 `CLAUDE.md`，替换以下占位符：

| 占位符 | 说明 | 示例 |
|---|---|---|
| `[PROJECT_NAME]` | 项目名（英文，用于标题）| `my-app` / `acme-backend` |
| `[PHASE]` | 当前阶段描述 | `开发 / MVP / Beta / GA` |
| `[DATE]` | 今天的日期 | `2026-05-23` |
| `[backend-dir]` | 后端代码根目录名 | `backend` / `api` / `server` |
| `[frontend-dir]` | 前端代码根目录名 | `frontend` / `web` / `app` |
| `[BACKEND_STACK]` | 后端技术栈一句话描述 | `FastAPI + PostgreSQL` |
| `[FRONTEND_STACK]` | 前端技术栈一句话描述 | `Next.js 14 + TypeScript` |
| `[INFRA]` | 基础设施描述 | `Docker Compose + GitHub Actions` |
| `[MAIN_BRANCH]` | git 主线分支名 | `main` / `master` / `develop` |

> 若项目无前端：删除 §1 结构中的 `[frontend-dir]/` 行、§2 前端描述行、`stack-frontend.md` 文件。
> 若项目无后端：同理删除后端相关行和 `stack-backend.md`。

---

## Step 2 — git-workflow.md（替换主线分支名）

文件路径：`.claude/rules/git-workflow.md`

用编辑器全局替换：`[MAIN_BRANCH]` → 实际主线分支名（如 `main`）

出现约 15 处，一次性替换即可。

---

## Step 3 — behavioral-rules.md（替换主线分支名）

文件路径：`.claude/rules/behavioral-rules.md`

同样全局替换：`[MAIN_BRANCH]` → 实际主线分支名

---

## Step 4 — project-context.md（技术栈详细版本）

文件路径：`.claude/rules/project-context.md`

替换 §5 技术栈约束中的占位符：

| 占位符 | 说明 | 示例 |
|---|---|---|
| `[BACKEND_LANGUAGE_VERSION]` | 语言 + 版本 | `Python 3.11` / `Node 20` / `Go 1.22` |
| `[BACKEND_FRAMEWORK]` | Web 框架 | `FastAPI` / `Express` / `Gin` |
| `[ORM_AND_MIGRATIONS]` | ORM + 迁移工具 | `SQLAlchemy + Alembic` / `Prisma` |
| `[DATABASE]` | 数据库 + 版本 | `PostgreSQL 15 + Redis 7` |
| `[TEST_FRAMEWORK]` | 测试框架 | `pytest` / `Jest` / `go test` |
| `[FRONTEND_FRAMEWORK]` | 前端框架 | `Next.js 14 App Router` / `React + Vite` |
| `[LANGUAGE]` | 前端语言 | `TypeScript 5` / `JavaScript` |
| `[STYLING]` | 样式方案 | `Tailwind CSS 3 + shadcn/ui` |
| `[STATE_MGMT]` | 状态管理 | `TanStack Query` / `Zustand` |
| `[I18N]` | 国际化库（无则删行）| `next-intl` / `react-i18next` |

同时在 §6 测试硬性要求里填写当前测试基线数字：
- `<unit-pass>/<unit-total>` → 如 `142/142`
- `<e2e-pass>/<e2e-total>` → 如 `28/28`

---

## Step 5 — stack-backend.md（后端技术栈详细规则）

文件路径：`.claude/rules/stack-backend.md`

文件内已有逐行 `# ←` 注释指引，照着填即可。完成后：
1. 把 frontmatter `paths:` 里的 `[backend-dir]` 改为实际目录名（如 `backend/**`）
2. 删除所有 `# ← ...` 注释和顶部 `<!-- ... -->` 初始化注释块
3. 若无后端，删除本文件

---

## Step 6 — stack-frontend.md（前端技术栈详细规则）

文件路径：`.claude/rules/stack-frontend.md`

同 Step 5，文件内有逐行注释指引：
1. 把 frontmatter `paths:` 里的 `[frontend-dir]` 改为实际目录名（如 `frontend/**`）
2. 删除所有 `# ← ...` 注释和顶部 `<!-- ... -->` 初始化注释块
3. 若无前端，删除本文件

---

## Step 7 — .enabled（按需启用额外 agent）

文件路径：`.claude/agents/.enabled`

参照 `.claude/agents/.enabled.example` 的注释，取消需要的 agent 的 `#` 注释。

常见启用组合：

```
# Web 项目标配
security-engineer
api-tester
evidence-collector

# 有 DB 变更时加
database-optimizer

# 有 Docker / CI 时加
devops-automator
```

修改后重启 Claude Code，SessionStart hook 会自动从 L1.5 池复制缺失的 agent 文件。

---

## Step 8 — progress.md（初始化任务列表）

在根目录创建 `progress.md`，填写项目初始状态：

```markdown
# progress.md — [PROJECT_NAME]

[项目]        [PROJECT_NAME]
[主线名]      [MAIN_BRANCH]
[当前分支]    [MAIN_BRANCH]
[最后更新]    [DATE]
[当前 sprint] —
[burning]     —

## 🔄 当前进行中
_（无）_

## 🟡 已 merge 待验收
_（无）_

## 🔴 待做
### P — Planned
- ⏳ P0-1: [第一个 sprint 任务描述]

## ✅ 已完成
_（无）_
```

---

## 初始化完成后

- [ ] 删除本文件（`SETUP.md`），或 `git mv SETUP.md docs/` 归档
- [ ] 运行 `git init`（如果还未初始化）并做第一次 commit
- [ ] 重启 Claude Code，验证 H6 SessionStart 摘要输出正确的 branch / PROGRESS 行数
- [ ] 验证 `.claude/rules/stack-backend.md` 在进入后端目录时能正确加载（查看 context 里是否出现"Backend 约定"）
