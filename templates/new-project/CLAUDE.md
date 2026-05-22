# [PROJECT_NAME] — Project Conventions

> 当前阶段：**[PHASE]**（截至 [DATE]）
> [Brief phase description]

---

## 1. 仓库结构（关键路径）

```
[project-root]/
├── [backend-dir]/              # [BACKEND_STACK] 后端
│   ├── app/                    # 应用模块
│   ├── tests/                  # 测试套件
│   ├── docs/                   # 后端文档
│   └── ...
├── [frontend-dir]/             # [FRONTEND_STACK] 前端
│   ├── app/                    # 页面
│   ├── components/             # 组件
│   ├── lib/                    # 工具库
│   └── ...
├── docs/                       # 项目级文档
├── docker-compose.dev.yml      # 本地开发栈（如有）
├── progress.md                 # ★ 任务状态唯一真相源
└── CLAUDE.md                   # 本文件
```

不要碰：[列出旧/废弃/不属于当前工作目标的目录]

---

## 2. 技术栈（概述）

- **后端**：[BACKEND_STACK]（详见 [`.claude/rules/backend.md`](./.claude/rules/backend.md)，工作在 `[backend-dir]/` 时自动加载）
- **前端**：[FRONTEND_STACK]（详见 [`.claude/rules/frontend.md`](./.claude/rules/frontend.md)，工作在 `[frontend-dir]/` 时自动加载）
- **基础设施**：[INFRA]

---

## 3. 当前任务与状态

状态唯一真相源：**`progress.md`**（根目录）。

| ID | 任务 | 状态 |
|---|---|---|
| | | |

PROGRESS 维护规约见 [`.claude/rules/progress-conventions.md`](./.claude/rules/progress-conventions.md)。

---

## 4. Agent / Team 分工

**默认**：当前会话（PM = Opus 主线）自己处理，不开子代理。
**例外**：用户明确要求 team 处理 / 并行执行时，派 sub-agent。

完整派单决策表 + 13 个 agent 模板见 [`.claude/rules/team-orchestration.md`](./.claude/rules/team-orchestration.md)。

### 基础三件套（每 sprint 默认走，工具权限锁）

| Role | subagent_type | Model | 工具权限（frontmatter `tools:` 锁定）|
|---|---|---|---|
| **PM** | (当前会话) | opus | * |
| **Implementer** | `implementer` | sonnet | Read / Glob / Grep / Bash / Edit / MultiEdit / Write |
| **Reviewer** | `reviewer` | sonnet | Read / Glob / Grep / Bash（**无** Edit/Write，只读）|
| **Tester** | `tester` | haiku | Read / Glob / Grep / Bash（**无** Edit/Write，只读）|

工具权限由 agent 文件 frontmatter 锁定 → Reviewer / Tester 即使想"小修一下"也写不了文件（deterministic）。

### 项目级专家（按需追加，从 [`.claude/agents/`](./.claude/agents/) 调用）

按 [team-orchestration.md §2.5 触发决策表](./.claude/rules/team-orchestration.md) 自动追加签字：

| Agent (Title Case) | Model | 触发场景 |
|---|---|---|
| Backend Architect | sonnet | 后端 API / 服务架构 / 数据库 / 云端服务 |
| Frontend Developer | sonnet | React / Vue / CSS / 组件 / accessibility |
| Minimal Change Engineer | sonnet | 单文件 bug fix / typo / 小逻辑改 |
| Code Reviewer | sonnet | 每 sprint 必经 |
| API Tester | sonnet | API 健康检查 / contract / 鉴权 |
| Evidence Collector | sonnet | UI / 浏览器证据（screenshot / console）|
| Security Engineer | sonnet | auth / token / secrets / OWASP-relevant |
| Reality Checker | sonnet | release readiness / GA 前复核 |
| **AI Engineer** | sonnet | ML 模型 / AI 集成 / 数据 pipeline |
| **Database Optimizer** | sonnet | DB schema / 索引 / 性能 / migration 影响 |
| **Data Engineer** | sonnet | ETL/ELT / Spark / dbt / 数据基础设施 |
| **Incident Response Commander** | sonnet | 生产事故 / postmortem / on-call |
| **SRE** | sonnet | SLO / 监控 / chaos engineering / toil |
| **LSP/Index Engineer** | sonnet | LSP 客户端编排 / semantic indexing |
| **Jira Workflow Steward** | opus | Jira-linked git workflow / 多团队协调 |
| **MCP Builder** | sonnet | Model Context Protocol server 开发 |
| **Accessibility Auditor** | sonnet | WCAG 审计 / 屏幕阅读器测试 |
| **Performance Benchmarker** | sonnet | 性能测量 / 优化 / 基线对比 |
| **Test Results Analyzer** | sonnet | 测试结果分析 / 质量指标 |

