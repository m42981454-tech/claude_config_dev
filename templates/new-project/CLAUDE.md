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

## 4. Agent / Team 分工（三层架构）

**默认**：当前会话（PM = Opus 主线）自己处理，不开子代理。
**例外**：用户明确要求 team 处理 / 并行执行时，派 sub-agent。

完整派单决策表 + 派单模板见 [`.claude/rules/team-orchestration.md`](./.claude/rules/team-orchestration.md)。

### 三层 Agent 架构

```
L1   <agent-reference-root>/              188 个   完整 catalog（备查，不加载）
L1.5 <agent-dev-pool>/                    44 个    dev 专家池（项目按需选用）
L2   <global-claude-config>/agents/       8 个     全局 baseline（任何项目都加载）
L3   <project>/.claude/agents/            按项目    项目专属 agent + 本地覆盖
```

### L2 用户级基础工具箱（任何项目都加载，从用户级 `<global-claude-config>/agents`）

| Agent ID | Model | 触发场景 |
|---|---|---|
| **project-manager-senior** | opus | 需求拆解、任务规划 |
| **code-reviewer** | sonnet | 每 sprint 必经审查 |
| **minimal-change-engineer** | haiku | bug fix / 小修小补 |
| **git-workflow-master** | haiku | git 操作 / 分支策略 |

### L3 项目默认角色（本项目模板默认 5 个，从 `.claude/agents/` 加载）

| Agent ID | Model | 触发场景 |
|---|---|---|
| **agents-orchestrator** | sonnet | 多 agent 流水线协调 |
| **backend-architect** | sonnet | 后端 API / 服务架构 / 数据库 |
| **frontend-developer** | sonnet | React / Vue / CSS / 组件 |
| **reality-checker** | sonnet | release readiness / GA 前复核 |
| **project-management-jira-workflow-steward** | opus | Jira-linked git workflow |

模板目录保留开发项目常用默认角色；可从 `<agent-dev-pool>` 取得的专项专家仍通过 `.enabled` 按需复制。项目确实需要覆盖共享池行为时，才在 `.claude/agents/` 放同名本地版本。

### 推荐补位角色（从 L1.5 池按需启用）

L2 用户级角色覆盖 PM、代码审查、最小变更和 Git；L3 模板角色覆盖编排、后端、前端、现实复核和 Jira-linked workflow。其他专家从 L1.5 dev 池按需启用，不默认全量加载，避免把上下文和工具面重新撑大。

| Agent ID | 建议启用时机 |
|---|---|
| **security-engineer** | 有登录、权限、密钥、支付、用户数据、网络边界或合规风险时 |
| **api-tester** | 有 API contract、外部集成、endpoint 回归或服务间协议变更时 |
| **test-results-analyzer** | 需要分析测试报告、失败分布、flaky pattern 或质量趋势时 |
| **performance-benchmarker** | 需要负载测试、延迟/吞吐基准、瓶颈定位或性能验收时 |
| **accessibility-auditor** | 有 UI、表单、键盘导航、ARIA 或 WCAG 验收要求时 |
| **devops-automator** | 有 Docker、CI/CD、部署、监控、环境变量或基础设施变更时 |
| **evidence-collector** | 需要浏览器证据、截图、日志、可复现步骤或 UI 验收证明时 |
| **codebase-onboarding-engineer** | 新项目初始化、接手陌生仓库、模块边界不清或需要风险地图时 |
| **technical-writer** | 文档密集 sprint、release notes、runbook、ADR 或面向团队交接时 |
| **software-architect** | 跨系统设计、边界重划、长期架构决策或重大技术选型时 |
| **ai-engineer** | 有 ML、AI 集成、模型部署或生产 AI 功能时 |
| **data-engineer** | 有 ETL/ELT、dbt、lakehouse、数据平台或数据质量链路时 |
| **database-optimizer** | 有 schema、索引、慢查询、迁移影响或数据库性能风险时 |
| **incident-response-commander** | 有生产事故、postmortem、on-call 或应急流程建设时 |
| **sre-site-reliability-engineer** | 有 SLO、error budget、observability、toil reduction 或可靠性治理时 |
| **lsp-index-engineer** | 有 LSP 编排、semantic indexing 或代码智能基础设施时 |
| **mcp-builder** | 有 MCP server、tools、resources、prompts 或 agent capability 集成时 |

### 现有测试类 agent 覆盖判断

| Agent ID | 覆盖范围 | 不适合替代 |
|---|---|---|
| **api-tester** | API contract、endpoint health、集成回归、API 性能与安全关注 | 不替代浏览器验收、整体测试报告分析或无障碍审计 |
| **test-results-analyzer** | 聚合测试结果、失败模式、flaky 分析、质量指标和改进建议 | 不直接执行 API/E2E 测试 |
| **performance-benchmarker** | 性能基准、延迟、吞吐、瓶颈证明和优化验证 | 不替代功能正确性测试 |
| **accessibility-auditor** | WCAG、键盘导航、屏幕阅读器、ARIA 和真实可访问性风险 | 不替代视觉截图验收 |
| **evidence-collector** | 浏览器证据、截图、日志、复现步骤和现实检查 | 不替代专门的 API contract 或性能基准 |

### 动态加载 — `.enabled` 清单（从 L1.5 池追加）

需要其他 dev 专家时（如 `security-engineer` / `api-tester` / `devops-automator` 等），编辑：

```
.claude/agents/.enabled
```

一行一个 kebab-case agent ID（必须匹配 L1.5 池中 frontmatter `name:`），# 开头是注释。SessionStart hook 会自动从 `<agent-dev-pool>` 复制缺失 agent 到项目 `.claude/agents/`。如果项目本地已经存在同名 agent 文件，项目版本优先，不会被共享池覆盖。

`.enabled` 示例:

```
# 本项目需要的额外 agent
security-engineer
api-tester
test-results-analyzer
performance-benchmarker
accessibility-auditor
evidence-collector
devops-automator
```

可用清单（44 个）：`ls <agent-dev-pool>/`

**加载优先级**: L3 项目级 > L2 用户级（同名时项目级覆盖，仅对该项目生效）。

### 派单关键约定

- subagent_type / agent ID 使用当前 agent frontmatter 的 kebab-case `name`（如 `backend-architect`）
- 派单时 4 channel 强制：description（ch1）+ commit subject（ch2）+ PROGRESS 表（ch3）+ agent 返回 header（ch4）
- 必经双签：`code-reviewer` + tester（如 `api-tester` / `evidence-collector`）
- 按需追加签字 ❌ → 阻断 merge

### 派单模板

```
Agent({
  description: "[T#·Role·Sprint·Phase] <动词 + 短描述>",
  subagent_type: "backend-architect",
  prompt: "上下文：...（文件路径 + 行号 + 相关规范）。
           任务：...（明确动作，最小变更范围）。
           验收：...（测试命令 / 期望测试通过）。
           完成后报告：变更文件清单 + 测试结果。"
})
```

> Model 在 agent frontmatter 已定，调用时不必再指定（临时 override 加 `model:` 参数）。

完整派单模板（含 Security / Reality Checker / SRE / DevOps / DBOpt / Incident Commander / Product Manager 等）→ [`.claude/rules/team-orchestration.md §2.7`](./.claude/rules/team-orchestration.md)。

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
