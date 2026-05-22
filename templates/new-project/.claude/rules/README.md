---
paths:
  - ".claude/rules/**"
---

# .claude/rules/ 规则文件索引

> **加载**: path-scoped（仅在读写本目录文件时载入，不进 session baseline）
> **目的**: 一眼看清哪个规则文件做什么、什么时候生效

---

## 每会话加载（session baseline）

每次 Claude 会话启动时自动注入，无论当前工作在哪个目录。

| 文件 | 作用 |
|---|---|
| `engineering.md` | Karpathy 4 原则：Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven |
| `behavioral-rules.md` | DON'T 清单：不跳测试 / 不绕 hook / 不直接 commit 主线 / 不 push 等 |
| `team-orchestration.md` | 派单决策表 + 4 channel 可视化（完整模板见 skill `my-dispatch-templates`）|
| `git-workflow.md` | 子分支命名 / merge 规范 / chained-pipe 防御 / Issue-First gate |
| `architecture-policies.md` | 架构决策契约，偏离需写 decision doc |
| `project-context.md` | 项目背景、技术约束、验证要求（新项目初始化后填写）|

---

## Path-scoped（按目录按需加载）

只有 Claude 读写对应路径的文件时才载入，**不占 session baseline**。

| 文件 | 触发路径 | 作用 |
|---|---|---|
| `progress-conventions.md` | `progress.md` / `PROGRESS*.md` | PROGRESS 三件套维护规约 + 滚动归档触发 |
| `skill-promotion-path.md` | `.claude/skills/**` | skill 三阶段晋升路径 + 占位符变量表 |
| `docs-conventions.md` | `docs/**/*.md` | docs/ 命名规范 + 月份归档 + frontmatter 要求 |
| `stack-backend.md` | `[backend-dir]/**` | 后端技术栈 + 测试命令 + API 契约约定 |
| `stack-frontend.md` | `[frontend-dir]/**` | 前端技术栈 + 测试命令 + 组件/a11y/性能约定 |

> **`stack-backend.md` / `stack-frontend.md` 初始化步骤**（文件内有逐行说明）：
>
> 1. 把 frontmatter `paths:` 里的 `[backend-dir]` / `[frontend-dir]` 改为实际目录名（如 `backend/**`）
> 2. 按文件内 `# ← ...` 注释逐行替换技术栈、测试命令、约定内容
> 3. 删除所有 `# ← ...` 注释行和顶部初始化注释块
> 4. 若项目无后端或无前端，直接删除对应文件

---

## 按需创建（不在模板中，视项目需要新增）

| 文件名建议 | 作用 |
|---|---|
| `dev-commands.md` | docker compose / 测试 / type-check / 迁移等常用命令速查 |
| `stack-infra.md` | 基础设施约定（K8s / Terraform / CI/CD 配置规范）|
| `stack-data.md` | 数据层约定（schema 规范 / 迁移策略 / 慢查询阈值）|

---

## 文件命名约定

| 前缀 | 含义 | 示例 |
|---|---|---|
| `stack-` | 技术栈约定，path-scoped 到对应代码目录 | `stack-backend.md` |
| `behavioral-` / `-rules` | 行为纪律，每会话强制加载 | `behavioral-rules.md` |
| `*-conventions.md` | 格式 / 流程规范 | `progress-conventions.md` |
| `*-policies.md` | 架构决策契约 | `architecture-policies.md` |
| `*-workflow.md` | 操作流程 | `git-workflow.md` |
| `*-context.md` | 背景信息 | `project-context.md` |