**派单关键约定**：

- subagent_type 用 Title Case **friendly name**（如 `"Backend Architect"`），**不是** kebab-case file name
- 派单时 4 channel 强制：description（ch1）+ commit subject（ch2）+ PROGRESS 表（ch3）+ agent 返回 header（ch4）
- 必经双签：Code Reviewer + Tester；按需追加签字 ❌ → 阻断 merge

### 派单模板（基础三件套）

```
Agent({
  description: "[T#·Role·Sprint·Phase] <动词 + 短描述>",
  subagent_type: "implementer",   // 或 reviewer / tester
  prompt: "上下文：...（文件路径 + 行号 + 相关规范）。
           任务：...（明确动作，最小变更范围）。
           验收：...（测试命令 / 期望测试通过）。
           完成后报告：变更文件清单 + 测试结果。"
})
```

> Model 在 agent frontmatter 已定，调用时不必再指定（临时 override 加 `model:` 参数）。

完整 13 个派单模板（含 Security / Reality Checker / SRE / DevOps / DBOpt / Incident Commander / Product Manager 等）→ [`.claude/rules/team-orchestration.md §2.7`](./.claude/rules/team-orchestration.md)。

---

## 5. Engineering rules — Always invoke `karpathy-guidelines` skill

详见 [`.claude/rules/engineering.md`](./.claude/rules/engineering.md) 和 [`.claude/rules/behavioral-rules.md`](./.claude/rules/behavioral-rules.md) §10。要点：

- **强制 trigger 时机**：写新代码 / Review diff / Refactor / 用户明示
- **4 原则**：Think Before Coding → Simplicity First → Surgical Changes → Goal-Driven Execution
- **全角色共同行为基础**：PM / Implementer / Reviewer / Tester 都遵循

---

## 6. 测试要求（通用原则）

- 不删除既有测试，不用 `@pytest.mark.skip` 或 `test.skip` 绕过失败
- 影响共享契约 / 路由 / API client / UI shell 的变更，必须扩大验证范围
- E2E 浏览器验证时，console 无 error 循环才算通过
- 具体命令：后端见 [`.claude/rules/backend.md`](./.claude/rules/backend.md)，前端见 [`.claude/rules/frontend.md`](./.claude/rules/frontend.md)

---

## 7. Git Workflow

详细规则见 [`.claude/rules/git-workflow.md`](./.claude/rules/git-workflow.md)。要点：

- **主线**：`[MAIN_BRANCH]`（PR → `main`）
- ❌ 不直接 commit 主线 — 所有改动开子分支 `[MAIN_BRANCH].<topic>`（`.ph<N>` / `.fix<M>` / `.chore.<topic>`）
- ✅ merge 用 `--no-ff -m "<src> -> <dst>: <what>"`，merge 后立刻 `git branch -d <name>` 删临时分支
- ❌ 不 push 远端 / 不 amend 已 push / 不 rebase 已 merge / 不 force push

**PROGRESS 更新时机（新工作流）**：

- ✅ progress.md 更新作为 **sprint 分支的最后一个 commit**，与 code 改动**一次 merge** 同时入主线
- ❌ 不再单独走 `chore.progress` 分支做第二次 merge（除非紧急 hotfix 后补 / 跨 sprint 归档整理）
- 详见 [`.claude/rules/git-workflow.md §7.7`](./.claude/rules/git-workflow.md) + [`progress-conventions.md`](./.claude/rules/progress-conventions.md)

**并行隔离**：

- 并行多个独立任务时用 git worktree 隔离（详见 git-workflow.md §7.7-§7.8），避免同目录双 Claude 互踩

---

## 8. 架构政策与文档约定

- **架构契约**：见 [`.claude/rules/architecture-policies.md`](./.claude/rules/architecture-policies.md)（source of truth；偏离需写 decision doc）
- **docs/ 命名 + 月份归档 + frontmatter**：见 [`.claude/rules/docs-conventions.md`](./.claude/rules/docs-conventions.md)（path-scoped 自动加载 `docs/**/*.md`）

---

## 9. 自定义 skills / commands / hooks

### Skills（[`.claude/skills/`](./.claude/skills/)）

| Skill | 触发场景 |
|---|---|
| `my-start-sprint` | "启动 P0-X" / "启动 sprint X" / "启动 ph<N>" — 7 步 SOP |
| `my-dispatch-sprint` | 显式派单（`disable-model-invocation: true`）— 13 agent 决策表 |
| `my-issue-first-gate` | 开 sprint 子分支前必先 `gh issue create` |
| `my-pm-progress-sync` | progress.md 更新（新工作流：作为 sprint 分支 last commit）|
| `my-postmortem` | 事故复盘 8 段标准结构 |
| `my-start-container` | 开新滚动容器（`disable-model-invocation: true`，必满足 5 条件）|

晋升路径：见 [`.claude/rules/skill-promotion-path.md`](./.claude/rules/skill-promotion-path.md)（项目级 → user-level → plugin 三阶段）。

### Commands（[`.claude/commands/`](./.claude/commands/)）

| Command | 作用 |
|---|---|
| `/cr` | 并发 code review（6 specialist agent 同时跑）|
| `/postmortem` | 事故复盘入口 |
| `/sprint:start` | 启动新 sprint（调 `my-start-sprint`）|
| `/sprint:dispatch` | 显式派单（调 `my-dispatch-sprint`）|
| `/sprint:sync` | progress.md 同步（调 `my-pm-progress-sync`）|
| `/sprint:container` | 开新滚动容器（调 `my-start-container`）|

### Hooks（[`.claude/settings.json`](./.claude/settings.json)）

| Hook | 时机 | 作用 |
|---|---|---|
| H1 (PreToolUse) | Bash 执行前 | 拦危险命令：`--no-verify` / force-push main / `rm -rf .claude` / chained-pipe with checkout/merge |
| H2-pre (PreToolUse) | sprint merge 前 | 检查 sprint 分支 last commit 是否含 progress.md，未触及则警告 |
| H2-post (PostToolUse) | sprint merge 后 | 兜底：若漏 progress.md 更新，提示开 chore.progress 补救 |
| H6 (SessionStart) | 会话起 | 显示 branch / ahead / open issues / progress.md 行数 |

---

## 10. .claude/rules/ 全部 sub-rules 索引

| 文件 | 加载机制 | 作用 |
|---|---|---|
| [`engineering.md`](./.claude/rules/engineering.md) | 每会话 | karpathy 4 原则（强制 trigger 时机 + 速查）|
| [`behavioral-rules.md`](./.claude/rules/behavioral-rules.md) | 每会话 | DON'T 清单 + karpathy §10 联动 |
| [`team-orchestration.md`](./.claude/rules/team-orchestration.md) | 每会话 | 派单决策表 + 13 模板 + 4 channel |
| [`git-workflow.md`](./.claude/rules/git-workflow.md) | 每会话 | 子分支 / merge / chained-pipe 防御 / Issue-First gate |
| [`progress-conventions.md`](./.claude/rules/progress-conventions.md) | 每会话 | PROGRESS 三件套 + 滚动归档 + 维护时机 |
| [`architecture-policies.md`](./.claude/rules/architecture-policies.md) | 每会话 | 架构政策（source of truth，偏离需 decision doc）|
| [`skill-promotion-path.md`](./.claude/rules/skill-promotion-path.md) | 每会话 | skill 三阶段晋升 + 占位符变量表 |
| [`docs-conventions.md`](./.claude/rules/docs-conventions.md) | **path-scoped** `docs/**/*.md` | docs/ 命名 + 月份归档 + frontmatter |
| [`backend.md`](./.claude/rules/backend.md) | **path-scoped** `[backend-dir]/**` | 后端技术栈 + 测试命令 + 约定 |
| [`frontend.md`](./.claude/rules/frontend.md) | **path-scoped** `[frontend-dir]/**` | 前端技术栈 + 测试命令 + 约定 |
| `dev-commands.md`（**按需创建**）| — | docker compose / 测试 / type-check / 迁移 等 |

---

## 11. 不要做（DON'T）

- ❌ 不删除既有测试或用 skip 绕过失败
- ❌ 不绕过 hooks（`--no-verify` / `--no-gpg-sign`）
- ❌ 不在 UI/API 变更后留下持续刷新的 console error 循环
- ❌ 不在修复聚焦问题时顺手做大范围重构（per karpathy §10 Surgical Changes）
- ❌ 不直接 commit 到主线——所有改动必须先开子分支（见 §7）
- ❌ sprint merge 前 progress.md 未更新就 merge（新工作流：progress 作为 sprint 分支 last commit）
- ❌ 不 push 远端（除非用户明确要求）
- ❌ 不在主线 Opus 上做编码工作——派给 Sonnet sub-agent
